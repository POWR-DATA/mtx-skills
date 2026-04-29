# Dimensional Model Designer

## Purpose

Design a practical star schema or dimensional model for BI and analytics reporting use cases. The output provides a structured model definition covering fact tables, dimension tables, measures, relationships, and key design decisions.

## When to use

Use this skill when the user has a reporting, dashboard, analytics, semantic model, or metric-driven requirement and needs to structure data for consumption.

Apply this skill after data requirements have been established and before physical table design or semantic model configuration begins.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Business process or use case
- Reporting questions the model must answer
- Measures and metrics required
- Dimensions needed for slicing and filtering
- Source tables or entities
- Desired grain of the fact table
- Known filters or slicers
- History requirements
- Target BI tool or semantic layer, if known

## Guiding principles

- Define the fact table grain before selecting measures. The grain is the single most important design decision.
- Facts should represent business events, transactions, periodic snapshots, or accumulating snapshots — choose the appropriate fact table type.
- Dimensions should provide descriptive context for slicing and filtering. Keep them denormalised unless there is a clear reason not to.
- Prefer clear business names over source-system field names.
- Identify conformed dimensions (dimensions shared across multiple fact tables) where they exist.
- Consider slowly changing dimensions and state the approach explicitly.
- Do not over-normalise the reporting layer. A few well-designed wide tables are more practical than a highly normalised snowflake.
- Keep semantic models understandable for business users.
- Make metric definitions explicit — including the formula, filters, and grain.
- Identify where calculated measures belong in the semantic layer rather than physical tables.
- Include modern lakehouse considerations where relevant (e.g. Delta tables, merge strategies).

## Process

1. Confirm the business process and the reporting questions the model must answer.
2. Define the fact table grain.
3. Identify the fact table type: transaction, periodic snapshot, or accumulating snapshot.
4. Select the measures based on the grain.
5. Identify the dimension tables required for each measure.
6. Design the dimension tables, noting key attributes, business keys, and surrogate keys.
7. Identify any conformed dimensions.
8. State the slowly changing dimension approach for each relevant dimension.
9. Define the relationships between fact and dimension tables.
10. Define metric calculations explicitly.
11. Note any data quality rules required to support the model.
12. Identify open questions and risks.

## Output format

1. **Model summary** — brief description of the model and its purpose
2. **Business process** — the process or use case being modelled
3. **Proposed grain** — the grain of the primary fact table
4. **Fact tables** — name, grain, type, and key measures for each fact table
5. **Dimension tables** — name, key attributes, business key, and surrogate key for each dimension
6. **Measures** — explicit definition of each measure, including formula and any filters
7. **Relationships** — fact-to-dimension relationships
8. **Slowly changing dimension approach** — SCD type and rationale for each relevant dimension
9. **Example star schema layout** — a simple diagram or table representation of the model structure
10. **Data quality rules** — key quality checks required to support the model
11. **Open questions** — unresolved design decisions
12. **Risks and trade-offs** — known risks and design compromises

## Quality checklist

- [ ] The fact table grain is clearly defined
- [ ] The fact table type is identified (transaction / snapshot / accumulating)
- [ ] All required dimensions are included
- [ ] Measures are explicitly defined, not just named
- [ ] SCD approach is stated for dimensions likely to change
- [ ] Conformed dimensions are identified
- [ ] Business-friendly names are used throughout
- [ ] Surrogate key approach is noted
- [ ] Data quality rules are included

## Avoid

- Defining measures before the grain is established
- Over-normalising the model with unnecessary snowflake hierarchies
- Using source-system field names as dimension attribute names without review
- Silently assuming SCD Type 1 (overwrite) for dimensions that require history
- Designing a dimensional model for a use case better served by a flat reporting table
- Including implementation-specific detail (physical partitioning, indexing) unless requested

## Example usage

> "Apply the Dimensional Model Designer skill to design a star schema for sales performance reporting. The business needs to analyse revenue, units sold, and margin by product category, store, region, and time period, with daily data and two years of history."
