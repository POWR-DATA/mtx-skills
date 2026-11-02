# Example Input — Supabase Migration Promotion

> GardenTrack's `.env` points at one Supabase project, but I'm not sure that's production. I need `20261028_plot_notes.sql` on production today, but two dev-only migrations sit ahead of it in the folder, and `add_garden` was hot-fixed live last week. Plan and run the promotion, with a rollback.

**Projects:** `.env` has `EXPO_PUBLIC_SUPABASE_URL=https://<ref-a>.supabase.co`. A second project, `<ref-b>`, appears in `supabase projects list`. The web app is live at `https://<your-site>` (Expo web export).

**Migrations folder (`supabase/migrations`), oldest first:**
- `20261015_masked_read.sql` — masks home-garden coordinates in `gardens_in_box`
- `20261020_dev_seed_fixtures.sql` — dev-only test gardens
- `20261024_experimental_search.sql` — dev-only, not ready
- `20261028_plot_notes.sql` — creates `plot_notes` with RLS policies, extends the shared `log_audit_event()` function, and re-creates `add_garden` so it writes an audit row

**Live changes:** `add_garden` was hot-fixed directly on production last week (a per-user rate limit). The repo copy does not have it.

**Companion integration:** an MCP connector reads gardens through `connector_gardens()`, defined in migrations on a separate `connector` branch.

**Credentials:** `SUPABASE_ACCESS_TOKEN` in `.env.local`; the CLI is logged in and currently linked to an unknown project. The promotion script uses Python `urllib`.

**Rollback expectation:** if `plot_notes` causes trouble, drop it and restore `add_garden` and `log_audit_event()` exactly as they were.
