---
name: flet-supabase-framework
description: Framework for a Flet + Supabase multi-platform Python app — correct project structure, dependency config, integration patterns, and hard-won lessons from a full build cycle
author: POWR-DATA
version: 2.1.0
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
- **Use `page.run_thread()` not raw threads.** Flet's `page.run_thread(fn)` is the correct way to run background work from a View. Raw `threading.Thread` does not reliably trigger UI repaints on Windows desktop.
- **Supabase client is a singleton.** Create the client once and return the cached instance from a module-level variable. Re-creating it on every request drops the auth session.
- **Auth state lives in the Supabase client, not in page state.** After sign-in, the session is held by the client object. Navigate by route change; never store user info on `page`.
- **Never block the main thread.** All Supabase API calls go in background threads via `page.run_thread()`. Call `page.update()` at the end of every background function to flush UI changes.
- **`did_mount` is the entry point for data loading.** Call `page.run_thread()` from `did_mount()`, not `__init__()`. The view must be mounted before any `page.update()` call is valid.
- **Pin cryptography and cffi to Android-compatible versions.** Only specific versions of these packages have pre-built Android arm64-v8a wheels on `pypi.flet.dev`. Use `cryptography==43.0.1` and `cffi==1.17.1`. Do not upgrade without first verifying wheel availability on the Flet custom index.
- **Do not put LLM API keys in the client app.** Route LLM calls (Gemini, OpenAI, Anthropic, etc.) through Supabase Edge Functions. The app only holds the Supabase anon key, which is safe to expose — it is protected by Row Level Security, not by secrecy.
- **`.env` does not exist at runtime on mobile.** `load_dotenv()` reads from disk — on Android and iOS there is no `.env` file in the app bundle. Always embed Supabase URL and anon key as code-level defaults so the app works on device, while still allowing `.env` to override for local dev.
- **Use a single transparent PNG for all icon placements.** A transparent PNG (RGBA mode, alpha=0 in background areas) blends against any background automatically. Creating separate icon variants per background colour requires the background RGB to match exactly — even a 1-point difference shows as a rectangular border.
- **Script all infrastructure — never click through the portal.** Keep an `infra/setup-azure.sh` (or equivalent) in the repo that provisions everything from scratch. Apply the same discipline to Supabase: table creation and RLS policies belong in SQL migration files, not just dashboard clicks.

---

## Flet 0.84 version notes

- **`ft.ImageFit` does not exist in Flet 0.84.0.** The `fit` parameter on `ft.Image` must be omitted — passing it causes `AttributeError: module 'flet' has no attribute 'ImageFit'`.
- **`ft.ElevatedButton` is deprecated from 0.80.0** — use `ft.Button` in new code.
- **`ft.padding.symmetric()` is deprecated from 0.80.0** — use `ft.Padding.symmetric()`.
- **`page.launch_url()` is async in 0.84.0** — handlers that call it must be `async def`.
- **`ft.app()` is deprecated from 0.80.0** — use `ft.run()`.

---

## Process

### 1. Create the project directory structure

```
your-app/
  main.py
  pyproject.toml
  requirements.txt
  .env                  <- gitignored, holds real keys
  .env.example          <- committed, holds placeholder keys
  .gitignore
  Dockerfile            <- for web deployment (see flet-multiplatform-build)
  services/
    __init__.py
    supabase_client.py
    auth.py
    [domain].py         <- one service module per data domain
  views/
    login.py
    home.py
    support.py          <- or other screens
  assets/
    icon.png            <- 1024x1024px transparent PNG (app icon + UI)
    splash.png          <- 2048x2048px (separate file, mobile startup splash)
  infra/
    setup-azure.sh      <- or setup-cloud.sh for your chosen host
  .github/
    workflows/
      build-web.yml
      build-android.yml
      build-ios.yml
```

### 2. Write pyproject.toml

Direct dependencies only — no transitive deps, no pinned sub-packages:

```toml
[project]
name = "your-app-name"
version = "1.0.0"
description = "Short app description"
requires-python = ">=3.11"
dependencies = [
    "flet==0.84.0",
    "supabase==2.25.1",
    "httpx==0.28.1",
    "python-dotenv==1.2.2",
    "tzdata==2026.2",
]

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.backends._legacy:_Backend"

[tool.flet]
app.icon = "assets/icon.png"
app.splash = "assets/splash.png"
# Uncomment and fill in before first app store build:
# app.name = "Your App"
# app.bundle_id = "com.yourorg.yourapp"
# app.version = "1.0.0"
# app.build_number = 1

[tool.flet.app]
exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]
```

### 3. Write requirements.txt

All transitive dependencies pinned explicitly. After `pip install -e .`, run `pip freeze` and annotate by group. Always include `flet-web` (required for Dockerfile build steps) and the constrained crypto packages:

```
# Core framework
flet==0.84.0
flet-web==0.84.0   # REQUIRED — used in Dockerfile RUN steps to patch web assets

# Supabase + sub-packages (supabase, supabase-auth, storage3, postgrest, realtime, ...)
# Auth / crypto — Android arm64-v8a constrained versions
cryptography==43.0.1
cffi==1.17.1
# HTTP client stack (httpx, httpcore, certifi, ...)
# ... full transitive set from pip freeze
```

### 4. Write services/supabase_client.py (mobile-safe)

