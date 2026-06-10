## compose.yaml

```yaml
version: '3.8'

services:
  postgres:
    image: <your-artifactory-mirror>/library/postgres:18-alpine
    container_name: geospatial-db
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql
      - ./init:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - geospatial

  postgis_loader:
    image: <your-artifactory-mirror>/library/postgis/postgis:18-3.6
    container_name: geospatial-loader
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      PGHOST: postgres
      PGUSER: ${POSTGRES_USER}
      PGPASSWORD: ${POSTGRES_PASSWORD}
      PGDATABASE: ${POSTGRES_DB}
    volumes:
      - ./scripts:/scripts
      - ./data:/data
    entrypoint: /bin/bash
    command: /scripts/load_natural_earth.sh
    networks:
      - geospatial

volumes:
  postgres_data:
    driver: local

networks:
  geospatial:
    driver: bridge
```

## .env

```
POSTGRES_USER=<your-db-user>
POSTGRES_PASSWORD=<your-secure-password>
POSTGRES_DB=geospatial_lab
```

## Key points

1. **PostgreSQL 18 volume path is `/var/lib/postgresql`** — older `/var/lib/postgresql/data` mounts trigger restart loops with an unused-mount error.
2. **`.env` is in the same directory as `compose.yaml`** — Compose reads from this location only.
3. **The image URI points to the Artifactory mirror** — replace `<your-artifactory-mirror>` with your organisation's Artifactory mirror host.
4. **The postgis_loader service depends on postgres healthcheck** — it waits for the database to be ready before running.
5. **Named volume `postgres_data` persists across restarts** — data survives `docker compose down` and `docker compose up`.
6. **For SQL Server `CMD-SHELL` healthchecks, use `$$MSSQL_SA_PASSWORD`** — avoids runtime truncation when the password contains `$`.

## Troubleshooting

- **Container restarts immediately:** Check that the volume mount path (`/var/lib/postgresql` for PG18) matches the image documentation. If upgrading from older versions, delete the named volume and recreate it (`docker volume rm geospatial-db_postgres_data`).
- **`.env` variables not read:** Verify `.env` is in the same directory as `compose.yaml`, not at the repository root.
- **Image pull fails:** Confirm the Artifactory mirror URL is correct and accessible from your network.
- **SQL Server healthcheck fails with special characters:** Ensure `CMD-SHELL` healthchecks use `$$MSSQL_SA_PASSWORD`, not `${MSSQL_SA_PASSWORD}`.
