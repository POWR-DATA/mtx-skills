# Example Input — Dimensional Model Designer

## Context

Continuing from the Sales Performance Reporting use case. Data requirements have been established. The team now needs a dimensional model design to support the reporting layer.

## Input provided

**Business process:** Retail sales transactions

**Reporting questions the model must answer:**
- What is total revenue, units sold, and margin by product category, store, region, and time period?
- How does current period performance compare to the same period last year?
- Which stores and categories are above or below target?
- What is the trend in margin percentage by category over the past 12 months?

**Measures required:** Revenue (sales amount), units sold, cost, margin (revenue minus cost), margin percentage

**Dimensions for slicing and filtering:** Date, product (including category and sub-category), store (including region and store format), sales channel

**Source entities:**
- Sales transaction lines (POS system)
- Product catalogue (ERP)
- Store master (ERP)
- Date/calendar reference

**Desired grain:** One row per transaction line (one product per transaction)

**History:** Two years

**Target tool:** Cloud-hosted BI semantic layer (tool-agnostic)
