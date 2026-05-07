---
name: medallion-architecture-designer
description: Design a bronze/silver/gold lakehouse data layer architecture
author: PowerData
version: 1.0.0
license: MIT
---

# Medallion Architecture Designer

## Purpose

Design a practical bronze/silver/gold data layer approach for lakehouse-style data pipelines. The output defines how data should be structured, transformed, and validated across ingestion, standardisation, and consumption layers.

## When to use

Use this skill when planning ingestion and transformation of data across structured lakehouse layers, regardless of whether the organisation uses the terms bronze/silver/gold, raw/staged/curated, or another naming pattern.

Apply this skill when designing a new data pipeline, onboarding a new source system, or reviewing an existing layered data architecture.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Source system name and type
- Source data format (structured, semi-structured, unstructured)
- Ingestion method (batch, CDC, API, streaming, file drop)
- Target consumers (BI tool, ML platform, downstream API, etc.)
- Transformation requirements
- Expected data volume
- Refresh frequency
- History and retention requirements
- Merge or upsert requirements
- Data quality expectations

## Guiding principles

- Bronze should preserve source-aligned data with minimal transformation. Capture it as received.
- Silver should standardise, clean, validate, deduplicate, and conform data to consistent standards.
- Gold should serve business-ready consumption: reporting, analytics, or ML needs.
- Not every use case needs all three layers. Apply only the layers that add value.
- Avoid transforming too much too early — over-processing at bronze reduces replayability.
- Preserve lineage and traceability across all layers.
- Make merge strategy explicit: full load, incremental, upsert, or CDC-based merge.
- Capture metadata: load timestamp, source file or API run ID, batch ID, record hash, effective dates, and source system identifiers where relevant.
- Separate technical quality checks (nulls, types, duplicates) from business rules (valid codes, referential integrity).
- Design for replayability and idempotency — rerunning a pipeline should produce the same result.
- Make retention and reprocessing assumptions explicit.
- Prefer simple layer designs unless requirements justify additional complexity.

## Process

1. Summarise the source system and ingestion scenario.
2. Identify the target consumers and their requirements.
3. Map the use case to the appropriate layers (bronze, silver, gold, or a subset).
4. Design the bronze layer: schema, format, partitioning, metadata, and load approach.
5. Design the silver layer: transformations, cleaning, validation rules, merge strategy.
6. Design the gold layer: output structure, aggregation level, and consumption format.
7. Define the metadata strategy across all layers.
8. Define the merge and change handling strategy.
9. Define data quality checks by layer.
10. Describe the end-to-end pipeline flow.
11. Note operational considerations: scheduling, monitoring, failure handling, reprocessing.
12. Capture open questions and risks.

## Output format

1. **Architecture summary** — brief overview of the proposed approach
2. **Source overview** — source system, format, volume, and ingestion method
3. **Layer mapping** — which layers are used and why
4. **Bronze design** — format, schema approach, partitioning, metadata, load strategy
5. **Silver design** — transformations, cleaning, validation, deduplication, merge strategy
6. **Gold design** — output structure, aggregation, consumption format
7. **Metadata strategy** — what metadata is captured and where
8. **Merge and change handling strategy** — full load, incremental, upsert, or CDC approach
9. **Data quality checks by layer** — technical and business rule checks per layer
10. **Pipeline flow** — end-to-end data flow summary
11. **Operational considerations** — scheduling, monitoring, failure handling, reprocessing
12. **Open questions** — unresolved design decisions
13. **Risks and trade-offs** — known risks and design compromises

## Quality checklist

- [ ] All three layers are defined or explicitly excluded with justification
- [ ] Merge strategy is stated
- [ ] Metadata fields are defined
- [ ] Data quality checks are separated by layer
- [ ] Replayability and idempotency are considered
- [ ] Retention requirements are captured
- [ ] Lineage is preserved across layers
- [ ] Operational and failure recovery considerations are included

## Avoid

- Applying heavy transformation at the bronze layer
- Silently assuming full load when incremental or CDC ingestion is more appropriate
- Merging business logic into technical quality checks
- Designing a gold layer that cannot be easily reprocessed from silver
- Over-engineering the layer design for simple use cases
- Assuming a specific platform or tool unless one has been specified

## Example usage

> "Apply the Medallion Architecture Designer skill to design a lakehouse architecture for ingesting daily sales transaction files from a point-of-sale system. The target is a cloud lakehouse. Consumers include a BI reporting layer and a data science team."
