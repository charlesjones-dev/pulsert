import Foundation

// MARK: - RealtimeResponse

/// Response from GA4 Real-Time API runRealtimeReport endpoint
/// Represents the active user count and related metrics
struct RealtimeResponse: Codable, Equatable, Sendable {
    /// Array of data rows (may be empty if no active users)
    let rows: [RealtimeRow]?

    /// Total count of rows returned
    let rowCount: Int?

    /// Metadata about the response
    let metadata: RealtimeMetadata?

    /// Extracts the active user count from the response
    /// Returns 0 if rows array is nil or empty (no active users)
    var activeUsers: Int {
        guard let rows, let firstRow = rows.first else {
            return 0
        }
        guard let firstMetric = firstRow.metricValues?.first else {
            return 0
        }
        return Int(firstMetric.value) ?? 0
    }
}

// MARK: - RealtimeRow

/// A single row in the real-time report response
struct RealtimeRow: Codable, Equatable, Sendable {
    /// Array of metric values for this row
    let metricValues: [RealtimeMetricValue]?

    /// Array of dimension values for this row (if dimensions were requested)
    let dimensionValues: [RealtimeDimensionValue]?
}

// MARK: - RealtimeMetricValue

/// A metric value in the response
struct RealtimeMetricValue: Codable, Equatable, Sendable {
    /// The metric value as a string (numeric values are still strings in the API)
    let value: String
}

// MARK: - RealtimeDimensionValue

/// A dimension value in the response
struct RealtimeDimensionValue: Codable, Equatable, Sendable {
    /// The dimension value as a string
    let value: String
}

// MARK: - RealtimeMetadata

/// Metadata about the real-time report
struct RealtimeMetadata: Codable, Equatable, Sendable {
    /// Currency code used in the report
    let currencyCode: String?

    /// Time zone used in the report
    let timeZone: String?
}
