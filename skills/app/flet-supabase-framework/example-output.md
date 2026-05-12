# Example Output

## Project structure

```
gardentrack/
  main.py
  pyproject.toml
  requirements.txt
  .env                  <- gitignored, holds real keys
  .env.example          <- committed, placeholder keys
  .gitignore
  Dockerfile            <- for web deployment (see flet-multiplatform-build)
  services/
    __init__.py
    supabase_client.py
    auth.py
    plants.py
  views/
    login.py
    home.py
    add_plant.py
  assets/
    icon.png            <- 1024x1024px transparent PNG
    splash.png          <- 2048x2048px separate file
  infra/
    setup-azure.sh
    schema.sql
  .github/
    workflows/
      build-web.yml
      build-android.yml
```

---

## pyproject.toml

```toml
[project]
name = "gardentrack"
version = "1.0.0"
description = "Track your plants and watering schedule"
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
# app.name = "GardenTrack"
# app.bundle_id = "com.myorg.gardentrack"
# app.version = "1.0.0"
# app.build_number = 1

[tool.flet.app]
exclude = [".venv", "build", ".git", ".github", "__pycache__", "*.pyc"]
```

---

## services/supabase_client.py

```python
import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

_DEFAULT_URL = "https://abcdefgh.supabase.co"
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

`.env` overrides the defaults locally. On Android/iOS `.env` is not bundled — the hardcoded defaults are used, which is safe for the Supabase anon key (protected by Row Level Security, not by secrecy).

---

## services/plants.py

```python
from services.supabase_client import get_client
from services.auth import get_user

def get_plants() -> list[dict]:
    user_id = get_user().user.id
    result = (
        get_client().table("plants")
        .select("*")
        .eq("user_id", user_id)
        .order("name")
        .execute()
    )
    return result.data

def add_plant(name: str, species: str, watering_interval_days: int) -> dict:
    user_id = get_user().user.id
    result = (
        get_client().table("plants")
        .insert({
            "user_id": user_id,
            "name": name,
            "species": species,
            "watering_interval_days": watering_interval_days,
        })
        .execute()
    )
    return result.data[0]
```

---

## views/home.py

```python
import flet as ft
from services.plants import get_plants

class HomeView(ft.View):
    def __init__(self, page: ft.Page):
        self._plant_list = ft.Column([])
        self._status = ft.Text("")
        super().__init__(
            route="/home",
            controls=[
                ft.AppBar(title=ft.Text("GardenTrack")),
                self._status,
                self._plant_list,
                ft.FloatingActionButton(
                    icon=ft.Icons.ADD,
                    on_click=lambda _: page.go("/add"),
                ),
            ],
        )

    def did_mount(self):
        self.page.run_thread(self._load_plants)

    def _load_plants(self):
        try:
            plants = get_plants()
            self._plant_list.controls = [
                ft.ListTile(
                    title=ft.Text(p["name"]),
                    subtitle=ft.Text(p["species"]),
                )
                for p in plants
            ]
        except Exception as ex:
            self._status.value = str(ex)
        self.page.update()
```

---

## main.py

```python
import flet as ft
from views.login import LoginView
from views.home import HomeView
from views.add_plant import AddPlantView

def main(page: ft.Page):
    page.title = "GardenTrack"
    page.theme_mode = ft.ThemeMode.DARK

    def route_change(e):
        page.views.clear()
        if page.route == "/home":
            page.views.append(HomeView(page))
        elif page.route == "/add":
            page.views.append(AddPlantView(page))
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

---

## infra/schema.sql

```sql
create table public.plants (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  species text,
  last_watered date,
  watering_interval_days int,
  created_at timestamptz default now()
);

alter table public.plants enable row level security;

create policy "Users can read own plants"
  on public.plants for select using (auth.uid() = user_id);

create policy "Users can insert own plants"
  on public.plants for insert with check (auth.uid() = user_id);

create policy "Users can update own plants"
  on public.plants for update using (auth.uid() = user_id);

create policy "Users can delete own plants"
  on public.plants for delete using (auth.uid() = user_id);
```

---

## Notes

- All Supabase calls are in background functions passed to `page.run_thread()` — never block the main thread
- `page.update()` is called at the end of every background thread function
- Data loading happens in `did_mount()`, not `__init__()` — the view must be mounted before `page.update()` is valid
- The Supabase client is a module-level singleton — re-creating it on every call drops the auth session

---

## Next recommended step

Run `flet run main.py` locally. Sign in, navigate to the plant list, confirm data loads from Supabase. Once this works, apply `flet-multiplatform-build` to set up the Android and web CI/CD pipelines.
