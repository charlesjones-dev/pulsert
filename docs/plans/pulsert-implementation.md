# PulseRT Implementation Plan

A native macOS menu bar application displaying real-time Google Analytics 4 visitor counts.

## Summary

| Attribute          | Value                                  |
| ------------------ | -------------------------------------- |
| Total Phases       | 6                                      |
| Execution Strategy | Sequential (phases build on each other)|
| Target Platform    | macOS 26+                              |
| Primary Tech       | Swift, SwiftUI, Security framework     |
| Config Location    | `~/.config/pulsert/`                   |

---

## Phase 1: Project Foundation & Configuration Service

**Goal:** Set up the Xcode project structure and implement configuration file management.

### Phase 1 Tasks

1. Create new Xcode project `PulseRT` with:
   - Bundle ID: `dev.charlesjones.pulsert`
   - Deployment target: macOS 26 or newer
   - Set `LSUIElement = YES` in Info.plist (menu bar only, no dock icon)

2. Create project directory structure:

   ```text
   PulseRT/
   ├── Models/
   ├── ViewModels/
   ├── Views/
   ├── Services/
   ├── Utilities/
   └── Resources/
   ```

3. Implement `Models/AppConfiguration.swift`:
   - Codable struct for user settings
   - Properties: `propertyId`, `propertyName`, `refreshIntervalSeconds`

4. Implement `Models/ServiceAccountCredentials.swift`:
   - Codable struct matching Google service account JSON structure
   - CodingKeys for snake_case mapping

5. Implement `Services/ConfigurationService.swift`:
   - Read/write config from `~/.config/pulsert/config.json`
   - Read credentials from `~/.config/pulsert/credentials.json`
   - Create config directory if missing
   - Validate credentials file structure

### Phase 1 Acceptance Criteria

- [ ] Xcode project builds without errors
- [ ] ConfigurationService can create `~/.config/pulsert/` directory
- [ ] ConfigurationService can read/write `config.json`
- [ ] ConfigurationService can parse valid `credentials.json`
- [ ] ConfigurationService returns clear errors for missing/invalid files

### Phase 1 Files Created

- `PulseRT.xcodeproj`
- `PulseRT/PulseRTApp.swift` (minimal placeholder)
- `PulseRT/Models/AppConfiguration.swift`
- `PulseRT/Models/ServiceAccountCredentials.swift`
- `PulseRT/Services/ConfigurationService.swift`

---

## Phase 2: JWT Signing & Google Authentication

**Goal:** Implement RS256 JWT signing using native Security framework and token exchange with Google OAuth.

### Phase 2 Tasks

1. Implement `Utilities/JWTSigner.swift`:
   - Parse PEM private key from service account JSON
   - Extract RSA private key using Security framework (`SecKeyCreateWithData`)
   - Create JWT header and claims
   - Sign with RS256 (`SecKeyCreateSignature` with `.rsaSignatureMessagePKCS1v15SHA256`)
   - Base64URL encode all components

2. Implement `Services/GoogleAuthService.swift`:
   - Build JWT with required claims:
     - `iss`: service account email
     - `scope`: `https://www.googleapis.com/auth/analytics.readonly`
     - `aud`: `https://oauth2.googleapis.com/token`
     - `iat`: current timestamp
     - `exp`: current + 3600 seconds
   - Exchange JWT for access token via POST to `https://oauth2.googleapis.com/token`
   - Cache access token with expiry tracking
   - Auto-refresh token when expired or within 5 minutes of expiry

3. Implement `Models/TokenResponse.swift`:
   - Codable struct for Google OAuth token response
   - Properties: `accessToken`, `expiresIn`, `tokenType`

### Phase 2 Acceptance Criteria

- [ ] JWTSigner correctly parses PEM private key format
- [ ] JWTSigner produces valid RS256-signed JWTs
- [ ] GoogleAuthService exchanges JWT for access token
- [ ] Token caching prevents unnecessary API calls
- [ ] Clear error messages for auth failures

### Phase 2 Implementation Details

```swift
// JWT Claims structure
{
  "iss": "service-account@project.iam.gserviceaccount.com",
  "scope": "https://www.googleapis.com/auth/analytics.readonly",
  "aud": "https://oauth2.googleapis.com/token",
  "iat": 1234567890,
  "exp": 1234571490
}

// Token exchange
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded
grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=SIGNED_JWT
```

### Phase 2 Files Created

- `PulseRT/Utilities/JWTSigner.swift`
- `PulseRT/Services/GoogleAuthService.swift`
- `PulseRT/Models/TokenResponse.swift`

---

## Phase 3: Analytics API Integration

**Goal:** Implement GA4 Real-Time API calls and polling logic.

### Phase 3 Tasks

