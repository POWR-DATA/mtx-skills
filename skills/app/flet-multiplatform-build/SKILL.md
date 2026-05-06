---
name: flet-multiplatform-build
description: Set up Android, iOS, and web build pipelines for a Flet app — applying the hard-won lessons about silent failures, package constraints, and CI toolchain gotchas
author: POWR-DATA
version: 1.0.0
license: MIT
---

# Flet Multi-Platform Build

## Purpose

Configure the complete build pipeline for a Flet Python app targeting Android APK/AAB, iOS IPA, and web (Docker server mode), and set up GitHub Actions CI/CD — with explicit guidance on the failure modes that cause builds to silently succeed but crash on device, and the exact configurations needed to avoid them.

## When to use

After the app framework is in place and running locally with `flet run main.py` (see `flet-supabase-framework`). Apply when setting up mobile or web builds for the first time, when debugging a build that passes CI but crashes on device, or when a working local build fails in GitHub Actions.

## Inputs expected

- Working local Flet app (confirmed running with `flet run main.py`)
- `pyproject.toml` with direct deps only and `[tool.flet.app] exclude` set
- `requirements.txt` with full transitive dep tree pinned
- Target platforms: Android, iOS, Web, or subset
- Web hosting target (Azure Container Apps, Fly.io, Railway, etc.)
- GitHub repository name (used in GHCR image path)

## Guiding principles

- **Flet's Android build reads `pyproject.toml`, not `requirements.txt`.** The `flet build apk` command invokes serious_python, which reads `[project] dependencies` from `pyproject.toml` (your direct deps) and resolves transitive deps for Android arm64-v8a from `pypi.flet.dev` — Flet's custom PyPI mirror with pre-built Android wheels. `requirements.txt` is only used to install `flet` on the host so the CLI is available. Never try to control Android package versions via requirements.txt.
- **A 3-second "Packaged Python app OK" means pip was silently skipped.** Serious_python caches the pip step via `build/.hash/package`. If this file exists and the hash matches, pip is skipped entirely and the previous (potentially empty or stale) site-packages are reused. A legitimate Android package step takes 3-8 minutes. If it completes in under 30 seconds, the cache is stale — delete `build/.hash/package` and rerun.
- **Serious_python swallows all exceptions silently.** Its outer `catch(e)` block catches everything — including OS-level file access errors — and exits with code 0. The Flet CLI reports "Packaged Python app OK" regardless. The only way to surface real errors is `flet build apk -vv` (double verbose), which reveals the actual pip output or exception.
- **OneDrive locks the arm64-v8a directory on Windows.** When the project lives inside a OneDrive-synced folder, OneDrive holds a directory lock on `build/site-packages/arm64-v8a/` during sync. Serious_python cannot delete this directory before running pip, so it silently exits. The APK is built but contains no Python packages — the app crashes on first import. Fix: pause OneDrive → delete `build/site-packages/arm64-v8a/` manually → delete `build/.hash/package` → run `flet build apk -vv` and watch for 3-8 minutes of pip output.
- **WASM builds fail with pydantic-core (and any Rust-based package).** `flet build web` compiles Python to WebAssembly via Pyodide. Pyodide requires Emscripten wheels for all packages; `pydantic-core` is written in Rust and has no Emscripten wheel. The build fails at pip install time with a misleading error. Always use Docker server mode for apps that depend on supabase-py.
- **Android arm64-v8a wheel versions are constrained by pypi.flet.dev.** Not all package versions have pre-built Android wheels. Confirmed working: `cryptography==43.0.1`, `cffi==1.17.1`. Do not upgrade these without first checking `pypi.flet.dev` for the target version's arm64-v8a wheel.
- **Accept Android SDK licenses in CI before running flet build.** GitHub Actions ubuntu-latest has the Android SDK pre-installed but not all license agreements accepted. Without explicit acceptance, Flutter's NDK installation step hangs or errors. Always include `yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true` before any `flet build` step.
- **Test on a physical device before trusting CI.** Emulators and build success do not guarantee the app works on real hardware. Install the APK via `adb install -r` and run through the critical paths manually before declaring a build stable.

## Process

### Web — Docker server mode

1. Confirm why WASM is not an option: any app using `supabase-py` depends on `pydantic-core` (Rust). Pyodide cannot load Rust-compiled native extensions. Server mode is the only viable web target.

2. Write `Dockerfile` in the project root:

   ```dockerfile
   FROM python:3.12-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY . .
   EXPOSE 8550
   ENV PYTHONUNBUFFERED=1
   CMD ["flet", "run", "--web", "--host", "0.0.0.0", "--port", "8550", "main.py"]
   ```

   Use `python:3.12-slim` to match the Python version in development. Port 8550 is Flet's default web port.

