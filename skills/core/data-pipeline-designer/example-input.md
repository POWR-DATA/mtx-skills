# Example Input — Data Pipeline Designer

## Context

The team needs a pipeline design for ingesting daily sales transaction files from the point-of-sale system into a cloud lakehouse. This builds on the previously established data requirements and medallion architecture design.

## Input provided

**Source system:** Point-of-sale (POS) system

**Target platform:** Cloud lakehouse (platform-agnostic)

**Data type and format:** Structured CSV files, one per store per day

**Volume:** ~2 million transaction lines per day across all stores (~50 stores)

**Frequency:** Daily, files delivered to cloud storage overnight

**Latency expectations:** BI reporting layer must be refreshed before business hours (7:00 AM local time). Near-real-time is not required.

**Access method:** Files dropped to a cloud object storage bucket. The pipeline has read access to the bucket via a service account.

**Transformation requirements:**
- Standardise date formats
- Cast revenue and cost to consistent decimal types
- Derive margin
- Join product and store master data
- Deduplicate on transaction line ID

**Data quality expectations:** High. Duplicate removal and referential integrity checks are mandatory. Failures must be quarantined and alerted, not silently dropped.

**Consumers:** BI reporting layer (dimensional model), data science feature table

**Operational constraints:** No dedicated data engineering team on-site. Pipeline must be self-monitoring and alert on failure. Reprocessing must be possible without data loss.
