import Combine
import Foundation

// MARK: - ConnectionState

/// Represents the current connection state of the analytics polling
enum ConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    var description: String {
        switch self {
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting..."
        case .connected:
            "Connected"
        case let .error(message):
            "Error: \(message)"
        }
    }
}

// MARK: - AnalyticsViewModel

/// ViewModel for managing GA4 real-time analytics polling
@MainActor
final class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current active user count (nil if not yet fetched)
    @Published private(set) var activeUsers: Int?

    /// Current connection state
    @Published private(set) var connectionState: ConnectionState = .disconnected

    /// Last error message (nil if no error)
    @Published private(set) var lastError: String?

    /// Timestamp of the last successful update
    @Published private(set) var lastUpdated: Date?

    // MARK: - Computed Properties

    /// Display string for active user count
    /// Returns the count as a string, or "--" if not available
    var displayCount: String {
        guard let count = activeUsers else {
            return "--"
        }
        return "\(count)"
    }

    // MARK: - Private Properties

    /// Current backoff interval in seconds
    private var backoffSeconds: Int = 10

    /// Minimum backoff interval
    private let minBackoffSeconds: Int = 10

    /// Maximum backoff interval
    private let maxBackoffSeconds: Int = 60

    /// Polling task
    private var pollingTask: Task<Void, Never>?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Configuration service reference
    private let configurationService = ConfigurationService.shared

    /// Analytics service reference
    private let analyticsService = AnalyticsService.shared

    // MARK: - Initialization

    init() {
        // Auto-start polling on launch
        startPolling()
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Public API

    /// Starts polling for active user count
    func startPolling() {
        guard pollingTask == nil else { return }

        connectionState = .connecting
        lastError = nil
        backoffSeconds = minBackoffSeconds

        pollingTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                await self.fetchActiveUsers()

                // Determine sleep interval based on connection state
                let sleepInterval: Int = if case .error = self.connectionState {
                    self.backoffSeconds
                } else {
                    self.getRefreshInterval()
                }

                do {
                    try await Task.sleep(for: .seconds(sleepInterval))
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }
    }

    /// Stops polling for active user count
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        connectionState = .disconnected
    }

    /// Forces an immediate refresh
    func refresh() async {
        await fetchActiveUsers()
    }

    // MARK: - Private Methods

    /// Fetches the current active user count
    private func fetchActiveUsers() async {
        let config = configurationService.loadConfigurationOrDefault()

        guard config.isValid else {
            connectionState = .error("Property ID not configured")
            lastError = "Property ID not configured"
            return
        }

        do {
            let count = try await analyticsService.fetchActiveUsers(propertyId: config.propertyId)

            // Success - update state
            activeUsers = count
            connectionState = .connected
            lastError = nil
            lastUpdated = Date()

            // Reset backoff on success
            resetBackoff()
        } catch {
            // Error - apply backoff
            let errorMessage = error.localizedDescription
            connectionState = .error(errorMessage)
            lastError = errorMessage

            // Increase backoff for next attempt
            increaseBackoff()
        }
    }

    /// Gets the configured refresh interval in seconds
    private func getRefreshInterval() -> Int {
        let config = configurationService.loadConfigurationOrDefault()
        return max(config.refreshIntervalSeconds, minBackoffSeconds)
    }

    /// Increases the backoff interval using exponential backoff
    private func increaseBackoff() {
        backoffSeconds = min(backoffSeconds * 2, maxBackoffSeconds)
    }

    /// Resets the backoff interval to minimum
    private func resetBackoff() {
        backoffSeconds = minBackoffSeconds
    }
}
