# PowerData Skills

Reusable AI skills for practical data delivery.

PowerData Skills is a public library of structured AI skills designed to help data professionals apply repeatable delivery methods using AI coding assistants and agentic tools.

These skills are not just prompts. They are lightweight operating procedures that define context, decision rules, expected inputs, and output formats for common data delivery tasks.

---

## Who is this for?

- Data engineers
- Analytics engineers
- BI developers
- Solution and data architects
- AI-assisted development practitioners
- Teams wanting repeatable AI workflows for data projects

---

## What is an AI skill?

An AI skill is a structured, reusable set of instructions for an AI assistant. It defines:

- **When to use it** — the context in which the skill applies
- **What inputs are needed** — the information to provide before starting
- **What the AI should do** — a clear operating procedure, not a vague instruction
- **What the output should look like** — a consistent, predictable structure

Skills are written in Markdown and are designed to be copied into AI tools, referenced as instructions, or loaded as context in agentic workflows.

---

## Skill categories

### Core skills

| Skill | Description |
|---|---|
| [Use Case to Data Requirements](skills/data/use-case-to-data-requirements/) | Translate a business use case into structured data requirements |
| [Dimensional Model Designer](skills/data/dimensional-model-designer/) | Design star schema and dimensional models for BI and reporting |
| [Medallion Architecture Designer](skills/data/medallion-architecture-designer/) | Design bronze/silver/gold lakehouse data layers |
| [Data Pipeline Designer](skills/data/data-pipeline-designer/) | Design high-level data pipelines for source-to-target data flows |

### Domain skills

| Skill | Description |
|---|---|
| [Time-Series Use Case Assessment](skills/domain/time-series/time-series-use-case-assessment/) | Assess time-series use cases and translate them into data requirements |

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
    roadmap.md                   # Planned additions

  templates/
    skill-template/              # Blank template for new skills

  skills/
    core/                        # Foundation skills for data delivery
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

See [docs/usage-patterns.md](docs/usage-patterns.md) for detailed guidance including Claude.ai web options, Claude Code project setup, Skillfish, and GitHub Copilot.

---

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidance.

---

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for planned additions.

---

## Disclaimer

This repository is intentionally generic and public-safe. Skills represent generalised patterns for common data delivery tasks.

Organisation-specific implementations should be created privately by extending these baseline skills with internal standards, platform constraints, naming conventions, security requirements, and governance requirements.

---

## Licence

MIT. See [LICENSE](LICENSE).
