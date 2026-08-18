---
name: supabase-marketing-backend
description: Use Supabase as the backend for a static marketing site — insert-only public forms on the anon key with RLS, a privacy-tiered first-party page-hit beacon, reader roles for Excel, and the RLS/view leaks that bite
author: PowerData
version: 1.0.0
license: MIT
---

# Supabase Marketing Backend

## Purpose

Stand up the small Supabase backend a static marketing site needs — public sign-up/wait-list forms that insert with the anon key under RLS, a first-party analytics beacon that counts page hits without collecting personal information, and read access for reporting tools — with the verification steps that prove anon can insert but never read, and the CSP/front-end wiring the site needs.

## When to use

When a static site (e.g. on Azure Static Web Apps, which has no access logs) needs to capture form submissions or count page hits without a server, and Supabase is already the org's backend. Apply before the first form goes live, and again when adding a reporting reader (Excel/Power BI) or a new campaign to an existing table.

## Inputs expected

Partial inputs are acceptable — infer defaults and state them.

- Supabase project ref, a way to run SQL (dashboard SQL editor or Management API), and the anon key
- The forms/campaigns to capture (fields, per-campaign caps, incentive rules) and the pages to count
- The site's CSP and which pages are marketing vs auth
- Who needs read access (reporting role, tool) and what counts as personal information for the org's privacy policy

---

## Guiding principles

- **Insert-only public forms on the anon key: RLS on, one table for every campaign.** Put the table in the PostgREST-exposed `public` schema with RLS enabled and an insert-only policy for `anon`; add a `campaign` column with a default plus a unique index on `(campaign, lower(email))` and a per-campaign row-cap trigger so one table serves every campaign. See *Public form table* in [`reference.md`](reference.md).
- **Verify with curl before shipping the client.** `apikey` plus `Authorization: Bearer <anon>` with `Prefer: return=minimal` returns 201; a duplicate returns 409 (map it to "already on the list"); an anon GET returns `[]`; a check-constraint failure returns 400. If any of those differ, the policies are wrong.
- **Every reader role needs a SELECT policy, not just a GRANT.** `GRANT SELECT` to a reporting role on an RLS-enabled table reads zero rows (Excel reported "0 rows loaded"); add `create policy ... for select to <role> using (true)` on each table the role should read.
- **Views bypass RLS and get auto-granted to anon — revoke in the same migration.** Views run with owner privileges, and Supabase default privileges auto-grant SELECT on new public views to `anon` and `authenticated`, so a summary view over a write-only table becomes readable through the anon API; always `revoke select on <view> from anon, authenticated` in the migration that creates it.
- **Session-pooler login for external tools:** host `aws-0-<region>.pooler.supabase.com`, port `5432`, database `postgres`, username `<role>.<project-ref>` — the project-ref suffix is mandatory and easy to mistype.
- **Count page hits with a first-party beacon and pick the privacy tier deliberately.** SWA Free has no access logs and Search Console only sees Google traffic. Referrer host, device class, browser and OS family, and timezone-derived region are not personal information; storing raw IP or user agent is — so derive region from the browser timezone client-side and never send the IP. Publish a privacy-policy section for it even when nothing personal is collected.
- **Beacon on every marketing page including the 404, never on auth pages, and in the CSP.** The 404 catches mistyped printed URLs; auth pages stay beacon-free; add the Supabase host to the site-wide CSP `connect-src` or the beacon is blocked silently.
- **Give the beacon a schema-lag fallback.** Post the enriched payload and on a 400 (columns not yet migrated) retry with the minimal payload, so the JS can deploy before the SQL migration runs and starts recording richer rows the moment it does.
- **Bot friction that worked for a public anon-key insert endpoint:** a honeypot field, a 3-second minimum time-to-submit gate, server-side email and name check constraints, per-email uniqueness and a hard per-campaign row-cap trigger; the real safeguard is that incentives are granted manually, with Turnstile inside an Edge Function as the escalation path if abuse appears.
- **`hidden` is defeated by any CSS `display` rule on the same element** (a `display:flex` success card showed on load); add `[hidden] { display: none !important; }` to the stylesheet.

## Process

1. **Model the table(s)** — form table with `campaign` default, email/name check constraints, unique `(campaign, lower(email))`, row-cap trigger; hits table with the chosen non-personal columns.
2. **Write the policies** — RLS on; anon insert-only on both tables; SELECT policy per reader role; no anon SELECT anywhere.
3. **Create views last and revoke** — any summary view gets `revoke select … from anon, authenticated` in the same migration.
4. **Verify with curl** — 201 / 409 / `[]` / 400 as above, using only the anon key.
5. **Wire the front end** — form JS with honeypot + 3 s gate + 409 → "already on the list"; beacon on all marketing pages + 404, minimal-payload fallback; `[hidden]` CSS rule; Supabase host in CSP `connect-src`.
6. **Add readers** — role with a strong password, `GRANT` + `SELECT` policies, session-pooler connection details handed over (see `excel-power-query-postgres` for the Excel side).
7. **Publish the privacy note** and record which fields are collected and why.

## Output format

1. **Schema + policies** — SQL for tables, constraints, trigger, RLS policies, view revokes
2. **Verification transcript** — the four anon-key curl checks with status codes
3. **Front-end wiring** — form handler, beacon snippet with fallback, CSP change, `[hidden]` rule
4. **Reader access** — role, policies, pooler connection string (no password in the doc)
5. **Privacy note** — what is and is not collected

## Quality checklist

- [ ] RLS enabled; anon has insert-only policies; no anon SELECT on tables or views
- [ ] Unique `(campaign, lower(email))` index and per-campaign row-cap trigger present
- [ ] curl: 201 insert, 409 duplicate, `[]` on GET, 400 on constraint failure — all with the anon key
- [ ] Every view created with `revoke select … from anon, authenticated` in the same migration
- [ ] Reader roles have SELECT policies, not just GRANTs; pooler username carries `.<project-ref>`
- [ ] Beacon: no IP/UA stored, region from timezone, on 404 page, not on auth pages, host in CSP `connect-src`, minimal-payload fallback on 400
- [ ] Honeypot + time-to-submit gate + server constraints in place; incentives granted manually
- [ ] `[hidden] { display: none !important; }` in the stylesheet; privacy-policy section published

## Avoid

- Granting anon SELECT "just for the thank-you page" — anon must never read
- Creating a summary view without revoking anon/authenticated SELECT — it leaks the write-only table
- Assuming a `GRANT SELECT` is enough for a reader — RLS returns zero rows without a policy
- Storing raw IP or user agent in the beacon — that crosses into personal information
- Loading the beacon on auth pages, or forgetting the CSP `connect-src` entry (silent block)
- Shipping the beacon and the migration in lockstep — use the minimal-payload fallback instead
- Relying on a `hidden` attribute where the element also has a CSS `display` rule
- Typing the pooler username without the `.<project-ref>` suffix

## Example usage

> "Our static site needs a 'register interest' form for two campaigns (cap 200 each, one entry per email) and a page-hit counter that doesn't collect personal data — SWA has no logs. Supabase project exists. Set up the tables, policies, the front-end JS and CSP change, and give marketing an Excel-readable role — and prove anon can't read anything."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
