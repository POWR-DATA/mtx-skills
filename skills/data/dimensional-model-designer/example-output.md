# Example Output — Dimensional Model Designer

*Generated using the Dimensional Model Designer skill applied to the example input in `example-input.md`.*

---

## 1. Model summary

A transaction-grain star schema for retail sales performance reporting. The model supports analysis of revenue, units sold, cost, and margin by product, store, region, and time period, with period-over-period comparison and target variance reporting.

---

## 2. Business process

Retail sales transactions — capturing product sales at the point of sale across all stores.

---

## 3. Proposed grain

One row per transaction line item: a single product sold within a single transaction at a single store on a single date.

---

## 4. Fact tables

### fact_sales

| Column | Type | Description |
|---|---|---|
| transaction_line_key | Surrogate key | Fact table primary key |
| date_key | Foreign key | Links to dim_date |
| product_key | Foreign key | Links to dim_product |
| store_key | Foreign key | Links to dim_store |
| transaction_id | Natural key | Source transaction identifier |
| quantity | Integer | Units sold |
| revenue | Decimal | Sales revenue (gross) |
| cost | Decimal | Cost of goods sold |
| margin | Decimal | Revenue minus cost (derived) |

> Note: Margin can be stored physically or calculated in the semantic layer. Prefer the semantic layer unless query performance requires pre-calculation.

---

## 5. Dimension tables

### dim_date

| Column | Description |
|---|---|
| date_key | Surrogate key (integer, YYYYMMDD format) |
| date | Calendar date |
| day_of_week | Day name |
| week_number | ISO week number |
| month_number | Month (1–12) |
| month_name | Month name |
| quarter | Quarter (Q1–Q4) |
| year | Calendar year |
| is_weekend | Boolean |
| fiscal_period | Fiscal period, if applicable |

### dim_product

| Column | Description |
|---|---|
| product_key | Surrogate key |
| product_id | Source system natural key |
| product_name | Product display name |
| sub_category | Product sub-category |
| category | Product category |
| brand | Brand, if available |
| is_active | Current active status |
| effective_from | SCD effective start date |
| effective_to | SCD effective end date |

### dim_store

| Column | Description |
|---|---|
| store_key | Surrogate key |
| store_id | Source system natural key |
| store_name | Store display name |
| store_format | Store format (e.g. large format, convenience) |
| region | Geographic region |
| state | State or territory |
| is_active | Current active status |
| effective_from | SCD effective start date |
| effective_to | SCD effective end date |

---

## 6. Measures

| Measure | Definition |
|---|---|
| Revenue | Sum of `fact_sales.revenue` |
| Units sold | Sum of `fact_sales.quantity` |
| Cost | Sum of `fact_sales.cost` |
| Gross margin | Sum of `fact_sales.margin` (or Revenue minus Cost) |
| Margin % | Gross margin / Revenue |
| Revenue vs prior year | Revenue for current period / Revenue for same period prior year |
| Revenue vs target | Revenue / Target revenue (requires target fact or separate comparison logic) |

---

## 7. Relationships

| Fact table | Dimension | Join key |
|---|---|---|
| fact_sales | dim_date | date_key |
| fact_sales | dim_product | product_key |
| fact_sales | dim_store | store_key |

All relationships are many-to-one from the fact table to the dimension.

---

## 8. Slowly changing dimension approach

| Dimension | Approach | Rationale |
|---|---|---|
| dim_product | SCD Type 2 | Product category and name may change. History should be preserved so historical sales report against the category at the time of sale. |
| dim_store | SCD Type 2 | Stores may be renamed, rebranded, or reassigned to a different region. History should be preserved. |
| dim_date | Not applicable | Date is immutable. |

---

## 9. Example star schema layout

```
                  dim_date
                     |
dim_product --- fact_sales --- dim_store
```

One central fact table with three dimension tables. Clean star schema — no snowflake hierarchies required. Category and region hierarchies are embedded within their respective dimension tables.

---

## 10. Data quality rules

- `fact_sales.revenue` must not be null or negative (returns should be handled separately or flagged)
- `fact_sales.product_key` must resolve to an active or historical product in `dim_product`
- `fact_sales.store_key` must resolve to a valid store in `dim_store`
- `fact_sales.date_key` must fall within the supported date range
- No duplicate transaction line keys in `fact_sales`

---

## 11. Open questions

1. Should returns and voids be included in `fact_sales` or handled in a separate fact table?
2. Is a target comparison required in the same model? If so, a `fact_sales_target` table at month/category/region grain will be needed.
3. Is fiscal calendar alignment required, or is standard calendar sufficient?
4. Does the organisation require a sales channel dimension (in-store, online, wholesale)?

---

## 12. Risks and trade-offs

- **SCD Type 2 complexity:** Adds implementation overhead but is necessary for accurate historical reporting. If the team is not ready for SCD Type 2, SCD Type 1 (overwrite) can be used initially with a clear plan to migrate.
- **Target comparison grain mismatch:** Targets are at month/category/region grain, while the fact table is at transaction level. Comparison logic will need to aggregate facts before comparing to targets, either in the semantic layer or via a separate target fact table.
- **Margin data availability:** If cost is not available in the POS system, margin calculations will require a product cost lookup from the product catalogue, which may introduce complexity and latency.
