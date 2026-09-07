# CLAUDE.md

**Retired — September 2026.** PulseRT will receive no further maintenance, features, bug fixes, or security updates. The build, testing, architecture, and release guidance below is historical documentation for independent forks. It does not authorize further releases or version changes for this repository. See [README.md](README.md) and [SUPPORT.md](SUPPORT.md) for the retirement status.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Historical Build & Run Commands

```bash
# Historical development build and run
./run.sh

# Build release and install to /Applications
./build.sh --install

# Open in Xcode
open PulseRT.xcodeproj

# Command-line build
xcodebuild -project PulseRT.xcodeproj -scheme PulseRT -configuration Debug build
xcodebuild -project PulseRT.xcodeproj -scheme PulseRT -configuration Release build

# Kill running instance
pkill -x PulseRT
```

## Testing

No automated test suite. Manual testing required:
- Verify menu bar icon appears with user count
- Verify "Last updated" timestamp shows in dropdown with seconds
- Test settings window opens in foreground
- Test settings persistence across restarts
- Test error handling: missing credentials, invalid JSON, wrong property ID
- Test network error recovery with exponential backoff
- Verify token refresh works (1-hour expiry)

## Architecture

Native macOS menu bar app (Swift 6.0, SwiftUI) displaying real-time GA4 visitor counts.

### Core Flow
```
PulseRTApp → AnalyticsViewModel (polling) → AnalyticsService → GoogleAuthService → GA4 API
                                                ↓
                                         JWTSigner (RS256)
```

### Key Patterns
- **Actors** for thread-safe services: `GoogleAuthService`, `AnalyticsService`
- **@MainActor ObservableObject** for ViewModel: `AnalyticsViewModel`
- **Exponential backoff**: 10s → 60s max on errors, resets on success
- **Token caching**: GoogleAuthService caches OAuth tokens with auto-refresh 5 min before expiry

### Directory Structure
```
PulseRT/
├── Models/           # Codable data structures (AppConfiguration, ServiceAccountCredentials, etc.)
├── Services/         # ConfigurationService, GoogleAuthService, AnalyticsService
├── ViewModels/       # AnalyticsViewModel (polling state, Published properties)
├── Views/            # MenuBarView, SettingsView (SwiftUI)
├── Utilities/        # JWTSigner (RS256 signing with Security framework)
└── Resources/        # Info.plist, Entitlements, Assets.xcassets (AppIcon)
```

### Scripts
- `build.sh` - Build and optionally install to /Applications (generates icons automatically)
- `run.sh` - Quick build and run for development
- `generate-icon.py` - Generate app icon (pink background, "RT" initials); auto-creates venv

### Configuration Storage
- Directory: `~/.config/pulsert/`
- `credentials.json` - Google service account key (chmod 600)
- `config.json` - App settings (property ID, refresh interval)

## Linting & Formatting

```bash
# Run linter
swiftlint lint PulseRT

# Run linter with auto-fix
swiftlint lint --fix PulseRT

# Check formatting
swiftformat --lint PulseRT

# Fix formatting
swiftformat PulseRT
```

Configuration files: `.swiftlint.yml`, `.swiftformat`

## Historical Changelog and Versioning

After preflight checks pass, use the `AskUserQuestion` tool to ask how to handle versioning:

- **Current version** - Add the feature/fix to the existing version section in `CHANGELOG.md`
- **New version** - Increment version in Xcode project, then add a new section in `CHANGELOG.md`
- **Skip** - Do nothing

When incrementing versions:
- Patch (x.x.X): Bug fixes, minor improvements
- Minor (x.X.0): New features, non-breaking changes
- Major (X.0.0): Breaking changes

Files to update for new versions:
- `PulseRT.xcodeproj/project.pbxproj` - Update `MARKETING_VERSION` (both Debug and Release configurations)
- `CHANGELOG.md` - Add new version section with date

## Code Style

- Swift 6.0 features, Swift API Design Guidelines
- 4 spaces indentation
- 120 character line limit
- `let` over `var` when possible
- Doc comments (`///`) for public APIs with parameter descriptions
