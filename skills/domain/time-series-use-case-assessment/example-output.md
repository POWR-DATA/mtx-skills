# Example Output — Time-Series Use Case Assessment

*Generated using the Time-Series Use Case Assessment skill applied to the example input in `example-input.md`.*

---

## 1. Use case summary

Monitor electrical energy consumption across a manufacturing facility using sub-meter data from an industrial energy monitoring historian. The goal is to understand consumption patterns by production line, shift, and time period, identify anomalies and waste, and support energy cost reduction and sustainability reporting.

---

## 2. Business outcome

Enable the facility manager and operations team to identify which production lines, shifts, and time periods are consuming the most energy, detect unusual consumption events, benchmark energy intensity against production output, and report energy consumption for finance and sustainability purposes.

---

## 3. Time-series data requirements

| Requirement | Detail |
|---|---|
| Primary signals | Active power (kW) per sub-meter — 12 meters |
| Supporting signals | Reactive power (kVAR), facility-level total power |
| Contextual signal | Production line status (running/idle/stopped) from SCADA |
| Data type | Regularly sampled (1-minute intervals) for energy; event-based for SCADA status |
| Required resolution | 1-minute raw data for anomaly detection; hourly and daily aggregates for reporting |
| Derived measures | Energy consumed (kWh, derived from kW and time interval), energy intensity (kWh per unit produced, if production output data is available) |

---

## 4. Source systems and signals

| Source | Signals | Access method |
|---|---|---|
| Industrial energy monitoring historian | Active power (kW), reactive power (kVAR), facility total power — 12 meters | REST API |
| SCADA system | Production line status (running/idle/stopped) — 5 lines | To be confirmed |

**Key signals list:**

| Tag | Description | Meter location |
|---|---|---|
| PWR_L1_KW | Active power — Line 1 | Production Line 1 |
| PWR_L2_KW | Active power — Line 2 | Production Line 2 |
| PWR_L3_KW | Active power — Line 3 | Production Line 3 |
| PWR_L4_KW | Active power — Line 4 | Production Line 4 |
| PWR_L5_KW | Active power — Line 5 | Production Line 5 |
| PWR_HVAC_KW | Active power — HVAC | Utilities building |
| PWR_CA_KW | Active power — Compressed air | Utilities building |
| PWR_FACILITY_KW | Facility total active power | Main meter |
| (+ reactive power equivalents and remaining sub-meters) | | |

---

## 5. Frequency, volume, and history

| Property | Detail |
|---|---|
| Sampling frequency | 1 minute per tag |
| Number of tags | ~16–20 (12 power meters x 2 signals + facility total + SCADA status) |
| Rows per day (raw) | ~28,800 rows/day (20 tags x 1,440 minutes) |
| Rows per year (raw) | ~10.5 million rows |
| Required history | 24 months (preferred), 12 months (minimum) |
| Estimated data volume | ~21 million rows for 24-month history |
| Aggregated data | Hourly and daily aggregates will significantly reduce query data volume |

---

## 6. Batch vs streaming recommendation

**Recommendation: Near-real-time batch (hourly polling) for operational dashboards, daily batch for management and sustainability reporting.**

**Rationale:**
- The stated latency requirement is hourly for operational dashboards and daily for management reporting.
- Streaming is not required and would add significant architectural complexity without delivering additional value.
- An hourly API poll from the historian captures 60 readings per tag per run, which is efficient and low-risk.
- Historical backfill should be performed as a one-time batch load before the ongoing pipeline begins.

---

## 7. Required contextual data

| Contextual data | Description | Source |
|---|---|---|
| Asset hierarchy | Site, area (production, utilities), production line, meter | To be defined — may require manual mapping |
| Shift schedule | Start and end times for each shift, by production line | Likely maintained in a spreadsheet or HR/scheduling system |
| Production output | Units or tonnes produced per line per shift | ERP or MES system (to be confirmed) |
| Meter metadata | Meter ID, location, rated capacity, calibration date | Energy monitoring system or manual register |
| Calendar/date | Date, time, day of week, shift, public holidays | Standard date dimension |

