import Foundation

/// Errors that can occur during Analytics API operations
enum AnalyticsError: LocalizedError {
    case invalidPropertyId
    case authenticationFailed(Error)
    case networkError(Error)
    case httpError(statusCode: Int, message: String?)
    case invalidResponse
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidPropertyId:
            return "Invalid GA4 property ID"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "API error \(statusCode): \(message)"
            }
            return "API error \(statusCode)"
        case .invalidResponse:
            return "Received invalid response from Analytics API"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

/// Service for fetching real-time analytics data from GA4 API
actor AnalyticsService {
    /// Shared singleton instance
    static let shared = AnalyticsService()

    /// GA4 Data API base URL
    private let baseURL = "https://analyticsdata.googleapis.com/v1beta/properties"

    /// URL session for network requests
    private let session: URLSession

    /// JSON decoder for parsing responses
    private let decoder: JSONDecoder

    /// JSON encoder for creating request bodies
    private let encoder: JSONEncoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Public API

    /// Fetches the current active user count from GA4 Real-Time API
    /// - Parameter propertyId: The GA4 property ID (numeric string)
    /// - Returns: The number of active users
    func fetchActiveUsers(propertyId: String) async throws -> Int {
        // Validate property ID
        guard !propertyId.isEmpty, propertyId.allSatisfy({ $0.isNumber }) else {
            throw AnalyticsError.invalidPropertyId
        }

        // Get access token
        let accessToken: String
        do {
            accessToken = try await GoogleAuthService.shared.getAccessToken()
        } catch {
            throw AnalyticsError.authenticationFailed(error)
        }

        // Build request
        let url = URL(string: "\(baseURL)/\(propertyId):runRealtimeReport")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        let requestBody = RealtimeReportRequest(
            metrics: [RealtimeMetric(name: "activeUsers")]
        )

        do {
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            throw AnalyticsError.networkError(error)
        }

        // Send request
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AnalyticsError.networkError(error)
        }

        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalyticsError.invalidResponse
        }

        // Handle error responses
        if httpResponse.statusCode != 200 {
            let errorMessage = parseErrorResponse(data)
            throw AnalyticsError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage
            )
        }

        // Parse response
        let realtimeResponse: RealtimeResponse
        do {
            realtimeResponse = try decoder.decode(RealtimeResponse.self, from: data)
        } catch {
            throw AnalyticsError.decodingFailed(error)
        }

        return realtimeResponse.activeUsers
    }

    // MARK: - Private Helpers

    /// Parses error response from Google Analytics API
    private func parseErrorResponse(_ data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let error: ErrorDetail?
        }

        struct ErrorDetail: Decodable {
            let code: Int?
            let message: String?
            let status: String?
        }

        guard let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) else {
            return String(data: data, encoding: .utf8)
        }

        if let detail = errorResponse.error {
            if let message = detail.message {
                return message
            }
            if let status = detail.status {
                return status
            }
        }

        return nil
    }
}

// MARK: - Request Models

/// Request body for runRealtimeReport API
private struct RealtimeReportRequest: Encodable {
    let metrics: [RealtimeMetric]
}

/// A metric to request in the report
private struct RealtimeMetric: Encodable {
    let name: String
}