1. Implement `Models/RealtimeResponse.swift`:
   - Codable structs for API response
   - Handle empty `rows` array (0 active users)
   - Extract metric value from nested structure

2. Implement `Services/AnalyticsService.swift`:
   - POST to `https://analyticsdata.googleapis.com/v1beta/properties/{propertyId}:runRealtimeReport`
   - Request body: `{"metrics": [{"name": "activeUsers"}]}`
   - Parse response to extract active user count
   - Handle API errors with meaningful messages

3. Implement `ViewModels/AnalyticsViewModel.swift`:
   - `@Published` properties: `activeUsers`, `connectionState`, `lastError`
   - Polling timer using `Timer.publish` or async Task
   - Exponential backoff on errors (10s -> 20s -> 40s -> max 60s)
   - Reset backoff on successful request
   - `displayCount` computed property returning number or "--"

### Phase 3 Acceptance Criteria

- [ ] AnalyticsService fetches real-time user count
- [ ] AnalyticsViewModel polls at configured interval
- [ ] Exponential backoff activates on errors
- [ ] Backoff resets on success
- [ ] Zero users handled correctly (empty rows array)

### Phase 3 API Details

```http
POST https://analyticsdata.googleapis.com/v1beta/properties/{propertyId}:runRealtimeReport
Authorization: Bearer {accessToken}
Content-Type: application/json

{"metrics": [{"name": "activeUsers"}]}

Response:
{
  "rows": [{"metricValues": [{"value": "42"}]}]
}
```

### Phase 3 Files Created

- `PulseRT/Models/RealtimeResponse.swift`
- `PulseRT/Services/AnalyticsService.swift`
- `PulseRT/ViewModels/AnalyticsViewModel.swift`

---

## Phase 4: Menu Bar UI

**Goal:** Implement the menu bar presence and dropdown menu using SwiftUI MenuBarExtra.

### Phase 4 Tasks

1. Update `PulseRTApp.swift`:
   - Create `@StateObject` AnalyticsViewModel
   - Add `MenuBarExtra` scene with label showing icon + count
   - Add `Settings` scene for settings window
   - Use SF Symbol `person.2.fill` for icon

2. Implement `Views/MenuBarView.swift`:
   - Property name/ID header (non-clickable)
   - Divider
   - "Settings..." button with keyboard shortcut (Cmd+,)
   - "Quit" button with keyboard shortcut (Cmd+Q)
   - Open settings using `@Environment(\.openSettings)`

3. Menu bar label styling:
   - Use `.monospacedDigit()` for count to prevent width jumping
   - Show "--" when loading or disconnected
   - Consider color coding: green (connected), gray (loading), orange (error)

### Phase 4 Acceptance Criteria

- [ ] Menu bar icon and count visible in macOS menu bar
- [ ] Count updates in real-time
- [ ] Dropdown menu appears on click
- [ ] Property name displays in header
- [ ] Settings menu item opens Settings window
- [ ] Quit terminates the application
- [ ] No dock icon appears (LSUIElement working)

### Phase 4 SwiftUI Pattern

```swift
@main
struct PulseRTApp: App {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                Text(viewModel.displayCount)
                    .monospacedDigit()
            }
        }

        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
```

### Phase 4 Files

- `PulseRT/PulseRTApp.swift` (update)
- `PulseRT/Views/MenuBarView.swift` (create)

---

## Phase 5: Settings Window

**Goal:** Implement the settings window with configuration UI and credential status.

### Phase 5 Tasks

1. Implement `Views/SettingsView.swift`:
   - Credentials status section:
     - Show checkmark + "Service account loaded" when valid
     - Show warning + setup instructions when missing
     - Display service account email when loaded
   - "Open Credentials Folder" button (opens `~/.config/pulsert/` in Finder)
   - GA4 Property ID text field (numeric validation)
   - Display Name optional text field
   - Refresh Interval picker (5s, 10s, 30s, 60s options)
   - "View Setup Guide" button (opens README or help URL)
   - Cancel/Save buttons

2. Settings persistence:
   - Load current config on appear
   - Validate property ID is numeric
   - Save to ConfigurationService on Save
   - Dismiss on Cancel
   - Trigger AnalyticsViewModel refresh on save

3. Error states in settings:
   - Missing credentials file: show clear setup path
   - Invalid JSON: show parse error
   - Invalid property ID: show validation message

### Phase 5 Acceptance Criteria

- [ ] Settings window opens via menu or Cmd+,
- [ ] Credential status accurately reflects file state
- [ ] "Open Credentials Folder" opens correct directory
- [ ] Property ID validates as numeric
- [ ] Configuration persists across app restarts
- [ ] Changes take effect immediately after save