> Note: Asset hierarchy and shift schedule data are critical for the core reporting use case. Without them, consumption cannot be attributed to specific lines or time periods meaningfully.

---

## 8. Data quality risks

| Risk | Description | Recommended handling |
|---|---|---|
| Zero readings | Known calibration issue producing zero values | Flag as suspect. Do not include in consumption calculations unless confirmed valid. Alert on sustained zero readings. |
| Negative values | Known calibration issue | Flag and quarantine. Investigate cause before use. |
| Gaps in signal | SCADA offline periods produce gaps in status data | Record as unknown status. Do not interpolate status without confirmation. |
| Stale values | Historian may repeat the last known value during communication loss | Detect using duplicate timestamp or flat-line detection over configurable windows. |
| Meter calibration drift | Calibration changes affect absolute values over time | Record calibration event dates. Flag data before and after calibration changes as potentially inconsistent. |
| Clock skew | Sub-meters may have small timestamp offsets | Normalise timestamps to a consistent reference on ingest. |
| Missing meters | Not all meters may have complete history for the full 24-month period | Document coverage per meter. Exclude periods with known data gaps from trend comparisons. |

---

## 9. Modelling and reporting considerations

- **Aggregation strategy:** Store raw 1-minute data in bronze/silver. Materialise hourly and daily aggregates in gold for reporting performance. Do not force all reporting to query raw data.
- **Consumption calculation:** kWh = kW x (interval in hours). For 1-minute data: kWh = kW / 60. Apply consistently across all tags.
- **Line status join:** Join production line status from SCADA to energy data by timestamp to enable running/idle energy split. Handle gaps in SCADA data explicitly.
- **Energy intensity:** kWh per unit produced is a valuable metric but requires production output data from ERP or MES. Confirm availability early.
- **Anomaly detection:** For the initial phase, flag readings more than N standard deviations from the rolling mean for each tag. Rule-based anomaly detection before committing to ML models.
- **Reporting grain:** Operational dashboard at 15-minute or hourly grain. Management reporting at daily and monthly grain.

---

## 10. Ingestion and storage considerations

- **API polling:** Hourly API poll from the historian REST API. Pull 60-minute window of readings per tag per call.
- **Historical backfill:** One-time bulk extraction of 24 months of history before the live pipeline begins. Confirm API supports date-range queries.
- **Storage format:** Raw data in Parquet (bronze). Delta or equivalent ACID format for silver (upsert on tag + timestamp). Aggregated tables in gold.
- **Partitioning:** Partition raw data by date. Partition aggregated tables by date and optionally by meter or production line.
- **Tag catalogue:** Maintain a tag metadata table as a dimension: tag ID, description, asset location, engineering unit, data type, active status.
- **Volume management:** 1-minute data for 24 months is manageable (~21M rows). Consider whether sub-minute data will be required in the future and design storage accordingly.

---

## 11. Open questions

1. Is production output (units or tonnes per line per shift) available from an ERP or MES system? This is required for energy intensity reporting.
2. How is the shift schedule maintained, and can it be accessed programmatically?
3. Does the SCADA system support API access for status data, or is a different extraction method required?
4. Are calibration event dates recorded for the sub-meters? These are needed to flag potentially inconsistent historical data.
5. Are there any meters currently offline or decommissioned that may create gaps in historical data?
6. What is the target platform for the reporting layer? (Cloud BI tool, operational dashboard platform, or other?)

---

## 12. Suggested next steps

- Confirm production output and shift schedule data availability before finalising the reporting scope.
- Obtain the full tag list and metadata from the energy monitoring system.
- Apply the **Medallion Architecture Designer** skill to design the bronze/silver/gold layer structure for time-series ingestion.
- Apply the **Data Pipeline Designer** skill to design the API polling pipeline from the historian.
- Define the tag catalogue as a reference dimension alongside the asset hierarchy.
