# Docker Compose Database Lab

Set up local Docker Compose database environments with correct volume mounts, configuration, health checks, and network access.

## What this skill does

Guides you through initialising a Docker Compose development environment for databases, handling the common gotchas that cause containers to restart immediately or data to be lost. Covers PostgreSQL 18 mount path changes, environment file placement, healthcheck variable escaping, and corporate network access patterns.

## When to use it

- Initialising a new Docker Compose database setup for local development
- Debugging "container restarts immediately" or "data not persisting" errors
- Setting up database containers behind a corporate proxy or restricted network
- Migrating to a new database version with breaking volume mount changes

## Example use cases

- Setting up PostgreSQL 18 with PostGIS for geospatial development, ensuring volumes persist across restarts
- Creating a local SQL Server environment for data import/export testing
- Configuring a database container to use a corporate Artifactory mirror for image pulls
- Writing SQL Server `CMD-SHELL` healthchecks that handle passwords containing `$` safely
- Debugging why a named volume is empty or a container keeps restarting

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide the database type, version, and your network constraints, then review the generated `compose.yaml` and `.env` template.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
