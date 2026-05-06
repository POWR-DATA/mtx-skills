# Example Input — Medallion Architecture Designer

## Context

Continuing from the Sales Performance Reporting use case. Data requirements and the dimensional model design are established. The team now needs a medallion architecture design for ingesting sales transaction data from the point-of-sale system into a cloud lakehouse.

## Input provided

**Source system:** Point-of-sale (POS) system

**Source data format:** Structured CSV files, one file per store per day, dropped to a cloud storage location overnight

**Ingestion method:** Batch file ingestion, daily

**Target consumers:**
- BI reporting layer (dimensional model, refreshed daily)
- Data science team (feature engineering for demand forecasting)

**Transformation requirements:**
- Standardise date formats (source uses multiple formats across stores)
- Derive margin from revenue and cost fields
- Join product and store master data to enrich transactions
- Deduplicate: some stores occasionally produce duplicate transaction lines

**Volume:** Approximately 2 million transaction lines per day across all stores

**Refresh frequency:** Daily, overnight batch

**History:** Two years required in all layers

**Merge requirements:** Daily files are full daily extracts per store. No CDC. Upsert by transaction line ID required to handle occasional re-sends.

**Data quality expectations:** High — the reporting layer feeds executive dashboards. Duplicate removal and referential integrity checks are mandatory.
