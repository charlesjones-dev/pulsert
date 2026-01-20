# PulseRT

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-15+-000000?logo=apple)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0+-F05138?logo=swift&logoColor=white)](https://swift.org)

A native macOS menu bar application that displays real-time Google Analytics 4 visitor counts.

![PulseRT Menu Bar](https://img.shields.io/badge/Menu%20Bar-Real--Time%20Analytics-green)

## Features

- **Real-time visitor counts** - See active users directly in your menu bar
- **Last updated timestamp** - Know exactly when data was last refreshed
- **Native macOS app** - Built with Swift and SwiftUI, no Electron or web views
- **Secure authentication** - Uses Google service account with local credential storage
- **Configurable refresh** - Choose polling intervals from 5 to 60 seconds
- **Minimal footprint** - Menu bar only, no dock icon
- **Multiple properties** - Easy to switch between GA4 properties

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16+ (for building from source)
- Swift 6.0+
- Python 3 with Pillow (auto-installed for icon generation)
- Google Analytics 4 property with Real-Time API access
- Google Cloud service account with Analytics Data API enabled

## Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services > Library**
4. Search for "Google Analytics Data API" and enable it

### Step 2: Create a Service Account

1. In Google Cloud Console, go to **IAM & Admin > Service Accounts**
2. Click **Create Service Account**
3. Enter a name (e.g., "pulsert-reader")
4. Click **Create and Continue**
5. Skip the optional permissions step (no special roles needed)
6. Click **Done**

### Step 3: Export Service Account Key

1. Click on the newly created service account
2. Go to the **Keys** tab
3. Click **Add Key > Create new key**
4. Select **JSON** format
5. Click **Create** - the key file will download automatically
6. **Keep this file secure** - it provides API access

### Step 4: Grant GA4 Property Access

1. Go to [Google Analytics](https://analytics.google.com/)
2. Select your GA4 property
3. Navigate to **Admin > Property Access Management**
4. Click the **+** button to add users
5. Enter the service account email (ends with `@*.iam.gserviceaccount.com`)
6. Set role to **Viewer** (minimum required)
7. Click **Add**

### Step 5: Configure PulseRT Credentials

1. Create the configuration directory:
   ```bash
   mkdir -p ~/.config/pulsert
   ```

2. Move your downloaded service account JSON file:
   ```bash
   mv ~/Downloads/your-project-*.json ~/.config/pulsert/credentials.json
   ```

3. Set appropriate file permissions:
   ```bash
   chmod 600 ~/.config/pulsert/credentials.json
   ```

### Step 6: Build and Run PulseRT

```bash
# Clone the repository
git clone https://github.com/charlesjones-dev/pulsert.git
cd pulsert

# Open in Xcode
open PulseRT.xcodeproj

# Build and run (Cmd+R)
```

Or build from command line:
```bash
xcodebuild -project PulseRT.xcodeproj -scheme PulseRT -configuration Release
```

### Installing to Applications Folder

Use the build script to create and install a standalone `.app`:

```bash
# Build only
./build.sh

# Build and install to /Applications
./build.sh --install
```

The `--install` flag will:

- Generate the app icon (pink background with "RT" initials)
- Build a release version
- Kill any running PulseRT instance
- Copy the app to `/Applications/`
- Remove the quarantine attribute (so Gatekeeper won't block it)

To customize the icon colors, edit `generate-icon.py` and change `BG_COLOR` or `FG_COLOR`, then rebuild.

#### First Launch (Unsigned App)

If you copied the app manually without removing the quarantine attribute, macOS will block it. To open:

1. Open **System Settings > Privacy & Security**
2. Scroll to Security - you'll see PulseRT was blocked
3. Click **Open Anyway**, then **Open** in the confirmation dialog

Or right-click the app in Finder, select **Open**, and click **Open** in the dialog.

### Step 7: Configure GA4 Property

1. Click the PulseRT icon in your menu bar
2. Select **Settings...**
3. Enter your GA4 Property ID (numeric, found in GA4 Admin > Property Details)
4. Optionally set a display name
5. Choose your preferred refresh interval
6. Click **Save**

## Configuration

PulseRT stores configuration in `~/.config/pulsert/`:

| File | Purpose |
|------|---------|
| `credentials.json` | Google service account key (required) |
| `config.json` | App settings - property ID, refresh interval (auto-created) |

### Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| Property ID | GA4 property numeric ID | None (required) |
| Display Name | Friendly name shown in menu | Property ID |
| Refresh Interval | Polling frequency | 10 seconds |

## Troubleshooting

### "Credentials not found"

Ensure `~/.config/pulsert/credentials.json` exists and contains a valid service account key.

```bash
# Check file exists
ls -la ~/.config/pulsert/credentials.json

# Verify JSON is valid
cat ~/.config/pulsert/credentials.json | python3 -m json.tool
```

### "Authentication failed"

1. Verify the Analytics Data API is enabled in Google Cloud Console
2. Check that the service account key hasn't been deleted or rotated
3. Ensure the JSON file is the complete, unmodified download from Google

### "No data / shows 0 users"

1. Confirm the service account has Viewer access to the GA4 property
2. Verify the Property ID is correct (numeric ID, not measurement ID)
3. Check if your site has any active visitors (test by opening your site)

### "API quota exceeded"

The Real-Time API has usage limits. Try increasing the refresh interval to 30 or 60 seconds.

### App doesn't appear in menu bar

1. Check System Settings > Control Center > Menu Bar Only
2. Ensure no other apps are hiding menu bar items
3. Try quitting and relaunching PulseRT

### Finding Your GA4 Property ID

1. Go to [Google Analytics](https://analytics.google.com/)
2. Select your property
3. Click **Admin** (gear icon)
4. Under Property column, click **Property Details**
5. Copy the **Property ID** (numeric value like `123456789`)

Note: This is different from the Measurement ID (which starts with "G-").

## Security

- Service account credentials are stored locally, never transmitted except to Google
- No data is collected or sent to third parties
- The app requests only `analytics.readonly` scope (minimum required)
- See [SECURITY.md](SECURITY.md) for credential handling best practices

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Author

Created by [Charles Jones](https://charlesjones.dev)

---

**PulseRT** - Real-time analytics at a glance
