import SwiftUI

@main
struct PulseRTApp: App {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(iconColor)
                Text(viewModel.displayCount)
                    .monospacedDigit()
                    .foregroundStyle(countColor)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Computed Properties

    /// Color for the menu bar icon based on connection state
    private var iconColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return .primary
        case .connecting:
            return .secondary
        case .disconnected:
            return .secondary
        case .error:
            return .orange
        }
    }

    /// Color for the count text based on connection state
    private var countColor: Color {
        switch viewModel.connectionState {
        case .connected:
            return .primary
        case .connecting:
            return .secondary
        case .disconnected:
            return .secondary
        case .error:
            return .orange
        }
    }
}
