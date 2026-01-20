import Foundation

/// User configuration for PulseRT application
struct AppConfiguration: Codable, Equatable {
    /// GA4 property ID (numeric string, e.g., "123456789")
    var propertyId: String

    /// Optional display name for the property (e.g., "charlesjones.dev")
    var propertyName: String?

    /// Polling interval in seconds (default: 10)
    var refreshIntervalSeconds: Int

    /// Default configuration with reasonable defaults
    static var `default`: AppConfiguration {
        AppConfiguration(
            propertyId: "",
            propertyName: nil,
            refreshIntervalSeconds: 10
        )
    }

    /// Validates that the property ID is a non-empty numeric string
    var isValid: Bool {
        !propertyId.isEmpty && propertyId.allSatisfy(\.isNumber)
    }
}
