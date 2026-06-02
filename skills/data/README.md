# Data Skills

Foundation skills for common data delivery tasks.

These skills cover the most frequently needed patterns in data engineering and analytics delivery. They are designed to be used in sequence — the output of one skill is often the natural input for the next.

## Skills

| Skill | Description | Typical next skill |
|---|---|---|
| [Use Case to Data Requirements](use-case-to-data-requirements/) | Translate a business use case into structured data requirements | Dimensional Model Designer or Medallion Architecture Designer |
| [Dimensional Model Designer](dimensional-model-designer/) | Design a star schema or dimensional model for BI and reporting | Medallion Architecture Designer or Data Pipeline Designer |
| [Medallion Architecture Designer](medallion-architecture-designer/) | Design bronze/silver/gold lakehouse data layers | Data Pipeline Designer |
| [Data Pipeline Designer](data-pipeline-designer/) | Design a high-level source-to-target data pipeline | — |
| [Geospatial Source Database](geospatial-source-database/) | Work with geospatial data sources (PostGIS, SQL Server, Natural Earth) and handle data-specific quirks | — |

## Suggested delivery sequence

For a typical analytics or reporting use case, apply the skills in this order:

```
Use Case to Data Requirements
    -> Dimensional Model Designer
        -> Medallion Architecture Designer
            -> Data Pipeline Designer
```

Not every use case needs every skill. A simple reporting request may go straight to the Dimensional Model Designer. A pure ingestion task may start at the Medallion Architecture Designer or Data Pipeline Designer.

## Adding a new data skill

Use the [skill template](../../contribute/templates/skill-template/) as your starting point. See [CONTRIBUTING.md](../../contribute/CONTRIBUTING.md) for submission guidance.
