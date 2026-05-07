# Example Output — Data Pipeline Designer

*Generated using the Data Pipeline Designer skill applied to the example input in `example-input.md`.*

---

## 1. Pipeline summary

A daily batch pipeline ingesting structured CSV sales transaction files from a cloud object storage location into a cloud lakehouse. The pipeline covers landing, standardisation, quality validation, and delivery to a BI reporting layer and a data science feature table. The pipeline is designed for autonomous operation with alerting and reprocessing capability.

---

## 2. Source and target

| Property | Detail |
|---|---|
| Source | Cloud object storage (CSV files, one per store per day) |
| Source volume | ~2 million rows per day across ~50 stores |
| Target | Cloud lakehouse (bronze, silver, and gold layers) |
| Consumers | BI reporting layer, data science feature table |
| Delivery deadline | BI layer refreshed before 7:00 AM daily |

---

## 3. Recommended ingestion pattern

**Pattern:** Batch file ingestion with file arrival gating.

**Rationale:** Daily CSV files delivered overnight are well-suited to a batch pattern. Near-real-time processing is not required. A file arrival gate (waiting for all expected store files before triggering the pipeline) reduces the risk of incomplete daily loads. Streaming is not warranted here and would add unnecessary complexity.

---

## 4. Processing flow

```
1. File arrival monitoring
   -> Wait for expected store files in cloud storage bucket

2. Bronze ingestion
   -> Read CSV files
   -> Convert to Parquet
   -> Append to bronze layer, partitioned by load_date
   -> Record file metadata (filename, load timestamp, store ID)

3. Silver processing
   -> Read new bronze partitions
   -> Standardise and cast fields
   -> Deduplicate on transaction_line_id
   -> Validate quality checks
   -> Write valid records to silver (upsert by transaction_line_id)
   -> Write invalid records to quarantine table

4. Gold delivery
   -> Incremental load to BI dimensional model (fact_sales)
   -> SCD Type 2 update for dimension tables
   -> Incremental append to data science feature table

5. Pipeline completion
   -> Log run metrics
   -> Send success or failure notification
```

---

## 5. Transformation approach

| Stage | Transformations |
|---|---|
| Bronze | Minimal. Convert CSV to Parquet. Add metadata fields only. |
| Silver | Standardise date formats to ISO 8601. Cast revenue, cost, quantity to correct types. Derive `margin = revenue - cost`. Join product and store master data. Deduplicate on `transaction_line_id`. |
| Gold | Aggregate and reshape for dimensional model. Apply SCD Type 2 logic for dimension updates. Flatten and enrich for data science feature table. |

---

## 6. Storage and layering approach

See Medallion Architecture Designer output for full layer design. Summary:

| Layer | Format | Partition key | Load strategy |
|---|---|---|---|
| Bronze | Parquet | `load_date` | Append-only |
| Silver | Delta (ACID) | `transaction_date` | Upsert on `transaction_line_id` |
| Gold — BI | Delta | `transaction_date` | Incremental + SCD Type 2 |
| Gold — Feature | Delta / Parquet | `transaction_date` | Incremental append |

---

## 7. Data quality and validation

| Check | Layer | Action on failure |
|---|---|---|
| File arrival completeness | Pre-ingest | Alert and hold pipeline until resolved or timeout reached |
| Schema validation | Bronze | Alert. Do not process files with unexpected schema. |
| Null checks (transaction ID, date, store, product, revenue) | Silver | Write failing records to quarantine table |
| Type validation (numeric fields) | Silver | Write failing records to quarantine table |
| Referential integrity (store ID, product ID) | Silver | Write failing records to quarantine table |
| Deduplication | Silver | Keep most recent record by load timestamp |
| Row count reconciliation (silver to gold) | Gold | Alert on variance beyond threshold |
| Revenue sanity check | Gold | Alert if total daily revenue per store is outside expected range |

---

## 8. Error handling and retries

| Scenario | Handling |
|---|---|
| Missing store file | Alert after configurable timeout. Pipeline can run with partial files if explicitly approved. Reprocessing triggered when missing file arrives. |
| File schema mismatch | Quarantine file. Alert. Do not process. Manual review required. |
| Quality check failures | Write failing records to quarantine table with reason code. Pipeline continues for valid records. |
| Pipeline stage failure | Retry up to three times with exponential backoff. Alert on persistent failure. |
| Full pipeline failure | Each layer is independently rerunnable from the previous layer. Bronze is the source of truth for full reprocessing. |

---

## 9. Observability

| Metric | Description |
|---|---|
| Files received | Count of store files received vs expected, per run |
| Rows processed | Rows ingested at bronze, silver, and gold per run |
| Quarantine row count | Number of records failing quality checks per run |
| Pipeline run duration | Total elapsed time per run |
| Pipeline status | Success / failure / partial success, with stage detail |
| Last successful run | Timestamp of last successful end-to-end run |

**Alerting:** Alert on pipeline failure, file arrival timeout, quarantine volume above threshold, and BI delivery deadline miss.

---

## 10. Security and access considerations

- The pipeline service account requires read access to the cloud storage bucket and write access to the lakehouse layers.
- Credentials should be stored in a secrets manager, not hardcoded in pipeline configuration.
- Lakehouse access for the BI and data science consumers should be managed separately from pipeline service account permissions.
- Transaction data is commercially sensitive. Apply column-level or row-level security in the gold layer as required.

---

## 11. Deployment and operations

| Property | Detail |
|---|---|
| Orchestration | Scheduled trigger after file arrival gate clears, or time-based fallback |
| Schedule | Daily, triggered when all store files have arrived or at a fallback time |
| Ownership | Designated pipeline owner responsible for alerting and reprocessing |
| Reprocessing | Reprocess from bronze by rerunning silver and gold stages for the target date |
| Documentation | Pipeline run logs retained for 90 days minimum |

---

## 12. Open questions

1. What is the acceptable fallback time if not all store files have arrived? Should the pipeline proceed with partial data or hold?
2. Who receives pipeline failure and quality alerting notifications?
3. Is there an existing orchestration platform, or does one need to be provisioned?
4. Should quarantined records be automatically retried after master data is updated, or only on manual trigger?

---

## 13. Risks and trade-offs

- **File arrival dependency:** The pipeline's reliability depends on the POS system delivering files on time. Late or missing files need a clearly defined escalation process.
- **Referential integrity failures:** If product or store master data is not kept up to date, transactions will fail referential integrity checks and be quarantined. A process for handling master data gaps is required.
- **No dedicated on-site support:** The pipeline must be self-monitoring and alert reliably. This increases the importance of observability investment upfront.
- **Deduplication adds complexity:** Upsert-based deduplication at silver adds pipeline complexity. If re-sends are very rare, a simpler approach could be considered, but the upsert pattern is the safer default given the quality requirements.
