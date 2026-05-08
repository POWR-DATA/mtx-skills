---
name: flet-multiplatform-build
description: Build Android, iOS, and web Docker artifacts for a Flet app — covers Android silent packaging failures, GHCR/ACA deploy patterns, web asset quality, and local dev gotchas
author: POWR-DATA
version: 2.0.0
license: MIT
---

# Flet Multi-Platform Build

## Purpose

Configure the complete build pipeline for a Flet Python app targeting Android APK/AAB, iOS IPA, and web (Docker server mode), and set up GitHub Actions CI/CD — with explicit guidance on the failure modes that cause builds to silently succeed but crash on device, and the exact configurations needed to avoid them.

## When to use

After the app framework is in place and running locally with `flet run main.py` (see `flet-supabase-framework`). Apply when setting up mobile or web builds for the first time, when debugging a build that passes CI but crashes on device, or when a working local build fails in GitHub Actions. For deploying the web image to Azure Container Apps, also load the `flet-aca-deploy` skill.

## Inputs expected

- Working local Flet app (confirmed running with `flet run main.py`)
- `pyproject.toml` with direct deps only and `[tool.flet.app] exclude` set
- `requirements.txt` with full transitive dep tree pinned (including `flet-web`)
- Target platforms: Android, iOS, Web, or subset
- Web hosting target (Azure Container Apps, Fly.io, Railway, etc.)
- GitHub repository name (used in GHCR image path)

---

## Guiding principles

### Android packaging

- **Flet's Android build reads `pyproject.toml`, not `requirements.txt`.** The `flet build apk` command invokes serious_python, which reads `[project] dependencies` from `pyproject.toml` and resolves transitive deps for Android arm64-v8a from `pypi.flet.dev` — Flet's custom PyPI mirror with pre-built Android wheels. `requirements.txt` is only used to install `flet` on the host so the CLI is available.
- **A 3-second "Packaged Python app OK" means pip was silently skipped.** Serious_python caches the pip step via `build/.hash/package`. A legitimate Android package step takes 3-8 minutes. If it completes in under 30 seconds, the cache is stale — delete `build/.hash/package` and rerun.
- **Serious_python swallows all exceptions silently.** Its outer catch block catches everything and exits with code 0. The only way to surface real errors is `flet build apk -vv` (double verbose).
- **OneDrive locks the arm64-v8a directory on Windows.** When the project lives inside a OneDrive-synced folder, OneDrive holds a lock on `build/site-packages/arm64-v8a/` during sync. Serious_python cannot delete this directory before running pip, so it silently exits with an empty APK. Fix: pause OneDrive → delete `build/site-packages/arm64-v8a/` → delete `build/.hash/package` → run `flet build apk -vv`.
- **WASM builds fail with pydantic-core (and any Rust-based package).** `flet build web` uses Pyodide/WebAssembly. `pydantic-core` is written in Rust and has no Emscripten wheel. Always use Docker server mode for apps that depend on supabase-py.
- **Android arm64-v8a wheel versions are constrained by pypi.flet.dev.** Confirmed working: `cryptography==43.0.1`, `cffi==1.17.1`. Do not upgrade without checking `pypi.flet.dev` for the target version's arm64-v8a wheel.
- **Accept Android SDK licenses in CI before running flet build.** Without explicit acceptance, Flutter's NDK installation step may hang or error.

### Docker / Web image build

- **Do not use `flet run --web` as the Dockerfile CMD.** Even in `--web` mode, `flet run` imports `flet_desktop` at startup. `flet_desktop` requires native GUI libraries not present in `python:3.12-slim` — the container crashes immediately. Use `python main.py` and configure web mode in code.
- **`docker/setup-buildx-action@v3` is required before `build-push-action` when using `cache-to: type=gha`.** Without it the build fails: `ERROR: Cache export is not supported for the docker driver`.
- **GHCR image names must be lowercase.** `${{ github.repository }}` preserves the repo name's original case. GHCR normalises to lowercase — the deploy step must reference the lowercase name explicitly.
- **`flet-web` must be in `requirements.txt` for Dockerfile RUN steps.** `flet_web` auto-installs at runtime but not at build time. Dockerfile `RUN python -c "import flet_web, ..."` steps fail with `ModuleNotFoundError` if `flet-web` is not listed.

### Web layout

- **Use `ft.View.horizontal_alignment` + fixed `width` on the container** to constrain content width in Flet web mode — the only reliable approach.
- **`ft.alignment.top_center` does not exist in Flet 0.84.** Use `ft.Alignment(0, -1)` or `View.horizontal_alignment`.
- **`expand=True` with nested containers and `ft.Alignment` does not reliably center content in scrollable web views.** Use `View.horizontal_alignment` instead.

