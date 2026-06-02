---
name: geospatial-source-database
description: Work with geospatial data sources (PostGIS, SQL Server, Natural Earth) and handle data-specific quirks
author: PowerData
version: 1.0.0
license: MIT
---

# Geospatial Source Database

## Purpose

Navigate the quirks and gotchas when working with geospatial data sources — PostGIS in Docker, SQL Server spatial data, and public datasets like Natural Earth. Ensure you understand data coverage limitations, geometry validation requirements, and tool parser limitations so you don't lose time debugging false positives.

## When to use

- Setting up PostGIS in a Docker environment and needing to load geospatial tools
- Querying Natural Earth datasets and encountering unexpected empty result sets
- Loading data from SQL Server's WideWorldImporters sample database
- Working with spatial geometries and encountering validation errors or parser warnings
- Debugging tool warnings that may or may not indicate real errors

## Inputs expected

- Target data sources (PostGIS, SQL Server, Natural Earth, etc.)
- Geospatial operations planned (distance calculations, containment checks, area calculations)
- Development environment (Docker, local install, cloud database)
- Tool stack (DBeaver, Azure Data Studio, psql, etc.)

## Guiding principles

- **PostGIS ships without client tools.** The `postgis/postgis` Docker image includes the extension but not the `shp2pgsql` command-line tool. Install it at container runtime if needed; the install does not persist across recreation, so automation scripts must reinstall.
- **Public datasets have coverage limitations despite appearing global.** Natural Earth's 110m scale contains only US state data, not world states. WideWorldImporters contains only US cities/states despite having a global schema. Always query a small sample first to verify coverage.
- **Geometry validation is data-dependent.** SQL Server's WideWorldImporters contains invalid geometries; validate with `.MakeValid()` before any spatial operations. PostGIS `geography` casts emit NOTICEs for coordinate coercion; suppress with `SET client_min_messages = warning`.
- **Tool parsers are not always accurate.** DBeaver flags valid SQL Server CLR geography methods (`.STDistance()`, `geography::Point`) as errors; these are parser limitations, not execution failures. The queries run correctly despite the warnings.
- **SQL Server reserved keywords require bracket-escaping.** `[current_user]` is a keyword and must be escaped; `CROSS JOIN` replaces `ON 1=1` which SQL Server does not accept.

## Process

1. **Identify the data source and its coverage.** Check documentation or query metadata tables to confirm geographic coverage (e.g., is Natural Earth 110m truly global or US-only?).
2. **Validate geometries before operations.** If using SQL Server or datasets known to have invalid geometries, call `.MakeValid()` or `ST_MakeValid()` before distance, containment, or area calculations.
3. **Suppress expected warnings.** Set `client_min_messages` in PostgreSQL, or accept DBeaver warnings in SQL Server if you've verified the query logic is correct.
4. **Handle tool parser false positives.** In DBeaver, if a valid spatial method is flagged as an error, run the query anyway — parser limitations don't affect execution.
5. **Test with a small sample first.** Before loading large datasets, query a representative sample to verify coverage and data quality.
6. **Document data-specific rules.** Note which tables are US-only, which geometries need validation, which operations are safe without validation.

## Output format

1. **Data coverage summary** — which geographies are actually present in the dataset, any caveats
2. **Validation requirements per table** — which tables need `.MakeValid()`, which are already clean
3. **Query patterns for the source** — e.g., how to safely cast to geography, how to suppress warnings
4. **Sample queries** — demonstrating safe operations with validation or suppression applied
5. **Tool-specific notes** — e.g., DBeaver warnings to ignore, Azure Data Studio quirks

## Quality checklist

- [ ] Data coverage has been verified with a sample query (not assumed from documentation)
- [ ] Geometries have been validated before spatial operations
- [ ] Expected warnings (client_min_messages, DBeaver flags) have been identified and documented
- [ ] SQL reserved keywords are bracket-escaped in SQL Server
- [ ] Example queries include both valid and invalid geometry handling
- [ ] No real data or identifiable information in examples (use generic geographic names or public datasets only)

## Avoid

- Assuming public datasets are truly global — always verify coverage with a query.
- Skipping geometry validation — invalid geometries cause spatial operations to fail silently or return incorrect results.
- Trusting tool parser flags without verification — DBeaver and other tools flag valid SQL, causing unnecessary debugging.
- Using `ON 1=1` in SQL Server `CROSS JOIN` — SQL Server does not accept this; use `CROSS JOIN` without the `ON` clause.
- Calling `.STDistance()` or similar spatial methods on invalid geometries — validate first with `.MakeValid()`.

## Example usage

> I'm loading Natural Earth data into PostGIS and querying for Australian states, but I'm getting empty results. I also see orange warnings in DBeaver about my `.STDistance()` calls in SQL Server. Help me verify that Natural Earth has the coverage I need, understand why the warnings appear, and show me the right way to query spatial data safely.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
