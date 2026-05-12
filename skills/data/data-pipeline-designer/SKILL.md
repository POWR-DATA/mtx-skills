---
name: data-pipeline-designer
description: Design a high-level data pipeline for source-to-target data flows
author: PowerData
version: 1.0.0
license: MIT
---

# Data Pipeline Designer

## Purpose

Design a high-level data pipeline for ingesting, transforming, validating, and delivering data from a source system to a target platform. The output is a practical pipeline design covering ingestion pattern, processing flow, transformation approach, quality checks, error handling, and operational considerations.

## When to use

Use this skill when a user needs a practical pipeline design for a source-to-target data flow, regardless of technology stack.

Apply this skill after data requirements have been established and alongside or after a medallion architecture design where applicable.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Source system name and type
- Target platform
- Data type and format
- Expected volume
- Frequency and latency expectations
- Authentication or access method
- Transformation requirements
- Data quality expectations
- Downstream consumers
- Operational constraints or preferences

## Guiding principles

- Start with source and consumer requirements. The pipeline exists to serve consumers, not the other way around.
- Choose batch, streaming, or hybrid deliberately — do not default to streaming unless the latency requirement justifies it.
- Design for idempotency — rerunning the pipeline should produce the same result.
- Include retry and failure handling from the start, not as an afterthought.
- Include observability and logging. A pipeline without monitoring is not production-ready.
- Capture metadata and lineage at every layer.
- Define data quality checks explicitly. Separate technical checks from business rules.
- Separate ingestion, transformation, and consumption concerns.
- Avoid premature over-engineering. A simple, reliable pipeline is better than a complex one.
- Identify operational ownership — who is responsible for this pipeline in production?
- Make deployment, monitoring, and failure recovery part of the design, not an assumption.

## Process

1. Confirm the source system, data format, and target platform.
2. Confirm consumer requirements and latency expectations.
3. Recommend the ingestion pattern (batch, streaming, CDC, API polling, file-based).
4. Define the processing flow from source to target.
5. Define the transformation approach at each stage.
6. Define the storage or layering approach.
7. Define data quality and validation checks.
8. Define error handling, retry logic, and failure recovery.
9. Define observability requirements: logging, alerting, and metrics.
10. Address security and access considerations.
11. Define deployment and operational requirements.
12. Capture open questions and risks.

## Output format

1. **Pipeline summary** — brief description of the pipeline, its source, target, and purpose
2. **Source and target** — source system details and target platform details
3. **Recommended ingestion pattern** — batch, streaming, CDC, API, or file-based, with rationale
4. **Processing flow** — end-to-end data flow from source to target
5. **Transformation approach** — what transformations occur and where
6. **Storage and layering approach** — how data is stored and organised in the target platform
7. **Data quality and validation** — checks applied and at what stage
8. **Error handling and retries** — failure modes and recovery approach
9. **Observability** — logging, alerting, and pipeline health metrics
10. **Security and access considerations** — credentials, encryption, access controls
11. **Deployment and operations** — scheduling, orchestration, ownership, and support considerations
12. **Open questions** — unresolved design decisions
13. **Risks and trade-offs** — known risks and design compromises

## Quality checklist

- [ ] Ingestion pattern is chosen deliberately with rationale
- [ ] Idempotency is addressed
- [ ] Data quality checks are defined
- [ ] Error handling and retry logic is included
- [ ] Observability and alerting is included
- [ ] Security and access considerations are addressed
- [ ] Operational ownership is identified
- [ ] Failure recovery approach is stated

## Avoid

- Defaulting to streaming when batch is sufficient
- Designing a pipeline without error handling or retry logic
- Omitting observability and monitoring
- Assuming credentials and access are already solved
- Over-engineering the pipeline for the stated requirements
- Designing transformation logic without confirming the consumer's requirements
- Treating deployment and operations as out of scope

## Example usage

> "Apply the Data Pipeline Designer skill to design a pipeline for ingesting daily CSV sales files from a cloud storage location into a cloud lakehouse. The target consumers are a BI reporting layer and a data science team."

---

_Source: This skill is sourced from the [PowerData Skills](https://github.com/POWR-DATA/skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