### Phase 5 UI Layout Reference

```text
+-------------------------------------------+
| PulseRT Settings                          |
+-------------------------------------------+
|                                           |
| Credentials Status                        |
| +---------------------------------------+ |
| | [checkmark] Service account loaded    | |
| |   analytics@proj.iam.gserviceaccount  | |
| +---------------------------------------+ |
|                  [Open Credentials Folder]|
|                                           |
| GA4 Property ID                           |
| +---------------------------------------+ |
| | 123456789                             | |
| +---------------------------------------+ |
|                                           |
| Display Name (optional)                   |
| +---------------------------------------+ |
| | charlesjones.dev                      | |
| +---------------------------------------+ |
|                                           |
| Refresh Interval                          |
| +---------------------------------------+ |
| | 10 seconds                          v | |
| +---------------------------------------+ |
|                                           |
| [View Setup Guide]      [Cancel]  [Save]  |
+-------------------------------------------+
```

### Phase 5 Files Created

- `PulseRT/Views/SettingsView.swift`

---

## Phase 6: Documentation & Open Source Files

**Goal:** Create all required documentation for open source release.

### Phase 6 Tasks

1. Create `README.md`:
   - Project title, description, feature list
   - Requirements (macOS 26, Xcode 16+, Swift 6.0+)
   - Detailed setup instructions with all 7 steps from spec
   - Build and run instructions
   - Configuration options
   - Troubleshooting section
   - License badge

2. Create `CONTRIBUTING.md`:
   - Welcome message
   - Bug reporting guidance
   - Feature suggestion process
   - Development setup
   - Swift code style guidelines
   - PR process
   - Code of conduct reference

3. Create `LICENSE`:
   - MIT License
   - Year: 2025
   - Copyright holder: "PulseRT Contributors"

4. Create `SECURITY.md`:
   - Credential security warnings
   - Rotation instructions
   - Vulnerability reporting

5. Create `.gitignore`:
   - Swift/Xcode standard ignores
   - `*.json` in config directories
   - Build artifacts
   - `.DS_Store`

6. Create `credentials.example.json`:
   - Template with placeholder values
   - All required fields shown

### Phase 6 Acceptance Criteria

- [ ] README provides complete setup walkthrough
- [ ] CONTRIBUTING guides new contributors
- [ ] LICENSE is valid MIT
- [ ] SECURITY warns about credential handling
- [ ] .gitignore prevents credential commits
- [ ] credentials.example.json shows correct structure
- [ ] No real credentials anywhere in repo

### Phase 6 Files Created

- `README.md`
- `CONTRIBUTING.md`
- `LICENSE`
- `SECURITY.md`
- `.gitignore`
- `credentials.example.json`

---

## Dependency Graph

```text
Phase 1 (Foundation)
    |
    v
Phase 2 (Auth) <-- depends on Models from Phase 1
    |
    v
Phase 3 (API) <-- depends on Auth from Phase 2
    |
    v
Phase 4 (Menu Bar UI) <-- depends on ViewModel from Phase 3
    |
    v
Phase 5 (Settings) <-- depends on UI patterns from Phase 4
    |
    v
Phase 6 (Docs) <-- can run in parallel with Phase 5
```

## Execution Strategy

Sequential execution is recommended. Each phase builds on the previous:

- Phase 1 establishes the data models and file I/O
- Phase 2 uses those models for authentication
- Phase 3 uses auth for API calls
- Phase 4 uses the ViewModel from Phase 3
- Phase 5 connects to all services
- Phase 6 can technically run in parallel with Phase 5

## Technical Notes

### RS256 Signing in Phase 2

Using native Security framework requires:

1. Strip PEM headers/footers from private key
2. Base64 decode the key data
3. Create `SecKey` with `kSecAttrKeyTypeRSA`
4. Sign using `SecKeyCreateSignature`

### Token Refresh Strategy

- Cache token with expiry timestamp
- Refresh if within 5 minutes of expiry
- On 401 response, force token refresh and retry once

### Error Backoff

```swift
var backoffSeconds = 10
func onError() {
    backoffSeconds = min(backoffSeconds * 2, 60)
}
func onSuccess() {
    backoffSeconds = 10
}
```

---

## Post-Implementation Testing Checklist

From the spec:

1. Menu bar item appears and updates
2. App behavior when credentials file is missing
3. App behavior with invalid/malformed JSON
4. App behavior with valid credentials but wrong property ID
5. App behavior when service account lacks GA4 access
6. Token refresh works (tokens expire after 1 hour)
7. Error states (disconnect wifi, invalid property ID)
8. Settings persistence across app restarts
9. Quit terminates the app
10. No dock icon appears
11. "Open Credentials Folder" and "View Setup Guide" buttons work