3. Write `.github/workflows/build-web.yml` — triggers on every push to `main`, builds and pushes to GitHub Container Registry:

   ```yaml
   name: Build and publish web image
   on:
     push:
       branches: [main]
   env:
     REGISTRY: ghcr.io
     IMAGE_NAME: ${{ github.repository }}
   jobs:
     build-and-push:
       runs-on: ubuntu-latest
       permissions:
         contents: read
         packages: write
       steps:
         - uses: actions/checkout@v4
         - uses: docker/login-action@v3
           with:
             registry: ${{ env.REGISTRY }}
             username: ${{ github.actor }}
             password: ${{ secrets.GITHUB_TOKEN }}
         - id: meta
           uses: docker/metadata-action@v5
           with:
             images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
             tags: |
               type=sha,prefix=sha-
               type=raw,value=latest,enable={{is_default_branch}}
         - uses: docker/build-push-action@v6
           with:
             context: .
             push: true
             tags: ${{ steps.meta.outputs.tags }}
             labels: ${{ steps.meta.outputs.labels }}
             cache-from: type=gha
             cache-to: type=gha,mode=max
   ```

   No secrets needed beyond `GITHUB_TOKEN` (automatically provided). The image is pushed to `ghcr.io/<owner>/<repo>:latest`.

4. When deploying the container, inject Supabase credentials as environment variables on the host — never bake them into the Docker image:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

5. For Azure Container Apps specifically: expose port 8550, set minimum replicas >= 1 (Flet uses persistent WebSocket connections — serverless cold-start behaviour will break the UI). Set ingress to external with target port 8550.

### Android — APK and AAB

6. Verify `pyproject.toml` before building:
   - `[project] dependencies` contains only your direct app deps (5-6 items)
   - `[tool.flet.app] exclude` includes `.venv` and `build`
   - `cryptography==43.0.1` and `cffi==1.17.1` are in `requirements.txt` (host dev env) — pip will resolve compatible versions for Android arm64-v8a automatically via pypi.flet.dev

7. Local build procedure on Windows (especially if project is inside OneDrive):

   ```
   a. Pause OneDrive sync (system tray -> pause)
   b. Delete build/site-packages/arm64-v8a/ (Windows Explorer or PowerShell)
   c. Delete build/.hash/package (forces pip re-run)
   d. Run: flet build apk -vv
   e. Watch output — pip should run for 3-8 minutes installing ~80 packages
   f. If "Packaged Python app OK" appears in under 30 seconds, pip was skipped — repeat from step a
   g. Resume OneDrive sync after build completes
   ```

8. Smoke-test the APK on a physical device:

   ```powershell
   # If adb is not in PATH, use full path:
   & "C:\Users\<user>\Android\sdk\platform-tools\adb.exe" install -r build\apk\your-app.apk
   ```

   Test: sign in, navigate all screens, confirm data loads from Supabase. A successful build that crashes on first import means packages were missing from the APK — the build/OneDrive issue (step 7) was not fully resolved.

9. Write `.github/workflows/build-android.yml` — manual trigger, produces APK and AAB artifacts:

   ```yaml
   name: Build Android
   on:
     workflow_dispatch:
   jobs:
     build-android:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v4
           with:
             distribution: temurin
             java-version: "17"
         - uses: actions/setup-python@v5
           with:
             python-version: "3.12"
         - uses: subosito/flutter-action@v2
           with:
             channel: stable
             cache: true
         - name: Accept Android SDK licenses
           run: yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true
         - name: Install Python dependencies
           run: pip install -r requirements.txt
         - name: Build APK
           run: flet build apk --verbose
         - name: Build AAB
           run: flet build aab --verbose
         - uses: actions/upload-artifact@v4
           with:
             name: android-apk
             path: build/apk/
             retention-days: 7
         - uses: actions/upload-artifact@v4
           with:
             name: android-aab
             path: build/aab/
             retention-days: 7
   ```

   The `sdkmanager --licenses` step is required — without it, Flutter's NDK download may hang on an interactive license prompt in CI. The `|| true` prevents the step from failing if sdkmanager is at a different path on some runners.

10. Confirm the CI build ran pip properly: the "Build APK" step should take 5-15 minutes in CI. A sub-1-minute APK build means something was cached incorrectly or pip was skipped.

### iOS

11. iOS builds require a macOS runner. Write `.github/workflows/build-ios.yml`:

    ```yaml
    name: Build iOS
    on:
      workflow_dispatch:
    jobs:
      build-ios:
        runs-on: macos-latest
        steps:
          - uses: actions/checkout@v4
          - uses: actions/setup-python@v5
            with:
              python-version: "3.12"
          - uses: subosito/flutter-action@v2
            with:
              channel: stable
              cache: true
          - name: Install Python dependencies
            run: pip install -r requirements.txt
          - name: Build iOS (unsigned)
            run: flet build ipa --verbose
          - uses: actions/upload-artifact@v4
            with:
              name: ios-ipa
              path: build/ipa/
              retention-days: 7
    ```

    This produces an unsigned IPA for local testing only. Signed distribution builds require Apple Developer Program enrollment.

