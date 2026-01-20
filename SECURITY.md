# Security Policy

## Credential Security

PulseRT uses Google Cloud service account credentials to authenticate with the Analytics Data API. These credentials provide API access and must be protected.

### Critical Warnings

**Never commit credentials to version control.**

The `credentials.json` file contains a private key that can be used to access any Google APIs the service account has permissions for. If exposed:

- Revoke the key immediately in Google Cloud Console
- Create a new service account key
- Audit API usage for unauthorized access

### Secure Storage

1. **File permissions**: Restrict access to the credentials file:
   ```bash
   chmod 600 ~/.config/pulsert/credentials.json
   ```

2. **Location**: Store only in the designated config directory (`~/.config/pulsert/`)

3. **Backups**: If backing up credentials, ensure backups are encrypted

4. **Sharing**: Never share credentials via email, chat, or unencrypted channels

### Minimal Permissions

The service account should have the minimum required access:

- **API scope**: `analytics.readonly` (read-only access)
- **GA4 role**: Viewer (read-only property access)
- **Google Cloud roles**: None required beyond service account creation

### Key Rotation

Rotate your service account key periodically:

1. Go to Google Cloud Console > IAM & Admin > Service Accounts
2. Select your service account
3. Go to Keys tab
4. Click "Add Key" > "Create new key" > JSON
5. Replace `~/.config/pulsert/credentials.json` with the new file
6. Delete the old key from Google Cloud Console
7. Restart PulseRT

**Recommended rotation frequency**: Every 90 days, or immediately if compromise is suspected.

### Credential Exposure Checklist

If you suspect your credentials have been exposed:

1. **Immediately** revoke the key in Google Cloud Console
2. Check Google Cloud audit logs for unauthorized usage
3. Review GA4 property access logs
4. Create a new service account key
5. Update your local credentials file
6. Consider creating an entirely new service account

## Application Security

### Data Handling

- Credentials are read from disk only when needed
- Access tokens are cached in memory, not persisted
- No analytics data is stored locally
- No data is sent to third parties

### Network Security

- All API communication uses HTTPS/TLS
- Tokens are transmitted only to Google OAuth endpoints
- No telemetry or usage data is collected

### Local Security

- PulseRT runs with standard user permissions
- No elevated privileges required
- Configuration stored in user-owned directory

## Reporting Vulnerabilities

If you discover a security vulnerability in PulseRT:

1. **Do not** open a public issue
2. Email the maintainer directly (see [charlesjones.dev](https://charlesjones.dev) for contact)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 7 days
- **Fix timeline**: Depends on severity
  - Critical: 24-72 hours
  - High: 1-2 weeks
  - Medium/Low: Next release

### Disclosure Policy

- Vulnerabilities will be fixed before public disclosure
- Credit will be given to reporters (unless anonymity is requested)
- A security advisory will be published for significant issues

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | Yes       |
| Older   | No        |

Only the latest release receives security updates. Users are encouraged to stay current.

## Security Best Practices

When using PulseRT:

1. Keep macOS and Xcode updated
2. Use a dedicated service account for PulseRT
3. Grant minimal GA4 permissions (Viewer only)
4. Rotate credentials periodically
5. Monitor Google Cloud audit logs
6. Review GA4 property access regularly
