import Foundation
import Security

// MARK: - JWTSignerError

/// Errors that can occur during JWT signing operations
enum JWTSignerError: LocalizedError {
    case invalidPEMFormat
    case pemDecodingFailed
    case privateKeyCreationFailed(OSStatus)
    case signingFailed(OSStatus)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidPEMFormat:
            "Private key is not in valid PEM format"
        case .pemDecodingFailed:
            "Failed to decode PEM private key data"
        case let .privateKeyCreationFailed(status):
            "Failed to create private key from data: OSStatus \(status)"
        case let .signingFailed(status):
            "Failed to sign JWT: OSStatus \(status)"
        case .encodingFailed:
            "Failed to encode JWT components"
        }
    }
}

// MARK: - JWTClaims

/// JWT claims for Google OAuth service account authentication
struct JWTClaims: Encodable {
    /// Issuer - service account email
    let iss: String

    /// Scope - API permissions requested
    let scope: String

    /// Audience - token endpoint
    let aud: String

    /// Issued at - Unix timestamp
    let iat: Int

    /// Expiration - Unix timestamp
    let exp: Int
}

// MARK: - JWTSigner

/// Utility for creating and signing JWTs using RS256
final class JWTSigner: Sendable {
    /// Google Analytics readonly scope
    static let analyticsReadonlyScope = "https://www.googleapis.com/auth/analytics.readonly"

    /// Google OAuth token endpoint
    static let tokenAudience = "https://oauth2.googleapis.com/token"

    /// Token validity duration in seconds (1 hour)
    static let tokenDuration: Int = 3600

    private init() {}

    // MARK: - Public API

    /// Creates a signed JWT for service account authentication
    /// - Parameters:
    ///   - credentials: Service account credentials containing private key and email
    ///   - scope: OAuth scope to request (defaults to Analytics readonly)
    /// - Returns: Signed JWT string
    static func createSignedJWT(
        credentials: ServiceAccountCredentials,
        scope: String = analyticsReadonlyScope
    ) throws -> String {
        let now = Int(Date().timeIntervalSince1970)

        let claims = JWTClaims(
            iss: credentials.clientEmail,
            scope: scope,
            aud: tokenAudience,
            iat: now,
            exp: now + tokenDuration
        )

        return try sign(claims: claims, privateKeyPEM: credentials.privateKey)
    }

    // MARK: - JWT Construction

    /// Signs JWT claims with the provided private key
    /// - Parameters:
    ///   - claims: JWT claims to sign
    ///   - privateKeyPEM: PEM-encoded RSA private key
    /// - Returns: Signed JWT string
    static func sign(claims: JWTClaims, privateKeyPEM: String) throws -> String {
        // Create JWT header
        let header: [String: String] = [
            "alg": "RS256",
            "typ": "JWT"
        ]

        // Encode header and claims
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONEncoder().encode(claims)

        let headerBase64 = base64URLEncode(headerData)
        let claimsBase64 = base64URLEncode(claimsData)

        // Create signing input
        let signingInput = "\(headerBase64).\(claimsBase64)"

        guard let signingInputData = signingInput.data(using: .utf8) else {
            throw JWTSignerError.encodingFailed
        }

        // Extract private key and sign
        let privateKey = try extractPrivateKey(from: privateKeyPEM)
        let signature = try signRS256(data: signingInputData, privateKey: privateKey)
        let signatureBase64 = base64URLEncode(signature)

        return "\(signingInput).\(signatureBase64)"
    }

    // MARK: - Private Key Extraction

    /// Extracts RSA private key from PEM-encoded string
    /// - Parameter pem: PEM-encoded private key string
    /// - Returns: SecKey for signing operations
    static func extractPrivateKey(from pem: String) throws -> SecKey {
        // Remove PEM headers and whitespace
        let pemContent = pem
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: pemContent) else {
            throw JWTSignerError.pemDecodingFailed
        }

        // For PKCS#8 format (Google service account keys), extract the RSA key
        let rsaKeyData = try extractRSAKeyFromPKCS8(keyData)

        // Create SecKey from the key data
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateWithData(
            rsaKeyData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            // Try with original data if PKCS#8 extraction fails
            guard let privateKey = SecKeyCreateWithData(
                keyData as CFData,
                attributes as CFDictionary,
                &error
            ) else {
                throw JWTSignerError.privateKeyCreationFailed(-1)
            }
            return privateKey
        }

        return privateKey
    }

    /// Extracts RSA private key from PKCS#8 format
    /// Google service account keys use PKCS#8 wrapper around the RSA key
    private static func extractRSAKeyFromPKCS8(_ pkcs8Data: Data) throws -> Data {
        // PKCS#8 structure:
        // SEQUENCE {
        //   INTEGER (version)
        //   SEQUENCE (algorithm identifier)
        //   OCTET STRING (private key)
        // }
        //
        // The OCTET STRING contains the actual RSA private key in PKCS#1 format

        var index = 0
        let bytes = [UInt8](pkcs8Data)

        // Skip outer SEQUENCE tag and length
        guard bytes.count > 2, bytes[index] == 0x30 else {
            return pkcs8Data // Return as-is if not PKCS#8 format
        }
        index += 1
        index = skipASN1Length(bytes: bytes, index: index)

        // Skip version INTEGER
        guard index < bytes.count, bytes[index] == 0x02 else {
            return pkcs8Data
        }
        index += 1
        let versionLength = Int(bytes[index])
        index += 1 + versionLength

        // Skip algorithm identifier SEQUENCE
        guard index < bytes.count, bytes[index] == 0x30 else {
            return pkcs8Data
        }
        index += 1
        index = skipASN1Length(bytes: bytes, index: index)

        // Skip algorithm OID and parameters
        while index < bytes.count, bytes[index] != 0x04 {
            if bytes[index] == 0x06 { // OID
                index += 1
                let oidLength = Int(bytes[index])
                index += 1 + oidLength
            } else if bytes[index] == 0x05 { // NULL
                index += 2
            } else {
                index += 1
            }
        }

        // Extract OCTET STRING containing RSA private key
        guard index < bytes.count, bytes[index] == 0x04 else {
            return pkcs8Data
        }
        index += 1
        index = skipASN1Length(bytes: bytes, index: index)

        // The remaining bytes are the RSA private key in PKCS#1 format
        let rsaKeyData = Data(bytes[index...])

        return rsaKeyData
    }

    /// Skips ASN.1 length encoding and returns new index
    private static func skipASN1Length(bytes: [UInt8], index: Int) -> Int {
        var idx = index
        guard idx < bytes.count else { return idx }

        let lengthByte = bytes[idx]
        idx += 1

        if lengthByte & 0x80 == 0 {
            // Short form: length is the byte itself
            return idx
        } else {
            // Long form: lower 7 bits indicate number of length bytes
            let numLengthBytes = Int(lengthByte & 0x7F)
            return idx + numLengthBytes
        }
    }

    // MARK: - RS256 Signing

    /// Signs data using RS256 (RSA PKCS#1 v1.5 with SHA-256)
    /// - Parameters:
    ///   - data: Data to sign
    ///   - privateKey: RSA private key
    /// - Returns: Signature data
    private static func signRS256(data: Data, privateKey: SecKey) throws -> Data {
        var error: Unmanaged<CFError>?

        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            throw JWTSignerError.signingFailed(-1)
        }

        return signature as Data
    }

    // MARK: - Base64URL Encoding

    /// Encodes data using Base64URL encoding (URL-safe, no padding)
    /// - Parameter data: Data to encode
    /// - Returns: Base64URL encoded string
    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
