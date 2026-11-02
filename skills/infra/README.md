# Infrastructure Skills

Skills for local development infrastructure, containerisation, and deployment tooling.

These skills cover the operational patterns developers need: setting up local environments, managing containers, configuring networks, and handling platform-specific gotchas. They complement app, data, and web skills by addressing the infrastructure layer.

## Skills

| Skill | Description |
|---|---|
| [Docker Compose Database Lab](docker-compose-database-lab/) | Set up local Docker Compose database environments with correct volume mounts, configuration, and network access |
| [GitHub Org Repository Setup](github-org-repository-setup/) | Set up a new GitHub repository in an organisation with correct access, security, and baseline branch protection |
| [Git Secret Remediation](git-secret-remediation/) | Remove committed secrets from Git history safely and verify remediations across local and remote repositories |
| [M365 Email Authentication](m365-email-authentication/) | Enable DKIM, SPF and DMARC for a Microsoft 365 custom domain — Defender portal path, per-domain CNAME values, negative-cache delays, cross-resolver DNS verification |
| [GitHub Actions Scheduled Automation](github-actions-scheduled-automation/) | Time-sensitive scheduled work on GitHub Actions — external dispatch, idempotency guards for every trigger, per-job secrets, safe comment chatops |
| [Windows CLI Gotchas](windows-cli-gotchas/) | Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, JSON payloads, stderr and exit codes, MSYS path mangling, which shell for which tool |
| [Azure Encrypted Database Backups](azure-encrypted-database-backups/) | Encrypted, immutable Postgres backups on Azure — a scheduled Container Apps job with Key Vault credentials, age encryption to two recipients, locked blob retention, restore rehearsal, alerts that do not page falsely |
| [Cloudflare R2 Static Data](cloudflare-r2-static-data/) | Large versioned static datasets on Cloudflare R2 — bulk sync by key prefix, immutable caching on versioned keys, a custom domain instead of r2.dev, completeness checks before release |

## Adding a new infrastructure skill

Use the [skill template](../../contribute/templates/skill-template/) as your starting point. See [CONTRIBUTING.md](../../contribute/CONTRIBUTING.md) for submission guidance.
