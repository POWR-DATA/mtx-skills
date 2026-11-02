---
name: supabase-postgres-guardrails
description: Write Supabase Postgres functions, RPCs and triggers that are safe to expose — explicit EXECUTE grants, null-safe ownership checks, server-side trust and location masking, concurrency guards, PostgREST error codes, and real SQL tests in CI
author: PowerData
version: 1.0.0
license: MIT
---

# Supabase Postgres Guardrails

## Purpose

Write and review the Postgres functions, PostgREST RPCs and triggers behind a Supabase app so that what the anon key and signed-in users can reach is exactly what was intended — explicit EXECUTE grants, ownership checks that fail closed on null, validation and location masking the client cannot bypass, guards against concurrent duplicates and status regressions, error codes the client can show — and prove it with SQL tests that run in CI.

## When to use

When adding or changing a function, RPC or trigger in an exposed schema (normally `public`), reviewing a migration before it is pushed, or investigating a report that a signed-out visitor or another user could read or change something they should not. Apply at authoring time and again at review. Getting the change onto the right project is covered by `supabase-migration-promotion`; Edge Function code by `supabase-edge-functions`.

## Inputs expected

Partial inputs are acceptable — read what the migrations folder shows and state assumptions.

- The migration(s) or function and trigger definitions under review, and the schema they live in
- The intended caller of each function (anon, authenticated, service role, internal only) and the data it returns
- The ownership model: which column holds the owner, and whether it can be null (admin-created rows, `on delete set null`)
- Any location or other field that is masked for some callers, and how the masking is applied
- The statuses records move through (including moderation states) and which calls change them
- The current test setup (pgTAP, `supabase test db`, CI workflow), if any

---

## Guiding principles

- **Grant EXECUTE explicitly, function by function — the defaults expose everything.** Postgres grants EXECUTE on every new function to PUBLIC and Supabase's default privileges add `anon`, so a blanket revoke in an early migration does not cover functions added later, and even internal helpers ("is this user connected to that account?") are callable by signed-out visitors. In the migration that creates each function, revoke EXECUTE from `public, anon, authenticated` and grant only to the intended role; add `alter default privileges in schema public revoke execute on functions from public, anon, authenticated`; audit with `has_function_privilege('anon', oid, 'execute')` against an allow-list, and verify by calling as anon. Two functions in an unpushed migration were callable with only the anon key and returned a person's email and full address. See *Grants and anon audit* in [`reference.md`](reference.md).
- **Ownership checks must fail closed on null.** `owner_id is not distinct from auth.uid()` is true when both are null, so an anonymous caller matches every row whose owner is null (rows opened by an admin, or owners whose account was deleted with `on delete set null`). Write `auth.uid() is not null and owner_id = auth.uid()`.
- **Mask the geometry the query uses, not just the coordinates it returns.** If the box filter, radius filter, sort or distance still use the exact point, about 20 shrinking-box calls, or three distance readings, recover it. Filter, sort and measure masked rows on a snapped public geometry, set a minimum box size and radius, and return no distance for masked rows.
- **Test database security with real SQL, not by reading the SQL.** Migration "tests" that pattern-matched the SQL file text passed while grant and null-check holes went through. Run the migrations in CI and call the functions as `anon` and as another signed-in user.
- **Make duplicate checks atomic.** A check-then-insert in an RPC without a lock or unique index lets two concurrent calls (a double tap) both pass and create two rows for one address. Enforce it with a unique partial index or an advisory lock, and disable the submit button while the call is in flight.
- **Recompute only the states recompute owns.** A function that sets `verified`/`unverified` from counts must keep `hidden` and `moderation_hold` rows as they are — preserving only `removed` let every vote, rating or clear call put a hidden record back on the public map. Make votes, ratings and clears require a live status, and when moderation restores a record, put back its prior status first and recompute after.
- **The server decides what is valid; a client-only dropdown is not a rule.** An RPC accepted any in-region point with any label starting with a number, and a made-up `lat,lng` geocoder place id passed the format check. When the rule is that only entries from a verified source may be added, resolve the provider id on the server and store the server's point and fields, never the client's.
- **Normalise both sides before a trigger decides a text field changed.** Compare `nullif(btrim(new.x), '') is distinct from nullif(btrim(old.x), '')`. A client that saves `''` as null otherwise fires the "changed" branch — which would have silently cleared a verified flag on an unrelated profile save.
- **Sync two tables with triggers that write only when out of step.** Two AFTER triggers keep two tables in step without looping if each side writes only when the other is not already in step (`where <flag>` on the update, `on conflict do nothing` on the insert). `on conflict do nothing` with no target also covers an expression unique index such as `lower(email)`. To hold a value instead of failing the whole write (an onboarding insert, say), use a BEFORE trigger that overrides `NEW` rather than raising.
- **Raise user-facing refusals as P0001.** Through PostgREST, P0001 maps to HTTP 400 with the message passed through, so the client can show it; an exception raised with SQLSTATE P0002 surfaced as HTTP 500.

