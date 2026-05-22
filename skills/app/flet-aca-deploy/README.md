# Flet ACA Deploy

Deploy a Flet web app to Azure Container Apps — covering every pitfall from container startup to WebSocket transport to CI/CD revision management.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | The skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## What this skill covers

- Why `flet run --web` crashes in Docker and what to use instead
- `flet-web` in requirements.txt for Dockerfile build-time asset patching
- Favicon, PWA icons, and loading animation overrides in the Dockerfile
- ACA ingress transport must be HTTP/1.1 for WebSocket (not Auto)
- Why private GHCR packages cannot be pulled by ACA and the correct fix
- Full `infra/setup-azure.sh` provisioning script
- Forcing new ACA revisions with `--revision-suffix` in CI
- Diagnosing `ImagePullBackOff` vs container crash failures

## Prerequisites

- Working Dockerfile using `python main.py` as CMD (see `flet-multiplatform-build`)
- GHCR image publishing configured in GitHub Actions
- Azure CLI installed and authenticated (`az login`)
- GitHub CLI installed and authenticated (`gh auth login`)

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
