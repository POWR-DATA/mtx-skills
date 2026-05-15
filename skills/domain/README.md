# Domain Skills

Domain-specific skills extending the core library.

These skills address patterns that arise in particular industries, data types, or problem domains. They are more specialised than the core skills and are designed to complement them — a domain skill typically feeds into one or more core skills once the domain-specific assessment is complete.

## Skills in this folder

| Skill | Description |
|---|---|
| [Time-Series Use Case Assessment](time-series-use-case-assessment/) | Assess time-series use cases and translate them into data ingestion and analytics requirements |
| [Static Website Hosting](static-website-hosting/) | Plan and deploy a static website on Azure Static Web Apps with custom domains, DNS, IaC, and CI/CD |
| [Website SEO and Indexing](website-seo-and-indexing/) | Prepare a static website for search engine indexing and submit it to Google Search Console |

## Relationship to core skills

Domain skills are not replacements for core skills. They handle the domain-specific assessment and requirements work that general-purpose core skills do not fully address. Once a domain skill has been applied, the outputs feed naturally into the core skills.

For example:

```
Time-Series Use Case Assessment (domain)
    -> Medallion Architecture Designer (core)
        -> Data Pipeline Designer (core)
```

## Adding a new skill

Create a folder directly under `skills/domain/` named after the skill (lowercase, hyphen-separated). Add a `SKILL.md` and `README.md` following the standard structure.

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for submission guidance.
