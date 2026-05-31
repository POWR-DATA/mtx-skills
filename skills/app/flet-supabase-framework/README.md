# Flet + Supabase App Framework

Scaffold a new Python cross-platform app using Flet and Supabase from the start — with the correct project structure, dependency configuration, and integration patterns that prevent the class of build failures that only appear on device if set up incorrectly.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | The skill definition |
| `reference.md` | Code templates for each Process step (loaded on demand) |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## What this skill covers

- Full project directory structure for a Flet + Supabase app
- `pyproject.toml` vs `requirements.txt` — what goes where and why it matters for Android builds
- Supabase singleton client with mobile-safe credential defaults (`.env` does not exist at runtime on device)
- Background thread pattern using `page.run_thread()` for all Supabase calls
- Auth flow and session management without storing state on the page object
- Flet 0.84 version-specific gotchas (`ft.ImageFit`, `ft.ElevatedButton`, `ft.app()` deprecations)
- Infrastructure scripting discipline — `infra/` scripts instead of portal clicks

## Prerequisites

- App name and intended bundle ID (placeholder is fine if not yet registered)
- Supabase project with URL and anon key
- Target platforms (Android, iOS, Web, or a subset)
- Rough list of planned screens and Supabase tables

## Use this skill first

This is the starting point for a Flet app. Once the framework is in place and running with `flet run main.py`, use `flet-multiplatform-build` to set up CI/CD for Android and web.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
