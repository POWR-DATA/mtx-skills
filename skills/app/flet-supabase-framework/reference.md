# Flet + Supabase Framework — Reference Templates

Load-on-demand templates for the steps in [`SKILL.md`](SKILL.md). These are **illustrative excerpts** — they show the load-bearing structure, not every line. Fill in placeholders (`<...>`) and extend as your app requires.

---

## Project structure

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
    supabase_client.py
    auth.py
    <domain>.py         <- one service module per data domain
  views/
    login.py
    home.py
  assets/
    icon.png            <- 1024x1024px transparent PNG (app icon + UI)
    splash.png          <- 2048x2048px (separate file, mobile startup splash)
  infra/
    setup-cloud.sh
  .github/workflows/    <- build-web.yml, build-android.yml, build-ios.yml
```

## pyproject.toml

Direct dependencies only — no transitive deps. The `exclude` keeps the dev venv out of the Android bundle.

```toml
[project]
name = "your-app-name"
requires-python = ">=3.11"
dependencies = [
    "flet==0.84.0",
    "supabase==2.25.1",
    "httpx==0.28.1",
    "python-dotenv==1.2.2",
    # ...
]

[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.backends._legacy:_Backend"

[tool.flet]
app.icon = "assets/icon.png"
app.splash = "assets/splash.png"
# app.bundle_id = "com.yourorg.yourapp"   # uncomment before first store build

[tool.flet.app]
exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]
```

## requirements.txt

Full transitive tree from `pip freeze`, annotated by group. The load-bearing entries:

```
flet==0.84.0
flet-web==0.84.0   # REQUIRED — used in Dockerfile RUN steps to patch web assets
cryptography==43.0.1   # Android arm64-v8a constrained version
cffi==1.17.1           # Android arm64-v8a constrained version
# ... full transitive set (supabase, httpx, certifi, ...) from pip freeze
```

## Supabase client

Lazy singleton with embedded defaults so the app works on device where `.env` does not exist.

```python
# services/supabase_client.py
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

# .env overrides these (local dev). On mobile .env doesn't exist — defaults are used.
_DEFAULT_URL = "https://<your-project-ref>.supabase.co"
_DEFAULT_KEY = "<your-anon-key>"

SUPABASE_URL = os.environ.get("SUPABASE_URL") or _DEFAULT_URL
SUPABASE_KEY = os.environ.get("SUPABASE_ANON_KEY") or _DEFAULT_KEY

_client: Client | None = None

def get_client() -> Client:
    global _client
    if _client is None:
        _client = create_client(SUPABASE_URL, SUPABASE_KEY)  # created once, cached
    return _client
```

## Auth service

Thin wrappers over `get_client()` — no state stored in this module.

```python
# services/auth.py
from services.supabase_client import get_client

def sign_in(email, password):
    return get_client().auth.sign_in_with_password({"email": email, "password": password})

# ... sign_up / sign_out / get_user follow the same delegate-to-client pattern
```

## main.py and navigation

One persistent `ft.View`; swap its controls via a **synchronous** `navigate(route)` callback (handlers are sync; `page.go()` is async in 0.84).

```python
# main.py
import flet as ft
from views.home import HomeView
from views.login import LoginView

def main(page: ft.Page):
    main_view = ft.View(route="/", controls=[])
    page.views.append(main_view)

    def navigate(route: str):
        content = HomeView(navigate=navigate) if route == "/home" else LoginView(navigate=navigate)
        main_view.controls = [content]
        main_view.appbar = content.appbar
        page.update()

    navigate("/")

if __name__ == "__main__":
    host = os.environ.get("FLET_HOST")
    if host:  # web/container
        ft.run(main, host=host, port=8550, view=ft.AppView.WEB_BROWSER,
               web_renderer=ft.WebRenderer.CANVAS_KIT)
    else:
        ft.run(main)
```

## Screen view

`ft.Column` subclass exposing `self.appbar`; load data in `did_mount()` (not `__init__`) via `page.run_thread()`.

```python
import flet as ft
from services.supabase_client import get_client

class HomeView(ft.Column):
    def __init__(self, navigate):
        self._navigate = navigate            # required if any method calls navigate
        self._status = ft.Text("")
        self.appbar = ft.AppBar(title=ft.Text("Home"))
        super().__init__(controls=[self._status])

    def did_mount(self):
        self.page.run_thread(self._load_data)   # mounted → page.update() now valid

    def _load_data(self):
        try:
            result = get_client().table("<your_table>").select("*").execute()
            self._status.value = str(result.data)
        except Exception as ex:
            self._status.value = str(ex)
        self.page.update()                   # always flush at the end of a bg thread
```

For a dynamic AppBar within one screen, pass a `set_appbar` callback from `navigate` and build each bar with a factory (`_make_appbar()`) — never reuse one `ft.AppBar` instance or index `page.views`.

## Environment files

```
# .env.example (committed)        # .env (gitignored) holds the real values
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

`.gitignore` entries: `.env`, `.venv/`, `build/`, `__pycache__/`, `*.pyc`, `*.apk`, `*.aab`, `*.ipa`

## Supabase profiles table

```sql
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "Users can read own profile"  on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
-- add app-specific columns as needed; insert a row on sign-up via trigger or service call
```