### Icons and images

- **SVG images are not supported in `ft.Image` in Flet 0.84.** Passing an SVG path renders as the default Flutter fish placeholder — no error is raised. Always use PNGs.
- **Image sizing strategy for web/HiDPI displays:** Use a purpose-built small source for small display sizes (e.g. a 48px PNG for a 44px AppBar icon), and a large source for larger display sizes (e.g. 512px source for 120–180px display). Downscaling a very large icon (512px → 44px) loses quality even with HIGH filter.
- **Set `filter_quality=ft.FilterQuality.HIGH` on every `ft.Image` control.**
  ```python
  # AppBar — use small source (48px) at small size (44px)
  ft.Image(src="simple_logo_48.png", width=44, height=44, filter_quality=ft.FilterQuality.HIGH)
  # Login screen — use large source (512px) at medium size (180px)
  ft.Image(src="logo_512.png", width=180, height=180, filter_quality=ft.FilterQuality.HIGH)
  ```

### Local web dev — Windows gotchas

- **`flet run --web` opens `http://0.0.0.0:PORT/` on Windows.** Navigate to `http://localhost:PORT/` instead. Use `--port 8550` for a predictable URL.
- **Browser caches Flutter web apps aggressively.** `Ctrl+Shift+R` is often insufficient. Use an incognito window or a completely different browser to test image/asset changes locally.
- **Local server restart on Windows (when port 8550 is busy):**
  ```powershell
  taskkill /F /IM python.exe
  python main.py
  ```
- **Refreshing local flet_web assets** (favicon, icons, loading-animation) without rebuilding Docker:
  ```powershell
  python -c "
  import flet_web, os, shutil
  web = os.path.join(os.path.dirname(flet_web.__file__), 'web')
  shutil.copy('assets/favicon.png', os.path.join(web, 'favicon.png'))
  for n in ['icon-192.png','icon-maskable-192.png','apple-touch-icon-192.png']:
      shutil.copy('assets/logo_192.png', os.path.join(web, 'icons', n))
  for n in ['icon-512.png','icon-maskable-512.png']:
      shutil.copy('assets/logo_512.png', os.path.join(web, 'icons', n))
  shutil.copy('assets/logo_512.png', os.path.join(web, 'icons', 'loading-animation.png'))
  print('Done')
  "
  ```
  The `.venv` must be active. After copying, restart the server and open a fresh incognito window.

---

## Process

### Web — Docker server mode

1. Confirm why WASM is not an option: any app using `supabase-py` depends on `pydantic-core` (Rust). Pyodide cannot load Rust-compiled native extensions.

2. Write `main.py` with the `FLET_HOST` env var pattern:
   ```python
   if __name__ == "__main__":
       import os
       host = os.environ.get("FLET_HOST", "localhost")
       ft.run(main, host=host, port=8550, view=ft.AppView.WEB_BROWSER,
              web_renderer=ft.WebRenderer.CANVAS_KIT)
   ```

3. Write `Dockerfile` — patches all flet_web assets in a single RUN step:
   ```dockerfile
   FROM python:3.12-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY . .
   RUN python -c "\
   import flet_web, os, shutil; \
   web = os.path.join(os.path.dirname(flet_web.__file__), 'web'); \
   shutil.copy('assets/favicon.png', os.path.join(web, 'favicon.png')); \
   [shutil.copy('assets/logo_192.png', os.path.join(web, 'icons', n)) for n in ['icon-192.png','icon-maskable-192.png','apple-touch-icon-192.png']]; \
   [shutil.copy('assets/logo_512.png', os.path.join(web, 'icons', n)) for n in ['icon-512.png','icon-maskable-512.png']]; \
   shutil.copy('assets/logo_512.png', os.path.join(web, 'icons', 'loading-animation.png')); \
   idx = os.path.join(web, 'index.html'); \
   html = open(idx).read().replace('scale(0.4)', 'scale(0.8)').replace('scale(0.35)', 'scale(0.75)'); \
   open(idx, 'w').write(html) \
   "
   EXPOSE 8550
   ENV PYTHONUNBUFFERED=1
   ENV FLET_HOST=0.0.0.0
   CMD ["python", "main.py"]
   ```

4. Write `.github/workflows/build-web.yml`:
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
         - uses: docker/setup-buildx-action@v3          # REQUIRED for GHA cache
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
   For the deploy job, see `flet-aca-deploy`.

