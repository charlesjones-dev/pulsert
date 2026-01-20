import SwiftUI

/// Main dropdown menu content for the menu bar
struct MenuBarView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.openSettings) private var openSettings

    private let configurationService = ConfigurationService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Property header
            propertyHeader
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

            Divider()

            // Menu items
            Button {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openSettings()
            } label: {
                Text("Settings...")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit PulseRT")
            }
            .keyboardShortcut("q", modifiers: .command)

            Divider()

            // Version footer
            Text("PulseRT v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
        }
    }

    // MARK: - App Version

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Subviews

    @ViewBuilder
    private var propertyHeader: some View {
        let config = configurationService.loadConfigurationOrDefault()

        VStack(alignment: .leading, spacing: 4) {
            // Property name or placeholder
            Text(config.propertyName ?? "PulseRT")
                .font(.headline)
                .foregroundStyle(.primary)

            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Last updated timestamp
            if let lastUpdated = viewModel.lastUpdated {
                Text("Last updated: \(lastUpdated.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch viewModel.connectionState {
        case .connected:
            .green
        case .connecting:
            .gray
        case .disconnected:
            .gray
        case .error:
            .orange
        }
    }

    private var statusText: String {
        switch viewModel.connectionState {
        case .connected:
            if let count = viewModel.activeUsers {
                return "\(count) active user\(count == 1 ? "" : "s")"
            }
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case let .error(message):
            // Truncate long error messages
            let truncated = message.prefix(30)
            return truncated.count < message.count ? "\(truncated)..." : message
        }
    }
}

#Preview {
    MenuBarView(viewModel: AnalyticsViewModel())
        .frame(width: 200)
}
