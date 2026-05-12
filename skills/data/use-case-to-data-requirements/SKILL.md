---
name: use-case-to-data-requirements
description: Translate a business use case into structured data requirements
author: PowerData
version: 1.0.0
license: MIT
---

# Use Case to Data Requirements

## Purpose

Translate a business use case into structured data requirements. The output defines what data is needed, at what grain, from which sources, with what freshness and history, before any solution design begins.

## When to use

Use this skill when a stakeholder describes a business problem, analytics idea, report request, AI/ML use case, operational requirement, or product idea and the team needs to identify what data is required to support it.

Apply this skill before designing a pipeline, data model, or analytics layer.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Use case name
- Business problem or opportunity
- Intended users of the output
- Desired business outcome
- Known data sources
- Reporting or analytics needs
- Latency expectations
- History requirements
- Known constraints or limitations

## Guiding principles

- Start from the business decision or outcome, not the data source.
- Identify the grain of analysis early — what does one row in the output represent?
- Separate required data from nice-to-have data.
- Capture history, latency, refresh frequency, and retention needs explicitly.
- Identify source systems and ownership — who owns the data?
- Make assumptions explicit rather than silent.
- Avoid jumping directly to implementation or solution design.
- Translate vague intent into specific, measurable data needs.
- Keep language business-friendly where the input is business-facing.
- If inputs are incomplete, identify the most critical gaps and ask targeted follow-up questions.

## Process

1. Summarise the use case in plain language to confirm understanding.
2. Identify the core business decision or outcome the use case is designed to support.
3. Define the key questions the data must answer.
4. Identify the required data entities and their key attributes.
5. Identify candidate source systems for each data entity.
6. Define the required grain of analysis.
7. Capture history requirements: how far back is data needed, and why?
8. Capture refresh and latency needs: real-time, near-real-time, daily, weekly?
9. Identify data quality considerations for each key entity.
10. Flag security, privacy, or access control considerations.
11. List open questions that need resolution before design can proceed.
12. Suggest logical next steps.

## Output format

1. **Use case summary** — plain-language description of the use case
2. **Business outcome** — what decision or action this data will enable
3. **Key questions to answer** — the specific analytical questions the data must support
4. **Required data entities** — the core entities, objects, or measures needed
5. **Data source candidates** — probable or known source systems for each entity
6. **Grain and granularity** — what one row represents in the primary dataset
7. **History requirements** — how far back data must go and why
8. **Refresh and latency needs** — required freshness and delivery cadence
9. **Data quality considerations** — known or expected quality issues per entity
10. **Security and privacy considerations** — access controls, PII, data sensitivity
11. **Open questions** — unresolved items that must be answered before design begins
12. **Suggested next steps** — recommended follow-on actions or skills to apply

## Quality checklist

- [ ] The grain has been defined
- [ ] Required vs nice-to-have data is distinguished
- [ ] Source systems have been identified for each key entity
- [ ] History requirements are explicit
- [ ] Refresh cadence is specified
- [ ] Assumptions are stated
- [ ] Open questions are captured
- [ ] Security or privacy considerations have been noted where relevant

## Avoid

- Jumping to pipeline or model design before requirements are clear
- Treating vague stakeholder statements as complete requirements
- Silently assuming data is available without confirming source systems
- Designing for the data that exists rather than the data that is needed
- Conflating what the business wants to see with what data is required
- Over-engineering the requirements document — keep it practical and actionable

## Example usage

> "Apply the Use Case to Data Requirements skill to the following use case: our sales team wants to understand which product categories are driving revenue decline in the past quarter, broken down by region and customer segment."

---

_Source: This skill is sourced from the [PowerData Skills](https://github.com/POWR-DATA/skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
