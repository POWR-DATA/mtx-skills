---
name: flet-supabase-framework
description: Framework for a Flet + Supabase multi-platform Python app — correct project structure, dependency config, integration patterns, and hard-won lessons from a full build cycle
author: POWR-DATA
version: 2.4.0
license: MIT
---

# Flet + Supabase App Framework

## Purpose

Scaffold a new Python cross-platform app using Flet (Python/Flutter UI framework) and Supabase (auth + database + edge functions backend) with the correct project structure, pyproject.toml configuration, dependency pinning, and integration patterns from the start — avoiding the class of build failures and runtime crashes that only emerge on device if set up incorrectly.

## When to use

When a developer wants to build a Python app that targets Android, iOS, and web from a single codebase, backed by Supabase for auth and data. Apply at project creation time, before any platform builds are attempted. The output of this skill feeds directly into `flet-multiplatform-build`.

## Inputs expected

- App name and intended bundle ID (or placeholder if not yet registered with Google Play / App Store)
- Target platforms: Android, iOS, Web, or a subset
- Supabase project URL and anon key (from Supabase dashboard → Project Settings → API)
- Rough list of Supabase tables or Edge Functions planned
- List of app screens/views planned (even just names)

---

## Guiding principles

- **pyproject.toml ≠ requirements.txt for Android builds.** Flet's Android packager (serious_python) reads `[project] dependencies` in `pyproject.toml` — your direct app dependencies only — and resolves transitive deps for Android arm64-v8a from Flet's custom wheel index (`pypi.flet.dev`). `requirements.txt` serves the host dev environment. Never put transitive deps in pyproject.toml.
- **Exclude your dev environment from the Android bundle.** Always add `exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]` under `[tool.flet.app]`. Without this, serious_python may bundle Windows packages from the local venv into the APK instead of cross-compiled arm64-v8a packages.
- **Use `page.run_thread()` not raw threads.** `page.run_thread(fn)` routes the thread through Flet's event loop, ensuring `page.update()` calls from background threads reach Flutter. With raw `threading.Thread`, calls to `page.update()` can silently drop on some targets — the update appears to succeed but the UI does not repaint.
- **Supabase client is a singleton.** Create the client once and return the cached instance from a module-level variable. Re-creating it on every request drops the auth session.
- **Auth state lives in the Supabase client, not in page state.** After sign-in, the session is held by the client object. Navigate by route change; never store user info on `page`.
- **Never block the main thread.** All Supabase API calls go in background threads via `page.run_thread()`. Call `page.update()` at the end of every background function to flush UI changes.
- **`did_mount` is the entry point for data loading.** Call `page.run_thread()` from `did_mount()`, not `__init__()`. The view must be mounted before any `page.update()` call is valid.
- **Pin cryptography and cffi to Android-compatible versions.** Only specific versions of these packages have pre-built Android arm64-v8a wheels on `pypi.flet.dev`. Use `cryptography==43.0.1` and `cffi==1.17.1`. Do not upgrade without first verifying wheel availability on the Flet custom index.
- **Do not put LLM API keys in the client app.** Route LLM calls (Gemini, OpenAI, Anthropic, etc.) through Supabase Edge Functions. The app only holds the Supabase anon key, which is safe to expose — it is protected by Row Level Security, not by secrecy.
- **`.env` does not exist at runtime on mobile.** `load_dotenv()` reads from disk — on Android and iOS there is no `.env` file in the app bundle. Always embed Supabase URL and anon key as code-level defaults so the app works on device, while still allowing `.env` to override for local dev. Use a lazy `get_client()` singleton — not a module-level `create_client()` call — to avoid import-time network activity that can crash on mobile before the runtime is fully ready.
- **Use a single transparent PNG for all icon placements.** A transparent PNG (RGBA mode, alpha=0 in background areas) blends against any background automatically. Creating separate icon variants per background colour requires the background RGB to match exactly — even a 1-point difference shows as a rectangular border.
- **Script all infrastructure — never click through the portal.** Keep an `infra/setup-azure.sh` (or equivalent) in the repo that provisions everything from scratch. Apply the same discipline to Supabase: table creation and RLS policies belong in SQL migration files, not just dashboard clicks.
- **Never reuse a single `ft.AppBar` instance — use a factory method.** Flet cannot reattach the same `ft.AppBar` object to a View after it has been detached. Reusing `self._appbar` causes `'AppBar' object has no attribute 'appbar'` on the second toggle. Fix: use a factory method (`_make_appbar()`) that returns a fresh `ft.AppBar` instance each time it is needed.
- **Pass a `set_appbar(appbar)` callback for dynamic AppBar changes within a view.** To show or hide an AppBar dynamically within a screen (e.g. toggling between sign-in and sign-up modes), pass a `set_appbar` callback from the `navigate` closure in `main.py` into the view constructor. Never access `page.views[0].appbar` directly — indexing into `page.views` is unreliable on Flet desktop.
- **Always assign `self._navigate = navigate` in `__init__` if any method in that view calls navigate.** Omitting this assignment causes `AttributeError: '<ViewName>' object has no attribute '_navigate'` at runtime when the handler fires — the error does not surface at construction time.

