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
| [Windows CLI Gotchas](windows-cli-gotchas/) | Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, JSON payloads, stderr and exit codes, MSYS path mangling, which shell for which tool |

## Adding a new infrastructure skill

Use the [skill template](../../contribute/templates/skill-template/) as your starting point. See [CONTRIBUTING.md](../../contribute/CONTRIBUTING.md) for submission guidance.
