# Example Input

## User request

> Scaffold a Flet + Supabase app called GardenTrack targeting Android and web. Users log in and then see a list of their plants. Supabase tables: `plants` (id, user_id, name, species, last_watered date, watering_interval_days int). Show me the full project structure and all files.

## Supplied context

- App name: `GardenTrack`
- Bundle ID: `com.myorg.gardentrack` (placeholder, not yet registered)
- Target platforms: Android, Web
- Supabase project URL: `https://abcdefgh.supabase.co`
- Supabase anon key: `sb_publishable_...` (placeholder)
- Planned screens: Login, Home (plant list), Add Plant
- Supabase tables: `plants` (id uuid, user_id uuid, name text, species text, last_watered date, watering_interval_days int)

## Requirements

- No LLM calls in this app
- Single transparent PNG icon, no background colour
- Infrastructure setup scripted — not portal-only
- Supabase schema as SQL migration file, not just dashboard clicks
