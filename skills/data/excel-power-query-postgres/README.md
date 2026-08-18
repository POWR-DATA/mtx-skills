# Excel Power Query Postgres

Connect Excel Power Query to PostgreSQL (including Supabase) — the Npgsql driver that works, credential caching and sharing, first-load refresh, and the COM-automation traps when scripting the workbook.

## What this skill does

Gets a refreshable Excel workbook reading live PostgreSQL data and makes it safe to hand to other people: the exact Npgsql build Excel's built-in connector accepts, how credentials are cached per machine rather than in the file, why a fresh workbook's "Refresh All" does nothing until queries are loaded once, and how to script the workbook with COM without blanking data or leaving zombie Excel processes.

## When to use it

- Excel says it cannot find the PostgreSQL driver, or the connector fails after installing the latest Npgsql
- A colleague opens the shared workbook and Refresh All does nothing, or a wrong username needs fixing
- Reporting off a Supabase table returns zero rows for the reader role
- A PowerShell/COM script needs to build pivots on, or refresh, a Power Query workbook

## Example use cases

- Load a Supabase `reporting` role's tables and a daily-hits view into Excel for the marketing team
- Fix "0 rows loaded" caused by a missing SELECT policy on an RLS table
- Hand a workbook to five readers and two refreshers with the right instructions for each
- Automate pivot creation without turning query tables into "Getting Data..." shells

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the Postgres connection details, who refreshes vs reads, and whether automation is involved, then follow the recipe and sharing notes. Pairs with [Supabase Marketing Backend](../../app/supabase-marketing-backend/) for the database-side reader role and policies.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