## Process

1. **Inventory the exposed surface** — every function in `public` (and any other exposed schema) and every trigger, with its intended caller, `security definer` or `invoker`, and what it returns or changes.
2. **Lock down grants** — per-function revoke from `public, anon, authenticated`, a grant to the intended role only, the default-privileges revoke, then the `has_function_privilege` audit reconciled against the allow-list of intentionally public functions.
3. **Check every ownership predicate** — find `is not distinct from auth.uid()` and any comparison a null owner could satisfy; rewrite as `auth.uid() is not null and owner_id = auth.uid()`.
4. **Move validation to the server** — for any value the client picks from a trusted source (geocoder, catalogue), re-resolve the provider id server-side (in the RPC, or an Edge Function — see `supabase-edge-functions`) and store the server's result.
5. **Close race windows** — give each check-then-insert a unique partial index or `pg_advisory_xact_lock`, turn the conflict into a P0001 message, and disable the client button while the call is in flight.
6. **Walk the status machine** — list every state; confirm recompute preserves moderation states, vote/rating/clear calls require a live status, and restore paths recompute after restoring.
7. **Review triggers** — normalise text change detection; check sync triggers stop once in step; replace raises with `NEW` overrides where the write should succeed.
8. **Audit masked reads** — for every function returning masked rows, confirm filter, sort and distance use the snapped geometry, the minimum box and radius are enforced, and distance is null for masked rows.
9. **Set error codes** — user-facing refusals raise P0001 (a bare `raise exception` already does); nothing the user should read raises P0002.
10. **Write and wire SQL tests** — pgTAP files under `supabase/tests` that run as `anon`, as the owner and as another user, covering the null-owner, duplicate and probing cases; run `supabase test db` in CI on every PR. See *SQL tests in CI* in `reference.md`.
11. **Hand over for promotion** — once the tests pass, deploy with `supabase-migration-promotion`.

## Output format

1. **Exposure inventory** — a table of functions and triggers: intended caller, definer or invoker, data returned, verdict
2. **Grants** — revoke/grant SQL per function, the default-privileges change, and the anon audit result against the allow-list
3. **Corrected SQL** — ownership predicates, server-side resolution, concurrency guard, status handling, trigger fixes, masking and error codes, each with a one-line reason
4. **Abuse cases** — each attack considered (anon call, other user, null owner, double submit, forged client payload, shrinking-box probe) and what now stops it
5. **SQL tests and CI** — the test file(s), what each assertion proves, and the CI job
6. **Open risks** — anything not fixed, and what must be checked on the deployed projects

## Quality checklist

- [ ] Every new function has its own revoke from `public, anon, authenticated` and a grant to its intended role only
- [ ] `alter default privileges in schema public revoke execute on functions from public, anon, authenticated` is in place
- [ ] The `has_function_privilege('anon', …)` audit returns only allow-listed functions, and an anon call is refused
- [ ] No ownership check can match a null owner
- [ ] Masked rows are filtered, sorted and measured on the snapped geometry; minimum box and radius enforced; no distance returned
- [ ] The server re-resolves provider ids and stores its own point and fields
- [ ] Every check-then-insert is protected by a unique partial index or advisory lock; submit disabled while in flight
- [ ] Recompute preserves `removed`, `hidden` and `moderation_hold`; signal calls require a live status; restores recompute afterwards
- [ ] Trigger change detection normalises both sides with `nullif(btrim(x), '')`
- [ ] Sync triggers write only when out of step; held values use a BEFORE trigger that overrides `NEW`
- [ ] User-facing refusals raise P0001, never P0002
- [ ] pgTAP tests run the migrations and call functions as anon and as another user, in CI on every PR

## Avoid

- Relying on a blanket revoke in an earlier migration — functions created later are executable by PUBLIC and anon again
- Leaving internal helpers in `public` with default grants because "the app never calls them"
- `is not distinct from auth.uid()` in an ownership check — two nulls match
- Masking only the returned lat/lng while the filter, sort or distance use the exact point
- Returning a distance for masked rows, or accepting an arbitrarily small box or radius
- Trusting client-supplied coordinates, labels or provider ids because the UI only offers valid choices
- A check-then-insert with no lock or unique index
- A recompute that overwrites moderation states, or votes, ratings and clears accepted on a record that is not live
- Comparing raw text in a trigger where `''` and null mean the same thing
- Raising in a trigger when the right outcome is to keep the write and hold one value
- P0002 for refusals the user should see — PostgREST turns it into an HTTP 500
- Migration "tests" that pattern-match the SQL text — they pass while the holes ship
- Pushing or promoting from this skill — project targeting belongs to `supabase-migration-promotion`

## Example usage

> "Review our next migration before it goes near production. It adds `owner_contact`, `add_garden` and `gardens_near` RPCs and a trigger that clears `phone_verified` when the phone changes. Home gardens are masked for signed-out visitors. Make sure anon can't call anything it shouldn't, fix whatever is unsafe, and give us SQL tests that run in CI."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
