# Support and Retirement

**Retired — September 2026.** PulseRT is unmaintained and will receive no further maintenance, features, bug fixes, or security updates. No versions are supported.

Maintainer support has ended. Do not open issues or pull requests, or contact the former maintainer for troubleshooting, feature requests, bug fixes, or vulnerability reports. Existing troubleshooting and setup instructions are historical reference only.

Independent forks are welcome under the existing [MIT License](LICENSE), including its copyright and permission notice requirements. Each fork is responsible for its own support and security policies. See [CONTRIBUTING.md](CONTRIBUTING.md) for historical development guidance and [SECURITY.md](SECURITY.md) for the retired security policy.

## Distribution and External Services

Retiring or archiving this repository does not unpublish software, revoke credentials, cancel subscriptions, or shut down services. The following inventory was checked on September 7, 2026. No external services or listings were changed as part of retirement preparation.

| Item | Verified status or limitation | Separate owner action |
|------|-------------------------------|-----------------------|
| GitHub release and tag | [v1.0.0](https://github.com/charlesjones-dev/pulsert/releases/tag/v1.0.0) remains published, with no uploaded binary assets. GitHub source archives remain available. | Preserve the release and tag as historical records; they are unsupported. |
| GitHub Packages | GitHub's repository package count is zero. No package publishing configuration is tracked. | No repository package was identified for retirement. Other registries were not verified. |
| Mac App Store / TestFlight | No store listing or App Store Connect configuration was identified in the repository. The bundle identifier is `dev.charlesjones.pulsert`; account-side distribution status is unverified. | Check App Store Connect for any listings or TestFlight builds and handle retirement separately if present. |
| GitHub hosting and automation | GitHub reports no Pages site, deployments, environments, Actions workflows, or repository webhooks. | No GitHub deployment was identified for shutdown. |
| Google Cloud / GA4 | The app uses user-supplied Google Cloud service account keys, the Analytics Data API, and GA4 property access. Actual projects, keys, permissions, usage, and billing are not verifiable from this repository. | Review dedicated keys, service accounts, GA4 access, and project billing in the relevant accounts. Retire resources that are no longer needed after checking for shared use. |
| Other deployments and paid services | No other hosting, subscription, payment, or deployment configuration was identified in tracked files. Account-level status is unverified. | Review provider accounts and billing records for any project-specific services outside GitHub. |

Source code, technical documentation, the license, changelog, and any existing lockfiles, tags, and releases are retained. The original implementation plan exists only in Git history and is historical documentation; unfinished items will not be completed by this project.

## Final Repository Step

Once the retirement documentation is merged and any account-level retirement work is reviewed, the owner can use GitHub's **Archive this repository** control. Retirement preparation does not archive the repository itself.
