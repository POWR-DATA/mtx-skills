# Roadmap

This document describes the planned development of the Matrix Skills library.

---

## V1 — Foundation (complete)

- Core skill scaffolds for common data delivery patterns
- Consistent skill template and file structure
- Initial documentation: skill authoring guide, usage patterns
- First domain-specific example: time-series use case assessment
- Public-safe, ready-to-use baseline skills

---

## V2 — App skills and domain expansion (current)

Multi-platform Python app development skills:

- Flet + Supabase App Framework — project scaffolding and integration patterns
- Flet Multi-Platform Build — Android, iOS, and web Docker CI/CD pipelines
- Flet ACA Deploy — Azure Container Apps deployment with WebSocket and GHCR guidance
- App Icon Asset Generation — production icon sets from an approved high-resolution logo

Web skills (`skills/web/`):

- Static Website Hosting — Azure Static Web Apps with custom domains, DNS, Bicep IaC, and GitHub Actions
- Website SEO and Indexing — canonical URLs, sitemap.xml, robots.txt, and Google Search Console setup

AI skills (`skills/ai/`):

- Category established; first skills in development
- `/skill` Claude Code slash command added — creates new skills or updates existing ones interactively, following contribution conventions

---

## V3 — Data skill depth and domain packs

- Additional worked examples for each data skill
- Test prompts for evaluating skill quality
- AI evaluation checklist for reviewing skill output
- Extensions for reporting and semantic model patterns
- Additional coverage of BI and metric layer design

Domain-specific skill packs:

- Time-series and industrial data patterns
- ERP and transactional data ingestion
- API-sourced data ingestion patterns
- Operational reporting patterns
- AI/ML readiness assessment

---

## V4 — Private extension guidance

- Guidance for creating private implementations of public skills
- Patterns for tailoring baseline skills into client-specific delivery accelerators
- Documentation on overlaying organisation-specific context: naming conventions, platform rules, governance, security
- Team workflow integration guidance

---

## Contributions

Contributions that advance any roadmap item are welcome. See [CONTRIBUTING.md](../CONTRIBUTING.md).
