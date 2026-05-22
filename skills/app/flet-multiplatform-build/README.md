# Flet Multi-Platform Build

Configure the complete build pipeline for a Flet Python app targeting Android APK/AAB, iOS IPA, and web (Docker server mode), with GitHub Actions CI/CD — and explicit guidance on the silent failure modes that cause builds to pass CI but crash on device.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | The skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## What this skill covers

- Why WASM builds fail with pydantic-core and when to use Docker server mode instead
- Silent Android packaging failures — why a 3-second build means pip was silently skipped
- OneDrive directory lock on `build/site-packages/arm64-v8a/` and how to work around it
- Dockerfile configuration using `python main.py` (not `flet run --web`)
- GitHub Actions workflows for web (Docker/GHCR), Android (APK/AAB), and iOS (IPA)
- GHCR image naming and lowercase requirements
- `install-apk.sh` pattern for installing CI-built APKs onto a physical device
- Android and iOS signing checklists before store submission

## Prerequisites

- Working Flet app running locally with `flet run main.py` (see `flet-supabase-framework`)
- `pyproject.toml` with direct dependencies only and `[tool.flet.app] exclude` configured
- `requirements.txt` with full transitive dependency tree pinned (including `flet-web`)
- For deploying the web image to Azure Container Apps, also load `flet-aca-deploy`

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
