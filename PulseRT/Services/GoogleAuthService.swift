import Foundation

/// Errors that can occur during Google authentication
enum GoogleAuthError: LocalizedError {
    case credentialsNotConfigured
    case jwtCreationFailed(Error)
    case tokenExchangeFailed(Error)
    case invalidTokenResponse
    case httpError(statusCode: Int, message: String?)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .credentialsNotConfigured:
            return "Service account credentials are not configured"
        case .jwtCreationFailed(let error):
            return "Failed to create JWT: \(error.localizedDescription)"
        case .tokenExchangeFailed(let error):
            return "Failed to exchange JWT for access token: \(error.localizedDescription)"
        case .invalidTokenResponse:
            return "Received invalid token response from Google"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "HTTP error \(statusCode): \(message)"
            }
            return "HTTP error \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

/// Service for authenticating with Google APIs using service account credentials
actor GoogleAuthService {
    /// Shared singleton instance
    static let shared = GoogleAuthService()

    /// Google OAuth token endpoint
    private let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!

    /// Cached access token
    private var cachedToken: CachedToken?

    /// URL session for network requests
    private let session: URLSession

    /// JSON decoder for parsing responses
    private let decoder: JSONDecoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Gets a valid access token, refreshing if necessary
    /// - Returns: Valid access token string
    func getAccessToken() async throws -> String {
        // Check if we have a valid cached token
        if let cached = cachedToken, !cached.shouldRefresh {
            return cached.token.accessToken
        }

        // Need to refresh or get new token
        let token = try await fetchNewToken()
        cachedToken = CachedToken(token: token, obtainedAt: Date())
        return token.accessToken
    }

    /// Forces a token refresh, ignoring any cached token
    /// - Returns: New access token string
    func forceRefresh() async throws -> String {
        let token = try await fetchNewToken()
        cachedToken = CachedToken(token: token, obtainedAt: Date())
        return token.accessToken
    }

    /// Checks if we have a valid (non-expired) cached token
    var hasValidToken: Bool {
        guard let cached = cachedToken else { return false }
        return !cached.isExpired
    }

    /// Clears the cached token
    func clearToken() {
        cachedToken = nil
    }

    /// Returns time until token expires, or nil if no token
    var tokenExpiresIn: TimeInterval? {
        guard let cached = cachedToken else { return nil }
        return cached.expiresAt.timeIntervalSince(Date())
    }

    // MARK: - Token Exchange

    /// Fetches a new access token from Google
    private func fetchNewToken() async throws -> TokenResponse {
        // Load credentials
        let credentials: ServiceAccountCredentials
        do {
            credentials = try ConfigurationService.shared.loadCredentials()
        } catch {
            throw GoogleAuthError.credentialsNotConfigured
        }

        // Create signed JWT
        let jwt: String
        do {
            jwt = try JWTSigner.createSignedJWT(credentials: credentials)
        } catch {
            throw GoogleAuthError.jwtCreationFailed(error)
        }

        // Exchange JWT for access token
        return try await exchangeJWTForToken(jwt)
    }

    /// Exchanges a signed JWT for an access token
    /// - Parameter jwt: Signed JWT assertion
    /// - Returns: Token response from Google
    private func exchangeJWTForToken(_ jwt: String) async throws -> TokenResponse {
        // Build request
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build form body
        let grantType = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        let body = "grant_type=\(grantType.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? grantType)&assertion=\(jwt)"
        request.httpBody = body.data(using: .utf8)

        // Send request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GoogleAuthError.networkError(error)
        }

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleAuthError.invalidTokenResponse
        }

        // Handle error responses
        if httpResponse.statusCode != 200 {
            let errorMessage = parseErrorResponse(data)
            throw GoogleAuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage
            )
        }

        // Parse token response
        do {
            return try decoder.decode(TokenResponse.self, from: data)
        } catch {
            throw GoogleAuthError.tokenExchangeFailed(error)
        }
    }

    /// Parses error response from Google
    private func parseErrorResponse(_ data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: String?
            let errorDescription: String?

            enum CodingKeys: String, CodingKey {
                case error
                case errorDescription = "error_description"
            }
        }

        guard let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) else {
            return String(data: data, encoding: .utf8)
        }

        if let description = errorResponse.errorDescription {
            return "\(errorResponse.error ?? "unknown"): \(description)"
        }
        return errorResponse.error
    }
}
