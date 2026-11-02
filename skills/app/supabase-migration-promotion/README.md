# Supabase Migration Promotion

Move Supabase schema changes between dev and production safely — checking what each project actually runs, promoting single migrations through the Management API, re-runnable migrations and rollbacks, and live function definitions as the base.

## What this skill does

Plans and carries out the promotion of Supabase migrations from a dev project to production without surprises. It establishes which project is really production, compares what each project runs with the repo, and picks the right path: `supabase db push` when every pending migration belongs on the target, or a single re-runnable migration applied through the Management API query endpoint when it does not. Function replacements are rebuilt on the live definitions, and rollbacks are rehearsed on dev first.

## When to use it

- A migration must reach production while other migrations stay pending or dev-only
- `.env`, CI secrets and the shipped app disagree about which project is production
- A migration redefines a function that may have been changed live
- The repo says a fix is in place but production still behaves the old way
- Management API calls fail with `403 error code: 1010` or `401 Invalid access token`

## Example use cases

- Promoting one new-table migration to production through the query endpoint, recording it, and verifying with a single final SELECT
- Finding the production project ref in a deployed Expo web bundle when `.env` points at dev
- Rebasing a function replacement on `pg_get_functiondef` from production so a live hot-fix is not reverted
- Merging a connector's migrations into the app's folder so both deploy from one workflow

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — bundle ref lookup, per-project state and probes, query-endpoint promotion with User-Agent, re-runnable DDL, live-definition diff, final SELECT checks, version recording |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt, then provide the migrations folder, the migration to promote, the candidate project refs and a Management API access token in your environment. Write and test the SQL first with [Supabase Postgres Guardrails](../supabase-postgres-guardrails/). For CLI authentication and baselining a project's migration history, see [Supabase Edge Functions](../supabase-edge-functions/).

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
