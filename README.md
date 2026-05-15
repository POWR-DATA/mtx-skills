# PowerData Skills

Reusable AI agent skills for practical data, analytics and architecture delivery.

PowerData Skills is a public library of structured Markdown skills designed to help AI assistants, coding agents and data professionals apply repeatable delivery methods across data engineering, analytics engineering, data modelling, lakehouse architecture and operational data use cases.

These skills are not just prompts. They are lightweight delivery procedures that define when to use a skill, what inputs are required, what decisions need to be made, and what a useful output should look like.

---

## Who is this for?

- Data engineers
- Analytics engineers
- BI developers
- Solution and data architects
- AI-assisted development practitioners
- Teams wanting repeatable AI workflows for data projects

---

## What is an AI agent skill?

An AI agent skill is a structured, reusable instruction set for an AI assistant or coding agent. It defines:

- **When to use it** — the context in which the skill applies
- **What inputs are needed** — the information to provide before starting
- **What the AI should do** — a clear operating procedure, not a vague instruction
- **What the output should look like** — a consistent, predictable structure

Skills are written in Markdown and are designed to be copied into AI tools, referenced as instructions, or loaded as context in agentic workflows.

---

## Skill categories

### Data skills

| Skill | Description |
|---|---|
| [Use Case to Data Requirements](skills/data/use-case-to-data-requirements/) | Translate a business use case into structured data requirements |
| [Dimensional Model Designer](skills/data/dimensional-model-designer/) | Design star schema and dimensional models for BI and reporting |
| [Medallion Architecture Designer](skills/data/medallion-architecture-designer/) | Design bronze/silver/gold lakehouse data layers |
| [Data Pipeline Designer](skills/data/data-pipeline-designer/) | Design high-level data pipelines for source-to-target data flows |

### App skills

| Skill | Description |
|---|---|
| [Flet + Supabase App Framework](skills/app/flet-supabase-framework/) | Scaffold a Flet + Supabase multi-platform Python app with correct project structure and integration patterns |
| [Flet Multi-Platform Build](skills/app/flet-multiplatform-build/) | Configure Android, iOS, and web Docker build pipelines for a Flet app with CI/CD |
| [Flet ACA Deploy](skills/app/flet-aca-deploy/) | Deploy a Flet web app to Azure Container Apps |
| [App Icon Asset Generation](skills/app/app-icon-asset-generation/) | Generate a consistent application icon asset set from an approved high-resolution logo |

### Domain skills

| Skill | Description |
|---|---|
| [Time-Series Use Case Assessment](skills/domain/time-series-use-case-assessment/) | Assess time-series use cases and translate them into data requirements |
| [Static Website Hosting](skills/domain/static-website-hosting/) | Plan and deploy a static website on Azure Static Web Apps with custom domains, DNS, IaC, and CI/CD |
| [Website SEO and Indexing](skills/domain/website-seo-and-indexing/) | Prepare a static website for search engine indexing and submit it to Google Search Console |

---

## Repository structure

```
skills/
  README.md
  LICENSE
  CONTRIBUTING.md
  .gitignore

  docs/
    skill-authoring-guide.md     # How to write a good skill
    usage-patterns.md            # How to use skills across AI tools
    databricks-genie-code.md     # Using skills with Databricks Genie Code
    roadmap.md                   # Planned additions

  templates/
    skill-template/              # Blank template for new skills

  skills/
    data/                        # Foundation skills for data delivery
    app/                         # Skills for multi-platform app development
    domain/                      # Domain-specific skill packs
```

---

## How to use these skills

Skills are plain Markdown files. There is no installation required. You load them into your AI tool by pasting or referencing the skill content.

### Quickest way — install with Skillfish

[Skillfish](https://github.com/knoxgraeme/skillfish) is a CLI tool that installs skills into every AI coding agent on your machine in one command:

```bash
npx skillfish add POWR-DATA/skills
```

This works with Claude Code, Cursor, Windsurf, GitHub Copilot, Gemini CLI, and 30+ other agents.

### Manual usage

**Claude.ai (web):** Paste this into a new conversation:

```
I have a set of reusable skills here:
https://github.com/POWR-DATA/skills

Please read the skills, summarise what is available, and use them
automatically when relevant in this conversation. Confirm once loaded.
```

**Claude Code:** Copy a skill into your project and reference it directly:

```bash
mkdir -p .claude/skills
cp -r /path/to/skills/skills/data/dimensional-model-designer .claude/skills/
```

Then in Claude Code: `"Apply the dimensional model designer skill to this use case."`

**Any other AI tool:** Open a `SKILL.md` file, copy the content, and paste it as instructions into your tool of choice.

For full installation and usage guidance across all supported tools, see the [Documentation](#documentation) section below.

---

## Documentation

| Document | Description |
|---|---|
| [docs/usage-patterns.md](docs/usage-patterns.md) | How to use skills across Claude, Cursor, Skillfish, GitHub Copilot, and other tools |
| [docs/databricks-genie-code.md](docs/databricks-genie-code.md) | Installing and using skills with Databricks Genie Code |
| [docs/skill-authoring-guide.md](docs/skill-authoring-guide.md) | How to write a well-structured skill |
| [docs/roadmap.md](docs/roadmap.md) | Planned additions to the library |

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidance.

---

## Disclaimer

This repository is intentionally generic and public-safe. Skills represent generalised patterns for common data delivery tasks.

Organisation-specific implementations should be created privately by extending these baseline skills with internal standards, platform constraints, naming conventions, security requirements, and governance requirements.

---

## Maintained by

PowerData Skills is maintained by [PowerData](https://powrdata.com.au).

For more context about the skills library, visit the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills).

---

## Licence

MIT. See [LICENSE](LICENSE).
