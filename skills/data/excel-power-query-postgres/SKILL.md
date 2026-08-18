---
name: excel-power-query-postgres
description: Connect Excel Power Query to PostgreSQL (including Supabase) — the Npgsql driver that works, credential caching and sharing, first-load refresh, and the COM-automation traps when scripting the workbook
author: PowerData
version: 1.0.0
license: MIT
---

# Excel Power Query Postgres

## Purpose

Get a shareable Excel workbook reading live PostgreSQL data through Power Query — the one Npgsql build the built-in connector accepts, how credentials are cached and (not) shared, why "Refresh All" does nothing on a fresh workbook, and how to automate the workbook with COM without blanking the user's data.

## When to use

When someone needs a refreshable Excel report over Postgres tables or views (a Supabase `reporting` role, a warehouse, a local lab DB) and the workbook will be opened by people who did not build it. Apply at first setup, when handing the file to a second person, and before scripting anything against the workbook.

## Inputs expected

Partial inputs are fine.

- Postgres host, port, database, role name (for Supabase pooler: `<role>.<project-ref>`) and which tables/views to load
- Excel version(s) in play (desktop vs Excel Online) and who will refresh vs only read
- Whether the workbook will be built or refreshed by automation (PowerShell/COM)

---

## Guiding principles

- **Excel's built-in PostgreSQL connector needs Npgsql 4.0.x from the MSI with "Npgsql GAC Installation" ticked.** Newer Npgsql releases dropped the MSI and GAC, so 4.0.17 is the one that works; fully restart Excel afterwards.
- **Credentials are cached per server on the machine, not in the workbook.** A wrong username is fixed under Data → Get Data → Data Source Settings → Edit Permissions → Credentials, and sharing the `.xlsx` never shares the password. Readers open the cached data without any driver or credentials; only the person refreshing needs Npgsql and the password.
- **"Refresh All" does nothing until the queries have been loaded once** through Get Data → Navigator → "Select multiple items" → Load; a workbook shipped with unloaded queries looks broken to the recipient.
- **COM-automated workbooks refresh headlessly with no credentials.** Query tables become "ExternalData_1: Getting Data..." shells, pivots built on them snapshot "(blank)", and opening the file in headless Excel with refresh-on-open enabled blanked the user's already-populated tables. Set `RefreshOnFileOpen=false`, build all pivots on shared caches, let the user refresh once in their own Excel, and only then run any automation against the populated file.
- **`GetActiveObject("Excel.Application")` fails from an agent session** with `MK_E_UNAVAILABLE` (0x800401E3) even while Excel is open in the user's session; ask the user to close the workbook and drive a fresh `New-Object -ComObject Excel.Application` instead. COM timeouts leave zombie `EXCEL.EXE` processes, so capture `Get-Process EXCEL` IDs before and kill only the new ones after.
- **Supabase reporting reads need a SELECT policy on each table**, not just a `GRANT` — otherwise Excel reports "0 rows loaded" (see `supabase-marketing-backend`).

## Process

1. **Install the driver** — Npgsql 4.0.17 MSI, GAC installation ticked, restart Excel.
2. **Connect** — Get Data → From Database → From PostgreSQL; server `host:port`, database; Database credentials with the role and password.
3. **Load once** — Navigator → Select multiple items → tick tables/views → Load (to sheets or the data model). Only now does Refresh All work.
4. **Fix credentials if needed** — Data Source Settings → Edit Permissions → Credentials (per-machine cache).
5. **Build reporting** — pivots on shared caches; leave `RefreshOnFileOpen` off if any automation will touch the file.
6. **Hand over** — recipients need nothing to *read*; refreshers need Npgsql + the password.
7. **Automate carefully** — user refreshes first in their own Excel; then a fresh COM instance, never `GetActiveObject`; track and kill only new `EXCEL.EXE` PIDs.

## Output format

1. **Driver + connection recipe** — versions, dialog values, credential type
2. **Query list** — tables/views loaded, sheet/data-model destination
3. **Sharing notes** — who needs what (driver, password), refresh model
4. **Automation notes** (if any) — refresh-on-open setting, COM approach, PID hygiene

## Quality checklist

- [ ] Npgsql **4.0.x** MSI with GAC install; Excel fully restarted
- [ ] Queries loaded once via Navigator → Select multiple items → Load; Refresh All confirmed working
- [ ] Credentials cached per machine; wrong-user fix path documented (Data Source Settings → Edit Permissions)
- [ ] Reader role has SELECT policies on RLS tables (non-zero rows)
- [ ] `RefreshOnFileOpen=false` and pivots on shared caches before any COM automation
- [ ] Automation uses a fresh COM instance after the user's own refresh; new `EXCEL.EXE` PIDs cleaned up

## Avoid

- Installing the latest Npgsql — no MSI/GAC, Excel will not see it; use 4.0.17
- Expecting the password to travel with the `.xlsx` — credentials are per-machine
- Shipping a workbook whose queries were never loaded — Refresh All is inert
- Opening the workbook in headless Excel with refresh-on-open enabled — it blanks populated tables
- `GetActiveObject` from an agent session — `MK_E_UNAVAILABLE`; use `New-Object -ComObject`
- Killing every `EXCEL.EXE` after a COM timeout — kill only the PIDs you spawned

## Example usage

> "Marketing wants the Supabase `interest_signups` table and `hits_daily` view in Excel with a refresh button. Two people will refresh, five will just read. Excel says it can't find the PostgreSQL driver, and when I got it connected the pivots showed '(blank)' after my PowerShell script ran."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
