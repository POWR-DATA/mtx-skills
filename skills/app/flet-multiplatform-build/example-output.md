# Example Output

## Why WASM is not an option

`supabase-py` depends on `pydantic-core`, which is written in Rust. Pyodide (the WebAssembly Python runtime used by `flet build web`) cannot load Rust-compiled native extensions. Use Docker server mode instead.

---

## Dockerfile

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

The `RUN python -c ...` step patches `flet_web` assets (favicon, PWA icons, loading animation, splash scale) at image build time. `flet-web` must be in `requirements.txt` for this step to work.

---

## .github/workflows/build-web.yml

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

For the ACA deploy job, see `flet-aca-deploy`.

---

## .github/workflows/build-android.yml

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

---

## install-apk.sh

```bash
#!/usr/bin/env bash
set -e

GH="/c/Program Files/GitHub CLI/gh.exe"
ADB="/c/Users/myuser/Android/sdk/platform-tools/adb.exe"
REPO="myorg/gardentrack"
WORK_DIR="/tmp/gardentrack-apk"

echo "==> Checking ADB device..."
"$ADB" devices

echo "==> Downloading latest android-apk artifact..."
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
"$GH" run download --repo "$REPO" --name android-apk --dir "$WORK_DIR"

APK=$(find "$WORK_DIR" -name "*.apk" | head -1)
echo "==> Uninstalling existing version (if any)..."
"$ADB" uninstall com.myorg.gardentrack 2>/dev/null || true

echo "==> Installing on device..."
"$ADB" install "$APK"
echo "Done!"
```

Always uninstall before installing — debug APKs from different CI runs have different signing keys, causing `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

---

## Local Android build on Windows (OneDrive project)

Before running `flet build apk` locally:

1. Pause OneDrive sync (system tray → right-click → Pause syncing)
2. Delete `build/site-packages/arm64-v8a/` (OneDrive holds a file lock on this directory)
3. Delete `build/.hash/package` (forces pip to re-run)
4. Run `flet build apk -vv`
5. Confirm pip runs for 3–8 minutes installing ~80 packages — if "Packaged Python app OK" appears in under 30 seconds, pip was skipped; repeat from step 1
6. Resume OneDrive sync after the build completes

---

## Notes

- `docker/setup-buildx-action@v3` is required before `docker/build-push-action` when using `cache-to: type=gha` — without it, the build fails with `ERROR: Cache export is not supported for the docker driver`
- GHCR image names must be lowercase. `${{ github.repository }}` preserves the repo's original case; the deploy step must reference a hardcoded lowercase name
- AAB build is gated to `workflow_dispatch` — do not build AAB on every push
- The pip cache step saves several minutes per Android CI run

---

## Next recommended step

Push to `main` to trigger both workflows. Once `android-apk` is available as a CI artifact, run `bash install-apk.sh` to install on a physical device and verify the app starts without a `ModuleNotFoundError`.
