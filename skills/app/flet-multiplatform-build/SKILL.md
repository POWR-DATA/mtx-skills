---
name: flet-multiplatform-build
description: Build Android, iOS, and web Docker artifacts for a Flet app — covers Android silent packaging failures, GHCR/ACA deploy patterns, web asset quality, and local dev gotchas
author: POWR-DATA
version: 2.4.0
license: MIT
---

# Flet Multi-Platform Build

## Purpose

Configure the complete build pipeline for a Flet Python app targeting Android APK/AAB, iOS IPA, and web (Docker server mode), and set up GitHub Actions CI/CD — with explicit guidance on the failure modes that cause builds to silently succeed but crash on device, and the exact configurations needed to avoid them.

## When to use

After the app framework is in place and running locally with `flet run main.py` (see `flet-supabase-framework`). Apply when setting up mobile or web builds for the first time, when debugging a build that passes CI but crashes on device, or when a working local build fails in GitHub Actions. For deploying the web image to Azure Container Apps, also load `flet-aca-deploy`.

## Inputs expected

- Working local Flet app (confirmed running with `flet run main.py`)
- `pyproject.toml` with direct deps only and `[tool.flet.app] exclude` set
- `requirements.txt` with full transitive dep tree pinned (including `flet-web`)
- Target platforms: Android, iOS, Web, or subset
- Web hosting target (Azure Container Apps, Fly.io, Railway, etc.)
- GitHub repository name (used in the GHCR image path)

---

## Guiding principles

### Android packaging

- **Flet's Android build reads `pyproject.toml`, not `requirements.txt`.** `flet build apk` invokes serious_python, which reads `[project] dependencies` and resolves transitive deps for arm64-v8a from `pypi.flet.dev`. `requirements.txt` only installs the `flet` CLI on the host.
- **A sub-30-second "Packaged Python app OK" means pip was silently skipped.** A real package step takes 3–8 minutes. Serious_python caches it via `build/.hash/package` — delete that file and rerun if the step is suspiciously fast.
- **Serious_python swallows all exceptions and exits 0.** The only way to surface real errors is `flet build apk -vv` (double verbose).
- **OneDrive locks `build/site-packages/arm64-v8a/` on Windows.** During sync, serious_python cannot delete the directory before pip and silently exits with an empty APK. Pause OneDrive before local Android builds.
- **WASM (`flet build web`) fails on any Rust-based package.** `pydantic-core` (a supabase-py dependency) has no Emscripten wheel — always use Docker server mode for supabase apps.
- **Android wheel versions are constrained by `pypi.flet.dev`.** Confirmed working: `cryptography==43.0.1`, `cffi==1.17.1`, `yarl==1.11.1`. `multidict` and `propcache` have no Android wheels — exclude them entirely; supabase-py runs without them.
- **Do not run `pip install -r requirements.txt` on the CI host for Android.** serious_python bundles deps from `pyproject.toml`; host installs are unused and cause version-conflict errors. Install only `flet==<version>`.
- **Accept Android SDK licenses in CI** before `flet build`, or the NDK install step hangs.
- **GitHub free-tier artifact storage (500 MB) fills fast.** Publish binaries via `gh release create` (Release assets are exempt from the artifact quota) and add `continue-on-error: true` to uploads.

### Docker / web image

- **Never use `flet run --web` as the Dockerfile CMD.** Even in web mode it imports `flet_desktop`, which needs native GUI libs absent from slim images — the container crashes immediately. Use `python main.py` and configure web mode in code.
- **`docker/setup-buildx-action@v3` is required before `build-push-action` when using `cache-to: type=gha`** — otherwise the build errors on cache export.
- **GHCR image names must be lowercase.** `${{ github.repository }}` preserves case; reference the lowercase name explicitly in the deploy step.
- **`flet-web` must be in `requirements.txt`** — Dockerfile `RUN` steps that `import flet_web` fail at build time without it.

### Web layout and images

- **Constrain web content width with `View.horizontal_alignment` + a fixed-`width` container** — the only reliable approach. `ft.alignment.top_center` does not exist in 0.84; `expand=True` + `ft.Alignment` does not reliably centre scrollable views.
- **SVGs are not supported in `ft.Image` in Flet 0.84** — they render as the Flutter fish placeholder with no error. Always use PNGs.
- **Set `filter_quality=ft.FilterQuality.HIGH` on every `ft.Image`,** and match source size to display size (small source for small icons, large for large). See *Image quality* in `reference.md`.

### Local web dev (Windows)

- **`flet run --web` serves `http://0.0.0.0:PORT/`** — navigate to `http://localhost:PORT/` instead; use `--port 8550` for a predictable URL.
- **Flutter web caches aggressively** — `Ctrl+Shift+R` is often insufficient; use incognito or a different browser to test asset changes. Refresh local `flet_web` assets without a Docker rebuild using the script in `reference.md`.

---

## Process

Code templates for every step are in [`reference.md`](reference.md).

### Web — Docker server mode

1. **Confirm WASM is out** — any supabase-py app depends on `pydantic-core` (Rust); use Docker server mode.
2. **Write `main.py`** with the `FLET_HOST` web guard — see *main.py — FLET_HOST web guard*.
3. **Write the `Dockerfile`** — patches flet_web assets, runs `python main.py` — see *Dockerfile*.
4. **Write `build-web.yml`** — include `setup-buildx-action`; reference the lowercase GHCR name — see *build-web.yml*. For the deploy job, use `flet-aca-deploy`.

### Android — APK and AAB

