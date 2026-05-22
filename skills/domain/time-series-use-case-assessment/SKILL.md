---
name: time-series-use-case-assessment
description: Assess time-series use cases and translate them into data ingestion and analytics requirements
author: PowerData
version: 1.0.0
license: MIT
---

# Time-Series Use Case Assessment

## Purpose

Assess a time-series data use case and translate it into structured data ingestion and analytics requirements. The output defines what signals are needed, at what frequency, from which sources, with what history and contextual data, and identifies key data quality and architectural considerations specific to time-series patterns.

## When to use

Use this skill when the business problem involves sensor data, industrial process data, historian data, IoT telemetry, operational events, or any time-dependent analysis where data is collected at regular or irregular intervals over time.

This skill should be applied before designing a time-series ingestion pipeline, analytics layer, or predictive model.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Use case description
- Assets, processes, or equipment involved
- Source systems (historians, IoT platforms, SCADA systems, databases)
- Tag or signal list, if available
- Sampling frequency (per second, per minute, hourly, event-based)
- History requirements
- Latency requirements
- Target consumers (reporting, analytics, ML model, operational dashboard)
- Analytics or reporting needs
- Known data quality issues

## Guiding principles

- Clarify whether the use case needs raw signal data, aggregated data, or event-derived data before recommending an approach.
- Capture sampling frequency and expected volume early — these drive storage and processing decisions significantly.
- Identify whether data is regularly sampled, irregularly sampled, event-based, or interpolated.
- Separate historical backfill requirements from ongoing ingestion requirements.
- Understand latency needs before recommending streaming. Most operational reporting use cases are adequately served by near-real-time or hourly batch.
- Capture tag metadata and asset contextual dimensions — time-series data without asset context has limited analytical value.
- Identify data quality concerns specific to time-series: gaps in signal, duplicate timestamps, outliers, stale values, unit changes, sensor failures, and tag decommissioning.
- Avoid assuming predictive modelling is required just because time-series data is involved. Confirm the actual use case before recommending ML approaches.
- Capture asset hierarchy and operational context where relevant (site, unit, equipment, component).
- Make batch, streaming, and hybrid trade-offs explicit.

## Process

1. Summarise the use case and confirm understanding.
2. Identify the business outcome and the decisions or actions this data will support.
3. Identify the assets, processes, or equipment involved.
4. Identify the source systems and data access method.
5. Define the signals or tags required and their sampling frequency.
6. Identify whether raw, aggregated, or event-derived data is required.
7. Capture history requirements: how far back is data needed?
8. Capture latency requirements: real-time, near-real-time, or batch?
9. Identify required contextual data (asset hierarchy, operational metadata, shift data, process parameters).
10. Identify data quality risks specific to the signal types involved.
11. Recommend a batch, streaming, or hybrid ingestion approach.
12. Define modelling and reporting considerations.
13. Outline ingestion and storage considerations.
14. Capture open questions and suggested next steps.

## Output format

1. **Use case summary** — plain-language description of the use case
2. **Business outcome** — what decision or action this data will enable
3. **Time-series data requirements** — what data is needed and at what resolution
4. **Source systems and signals** — source systems, access method, and key tags or signals
5. **Frequency, volume, and history** — sampling rate, estimated data volume, and required history depth
6. **Batch vs streaming recommendation** — recommended ingestion pattern with rationale
7. **Required contextual data** — asset hierarchy, operational metadata, and dimensional context
8. **Data quality risks** — time-series-specific quality concerns for this use case
9. **Modelling and reporting considerations** — how data should be structured for the target use case
10. **Ingestion and storage considerations** — architectural considerations for time-series at scale
11. **Open questions** — unresolved items that must be answered before design proceeds
12. **Suggested next steps** — recommended follow-on actions or skills to apply

## Quality checklist

- [ ] Sampling frequency and volume are captured
- [ ] Raw vs aggregated vs event-derived requirement is clarified
- [ ] Historical backfill vs ongoing ingestion is distinguished
- [ ] Latency requirement is specified
- [ ] Asset hierarchy and contextual dimensions are identified
- [ ] Data quality risks specific to this signal type are noted
- [ ] Batch vs streaming recommendation is justified
- [ ] Predictive modelling assumption is not made without confirmation

## Avoid

- Recommending streaming when near-real-time or batch is sufficient
- Assuming predictive modelling is required just because the data is time-series
- Ignoring asset hierarchy and contextual metadata
- Treating all time-series data as uniform — sampling patterns, quality issues, and storage needs vary significantly by signal type
- Underestimating data volume from high-frequency signals
- Failing to distinguish historical backfill from ongoing ingestion requirements

## Example usage

> "Apply the Time-Series Use Case Assessment skill to the following use case: we want to monitor energy consumption across a manufacturing facility's production lines using data from electrical sub-meters, and identify anomalies and high-consumption periods."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