---

## Flet 0.84 version notes

- **`ft.ImageFit` does not exist in Flet 0.84.0.** The `fit` parameter on `ft.Image` must be omitted — passing it causes `AttributeError: module 'flet' has no attribute 'ImageFit'`.
- **`ft.ElevatedButton` is deprecated from 0.80.0** — use `ft.Button` in new code.
- **`ft.padding.symmetric()` is deprecated from 0.80.0** — use `ft.Padding.symmetric()`.
- **`page.launch_url()` is async in 0.84.0** — handlers that call it must be `async def`.
- **`ft.app()` is deprecated from 0.80.0** — use `ft.run()`.

---

## Process

Generate every project file from the templates in [`reference.md`](reference.md) — it holds the load-bearing code for each step below.

1. **Create the directory structure** — see *Project structure* in `reference.md`.
2. **Write `pyproject.toml`** — direct dependencies only (no transitive deps); add `[tool.flet.app] exclude` to keep the dev venv out of the Android bundle. See *pyproject.toml*.
3. **Write `requirements.txt`** — the full transitive tree from `pip freeze`, including `flet-web` and the pinned `cryptography`/`cffi` versions. See *requirements.txt*.
4. **Write `services/supabase_client.py`** — a lazy `get_client()` singleton with embedded URL/key defaults so the app works on device without `.env`. See *Supabase client*.
5. **Write `services/auth.py`** — thin `sign_in`/`sign_up`/`sign_out`/`get_user` wrappers over `get_client()`; store no state here. See *Auth service*.
6. **Write `main.py`** — one persistent `ft.View`, controls swapped via a synchronous `navigate(route)` callback (not `page.controls`-only, not view-per-route). See *main.py and navigation*.
7. **Write each screen as an `ft.Column` subclass** — expose `self.appbar`; load data in `did_mount()` via `page.run_thread()`, ending every background function with `page.update()`. See *Screen view*.
8. **Write `.env.example` (committed) and `.env` (gitignored)** — see *Environment files*.
9. **Add `.gitignore` entries** — `.env`, `.venv/`, `build/`, `__pycache__/`, `*.pyc`, `*.apk`, `*.aab`, `*.ipa`.
10. **Create the Supabase `profiles` table** with RLS policies — see *Supabase profiles table*.
11. **Verify** — run `flet run main.py` locally; sign in, navigate, confirm data loads before attempting any mobile build.

---

## Output format

The skill produces a complete, runnable project. Present the result as:

1. **Project structure** — the directory tree created
2. **Generated files** — each file from the Process in order (`pyproject.toml`, `requirements.txt`, `services/`, `main.py`, views, `.env.example`, `.gitignore`), drawn from the templates in `reference.md`
3. **Supabase setup** — the `profiles` table SQL and RLS policies
4. **Verification result** — confirmation that `flet run main.py` runs locally, sign-in works, and navigation and data loading succeed

---

## Testing workflow

Use the fastest tier that answers your question — never push to trigger a CI build just to test a local change:

| Tier | Command | Time | Use for |
|------|---------|------|---------|
| Desktop | `flet run main.py` | Instant | All logic, Supabase, navigation, UI — 90% of dev |
| Web local | `flet run --web --port 8550 main.py` → http://localhost:8550 | Seconds | Web layout, before every push |
| Android (CI) | push → `bash install-apk.sh` | ~12 min | Mobile-specific, official artifact |
| Android (local) | `flet build apk` + `adb install` | ~5 min | Frequent mobile testing (requires local Flutter) |
| iOS | macOS only | N/A on Windows | Defer to App Store prep |

---

## Quality checklist

