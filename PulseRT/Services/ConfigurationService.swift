import Foundation

// MARK: - ConfigurationError

/// Errors that can occur during configuration operations
enum ConfigurationError: LocalizedError {
    case configDirectoryCreationFailed(Error)
    case configFileNotFound
    case configFileReadFailed(Error)
    case configFileWriteFailed(Error)
    case configFileInvalidJSON(Error)
    case credentialsFileNotFound
    case credentialsFileReadFailed(Error)
    case credentialsFileInvalidJSON(Error)
    case credentialsInvalidStructure(String)

    var errorDescription: String? {
        switch self {
        case let .configDirectoryCreationFailed(error):
            "Failed to create configuration directory: \(error.localizedDescription)"
        case .configFileNotFound:
            "Configuration file not found at ~/.config/pulsert/config.json"
        case let .configFileReadFailed(error):
            "Failed to read configuration file: \(error.localizedDescription)"
        case let .configFileWriteFailed(error):
            "Failed to write configuration file: \(error.localizedDescription)"
        case let .configFileInvalidJSON(error):
            "Configuration file contains invalid JSON: \(error.localizedDescription)"
        case .credentialsFileNotFound:
            "Credentials file not found at ~/.config/pulsert/credentials.json"
        case let .credentialsFileReadFailed(error):
            "Failed to read credentials file: \(error.localizedDescription)"
        case let .credentialsFileInvalidJSON(error):
            "Credentials file contains invalid JSON: \(error.localizedDescription)"
        case let .credentialsInvalidStructure(message):
            "Invalid credentials structure: \(message)"
        }
    }
}

// MARK: - ConfigurationService

/// Service for managing PulseRT configuration and credentials files
final class ConfigurationService: @unchecked Sendable {
    /// Shared singleton instance
    static let shared = ConfigurationService()

    /// Base configuration directory path
    private let configDirectoryPath: URL

    /// Configuration file path
    private let configFilePath: URL

    /// Credentials file path
    private let credentialsFilePath: URL

    /// JSON encoder configured for pretty printing
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// JSON decoder
    private let decoder = JSONDecoder()

    private init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        configDirectoryPath = homeDirectory
            .appendingPathComponent(".config")
            .appendingPathComponent("pulsert")
        configFilePath = configDirectoryPath.appendingPathComponent("config.json")
        credentialsFilePath = configDirectoryPath.appendingPathComponent("credentials.json")
    }

    // MARK: - Directory Management

    /// Ensures the configuration directory exists, creating it if necessary
    func ensureConfigDirectoryExists() throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: configDirectoryPath.path) {
            do {
                try fileManager.createDirectory(
                    at: configDirectoryPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw ConfigurationError.configDirectoryCreationFailed(error)
            }
        }
    }

    /// Returns the path to the configuration directory
    var configDirectory: URL {
        configDirectoryPath
    }

    // MARK: - Configuration File

    /// Checks if the configuration file exists
    var configFileExists: Bool {
        FileManager.default.fileExists(atPath: configFilePath.path)
    }

    /// Loads the application configuration from disk
    func loadConfiguration() throws -> AppConfiguration {
        guard configFileExists else {
            throw ConfigurationError.configFileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: configFilePath)
        } catch {
            throw ConfigurationError.configFileReadFailed(error)
        }

        do {
            return try decoder.decode(AppConfiguration.self, from: data)
        } catch {
            throw ConfigurationError.configFileInvalidJSON(error)
        }
    }

    /// Saves the application configuration to disk
    func saveConfiguration(_ config: AppConfiguration) throws {
        try ensureConfigDirectoryExists()

        let data: Data
        do {
            data = try encoder.encode(config)
        } catch {
            throw ConfigurationError.configFileWriteFailed(error)
        }

        do {
            try data.write(to: configFilePath, options: .atomic)
        } catch {
            throw ConfigurationError.configFileWriteFailed(error)
        }
    }

    /// Loads configuration or returns default if file doesn't exist
    func loadConfigurationOrDefault() -> AppConfiguration {
        do {
            return try loadConfiguration()
        } catch ConfigurationError.configFileNotFound {
            return .default
        } catch {
            // Return default on error (file may not exist yet)
            return .default
        }
    }

    // MARK: - Credentials File

    /// Checks if the credentials file exists
    var credentialsFileExists: Bool {
        FileManager.default.fileExists(atPath: credentialsFilePath.path)
    }

    /// Loads and validates the service account credentials from disk
    func loadCredentials() throws -> ServiceAccountCredentials {
        guard credentialsFileExists else {
            throw ConfigurationError.credentialsFileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: credentialsFilePath)
        } catch {
            throw ConfigurationError.credentialsFileReadFailed(error)
        }

        let credentials: ServiceAccountCredentials
        do {
            credentials = try decoder.decode(ServiceAccountCredentials.self, from: data)
        } catch {
            throw ConfigurationError.credentialsFileInvalidJSON(error)
        }

        // Validate the credentials structure
        guard credentials.type == "service_account" else {
            throw ConfigurationError.credentialsInvalidStructure(
                "Expected type 'service_account', got '\(credentials.type)'"
            )
        }

        guard !credentials.privateKey.isEmpty else {
            throw ConfigurationError.credentialsInvalidStructure("Private key is empty")
        }

        guard credentials.privateKey.contains("BEGIN"), credentials.privateKey.contains("PRIVATE KEY") else {
            throw ConfigurationError.credentialsInvalidStructure(
                "Private key does not appear to be in PEM format"
            )
        }

        guard !credentials.clientEmail.isEmpty else {
            throw ConfigurationError.credentialsInvalidStructure("Client email is empty")
        }

        return credentials
    }

    /// Returns the credentials file path for display purposes
    var credentialsPath: URL {
        credentialsFilePath
    }

    /// Returns the config file path for display purposes
    var configPath: URL {
        configFilePath
    }
}
