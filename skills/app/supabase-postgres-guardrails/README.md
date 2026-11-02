# Supabase Postgres Guardrails

Write Supabase Postgres functions, RPCs and triggers that are safe to expose — explicit EXECUTE grants, null-safe ownership checks, server-side trust and location masking, concurrency guards, PostgREST error codes, and real SQL tests in CI.

## What this skill does

Reviews and writes the database side of a Supabase app — the functions PostgREST exposes as RPCs, the helpers RLS policies call, and the triggers that keep tables consistent — so that the anon key and other users can reach only what was intended. It covers the defaults that quietly expose new functions, ownership checks that match null owners, location masking that a few probing calls can undo, duplicate checks that race, status recomputes that undo moderation, and trigger comparisons that misfire, then proves the fixes with pgTAP tests that run against migrated databases in CI.

## When to use it

- A migration adds or changes functions, RPCs or triggers in `public`
- You need to confirm what a signed-out visitor can execute with the anon key
- A map or search feature hides exact locations for some callers
- Duplicate rows appear after double taps, or hidden records reappear after a vote
- Database "tests" check SQL text rather than running it

## Example use cases

- Revoking default EXECUTE from new functions and auditing anon access with `has_function_privilege`
- Replacing `is not distinct from auth.uid()` ownership checks that let anon match admin-created rows
- Moving a radius search's filter, sort and distance onto a snapped geometry for masked rows
- Adding pgTAP tests and a `supabase test db` CI job that call each RPC as anon and as another user

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — grants and anon audit, masked reads, atomic duplicate checks, status recompute, trigger patterns, PostgREST error codes, pgTAP tests and CI |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt, then provide the migration or function definitions, the intended caller of each function, the ownership and status model, and any masking rules. Pair with [Supabase Migration Promotion](../supabase-migration-promotion/) to get the reviewed change onto the right project, and [Supabase Edge Functions](../supabase-edge-functions/) when server-side validation runs in an Edge Function.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