### Android — APK and AAB

5. Verify `pyproject.toml` before building:
   - `[project] dependencies` contains only your direct app deps (5-6 items)
   - `[tool.flet.app] exclude` includes `.venv` and `build`
   - `cryptography==43.0.1` and `cffi==1.17.1` in `requirements.txt`

6. Local build procedure on Windows (especially if project is inside OneDrive):
   ```
   a. Pause OneDrive sync (system tray → pause)
   b. Delete build/site-packages/arm64-v8a/ (Windows Explorer or PowerShell)
   c. Delete build/.hash/package (forces pip re-run)
   d. Run: flet build apk -vv
   e. Watch output — pip should run for 3-8 minutes installing ~80 packages
   f. If "Packaged Python app OK" appears in under 30 seconds, pip was skipped — repeat from step a
   g. Resume OneDrive sync after build completes
   ```

7. Smoke-test the APK on a physical device:
   ```powershell
   & "C:\Users\<user>\Android\sdk\platform-tools\adb.exe" install -r build\apk\your-app.apk
   ```

8. Write `.github/workflows/build-android.yml` — APK on every push, AAB only on manual trigger:
   ```yaml
   name: Build Android
   on:
     push:
       branches: [main]
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
         - uses: actions/cache@v4
           with:
             path: ~/.cache/pip
             key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
             restore-keys: ${{ runner.os }}-pip-
         - run: pip install -r requirements.txt
         - name: Build APK
           run: flet build apk --verbose
         - name: Build AAB (manual trigger only)
           if: github.event_name == 'workflow_dispatch'
           run: flet build aab --verbose
         - uses: actions/upload-artifact@v4
           with:
             name: android-apk
             path: build/apk/
             retention-days: 7
         - name: Upload AAB
           if: github.event_name == 'workflow_dispatch'
           uses: actions/upload-artifact@v4
           with:
             name: android-aab
             path: build/aab/
             retention-days: 7
   ```

### install-apk.sh pattern

```bash
#!/usr/bin/env bash
set -e

GH="/c/Program Files/GitHub CLI/gh.exe"
ADB="/c/Users/<user>/Android/sdk/platform-tools/adb.exe"
REPO="<owner>/<repo>"
WORK_DIR="/tmp/<app>-apk"

echo "==> Checking ADB device..."
"$ADB" devices

echo "==> Downloading latest android-apk artifact..."
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
"$GH" run download --repo "$REPO" --name android-apk --dir "$WORK_DIR"

APK=$(find "$WORK_DIR" -name "*.apk" | head -1)
echo "==> Uninstalling existing version (if any)..."
"$ADB" uninstall com.<bundle.id> 2>/dev/null || true

echo "==> Installing on device..."
"$ADB" install "$APK"
echo "Done!"
```

Always uninstall first — debug builds from different CI runs have different signing keys, causing `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

### iOS

9. iOS builds require a macOS runner. Write `.github/workflows/build-ios.yml`:
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
   This produces an unsigned IPA for local testing only. Signed distribution builds require Apple Developer Program enrollment ($99/year, annual — no monthly option). Xcode only runs on macOS — Windows cannot build iOS apps directly.

### Signing (before store submission)

10. Android signing:
    ```bash
    keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000
    base64 -i upload-keystore.jks | pbcopy   # macOS — paste into GitHub Secret
    ```
    Required secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`

11. iOS signing secrets (requires Apple Developer Program):
    - `APPLE_CERTIFICATE_BASE64`
    - `APPLE_CERTIFICATE_PASSWORD`
    - `APPLE_PROVISIONING_PROFILE_BASE64`
    - `APP_STORE_CONNECT_API_KEY_ID`
    - `APP_STORE_CONNECT_ISSUER_ID`
    - `APP_STORE_CONNECT_API_KEY_BASE64`

12. Before store submission, fill in `pyproject.toml [tool.flet]`:
    - `app.name`, `app.bundle_id`, `app.version`, `app.build_number`
    - Update platform-specific URL constants in the app (Play Store / App Store review URL)

---

## Testing tiers

| Tier | Command | Time | Use for |
|------|---------|------|---------|
| Desktop | `flet run main.py` | Instant | All logic, Supabase, navigation, UI |
| Web local | `flet run --web --port 8550 main.py` → `http://localhost:8550/` | Seconds | Web rendering, before every push |
| Android (CI) | push → `bash install-apk.sh` | ~12 min | Mobile-specific behaviour, official artifact |
| Android (local) | `flet build apk` + `adb install` | ~5 min | Frequent mobile testing (requires Flutter locally) |
| iOS | macOS + `flet build ipa` | N/A on Windows | Defer to App Store prep |

