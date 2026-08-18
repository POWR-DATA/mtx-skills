# Supabase Marketing Backend

Use Supabase as the backend for a static marketing site — insert-only public forms on the anon key with RLS, a privacy-tiered first-party page-hit beacon, reader roles for Excel, and the RLS/view leaks that bite.

## What this skill does

Gives a static marketing site the small backend it needs without a server: a single Supabase table that takes public form submissions for every campaign under an insert-only anon policy, a first-party beacon that counts page hits without collecting personal information, and reporting-role access that actually returns rows. It includes the anon-key curl checks that prove the site can write but never read, and the front-end/CSP wiring.

## When to use it

- A static site (e.g. Azure Static Web Apps, no access logs) needs a wait-list or register-interest form
- You want page-hit counts without a third-party analytics script or personal data
- Marketing needs to open the sign-ups in Excel or Power BI
- A summary view or reader role was added and either leaks to anon or returns zero rows

## Example use cases

- Two campaign wait-lists in one table with a 200-row cap each and duplicate handling
- A page-hit beacon on every marketing page and the 404, with region derived from the browser timezone
- A `reporting` role Excel can log into via the session pooler
- Fix a `hits_daily` view that was readable with the anon key

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — form table + policies + cap trigger, anon curl checks, reader role/view revoke, beacon snippet |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the project ref, the forms/campaigns and pages, the site's CSP and who needs read access, then apply the SQL and front-end output and run the verification transcript. Pair with [Excel Power Query Postgres](../../data/excel-power-query-postgres/) for the reporting side and [Static Website Config and CSP](../../web/static-website-config-and-csp/) for the CSP change.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
