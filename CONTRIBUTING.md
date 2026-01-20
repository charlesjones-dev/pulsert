# Contributing to PulseRT

Thank you for your interest in contributing to PulseRT! This document provides guidelines and instructions for contributing.

## Ways to Contribute

- **Report bugs** - Found something broken? Let us know
- **Suggest features** - Have an idea? We'd love to hear it
- **Submit pull requests** - Code contributions are welcome
- **Improve documentation** - Help make the docs clearer
- **Share feedback** - Tell us about your experience

## Bug Reports

Before reporting a bug, please:

1. Search existing issues to avoid duplicates
2. Try the latest version to see if it's already fixed

When reporting, include:

- macOS version
- PulseRT version or commit hash
- Steps to reproduce
- Expected vs actual behavior
- Any error messages (check Console.app for logs)
- Screenshots if relevant

## Feature Suggestions

Open an issue with:

- Clear description of the feature
- Use case - why is this useful?
- Any implementation ideas (optional)

## Development Setup

### Prerequisites

- macOS 26 or later
- Xcode 16+
- Git

### Getting Started

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

## Code Style Guidelines

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

## Pull Request Process

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Keep commits focused and atomic
   - Write clear commit messages
   - Test your changes thoroughly

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Open a Pull Request**:
   - Provide a clear title and description
   - Reference any related issues
   - Include screenshots for UI changes
   - List any breaking changes

5. **Respond to feedback**:
   - Address review comments
   - Push additional commits as needed
   - Keep the PR updated with `main` if needed

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

## Testing

- Test manually on macOS 26
- Verify menu bar appearance and behavior
- Test settings persistence across app restarts
- Check error handling with invalid credentials
- Test network error recovery

## Security Considerations

- Never commit real credentials
- Don't log sensitive information (tokens, keys)
- Validate all user input
- See [SECURITY.md](SECURITY.md) for more details

## Code of Conduct

- Be respectful and inclusive
- Assume good intent
- Focus on constructive feedback
- Welcome newcomers

## Questions?

Open an issue with the "question" label or reach out to the maintainers.

---

Thank you for contributing to PulseRT!