### Signing (before store submission)

12. Android signing — generate a keystore, encode it, add to GitHub Secrets:

    ```bash
    keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000
    base64 -i upload-keystore.jks | pbcopy   # macOS — paste into GitHub Secret
    ```

    Required secrets:
    - `ANDROID_KEYSTORE_BASE64`
    - `ANDROID_KEY_ALIAS`
    - `ANDROID_KEY_PASSWORD`
    - `ANDROID_STORE_PASSWORD`

13. iOS signing secrets (requires Apple Developer Program):
    - `APPLE_CERTIFICATE_BASE64`
    - `APPLE_CERTIFICATE_PASSWORD`
    - `APPLE_PROVISIONING_PROFILE_BASE64`
    - `APP_STORE_CONNECT_API_KEY_ID`
    - `APP_STORE_CONNECT_ISSUER_ID`
    - `APP_STORE_CONNECT_API_KEY_BASE64`

14. Before store submission, set in `pyproject.toml [tool.flet]`:
    - `app.name` — display name
    - `app.bundle_id` — must match Play Store package name / App Store bundle ID exactly
    - `app.version` and `app.build_number`

    Update platform-specific URL constants in the app (Play Store review URL, App Store review URL) once the app is registered.

## Output format

1. **`Dockerfile`** — complete file
2. **`.github/workflows/build-web.yml`** — complete file
3. **`.github/workflows/build-android.yml`** — complete file
4. **`.github/workflows/build-ios.yml`** — complete file (unsigned)
5. **Local build procedure** — step-by-step for Windows/OneDrive environments
6. **Secrets reference** — all GitHub Secrets needed per platform, grouped
7. **Pre-store checklist** — items to complete before Play Store / App Store submission
8. **Diagnostic guide** — how to detect and fix silent Android packaging failures

## Quality checklist

- [ ] `pyproject.toml` has only direct dependencies — no transitive deps
- [ ] `[tool.flet.app] exclude` contains `.venv` and `build`
- [ ] `cryptography==43.0.1` and `cffi==1.17.1` in `requirements.txt`
- [ ] Dockerfile uses `python:3.12-slim`, exposes 8550, uses `flet run --web --host 0.0.0.0`
- [ ] Supabase credentials injected as env vars on container host — not in the image
- [ ] `build-android.yml` includes `sdkmanager --licenses || true` before `flet build`
- [ ] CI Android build step ran for >3 minutes (confirms pip actually executed)
- [ ] APK tested on a physical Android device — not just in emulator
- [ ] `build/.hash/package` deleted before any forced local rebuild
- [ ] OneDrive sync paused before local Android builds (Windows)
- [ ] Azure Container Apps ingress target port set to 8550 with min replicas >= 1

## Avoid

- Using `flet build web` (Pyodide/WASM) when `pydantic-core` or any Rust-compiled package is in the dependency tree — the build fails at pip install time, not at compile time, and the error message does not mention WASM incompatibility
- Trusting a `flet build apk` that completes "Packaged Python app OK" in under 30 seconds — pip was almost certainly skipped; the APK will crash on device at first import
- Building Android APKs on a Windows machine inside an OneDrive-synced directory without pausing sync and clearing the arm64-v8a directory first
- Running `flet build apk` without `-vv` when debugging — the default output swallows all pip errors and shows success regardless
- Upgrading `cryptography` or `cffi` without first confirming the new version has an arm64-v8a wheel on `pypi.flet.dev`
- Baking `SUPABASE_URL` or `SUPABASE_ANON_KEY` into the Docker image — always inject as runtime environment variables on the container host
- Setting Azure Container Apps minimum replicas to 0 — Flet's WebSocket connection requires a persistent server; cold starts break the UI

## Diagnostic guide — silent Android packaging failures

If the app installs but crashes on first screen with `ModuleNotFoundError`:

1. Check build timing: was "Packaged Python app OK" in under 30 seconds? → pip was skipped
2. Run `flet build apk -vv` and look for `PathAccessException` or `Access is denied` → OneDrive lock
3. Check `build/site-packages/arm64-v8a/` — if empty or missing, pip never ran
4. Pause OneDrive, delete `arm64-v8a/` and `build/.hash/package`, rebuild with `-vv`
5. Confirm pip runs for 3-8 minutes and installs ~80 packages
6. Check `build/site-packages/arm64-v8a/` after rebuild — should contain 80+ package directories
7. If pip runs but a specific package fails: check `pypi.flet.dev` for arm64-v8a wheel availability for that version

## Example usage

> "The Flet app runs locally. Set up Android and web builds. We're pushing to GitHub Container Registry for web and want to deploy to Azure Container Apps eventually. Generate all three workflow files and the Dockerfile."