**Workflow:** `write code → flet run (desktop) → flet run --web → [if mobile needed] → commit + push → install-apk.sh`

---

## Quality checklist

- [ ] `docker/setup-buildx-action@v3` step added before `docker/login-action`
- [ ] Dockerfile CMD uses `python main.py`, not `flet run --web main.py`
- [ ] `ft.run()` used (not deprecated `ft.app()`); `FLET_HOST` env var controls bind address
- [ ] `flet-web==<version>` in `requirements.txt` (same version as `flet`)
- [ ] Dockerfile RUN step patches flet_web assets: favicon, PWA icons, loading-animation, CSS scale
- [ ] AAB build and upload steps gated with `if: github.event_name == 'workflow_dispatch'`
- [ ] Pip cache step added to Android workflow before `pip install`
- [ ] App icon is transparent PNG — 1024×1024px; splash screen 2048×2048px (separate files)
- [ ] All `ft.Image` controls have `filter_quality=ft.FilterQuality.HIGH`
- [ ] AppBar icon uses a purpose-built small source (≤48px); login/splash images use large source (≥512px)
- [ ] No SVG files referenced in `ft.Image` — use PNG equivalents
- [ ] `install-apk.sh` in repo root with uninstall-before-install pattern
- [ ] Web views that need max-width use `View.horizontal_alignment=CENTER` + fixed `width` container
- [ ] `build/.hash/package` deleted before any forced local Android rebuild
- [ ] OneDrive sync paused before local Android builds (Windows)

---

## Avoid

- `flet run --web` as Dockerfile CMD — `flet_desktop` unavailable in slim images; container crashes immediately
- `ft.app()` — deprecated since Flet 0.80; use `ft.run()`
- `web_renderer="html"` — removed in Flutter 3+; raises `ValueError`; use `ft.WebRenderer.CANVAS_KIT`
- Hardcoding `host="0.0.0.0"` in `ft.run()` — breaks local dev; use `FLET_HOST` env var
- Omitting `flet-web` from `requirements.txt` — Dockerfile RUN steps that `import flet_web` fail at build time
- SVG images in `ft.Image` — not supported in Flet 0.84; renders as Flutter fish placeholder with no error
- Omitting `filter_quality=ft.FilterQuality.HIGH` on `ft.Image` — blurry/grainy rendering on web and HiDPI
- Downscaling a large icon to a small display size (e.g. 512px → 44px) — use a purpose-built small source
- Testing asset changes with a regular browser tab — Flutter service worker caches aggressively; use incognito
- Using `${{ github.repository }}` in image references — preserves mixed case, breaks GHCR
- Building AAB on every push — gate it to `workflow_dispatch`
- Skipping pip cache in Android CI — adds several minutes per run
- Relying on `.env` for runtime config on mobile — the file is not bundled
- Trusting a `flet build apk` that completes in under 30 seconds — pip was skipped; APK will crash on device
- Building Android APKs on Windows inside an OneDrive-synced directory without pausing sync first
- Running `flet build apk` without `-vv` when debugging — default output swallows all pip errors
- Upgrading `cryptography` or `cffi` without first confirming the new version has an arm64-v8a wheel on `pypi.flet.dev`
- Setting Azure Container Apps minimum replicas to 0 — Flet's WebSocket connection breaks on cold start
- `ft.alignment.top_center` — does not exist in Flet 0.84; use `View.horizontal_alignment`
- `expand=True` with nested containers and `ft.Alignment` for centering in web views — unreliable
- Navigating to `http://0.0.0.0:PORT/` in browser on Windows — use `localhost:PORT`

---

## Diagnostic guide — silent Android packaging failures

If the app installs but crashes on first screen with `ModuleNotFoundError`:

1. Check build timing: was "Packaged Python app OK" in under 30 seconds? → pip was skipped
2. Run `flet build apk -vv` and look for `PathAccessException` or `Access is denied` → OneDrive lock
3. Check `build/site-packages/arm64-v8a/` — if empty or missing, pip never ran
4. Pause OneDrive, delete `arm64-v8a/` and `build/.hash/package`, rebuild with `-vv`
5. Confirm pip runs for 3-8 minutes and installs ~80 packages
6. If pip runs but a specific package fails: check `pypi.flet.dev` for arm64-v8a wheel availability
