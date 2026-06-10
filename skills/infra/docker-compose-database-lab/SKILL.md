---
name: docker-compose-database-lab
description: Set up local Docker Compose database environments with correct volume mounts, configuration, and network access
author: PowerData
version: 1.1.0
license: MIT
---

# Docker Compose Database Lab

## Purpose

Set up a local Docker Compose development environment for database work, avoiding common gotchas around volume mounts, environment file placement, and corporate network access. This skill ensures containers start reliably and persist data correctly.

## When to use

- Initialising a new Docker Compose setup for local database development
- Debugging "container restarts immediately" or "data not persisting" issues
- Setting up database containers behind a corporate proxy or restricted network
- Migrating between PostgreSQL versions with breaking volume mount changes

## Inputs expected

- Target database (PostgreSQL, MySQL, SQL Server, etc.) and version
- Corporate network constraints (proxy requirements, registry mirrors)
- Volume mount paths and desired data persistence model
- Environment configuration (`.env` variables, secrets)

## Guiding principles

- **Volume mounts are version-specific.** PostgreSQL 18 uses `/var/lib/postgresql` as the container data path. Using the older `/var/lib/postgresql/data` mount with PG18 causes immediate restart loops with an "unused mount" error.
- **Compose reads `.env` from the directory containing `compose.yaml`, not from the repository root.** Place `.env` and `compose.yaml` in the same subdirectory; Compose silently ignores misplaced files.
- **Corporate networks often block direct Docker Hub access.** Use Artifactory mirrors for Docker Hub images; Microsoft Container Registry (MCR) typically works without a mirror on the same networks.
- **Named volumes survive container recreation; bind mounts do not.** Use named volumes for persistent data; use bind mounts only for development code.
- **Health checks prevent dependent services from starting before the database is ready.** Always include a `healthcheck` in the database service and reference it in dependent services' `depends_on`.
- **Escape runtime env vars in `CMD-SHELL` healthchecks.** Use `$$VAR_NAME` in Compose healthchecks so `$` is passed literally to the container shell; this prevents silent truncation when secrets contain `$`.

## Process

1. **Identify the database image and version.** Check the upstream image documentation (Docker Hub, vendor site) for the container's expected volume mount paths.
2. **Choose a volume strategy.** Decide: named volume (persistent across compose restarts) or bind mount (synchronised with local filesystem). Use named volumes for databases; use bind mounts for code or configuration that developers edit.
3. **Create the directory structure.** Place `compose.yaml` and `.env` in the same subdirectory (e.g. `docker/` or `infra/docker/`). Do not place `.env` at the repository root.
4. **Define services in `compose.yaml`.** Include explicit volume mounts with the correct container paths for the version in use. Add a `healthcheck` to the database service. Reference the healthcheck in dependent services.
5. **Populate `.env` with database credentials and configuration.** Use strong, randomly generated values for development. Document which variables are required.
6. **Test volume persistence.** Start the service, create test data, stop the service, restart, and verify the data is still present. If the container restarts immediately, check the volume mount path against the image documentation.
7. **Handle major version mount changes.** When moving to PostgreSQL 18 from older versions, update mounts to `/var/lib/postgresql` and remove stale named volumes before restarting.
8. **Configure network access if needed.** If behind a corporate proxy, add `registry-mirrors` to Docker daemon config or use `image:` URIs that point to Artifactory mirrors for Docker Hub images.
9. **Validate shell-based healthchecks with special-character secrets.** For SQL Server and other `CMD-SHELL` checks, reference variables as `$$MSSQL_SA_PASSWORD` (not `${MSSQL_SA_PASSWORD}`) so runtime expansion is correct.

## Output format

A working `compose.yaml` and `.env` template with:

1. **Database service definition** — image, version, volume mounts (correct for the version), environment variables, healthcheck
2. **Volume declaration** (if using named volumes) — name and driver
3. **Network declaration** (if needed) — custom network for service-to-service communication
4. **Dependent service examples** (e.g., backup, load scripts) — showing how to reference the database healthcheck
5. **.env template** — required variables, descriptions, example values (using placeholders like `<your-password>`)
6. **Troubleshooting checklist** — volume path verification, .env placement verification, container restart diagnosis

## Quality checklist

- [ ] Volume mount paths match the database image documentation for the specified version
- [ ] `.env` and `compose.yaml` are in the same directory
- [ ] Database service includes a `healthcheck` command appropriate for the database type
- [ ] Dependent services reference `depends_on: db: condition: service_healthy`
- [ ] Named volumes are explicitly declared in the `volumes:` section
- [ ] `.env` template uses generic placeholders (`<your-username>`, `<your-password>`), not real credentials
- [ ] Example demonstrated on the target version and tested for data persistence
- [ ] `CMD-SHELL` healthchecks use `$$VAR` escaping for passwords that may include `$`

## Avoid

- Placing `.env` at the repository root — Compose will not find it.
- Reusing volume mount paths from older PostgreSQL versions without checking current documentation — PostgreSQL 18 expects `/var/lib/postgresql`.
- Omitting healthchecks — dependent services will start before the database is ready.
- Using `${MSSQL_SA_PASSWORD}` directly inside a `CMD-SHELL` healthcheck — use `$$MSSQL_SA_PASSWORD` to avoid shell re-expansion bugs.
- Using `POSTGRES_PASSWORD` as an environment variable directly in `compose.yaml` — always read from `.env`.
- Mixing named volumes and bind mounts for the same data (e.g., a named volume for data and a bind mount for backups in the same directory).

## Example usage

> I'm setting up a local PostgreSQL 18 and PostGIS environment for geospatial development. I have data that needs to persist across restarts, and I'm on a corporate network that blocks Docker Hub. Help me create a `compose.yaml` that mounts volumes correctly for PG18, uses a local Artifactory mirror, and includes a backup service that depends on the database being healthy.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
