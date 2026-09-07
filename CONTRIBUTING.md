# Contributing to PulseRT

**Retired — September 2026.** PulseRT is unmaintained. This repository no longer accepts contributions, pull requests, bug reports, or feature requests. There will be no further maintenance, features, bug fixes, or security updates.

Independent forks are welcome under the existing [MIT License](LICENSE). Preserve its copyright and permission notices as required. Fork maintainers are responsible for their own development, support, and security policies.

See [SUPPORT.md](SUPPORT.md) for retirement details. The development instructions and conventions below are historical documentation for reference by independent forks, not a request to contribute to this repository. They are no longer maintained or verified against current tools.

## Historical Development Setup

### Prerequisites

- macOS 26 or later
- Xcode 16+
- Git

### Historical Local Setup

1. Fork the repository on GitHub

2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/pulsert.git
   cd pulsert
   ```

3. Open in Xcode:
   ```bash
   open PulseRT.xcodeproj
   ```

4. Set up test credentials (optional, for integration testing):
   ```bash
   mkdir -p ~/.config/pulsert
   cp credentials.example.json ~/.config/pulsert/credentials.json
   # Edit with your actual service account credentials
   ```

5. Build and run with Cmd+R

### Project Structure

```
PulseRT/
├── Models/              # Data structures
├── ViewModels/          # SwiftUI view models
├── Views/               # SwiftUI views
├── Services/            # Business logic, API clients
├── Utilities/           # Helpers (JWT signing, etc.)
└── Resources/           # Assets, Info.plist
```

## Historical Code Style Guidelines

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift 6.0 features where appropriate
- Prefer `let` over `var` when possible
- Use meaningful variable and function names
- Keep functions focused and concise

### Formatting

- Use Xcode's default formatting (Ctrl+I to re-indent)
- 4 spaces for indentation
- Opening braces on the same line
- One blank line between functions
- Remove trailing whitespace

### Documentation

- Add doc comments (`///`) for public APIs
- Include parameter descriptions for non-obvious parameters
- Document any side effects or preconditions

### Example

```swift
/// Fetches the current active user count from Google Analytics.
///
/// - Parameter propertyId: The GA4 property ID (numeric).
/// - Returns: The number of active users, or 0 if unavailable.
/// - Throws: `AnalyticsError` if the API request fails.
func fetchActiveUsers(propertyId: String) async throws -> Int {
    // Implementation
}
```

### Commit Messages

- Use present tense: "Add feature" not "Added feature"
- Use imperative mood: "Fix bug" not "Fixes bug"
- Keep the first line under 72 characters
- Add details in the body if needed

Good examples:
```
Add refresh interval picker to settings

Fix token refresh not triggering before expiry

Update README with troubleshooting section
```

## Historical Testing

- Test manually on macOS 26
- Verify menu bar appearance and behavior
- Test settings persistence across app restarts
- Check error handling with invalid credentials
- Test network error recovery

## Historical Security Considerations

- Never commit real credentials
- Don't log sensitive information (tokens, keys)
- Validate all user input
- See [SECURITY.md](SECURITY.md) for more details

## Historical Code of Conduct

- Be respectful and inclusive
- Assume good intent
- Focus on constructive feedback
- Welcome newcomers
