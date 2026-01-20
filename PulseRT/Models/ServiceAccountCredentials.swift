import Foundation

/// Google Cloud service account credentials structure
/// Matches the JSON format exported from Google Cloud Console
struct ServiceAccountCredentials: Codable, Equatable {
    /// Service account type (should be "service_account")
    let type: String

    /// Google Cloud project ID
    let projectId: String

    /// Private key ID for identification
    let privateKeyId: String

    /// PEM-encoded RSA private key for signing JWTs
    let privateKey: String

    /// Service account email address (used as JWT issuer)
    let clientEmail: String

    /// Client ID from Google Cloud
    let clientId: String

    /// Authentication URI
    let authUri: String

    /// Token URI for exchanging JWTs for access tokens
    let tokenUri: String

    /// Auth provider certificate URL
    let authProviderX509CertUrl: String

    /// Client certificate URL
    let clientX509CertUrl: String

    /// Universe domain (typically "googleapis.com")
    let universeDomain: String?

    enum CodingKeys: String, CodingKey {
        case type
        case projectId = "project_id"
        case privateKeyId = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientId = "client_id"
        case authUri = "auth_uri"
        case tokenUri = "token_uri"
        case authProviderX509CertUrl = "auth_provider_x509_cert_url"
        case clientX509CertUrl = "client_x509_cert_url"
        case universeDomain = "universe_domain"
    }

    /// Validates that this is a valid service account credential
    var isValid: Bool {
        type == "service_account" &&
        !privateKey.isEmpty &&
        !clientEmail.isEmpty &&
        privateKey.contains("BEGIN") &&
        privateKey.contains("PRIVATE KEY")
    }
}