5. **Verify `pyproject.toml`** — direct deps only, `[tool.flet.app] exclude` set, pinned crypto versions.
6. **Build locally** (Windows/OneDrive) using the pause-delete-rebuild procedure — see *Local Android build*.
7. **Smoke-test the APK** on a device via `adb install -r`.
8. **Write `build-android.yml`** — APK every push, AAB on `workflow_dispatch`, CLI-only host install — see *build-android.yml*. Add `install-apk.sh` (uninstall-before-install) — see *install-apk.sh*.

### iOS

9. **Require a paid Apple Developer account ($99/yr).** Without proper signing entitlements the app launches to a permanent black screen — Flutter loads but Python never starts. This is platform enforcement, not an app bug.
10. **Set `app.bundle_id`** in a single `[tool.flet.app]` section — see *iOS — pyproject.toml*.
11. **Write `build-ios.yml`** with the xcarchive → ad-hoc-signed `.ipa` packaging step — see *build-ios.yml*.
12. **Confirm packaging** — "Packaged Python app ✅" after ~30–40s is expected for iOS (unlike Android's 3–8 min).
13. **Diagnose a black screen** via device Analytics Data and the app-switcher preview — both black = signing issue, not code. Full steps in *Troubleshooting* in `reference.md`.

---

## Output format

Present the configured pipeline as:

1. **Platform coverage** — which targets were set up (Android / iOS / web) and why any were skipped
2. **Files created** — `Dockerfile`, the workflow YAMLs, `install-apk.sh`, `main.py` web guard, `pyproject.toml` changes (templates from `reference.md`)
3. **CI/CD summary** — triggers per workflow (push vs `workflow_dispatch`), artifact vs Release strategy
4. **Verification** — local build confirmed, on-device smoke test result, CI run status

---

## GitHub Actions free tier limits

- **Artifact storage: 500 MB total.** IPA (~80 MB) and APK (~50 MB) fill it fast; delete old runs (`gh run delete <id>`). A full quota fails the upload step only — not the build.
- **macOS runners cost 10× minutes** (a 15-min iOS build = 150 of 2,000 free minutes). Ubuntu is 1×.
- **Public repos have unlimited Actions minutes** — secrets stay protected regardless of visibility.

---

## Testing tiers

| Tier | Command | Time | Use for |
|------|---------|------|---------|
| Desktop | `flet run main.py` | Instant | All logic, Supabase, navigation, UI — 90% of dev |
| Web local | `flet run --web --port 8550 main.py` → `http://localhost:8550/` | Seconds | Web rendering, before every push |
| Android (CI) | push → `bash install-apk.sh` | ~12 min | Mobile-specific behaviour, official artifact |
| Android (local) | `flet build apk` + `adb install` | ~5 min | Frequent mobile testing (requires Flutter locally) |
| iOS | macOS + `flet build ipa` | N/A on Windows | Defer to App Store prep |

---

## Quality checklist

- [ ] `docker/setup-buildx-action@v3` added before `docker/login-action`
- [ ] Dockerfile CMD is `python main.py`, not `flet run --web`
- [ ] `ft.run()` used; `FLET_HOST` guards web params so Android is unaffected
- [ ] Android CI installs only `flet==<version>` on host — not `pip install -r requirements.txt`
- [ ] `flet-web==<version>` in `requirements.txt`
- [ ] AAB build/upload gated on `workflow_dispatch`
- [ ] `multidict`/`propcache` excluded from `requirements.txt`; `cryptography`/`cffi`/`yarl` pinned to arm64-v8a wheels
- [ ] All `ft.Image` controls set `filter_quality=ft.FilterQuality.HIGH`; no SVGs referenced
- [ ] `install-apk.sh` uses uninstall-before-install
- [ ] OneDrive paused and `build/.hash/package` deleted before any forced local Android rebuild
- [ ] iOS app metadata in one `[tool.flet.app]` section; paid Apple Developer account in place

---

## Avoid

- Passing `view=ft.AppView.WEB_BROWSER` unconditionally — crashes serious_python on Android; guard with `FLET_HOST`
- `pip install -r requirements.txt` on the CI host for Android — unused and causes version conflicts; install the CLI only
- Including `multidict`/`propcache` in `requirements.txt` for Android — no Android wheels exist
- `flet run --web` as Dockerfile CMD — `flet_desktop` is unavailable in slim images
- Omitting `flet-web` from `requirements.txt` — Dockerfile `import flet_web` steps fail at build time
- SVG images in `ft.Image`, or omitting `filter_quality=HIGH` — placeholder/blurry rendering
- Using `${{ github.repository }}` directly in image refs — mixed case breaks GHCR
- Building AAB on every push — gate to `workflow_dispatch`
- Trusting a sub-30-second `flet build apk` — pip was skipped; the APK will crash on device
- Building Android on Windows inside OneDrive without pausing sync
- `ft.app()`, `web_renderer="html"`, `ft.alignment.top_center` — removed/deprecated in current Flet
- Setting Azure Container Apps minimum replicas to 0 — Flet's WebSocket breaks on cold start (see `flet-aca-deploy`)
- AltStore / free Apple ID for iOS — the Python runtime won't initialise; a paid account is required
- Uploading `build/ipa/` as the artifact — includes the xcarchive; specify the `.ipa` path
- Changing app code to fix an iOS black screen when there are no crash logs — it is a signing issue

---

## Example usage

> "My Flet + Supabase app runs locally. Set up the full build pipeline — Docker web image to GHCR, Android APK on push with AAB on demand, and an iOS build — with GitHub Actions. The web image will deploy to Azure Container Apps. Flag anything that will silently crash on device."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
