# Example Input

## User request

> My Flet app is running locally with `flet run main.py`. I need to set up CI/CD for Android APK and web (Docker). The app uses supabase-py so WASM is not an option. The repo is `myorg/gardentrack` and the project lives inside a OneDrive-synced folder on Windows. Generate the Dockerfile, the web and Android GitHub Actions workflows, and an `install-apk.sh` script.

## Current state

- App confirmed working locally: `flet run main.py` and `flet run --web --port 8550 main.py`
- `pyproject.toml` has direct dependencies only (flet, supabase, httpx, python-dotenv, tzdata)
- `requirements.txt` has the full transitive dep tree pinned, including `flet-web==0.84.0`
- `[tool.flet.app] exclude` already includes `.venv` and `build`
- No existing Dockerfile or CI/CD workflows
- Project path: `C:\Users\myuser\OneDrive\Documents\gardentrack`

## Requirements

- Web target: Docker server mode pushed to GHCR, deployed to Azure Container Apps (ACA deploy handled separately)
- Android target: APK on every push to `main`; AAB only on manual trigger
- Local APK install helper script using ADB and GitHub CLI
- iOS not needed at this stage
