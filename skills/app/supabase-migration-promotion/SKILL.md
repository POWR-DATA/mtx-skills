---
name: supabase-migration-promotion
description: Move Supabase schema changes between dev and production safely — checking what each project actually runs, promoting single migrations through the Management API, re-runnable migrations and rollbacks, and live function definitions as the base
author: PowerData
version: 1.0.0
license: MIT
---

# Supabase Migration Promotion

## Purpose

Get Supabase schema changes onto the intended project — and only those changes — by establishing which project is production, what each project actually runs, and which promotion path fits: `supabase db push` for a full pending set, or a single re-runnable migration applied through the Management API query endpoint, with a rehearsed rollback and function replacements built on the live definitions.

## When to use

Before pushing migrations to any shared project; when one migration must reach production ahead of others still pending in the folder; when a migration redefines a function; or when the repo's SQL and the live behaviour disagree. Apply after the SQL itself has been written and tested (see `supabase-postgres-guardrails`). CLI authentication and baselining a project's migration history before its first push are covered in `supabase-edge-functions`.

## Inputs expected

Partial inputs are acceptable — state which project refs are assumed and how that was established.

- The repo's `supabase/migrations` folder and the migration(s) to promote
- Candidate project refs: `.env`, CI secrets, the shipped app bundle, any connector configuration
- A personal access token (PAT) for the Management API and a working Supabase CLI login
- Which migrations are dev-only, and any companion integration (e.g. an MCP connector) that defines functions in the same database
- A dev project to rehearse on, and what a rollback must restore

---

## Guiding principles

- **Never infer deployed state from the repo.** A project in `.env` was missing every migration from a masking migration onward, so a live anon call to the public read function returned every point with exact coordinates while the repo's SQL said they were masked. Run `supabase migration list --linked` for each project, and probe deployed behaviour — aggregate counts only, printing no personal data — before trusting or pushing.
- **Establish which project is production from what ships.** The repo `.env` pointed at a dev project, while the live site's JavaScript bundle and a connector's ids came from a different production project. When it is unclear, read the ref out of the shipped bundle (`EXPO_PUBLIC_*` values are inlined) rather than assuming `.env`.
- **`supabase db push` takes the whole folder.** It applies every pending file in `supabase/migrations`, in timestamp order, so a migration meant to stay off production goes out with the next push from that branch. Keep dev-only migrations out of the folder, and run `supabase migration list --linked` against each project before pushing.
- **Promote a single migration through the Management API query endpoint.** To move one independent migration without dragging along other unapplied ones, apply its SQL with `POST https://api.supabase.com/v1/projects/{ref}/database/query` and `Authorization: Bearer <access-token>` rather than `db push`. Large DDL (create tables and functions, extend a shared audit function) applies fine this way. See *Single-migration promotion* in [`reference.md`](reference.md).
- **Every migration must be safe to re-run.** Applying through the query endpoint and recording the version in `supabase_migrations.schema_migrations` are two separate requests, not one transaction, and a later `db push` may apply the file again. Use `create table if not exists`, `drop policy if exists` before `create policy`, `create or replace function`. A rehearsed rollback-then-re-promotion failed on a migration that recreated a policy without `drop policy if exists` — rehearse the rollback on dev before relying on it.
- **Base every function replacement on the live definition.** A migration that re-creates a function from the repo's copy silently reverts whatever was changed live since that copy: a feature-freeze migration replaced a live write function with an older body and had to be rebuilt, and recompute functions needed the same rebuild days earlier. Fetch the live definition with `pg_get_functiondef`, use it as the base for the replacement and its rollback, and diff the two before applying.
- **Keep everything that defines functions in one migrations folder and one workflow.** A connector's public read functions kept in a separate branch's migrations were replaced by later app migrations that redefined the same functions, so the connector silently diverged from the app. Merge connector migrations into the same folder as the app's and deploy every project from one workflow.
- **End query-endpoint scripts with a SELECT of what you need to see.** The endpoint returns only the last statement's result set and drops `RAISE NOTICE` output, so a script whose checks are notices shows nothing. Combine several checks into one final SELECT using subqueries and `json_agg`.
- **Send an explicit User-Agent to the Management API.** Cloudflare can block the request with `403 error code: 1010` when the HTTP client sends a default or absent User-Agent (e.g. Python `urllib`); set an explicit `User-Agent` header and it goes through.
- **The PAT and the CLI login are separate credentials, and the linked project may be production.** A PAT kept in a local env file expires or is revoked independently of the CLI login: HTTP 401 "Invalid access token" from the query endpoint while `supabase projects list` still works means rotate the PAT. Always pass `--project-ref` explicitly, and re-link with `supabase link --project-ref <ref>` before any `--linked` command.