- [ ] `pyproject.toml` has 5-6 direct dependencies only, no transitive deps
- [ ] `[tool.flet.app] exclude` includes `.venv` and `build`
- [ ] `requirements.txt` has the full transitive dep tree with annotated groups
- [ ] `flet-web==<version>` in `requirements.txt` (same version as `flet`)
- [ ] `cryptography==43.0.1` and `cffi==1.17.1` (or explicitly verified newer versions)
- [ ] `supabase_client.py` has embedded defaults for URL and anon key — not relying solely on `.env`
- [ ] Supabase client is a module-level singleton — one instance, cached in `_client`
- [ ] All Supabase calls are in background functions passed to `page.run_thread()` — not raw `threading.Thread`
- [ ] `page.update()` is called at the end of every background thread function
- [ ] Data loading happens in `did_mount()`, not `__init__()`
- [ ] Navigation uses a single persistent `ft.View` with controls swapped via `navigate(route)` callback — not view-per-route or `page.controls`-only
- [ ] Screen views are `ft.Column` subclasses with `self.appbar` exposed — not `ft.View` subclasses
- [ ] `navigate(route)` is a synchronous callback — not `await page.go(route)` from synchronous handlers
- [ ] `.env` is in `.gitignore`; `.env.example` is committed with placeholder values
- [ ] No LLM API keys in the client app — routed via Edge Functions
- [ ] App icon is a transparent PNG — 1024×1024px, no coloured background
- [ ] Splash screen is 2048×2048px — separate file from icon
- [ ] Infrastructure setup is scripted in `infra/` — not portal-click-only
- [ ] Supabase schema is in SQL migration files, not just dashboard clicks
- [ ] App runs locally with `flet run main.py` before any mobile build is attempted
- [ ] `self._navigate = navigate` is assigned in `__init__` for every view that calls navigate in any of its methods
- [ ] Views that need to change the AppBar dynamically receive a `set_appbar` callback — not direct access to `page.views`

---

## Avoid

- Putting transitive dependencies in `pyproject.toml` — direct deps only; transitive deps here break Android arm64-v8a pip resolution
- Upgrading `cryptography` or `cffi` without first verifying the target version has an arm64-v8a wheel on `pypi.flet.dev`
- Using `threading.Thread(target=fn).start()` directly — `page.update()` from a raw thread can silently drop on some targets; use `page.run_thread(fn)`
- Calling `page.update()` from `__init__` — the view is not yet mounted; defer to `did_mount`
- Storing user session data on the `page` object — the Supabase auth client holds the session
- Putting LLM API keys in the mobile app — always route AI calls server-side through Supabase Edge Functions
- Committing `.env` — always gitignore it and ship `.env.example` instead
- Relying on `.env` for runtime config on mobile — the file is not bundled; embed defaults in code
- Using a module-level `create_client()` call — triggers import-time network activity that can crash on mobile before the runtime is fully ready; use a lazy `get_client()` singleton
- Using view-per-route navigation (multiple entries in `page.views`) — causes issues on Android; use a single persistent `ft.View` with controls swapped via `navigate(route)` callback
- Using only `page.controls` (no `page.views`) — renders nothing on Android; Flutter's Navigator requires at least one `ft.View` in `page.views`
- Using `await page.go(route)` in synchronous event handlers — `page.go()` is async in Flet 0.84 but handlers are sync; pass a synchronous `navigate(route)` callback to each view instead
- Writing screen views as `ft.View` subclasses — use `ft.Column` subclasses with an `appbar` instance attribute so `navigate()` in main can assign it to the persistent view's appbar
- Creating separate icon files per background colour — use transparent PNG instead
- Clicking through Azure portal or Supabase dashboard for setup steps — script everything in `infra/`
- Using `fit=ft.ImageFit.CONTAIN` in Flet 0.84.0 — the attribute doesn't exist in this version
- Using `ft.app()` — deprecated since Flet 0.80; use `ft.run()`
- Pushing to `main` just to test a change — use desktop or web local tier first
- Reusing the same `ft.AppBar` instance across multiple show/hide cycles — use a factory method that returns a fresh instance each time
- Accessing `page.views[0].appbar` directly to change the AppBar dynamically — indexing into `page.views` is unreliable on Flet desktop; pass a `set_appbar` callback from the navigate closure instead
- Omitting `self._navigate = navigate` in a view's `__init__` when any method in that class calls navigate — the `AttributeError` only surfaces at runtime when the handler fires, not at construction time

---

## Example usage

> "Scaffold a Flet + Supabase app called GardenTrack targeting Android and web. Users log in then see a list of their plants. Supabase tables: plants (id, user_id, name, species, last_watered date, watering_interval_days int). Show me the full project structure and all files."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
