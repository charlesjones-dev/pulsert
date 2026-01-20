import SwiftUI

/// Represents the credential loading status
enum CredentialStatus: Equatable {
    case notFound
    case invalidJSON(String)
    case invalidStructure(String)
    case loaded(email: String)

    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
}

/// Settings window view with full configuration UI
struct SettingsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Local State

    @State private var propertyId: String = ""
    @State private var displayName: String = ""
    @State private var refreshInterval: Int = 10
    @State private var credentialStatus: CredentialStatus = .notFound
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""

    // MARK: - Services

    private let configurationService = ConfigurationService.shared

    // MARK: - Constants

    private let refreshIntervalOptions = [5, 10, 30, 60]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Credentials Status Section
            credentialsSection

            Divider()

            // Configuration Section
            configurationSection

            Spacer()

            // Footer Buttons
            footerButtons
        }
        .padding(32)
        .frame(width: 480, height: 460)
        .onAppear(perform: loadCurrentSettings)
    }

    // MARK: - Credentials Section

    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Credentials Status")
                .font(.headline)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    credentialStatusRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            HStack {
                Spacer()
                Button("Open Credentials Folder") {
                    openCredentialsFolder()
                }
            }
        }
    }

    @ViewBuilder
    private var credentialStatusRow: some View {
        switch credentialStatus {
        case .loaded(let email):
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Service account loaded")
                        .fontWeight(.medium)
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        case .notFound:
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Credentials file not found")
                        .fontWeight(.medium)
                    Text("Place credentials.json in ~/.config/pulsert/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

        case .invalidJSON(let message):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invalid JSON in credentials file")
                        .fontWeight(.medium)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

        case .invalidStructure(let message):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invalid credentials structure")
                        .fontWeight(.medium)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Property ID Field
            VStack(alignment: .leading, spacing: 6) {
                Text("GA4 Property ID")
                    .font(.headline)
                TextField("123456789", text: $propertyId)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: propertyId) { _, newValue in
                        // Filter to only allow numeric characters
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            propertyId = filtered
                        }
                        // Clear validation error when user edits
                        showValidationError = false
                    }
                if showValidationError && !validationErrorMessage.isEmpty {
                    Text(validationErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Display Name Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Name (optional)")
                    .font(.headline)
                TextField("charlesjones.dev", text: $displayName)
                    .textFieldStyle(.roundedBorder)
            }

            // Refresh Interval Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Refresh Interval")
                    .font(.headline)
                Picker("", selection: $refreshInterval) {
                    ForEach(refreshIntervalOptions, id: \.self) { interval in
                        Text("\(interval) seconds").tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        HStack {
            Button("View Setup Guide") {
                openSetupGuide()
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)

            Button("Save") {
                saveSettings()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Actions

    private func loadCurrentSettings() {
        // Load configuration
        let config = configurationService.loadConfigurationOrDefault()
        propertyId = config.propertyId
        displayName = config.propertyName ?? ""
        refreshInterval = config.refreshIntervalSeconds

        // Validate refresh interval is in our options
        if !refreshIntervalOptions.contains(refreshInterval) {
            refreshInterval = 10
        }

        // Check credentials status
        loadCredentialStatus()
    }

    private func loadCredentialStatus() {
        do {
            let credentials = try configurationService.loadCredentials()
            credentialStatus = .loaded(email: credentials.clientEmail)
        } catch ConfigurationError.credentialsFileNotFound {
            credentialStatus = .notFound
        } catch ConfigurationError.credentialsFileInvalidJSON(let error) {
            credentialStatus = .invalidJSON(error.localizedDescription)
        } catch ConfigurationError.credentialsInvalidStructure(let message) {
            credentialStatus = .invalidStructure(message)
        } catch {
            credentialStatus = .invalidJSON(error.localizedDescription)
        }
    }

    private func openCredentialsFolder() {
        let folderURL = configurationService.configDirectory

        // Ensure the directory exists before opening
        try? configurationService.ensureConfigDirectoryExists()

        NSWorkspace.shared.open(folderURL)
    }

    private func openSetupGuide() {
        // Open the GitHub README or a help URL
        if let url = URL(string: "https://github.com/charlesjones-dev/pulsert#setup") {
            NSWorkspace.shared.open(url)
        }
    }

    private func saveSettings() {
        // Validate property ID
        if propertyId.isEmpty {
            validationErrorMessage = "Property ID is required"
            showValidationError = true
            return
        }

        if !propertyId.allSatisfy({ $0.isNumber }) {
            validationErrorMessage = "Property ID must contain only numbers"
            showValidationError = true
            return
        }

        // Create configuration
        let config = AppConfiguration(
            propertyId: propertyId,
            propertyName: displayName.isEmpty ? nil : displayName,
            refreshIntervalSeconds: refreshInterval
        )

        // Save configuration
        do {
            try configurationService.saveConfiguration(config)

            // Trigger refresh in ViewModel
            Task {
                await viewModel.refresh()
            }

            // Dismiss the settings window
            dismiss()
        } catch {
            validationErrorMessage = "Failed to save: \(error.localizedDescription)"
            showValidationError = true
        }
    }
}

#Preview {
    SettingsView(viewModel: AnalyticsViewModel())
}
