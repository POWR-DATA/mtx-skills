---
name: flet-supabase-framework
description: Framework for a Flet + Supabase multi-platform Python app — correct project structure, dependency config, and integration patterns to avoid runtime failures on mobile
author: POWR-DATA
version: 1.0.0
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

## Guiding principles

- **pyproject.toml ≠ requirements.txt for Android builds.** Flet's Android packager (serious_python) reads `[project] dependencies` in `pyproject.toml` — your direct app dependencies only — and resolves transitive deps for Android arm64-v8a from Flet's custom wheel index (`pypi.flet.dev`). `requirements.txt` serves the host dev environment. Never put transitive deps in pyproject.toml or it will interfere with cross-compile resolution.
- **Exclude your dev environment from the Android bundle.** Always add `exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]` under `[tool.flet.app]`. Without this, serious_python may bundle Windows packages from the local venv into the APK instead of the cross-compiled arm64-v8a packages, causing runtime crashes on device.
- **Use `page.run_thread()` not raw threads.** Flet's `page.run_thread(fn)` is the correct way to run background work from a View. Raw `threading.Thread` does not reliably trigger UI repaints on Windows desktop — the UI appears frozen until the window regains focus.
- **Supabase client is a singleton.** Create the client once and return the cached instance from a module-level variable. Re-creating it on every request drops the auth session.
- **Auth state lives in the Supabase client, not in page state.** After sign-in, the session is held by the client object. Navigate by route change; never store user info on `page`.
- **Never block the main thread.** All Supabase API calls go in background threads via `page.run_thread()`. Call `page.update()` at the end of every background function to flush UI changes.
- **`did_mount` is the entry point for data loading.** Call `page.run_thread()` from `did_mount()`, not `__init__()`. The view must be mounted before any `page.update()` call is valid.
- **Pin cryptography and cffi to Android-compatible versions.** Only specific versions of these packages have pre-built Android arm64-v8a wheels on `pypi.flet.dev`. Use `cryptography==43.0.1` and `cffi==1.17.1`. Do not upgrade without first verifying wheel availability on the Flet custom index.
- **Do not put API keys in the client app.** Route LLM calls (Gemini, OpenAI, etc.) through Supabase Edge Functions. The app only holds the Supabase anon key, which is safe to expose; other service keys stay server-side.

## Process

1. Create the project directory structure:

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
     assets/               <- icon.png (1024x1024), splash.png (2048x2048)
     .github/
       workflows/
         build-web.yml
         build-android.yml
         build-ios.yml
   ```

2. Write `pyproject.toml` with only the direct application dependencies — no transitive deps, no pinned sub-packages:

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
   # Uncomment and fill in before first app store build:
   # app.name = "Your App"
   # app.bundle_id = "com.yourorg.yourapp"
   # app.version = "1.0.0"
   # app.build_number = 1

   [tool.flet.app]
   exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]
   ```

3. Write `requirements.txt` with ALL transitive dependencies pinned explicitly. After `pip install -e .` (or installing pyproject.toml deps), run `pip freeze` and annotate by group. The full set for a Flet + Supabase app is typically 40-60 packages. Critical section:

   ```
   # Core framework
   flet==0.84.0

   # Supabase and sub-packages (pin sub-packages to match main supabase version)
   supabase==2.25.1
   supabase-auth==2.25.1
   supabase-functions==2.25.1
   storage3==2.25.1
   postgrest==2.25.1
   realtime==2.25.1

   # Auth / crypto — Android arm64-v8a constrained versions (do not upgrade without
   # verifying wheel availability on pypi.flet.dev)
   PyJWT==2.12.1
   cryptography==43.0.1
   cffi==1.17.1
   pycparser==3.0

   # HTTP client stack
   httpx==0.28.1
   httpcore==1.0.9
   certifi==...
   # ... full transitive set — run pip freeze to get exact versions
   ```

4. Write the Supabase client singleton (`services/supabase_client.py`):

   ```python
   import os
   from dotenv import load_dotenv
   from supabase import create_client, Client

   load_dotenv()

   SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "")
   SUPABASE_KEY: str = (
       os.environ.get("SUPABASE_ANON_KEY")
       or os.environ.get("SUPABASE_KEY", "")
   )

   _client: Client | None = None

   def get_client() -> Client:
       global _client
       if _client is None:
           _client = create_client(SUPABASE_URL, SUPABASE_KEY)
       return _client
   ```

