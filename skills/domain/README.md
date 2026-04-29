# Domain Skills

Domain-specific skills extending the core library.

These skills address patterns that arise in particular industries, data types, or problem domains. They are more specialised than the core skills and are designed to complement them — a domain skill typically feeds into one or more core skills once the domain-specific assessment is complete.

## Domains

| Domain | Description |
|---|---|
| [Time-Series](time-series/) | Skills for sensor, historian, IoT, and industrial time-series data |

## Relationship to core skills

Domain skills are not replacements for core skills. They handle the domain-specific assessment and requirements work that general-purpose core skills do not fully address. Once a domain skill has been applied, the outputs feed naturally into the core skills.

For example:

```
Time-Series Use Case Assessment (domain)
    -> Medallion Architecture Designer (core)
        -> Data Pipeline Designer (core)
```

## Adding a new domain

Create a folder under `skills/domain/` named after the domain (lowercase, hyphen-separated). Add a `README.md` for the domain and at least one skill following the standard structure.

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for submission guidance.
