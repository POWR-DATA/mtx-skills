# Flet Multi-Platform Build — Reference Templates

Load-on-demand templates and troubleshooting for the steps in [`SKILL.md`](SKILL.md). These are **illustrative excerpts** — load-bearing lines only. Fill in placeholders (`<...>`) and pin versions to match your `requirements.txt`.

---

## main.py — FLET_HOST web guard

Only pass web params when `FLET_HOST` is set; passing them unconditionally crashes serious_python on Android before `main(page)` runs.

```python
if __name__ == "__main__":
    import os
    host = os.environ.get("FLET_HOST")
    if host:
        ft.run(main, host=host, port=8550, view=ft.AppView.WEB_BROWSER,
               web_renderer=ft.WebRenderer.CANVAS_KIT)
    else:
        ft.run(main)
```

## Dockerfile (web, server mode)

Patches all flet_web assets in one RUN step; runs `python main.py` (never `flet run --web`).

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
# ... copy PWA icons (icon-192/512, maskable, apple-touch) and loading-animation.png; \
idx = os.path.join(web, 'index.html'); \
open(idx,'w').write(open(idx).read().replace('scale(0.4)','scale(0.8)')) \
"
EXPOSE 8550
ENV PYTHONUNBUFFERED=1
ENV FLET_HOST=0.0.0.0
CMD ["python", "main.py"]
```

## build-web.yml

`setup-buildx-action` is required before `build-push-action` when using GHA cache. For the deploy job, see `flet-aca-deploy`.

```yaml
name: Build and publish web image
on:
  push: { branches: [main] }
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions: { contents: read, packages: write }
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
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

> Reference the **lowercase** image name in the deploy step — `${{ github.repository }}` preserves case; GHCR normalises to lowercase.

## build-android.yml

APK on every push, AAB only on manual trigger. Install only the flet CLI on the host — serious_python bundles deps from `pyproject.toml`.

```yaml
name: Build Android
on:
  push: { branches: [main] }
  workflow_dispatch:
jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: "17" }
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - name: Accept Android SDK licenses
        run: yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true
      - name: Install flet CLI
        run: pip install flet==<version>   # CLI only — NOT pip install -r requirements.txt
      - name: Build APK
        run: flet build apk --verbose
      - name: Build AAB (manual only)
        if: github.event_name == 'workflow_dispatch'
        run: flet build aab --verbose
      - uses: actions/upload-artifact@v4
        with: { name: android-apk, path: build/apk/, retention-days: 7 }
      # ... AAB upload gated on workflow_dispatch
```

## Local Android build (Windows / OneDrive)

```
a. Pause OneDrive sync (system tray → pause)
b. Delete build/site-packages/arm64-v8a/
c. Delete build/.hash/package        # forces pip re-run
d. flet build apk -vv                 # pip should run 3–8 min (~80 packages)
e. If "Packaged Python app OK" in <30s → pip was skipped; repeat from (a)
f. Resume OneDrive sync after the build
```

## install-apk.sh

Always uninstall first — CI debug builds have different signing keys, causing `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

```bash
#!/usr/bin/env bash
set -e
ADB="/c/Users/<user>/Android/sdk/platform-tools/adb.exe"
REPO="<owner>/<repo>"
gh run download --repo "$REPO" --name android-apk --dir /tmp/apk
APK=$(find /tmp/apk -name "*.apk" | head -1)
"$ADB" uninstall com.<bundle.id> 2>/dev/null || true   # different signing key each run
"$ADB" install "$APK"
```

## iOS — pyproject.toml

All app metadata in one `[tool.flet.app]` section — do not mix dotted `[tool.flet]` keys with it (TOML duplicate-declaration error).

```toml
[tool.flet.app]
name = "YourApp"
bundle_id = "com.yourorg.yourapp"
version = "1.0.0"
build_number = 1
icon = "assets/<icon>.png"
splash = "assets/<splash>.png"
exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]
```

## build-ios.yml

`flet build ipa` without signing produces an `.xcarchive`, not an `.ipa` — the packaging step extracts the `.app`, ad-hoc signs it, wraps it in `Payload/`, and zips it.

```yaml
name: Build iOS
on: { workflow_dispatch: {} }
jobs:
  build-ios:
    runs-on: macos-latest        # 10× minutes vs ubuntu
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
      - run: pip install -r requirements.txt
      - run: flet build ipa --verbose
      - name: Package IPA from xcarchive
        run: |
          XCARCHIVE=$(find build/ipa -name "*.xcarchive" | head -1)
          APP=$(find "$XCARCHIVE/Products/Applications" -name "*.app" | head -1)
          codesign --force --deep --sign - "$APP"
          mkdir -p /tmp/ipa-stage/Payload && cp -r "$APP" /tmp/ipa-stage/Payload/
          (cd /tmp/ipa-stage && zip -r app.ipa Payload)
          cp /tmp/ipa-stage/app.ipa build/ipa/app.ipa
      - uses: actions/upload-artifact@v4
        with: { name: ios-ipa, path: build/ipa/app.ipa }   # the .ipa, not the dir
```

## Image quality

```python
# small source for small size; large source for large size; HIGH filter always
ft.Image(src="logo_48.png",  width=44,  height=44,  filter_quality=ft.FilterQuality.HIGH)
ft.Image(src="logo_512.png", width=180, height=180, filter_quality=ft.FilterQuality.HIGH)
```

## Local flet_web asset refresh (Windows, no Docker rebuild)

`.venv` must be active; restart the server and open a fresh incognito window after.

```powershell
python -c "import flet_web, os, shutil; web=os.path.join(os.path.dirname(flet_web.__file__),'web'); shutil.copy('assets/favicon.png', os.path.join(web,'favicon.png'))"
# ... repeat for PWA icons and loading-animation.png
```

## Troubleshooting — silent Android packaging failure

App installs but crashes on first screen with `ModuleNotFoundError`:

1. Was "Packaged Python app OK" in under 30s? → pip was skipped.
2. `flet build apk -vv` → look for `PathAccessException` / `Access is denied` → OneDrive lock.
3. Check `build/site-packages/arm64-v8a/` — empty or missing means pip never ran.
4. Pause OneDrive, delete `arm64-v8a/` and `build/.hash/package`, rebuild with `-vv`.
5. Confirm pip runs 3–8 min installing ~80 packages.
6. If a specific package fails: check `pypi.flet.dev` for its arm64-v8a wheel.