```python
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

# .env overrides these defaults (local dev). On mobile .env doesn't exist — defaults are used.
_DEFAULT_URL = "https://your-ref.supabase.co"
_DEFAULT_KEY = "sb_publishable_your-anon-key"

SUPABASE_URL: str = os.environ.get("SUPABASE_URL") or _DEFAULT_URL
SUPABASE_KEY: str = (
    os.environ.get("SUPABASE_ANON_KEY")
    or os.environ.get("SUPABASE_KEY")
    or _DEFAULT_KEY
)

_client: Client | None = None

def get_client() -> Client:
    global _client
    if _client is None:
        _client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return _client
```

### 5. Write services/auth.py

Thin wrappers over the Supabase client — `sign_in`, `sign_up`, `sign_out`, `get_user`. Each function calls `get_client()` and delegates directly to `client.auth`. No state is stored in this module.

### 6. Write main.py

```python
import flet as ft
from views.login import LoginView
from views.home import HomeView

def main(page: ft.Page):
    page.title = "Your App"
    page.theme_mode = ft.ThemeMode.DARK

    def route_change(e):
        page.views.clear()
        if page.route == "/home":
            page.views.append(HomeView(page))
        # add elif branches for each route
        else:
            page.views.append(LoginView(page))
        page.update()

    def view_pop(e):
        page.views.pop()
        page.go(page.views[-1].route)

    page.on_route_change = route_change
    page.on_view_pop = view_pop
    route_change(None)

if __name__ == "__main__":
    import os
    host = os.environ.get("FLET_HOST", "localhost")
    ft.run(main, host=host, port=8550, view=ft.AppView.WEB_BROWSER,
           web_renderer=ft.WebRenderer.CANVAS_KIT)
```

### 7. Write each screen as a ft.View subclass

Build all controls in `__init__`, load remote data in `did_mount` via `page.run_thread()`:

```python
import flet as ft
from services.supabase_client import get_client
from services.auth import get_user

class HomeView(ft.View):
    def __init__(self, page: ft.Page):
        self._status = ft.Text("")
        super().__init__(
            route="/home",
            controls=[self._status],
        )

    def did_mount(self):
        self.page.run_thread(self._load_data)

    def _load_data(self):
        try:
            client = get_client()
            user_id = get_user().user.id
            result = (
                client.table("your_table")
                .select("*")
                .eq("id", user_id)
                .execute()
            )
            self._status.value = str(result.data)
        except Exception as ex:
            self._status.value = str(ex)
        self.page.update()  # always call at the end of every background thread
```

### 8. Write .env.example (committed) and .env (gitignored)

```
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 9. Add .gitignore entries

`.env`, `.venv/`, `build/`, `__pycache__/`, `*.pyc`, `*.apk`, `*.aab`, `*.ipa`, `*.DS_Store`

### 10. Create the Supabase profiles table

```sql
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can read own profile"
  on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);
```

Add app-specific columns as needed. Insert a profile row on sign-up via a Supabase trigger or from the sign-up service call.

### 11. Verify the framework

Run `flet run main.py` locally. Sign in, navigate between screens, confirm data loads. Do not proceed to mobile builds until this works.

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
- [ ] All Supabase calls are in background functions passed to `page.run_thread()`
- [ ] `page.update()` is called at the end of every background thread function
- [ ] Data loading happens in `did_mount()`, not `__init__()`
- [ ] `.env` is in `.gitignore`; `.env.example` is committed with placeholder values
- [ ] No LLM API keys in the client app — routed via Edge Functions
- [ ] App icon is a transparent PNG — 1024×1024px, no coloured background
- [ ] Splash screen is 2048×2048px — separate file from icon
- [ ] Infrastructure setup is scripted in `infra/` — not portal-click-only
- [ ] Supabase schema is in SQL migration files, not just dashboard clicks
- [ ] App runs locally with `flet run main.py` before any mobile build is attempted

---

## Avoid

- Putting transitive dependencies in `pyproject.toml` — direct deps only; transitive deps here break Android arm64-v8a pip resolution
- Upgrading `cryptography` or `cffi` without first verifying the target version has an arm64-v8a wheel on `pypi.flet.dev`
- Using `threading.Thread(target=fn).start()` directly — use `page.run_thread(fn)`
- Calling `page.update()` from `__init__` — the view is not yet mounted; defer to `did_mount`
- Storing user session data on the `page` object — the Supabase auth client holds the session
- Putting LLM API keys in the mobile app — always route AI calls server-side through Supabase Edge Functions
- Committing `.env` — always gitignore it and ship `.env.example` instead
- Relying on `.env` for runtime config on mobile — the file is not bundled; embed defaults in code
- Creating separate icon files per background colour — use transparent PNG instead
- Clicking through Azure portal or Supabase dashboard for setup steps — script everything in `infra/`
- Using `fit=ft.ImageFit.CONTAIN` in Flet 0.84.0 — the attribute doesn't exist in this version
- Using `ft.app()` — deprecated since Flet 0.80; use `ft.run()`
- Pushing to `main` just to test a change — use desktop or web local tier first

---

## Example usage

> "Scaffold a Flet + Supabase app called GardenTrack targeting Android and web. Users log in then see a list of their plants. Supabase tables: plants (id, user_id, name, species, last_watered date, watering_interval_days int). Show me the full project structure and all files."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
