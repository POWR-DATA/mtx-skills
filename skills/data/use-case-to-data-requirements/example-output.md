# Example Output — Use Case to Data Requirements

*Generated using the Use Case to Data Requirements skill applied to the example input in `example-input.md`.*

---

## 1. Use case summary

The sales leadership team requires a structured reporting solution to track sales performance by product category, store, and region. The current approach relies on manually compiled spreadsheet exports, which are inconsistent and time-consuming to analyse. The goal is to replace this with a reliable, refreshed reporting layer that supports daily analysis and period-over-period comparison.

---

## 2. Business outcome

Enable sales directors, regional managers, and category managers to identify underperforming categories, stores, and regions quickly, compare actuals against targets, and spot trends across time periods — without manual data preparation.

---

## 3. Key questions to answer

- Which product categories are performing above or below revenue target this month?
- Which regions and stores are driving the largest variances from target?
- How does current period performance compare to the same period last year?
- What is the margin trend by category over the past 12 months?
- Which stores have shown the most significant performance changes in the last quarter?

---

## 4. Required data entities

| Entity | Key attributes |
|---|---|
| Sales transactions | Transaction ID, date, store ID, product ID, quantity, revenue, cost |
| Product catalogue | Product ID, product name, category, sub-category |
| Store master | Store ID, store name, region, format |
| Sales targets | Period (month), store ID or region, product category, target revenue |

---

## 5. Data source candidates

| Entity | Probable source |
|---|---|
| Sales transactions | Point-of-sale system |
| Product catalogue | ERP system |
| Store master | ERP system |
| Sales targets | Monthly targets spreadsheet |

---

## 6. Grain and granularity

The primary fact is at **transaction line level** (one row per product sold per transaction). Reporting aggregations will be built on top of this grain.

For target comparison, the grain is **month / store or region / product category**.

---

## 7. History requirements

- **Sales transactions:** Minimum two years of history required for trend analysis and year-over-year comparisons.
- **Product catalogue and store master:** Current state plus history of changes, to support accurate reporting against historical transactions.
- **Sales targets:** Historical targets required for the same two-year window to enable actuals vs target comparison.

---

## 8. Refresh and latency needs

- **Sales transactions:** Daily refresh. Overnight batch is acceptable.
- **Product and store master data:** Daily refresh to capture additions or changes.
- **Sales targets:** On-demand or triggered refresh when the spreadsheet is updated (monthly cadence expected).

---

## 9. Data quality considerations

| Entity | Considerations |
|---|---|
| Sales transactions | Check for duplicate transaction IDs, null product or store references, negative quantities (returns), and outlier values |
| Product catalogue | Validate product ID referential integrity against POS transactions; check for unmapped or discontinued products |
| Store master | Confirm store IDs align between ERP and POS; check for closed or renamed stores |
| Sales targets | Targets spreadsheet is manually maintained — validate for missing periods, duplicate entries, and inconsistent category naming |

---

## 10. Security and privacy considerations

- Sales transaction data is commercially sensitive. Access should be restricted by role (e.g. regional managers see their region only).
- No PII is expected in this use case, but confirm the POS system does not store loyalty or customer identifiers in the transaction data.
- Target data may be commercially sensitive and should be access-controlled accordingly.

---

## 11. Open questions

1. Does the POS system use the same product IDs and store IDs as the ERP? If not, a mapping table will be required.
2. Who owns and maintains the targets spreadsheet, and can it be replaced with a structured input process?
3. Are returns and voids captured in the POS transaction data, and should they be included or excluded from reported revenue?
4. Is margin (cost) available in the POS system, or is it derived from the product catalogue?
5. Are there any regional or category exclusions (e.g. franchise stores, clearance categories) that should be filtered?

---

## 12. Suggested next steps

- Confirm source system IDs and assess the need for a product/store mapping layer.
- Apply the **Dimensional Model Designer** skill to design the star schema for this reporting use case.
- Apply the **Medallion Architecture Designer** skill to plan the ingestion and transformation layers.
- Engage the targets spreadsheet owner to assess feasibility of a structured replacement.
