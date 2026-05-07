# Example Output — Medallion Architecture Designer

*Generated using the Medallion Architecture Designer skill applied to the example input in `example-input.md`.*

---

## 1. Architecture summary

A three-layer medallion architecture is appropriate for this use case. Daily CSV files from the POS system are landed in bronze, standardised and deduplicated in silver, and modelled into a consumption-ready reporting layer in gold. All three layers are required given the data quality obligations and the dual consumer requirements (BI and data science).

---

## 2. Source overview

| Property | Detail |
|---|---|
| Source | Point-of-sale system |
| Format | Structured CSV, one file per store per day |
| Delivery | Overnight file drop to cloud storage |
| Volume | ~2 million transaction lines per day |
| Ingestion | Daily batch |
| Re-send handling | Occasional re-sends — upsert required |

---

## 3. Layer mapping

| Layer | Used | Rationale |
|---|---|---|
| Bronze | Yes | Land raw files as received. Preserve source data for replayability and audit. |
| Silver | Yes | Standardise, deduplicate, validate, and enrich transactions before consumption. |
| Gold | Yes | Serve the dimensional model for BI and a flattened feature table for data science. |

---

## 4. Bronze design

**Purpose:** Land raw source data with minimal transformation.

| Property | Design decision |
|---|---|
| Format | Parquet (converted from CSV on ingest for efficient storage and querying) |
| Partitioning | Partitioned by `load_date` (the date the file was processed) |
| Schema | Source columns preserved as-is. No field renaming or data type casting at this layer. |
| Load strategy | Append-only. Each daily file creates a new partition. Never overwrite or delete raw data. |
| Metadata added | `source_file_name`, `load_timestamp`, `store_id` (derived from filename) |
| Retention | Two years plus one additional year for replay buffer (three years total) |

---

## 5. Silver design

**Purpose:** Standardise, clean, validate, and enrich transactions.

| Property | Design decision |
|---|---|
| Format | Delta (or equivalent ACID-capable lakehouse table format) |
| Partitioning | Partitioned by `transaction_date` |
| Load strategy | Upsert (merge) by `transaction_line_id`. Handles re-sends and deduplication. |
| Transformations | Standardise all date fields to ISO 8601. Cast revenue and cost to consistent decimal type. Derive `margin = revenue - cost`. |
| Enrichment | Join product master and store master to resolve product and store identifiers. |
| Deduplication | Deduplicate on `transaction_line_id` before merge. Keep the most recent record by `load_timestamp`. |
| Metadata added | `silver_load_timestamp`, `is_valid` (boolean), `validation_failure_reason` |
| Retention | Two years |

---

## 6. Gold design

**Purpose:** Serve business-ready consumption layers.

### Gold — BI reporting layer

| Property | Design decision |
|---|---|
| Structure | Dimensional model (fact_sales + dimension tables) as defined in the Dimensional Model Designer output |
| Load strategy | Incremental load from silver. Full refresh of dimension tables. SCD Type 2 for product and store dimensions. |
| Format | Delta table |
| Partitioning | fact_sales partitioned by `transaction_date` |

### Gold — data science feature table

| Property | Design decision |
|---|---|
| Structure | Flat, denormalised table with transaction-level attributes plus enriched fields |
| Load strategy | Daily incremental append from silver |
| Format | Delta table or Parquet, depending on ML platform preference |
| Contents | Transaction ID, date, product ID, category, store ID, region, quantity, revenue, cost, margin |

---

## 7. Metadata strategy

| Metadata field | Layer | Description |
|---|---|---|
| `source_file_name` | Bronze | Original source filename |
| `load_timestamp` | Bronze, Silver | When the record was loaded |
| `store_id` | Bronze | Derived from filename on ingest |
| `silver_load_timestamp` | Silver | When the record was processed to silver |
| `is_valid` | Silver | Whether the record passed all quality checks |
| `validation_failure_reason` | Silver | Description of any quality failure |

---

## 8. Merge and change handling strategy

| Layer | Strategy |
|---|---|
| Bronze | Append-only. No merges. |
| Silver | Upsert (merge) on `transaction_line_id`. Handles daily re-sends. Deduplication applied before merge. |
| Gold (fact) | Incremental append for new transactions. SCD Type 2 merge for dimension tables. |

---

## 9. Data quality checks by layer

### Bronze
- File arrival check: confirm expected number of store files received before processing
- Row count check: compare row count per file to previous day's file for the same store (alert on significant variance)
- Schema validation: confirm expected columns are present

### Silver
- Null checks: `transaction_line_id`, `transaction_date`, `store_id`, `product_id`, `revenue` must not be null
- Type validation: `revenue`, `cost`, and `quantity` must be numeric
- Referential integrity: `store_id` must resolve to a known store; `product_id` must resolve to a known product
- Duplicate check: `transaction_line_id` must be unique after merge
- Date format validation: all dates successfully parsed to ISO 8601

### Gold
- Row count reconciliation: silver-to-gold row counts must align within expected tolerance
- Measure sanity checks: total daily revenue must fall within expected range (configurable per store)
- Dimension coverage: all products and stores in fact table must have a matching dimension record

---

## 10. Pipeline flow

```
Cloud storage (CSV files)
    -> Bronze (Parquet, append, partitioned by load_date)
        -> Silver (Delta, upsert on transaction_line_id, partitioned by transaction_date)
            -> Gold — BI layer (Delta, dimensional model, SCD Type 2 dimensions)
            -> Gold — Feature table (Delta/Parquet, flat enriched table)
```

---

## 11. Operational considerations

- **Scheduling:** Daily batch, triggered after all store files have arrived (file arrival check as a dependency gate).
- **Failure handling:** Each layer should be independently rerunnable. A failure at silver should not re-process bronze. Failed records should be written to a quarantine table with failure reason.
- **Reprocessing:** Bronze is the source of truth for reprocessing. Silver and gold can be rebuilt from bronze at any time.
- **Alerting:** Alert on file arrival failures, quality check failures, and row count anomalies.
- **Data lineage:** Record source file name and load timestamp at bronze. Carry `source_file_name` and `load_timestamp` through to silver for traceability.

---

## 12. Open questions

1. Is there a master data management process for product and store data, or will bronze/silver need to handle master data gaps?
2. What is the acceptable latency for the BI layer? Does the pipeline need to complete before business hours begin?
3. Are there any stores with known data quality issues that require special handling?
4. Should the data science feature table include only validated records, or all silver records including those that failed quality checks?

---

## 13. Risks and trade-offs

- **Re-send handling adds complexity:** Upsert logic is more complex than a simple append. If re-sends are rare and can be handled manually, a simpler append-with-deduplication approach may be acceptable initially.
- **Enrichment join failures:** If a `product_id` or `store_id` does not resolve in the master data, the transaction will fail the referential integrity check. The team needs a process for handling unmapped identifiers.
- **Dual gold consumers:** The BI and data science gold tables have different structural requirements. Maintaining two separate gold outputs adds pipeline complexity. This is appropriate given the different consumer needs, but should be reviewed if requirements converge.
