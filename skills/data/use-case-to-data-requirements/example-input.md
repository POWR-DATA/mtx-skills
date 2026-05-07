# Example Input — Use Case to Data Requirements

## Context

A retail organisation's sales leadership team wants to understand sales performance across their product catalogue and store network. They currently work from weekly spreadsheet exports and cannot compare performance across periods or drill into category-level trends.

## Input provided

**Use case name:** Sales Performance Reporting

**Business problem:** The sales leadership team does not have a reliable way to understand which product categories, stores, and regions are performing above or below target. Weekly spreadsheet exports are manually compiled and inconsistent. Comparing performance across time periods requires significant manual effort.

**Intended users:** Sales directors, regional managers, category managers

**Desired outcome:** A dashboard or report showing sales revenue, units sold, and margin by product category, store, region, and time period. Users need to compare against targets and prior periods, and filter by date range, region, store, and product category.

**Known data sources:**
- Point-of-sale system (transaction-level sales data)
- Product catalogue in the ERP system
- Store master data in the ERP system
- Sales targets maintained in a monthly spreadsheet

**Reporting needs:** Daily refresh. History of at least two years for trend analysis.

**Latency:** Daily update is acceptable. Near-real-time is not required.

**Known constraints:**
- The targets spreadsheet is manually maintained and may have gaps or inconsistencies
- Store master data in the ERP may not fully align with the point-of-sale system
- No existing data warehouse or reporting layer is in place