5. Write auth service (`services/auth.py`):

   ```python
   from services.supabase_client import get_client

   def sign_in(email: str, password: str):
       return get_client().auth.sign_in_with_password({"email": email, "password": password})

   def sign_up(email: str, password: str, **metadata):
       return get_client().auth.sign_up({
           "email": email,
           "password": password,
           "options": {"data": metadata},
       })

   def sign_out():
       get_client().auth.sign_out()

   def get_user():
       return get_client().auth.get_user()
   ```

6. Write `main.py` with the Flet routing pattern — route_change rebuilds the view stack on every navigation:

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
       ft.run(main)
   ```

7. Write each screen as a class inheriting `ft.View`. Build all controls in `__init__`, load remote data in `did_mount` via `page.run_thread()`:

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

8. Write `.env.example` (committed) and `.env` (gitignored):

   ```
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

9. Add `.gitignore` entries: `.env`, `.venv/`, `build/`, `__pycache__/`, `*.pyc`, `*.apk`, `*.aab`, `*.ipa`, `*.DS_Store`

10. Create the Supabase `profiles` table if it doesn't exist. Minimum schema:

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

    Add app-specific columns as needed. Insert a profile row on sign-up using a Supabase trigger or from the sign-up service call.

11. Verify the framework: run `flet run main.py` locally. Sign in, navigate between screens, confirm data loads. Do not proceed to mobile builds until this works.

## Output format

1. **Directory tree** — complete project structure with all files listed
2. **`pyproject.toml`** — complete file
3. **`requirements.txt`** — complete file with all transitive deps, annotated by group
4. **`services/supabase_client.py`** — complete file
5. **`services/auth.py`** — complete file
6. **`main.py`** — complete file with routing
7. **Each View class** — one complete file per screen
8. **`.env.example`** — complete file
9. **Supabase SQL** — profiles table creation (and any domain tables requested)
10. **Next step** — point to `flet-multiplatform-build` for build and CI setup

## Quality checklist

- [ ] `pyproject.toml` has 5-6 direct dependencies only, no transitive deps
- [ ] `[tool.flet.app] exclude` includes `.venv` and `build`
- [ ] `requirements.txt` has the full transitive dep tree with annotated groups
- [ ] `cryptography==43.0.1` and `cffi==1.17.1` (or explicitly verified newer versions)
- [ ] Supabase client is a module-level singleton — one instance, cached in `_client`
- [ ] All Supabase calls are in background functions passed to `page.run_thread()`
- [ ] `page.update()` is called at the end of every background thread function
- [ ] Data loading happens in `did_mount()`, not `__init__()`
- [ ] `.env` is in `.gitignore`; `.env.example` is committed with placeholder values
- [ ] No LLM API keys (Gemini, OpenAI, etc.) in the client app — routed via Edge Functions
- [ ] App runs locally with `flet run main.py` before any mobile build is attempted

## Avoid

- Putting transitive dependencies in `pyproject.toml` — that file is for direct deps only; adding transitive deps here interferes with Flet's Android arm64-v8a pip resolution
- Upgrading `cryptography` or `cffi` without first verifying the target version has an arm64-v8a wheel on `pypi.flet.dev`
- Using `threading.Thread(target=fn).start()` directly — use `page.run_thread(fn)` so Flet manages the thread lifecycle and repaints correctly on all platforms
- Calling `page.update()` from `__init__` — the view is not yet mounted; defer to `did_mount`
- Storing user session data on the `page` object — the Supabase auth client holds the session; read it via `get_client().auth.get_user()`
- Putting LLM API keys (Gemini, OpenAI, Anthropic) in the mobile app — always route AI calls server-side through Supabase Edge Functions
- Committing `.env` — always gitignore it and ship `.env.example` instead

## Example usage

> "Scaffold a Flet + Supabase app called GardenTrack targeting Android and web. Users log in then see a list of their plants. Supabase tables: plants (id, user_id, name, species, last_watered date, watering_interval_days int). Show me the full project structure and all files."
