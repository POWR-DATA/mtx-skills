I'm setting up a local PostgreSQL 18 + PostGIS environment for geospatial feature development. I need:
- Named volumes for persistent data across restarts
- Correct volume mount paths for PostgreSQL 18 (I was using PG15 before and the old paths might be wrong)
- A `.env` file with database credentials
- Our corporate network uses an Artifactory mirror for Docker images — I need to point to that
- A PostGIS loader service that depends on the database being healthy before it runs

Our network blocks direct Docker Hub access, but `riotinto-docker.artifactory.riotinto.com` is available for Docker Hub mirrors.
