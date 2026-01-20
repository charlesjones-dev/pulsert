import Foundation

/// Response from Google OAuth token endpoint
/// Represents the access token received after JWT exchange
struct TokenResponse: Codable, Equatable, Sendable {
    /// The access token for API requests
    let accessToken: String

    /// Token lifetime in seconds (typically 3600)
    let expiresIn: Int

    /// Token type (typically "Bearer")
    let tokenType: String

    /// Optional scope granted (may differ from requested)
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
    }
}

/// Cached access token with expiry tracking
struct CachedToken: Sendable {
    /// The token response from Google
    let token: TokenResponse

    /// When the token was obtained
    let obtainedAt: Date

    /// Calculated expiry time
    var expiresAt: Date {
        obtainedAt.addingTimeInterval(TimeInterval(token.expiresIn))
    }

    /// Check if token is expired
    var isExpired: Bool {
        Date() >= expiresAt
    }

    /// Check if token will expire within the given time interval
    /// - Parameter interval: Time interval in seconds to check
    /// - Returns: True if token expires within the interval
    func expiresWithin(_ interval: TimeInterval) -> Bool {
        Date().addingTimeInterval(interval) >= expiresAt
    }

    /// Check if token should be refreshed (expired or within 5 minutes of expiry)
    var shouldRefresh: Bool {
        isExpired || expiresWithin(300) // 5 minutes
    }
}