## Process

1. **Map the projects** — list every candidate ref; confirm production from the shipped bundle and connector configuration; record dev and production refs with the evidence for each.
2. **Check credentials** — send `select 1` through the query endpoint (explicit User-Agent) for each ref; on a 401 while the CLI still works, rotate the PAT. Note which project the CLI is linked to.
3. **Read deployed state** — `supabase link --project-ref <ref>` then `supabase migration list --linked` for each project; run aggregate-only probes of anything security-relevant (masking, anon grants).
4. **Choose the path** — `supabase db push` only if every pending file is meant for the target; otherwise promote the single migration through the query endpoint. Move dev-only migrations out of the folder either way.
5. **Prepare the SQL** — fetch the live definition of every function the migration replaces, rebase the replacement on it, diff, write the rollback from the live definition, and make both re-runnable.
6. **Rehearse on dev** — apply, roll back, apply again; the final SELECT must show the expected state each time.
7. **Apply to the target** — POST the migration, read the final SELECT, then record the version in `supabase_migrations.schema_migrations` in a second request.
8. **Verify** — `supabase migration list --linked` shows the version as applied; rerun the behaviour probes.
9. **Fix the structure** — connector migrations merged into the app's folder, dev-only migrations kept outside it, one workflow deploying every project.

## Output format

1. **Project map** — dev and production refs and the evidence for each (bundle, connector, `.env`)
2. **Deployed state** — `migration list` per project, behaviour probe results (counts only), and any drift found
3. **Promotion plan** — each migration, its target project, the path (`db push` or query endpoint), the order, and what is deliberately held back
4. **Migration and rollback SQL** — re-runnable, rebased on live definitions, with a summary of the diff
5. **Apply transcript** — requests made (no tokens), final SELECT output, and the `schema_migrations` record
6. **Verification and follow-ups** — post-apply `migration list` and probes, the rehearsal result, and structural fixes

## Quality checklist

- [ ] Production ref confirmed from the shipped bundle or connector configuration, not assumed from `.env`
- [ ] `supabase migration list --linked` run against each project after an explicit `supabase link --project-ref`
- [ ] Deployed behaviour probed with aggregate counts only; no personal data printed
- [ ] No dev-only migration in `supabase/migrations` before any `db push`
- [ ] A single migration promoted through the query endpoint, not `db push`
- [ ] Every migration and rollback re-runnable (`if not exists`, `drop policy if exists`, `create or replace`)
- [ ] Replaced functions rebased on `pg_get_functiondef` from the target and diffed before applying
- [ ] Rollback and re-promotion rehearsed on dev
- [ ] Scripts end with one SELECT (subqueries, `json_agg`), not `RAISE NOTICE`
- [ ] Management API requests send an explicit `User-Agent`
- [ ] Version recorded in `supabase_migrations.schema_migrations` after the apply
- [ ] PAT checked separately from the CLI login; `--project-ref` passed explicitly
- [ ] Connector and app migrations in one folder, deployed from one workflow

## Avoid

- Reading the migrations folder as evidence of what a project runs
- Assuming `.env` points at production
- `supabase db push` from a branch carrying a migration that must not reach the target
- Re-creating a function from the repo copy without comparing it to the live definition
- Non-idempotent DDL (`create policy`, bare `create table`) in anything applied through the query endpoint
- Relying on a rollback that has never been run on dev
- `RAISE NOTICE` checks through the query endpoint — the output is dropped
- Calling the Management API from a client with a default or missing User-Agent
- Treating a query-endpoint 401 as a CLI problem — the PAT is a separate credential
- Running `--linked` commands without checking which project is linked
- Keeping a connector's migrations on a separate branch or in a separate folder from the app's
- Printing personal data while probing a production project
- Fixing function or grant logic here — write and test it with `supabase-postgres-guardrails` first

## Example usage

> "GardenTrack's `.env` points at one Supabase project, but I'm not sure that's production. I need `20261028_plot_notes.sql` (a new table plus an extended audit function) on production today, but two dev-only migrations sit ahead of it in the folder, and `add_garden` was hot-fixed live last week. Plan and run the promotion, with a rollback."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
