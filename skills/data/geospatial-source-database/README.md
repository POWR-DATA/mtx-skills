# Geospatial Source Database

Work with geospatial data sources (PostGIS, SQL Server, Natural Earth) and handle data-specific quirks.

## What this skill does

Guides you through working with geospatial data sources, navigating data coverage limitations, geometry validation requirements, SQL client quirks, and parser false positives. Ensures you understand what data you actually have and how to query it safely without losing time to confusing warnings or empty result sets.

## When to use it

- Setting up PostGIS in Docker and installing client tools like `shp2pgsql`
- Querying Natural Earth or WideWorldImporters and getting unexpected empty results
- Working with SQL Server spatial data and encountering validation errors
- Dealing with DBeaver or SQL IDE warnings on spatial queries
- Debugging why geometry operations are failing or returning wrong results

## Example use cases

- Loading Natural Earth data into PostGIS and discovering it only covers US states at the 110m scale
- Querying WideWorldImporters for Australian cities and finding none because the dataset contains only US data
- Running `.STDistance()` queries in SQL Server and seeing DBeaver parser warnings despite correct syntax
- Casting PostGIS `geometry` to `geography` and seeing unexpected NOTICEs about coordinate coercion
- Fixing SQL Server 2025 local scripts after `sqlcmd` v18 starts requiring trusted TLS configuration
- Retrieving spatial data in Python when `pyodbc` fails on SQL type `-151` and `psycopg2` returns `memoryview` for WKB

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Describe the data sources you're working with and the operations you need to perform, then review the guidance on coverage, validation, and tool-specific quirks.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
