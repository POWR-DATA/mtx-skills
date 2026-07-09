# Matrix Skills

Reusable AI agent skills for data engineering, app development, web delivery, and beyond.

Matrix Skills is a public library of structured Markdown skills designed to help AI assistants, coding agents, and practitioners apply repeatable delivery methods across a growing range of domains — from data engineering and lakehouse architecture to multi-platform app development, web deployment, and domain-specific workflows.

These skills are not just prompts. They are lightweight delivery procedures that define when to use a skill, what inputs are required, what decisions need to be made, and what a useful output should look like.

---

## Quick navigation

**I want to use skills in my projects**

Use [Skillfish](https://github.com/POWR-DATA/skillfish) to install skills into your Claude Code projects:

```bash
npx skillfish add POWR-DATA/mtx-skills
```

See [Usage Patterns](docs/users/usage-patterns.md) for detailed instructions.

---

**I want to contribute to the library**

Run the install script once:

**macOS/Linux:**
```bash
./contribute/install.sh
```

**Windows (PowerShell):**
```powershell
.\contribute\install.ps1
```

Then see [contribute/CONTRIBUTING.md](contribute/CONTRIBUTING.md) for the full workflow.

---

## Who is this for?

- Data engineers and analytics engineers
- BI developers and data architects
- Python and mobile app developers
- Web and cloud infrastructure practitioners
- AI-assisted development practitioners
- Teams wanting repeatable AI workflows across any delivery domain

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
| [Geospatial Source Database](skills/data/geospatial-source-database/) | Work with geospatial data sources (PostGIS, SQL Server, Natural Earth) and handle data-specific quirks |

### App skills

| Skill | Description |
|---|---|
| [Flet + Supabase App Framework](skills/app/flet-supabase-framework/) | Scaffold a Flet + Supabase multi-platform Python app with correct project structure and integration patterns |
| [Flet Multiplatform Build](skills/app/flet-multiplatform-build/) | Build and package Flet apps for Windows, macOS, Linux, iOS, and Android from a single codebase |
| [Flet ACA Deploy](skills/app/flet-aca-deploy/) | Deploy Flet web apps to Azure Container Apps |
| [Expo React Native App](skills/app/expo-react-native-app/) | Scaffold and configure a React Native project using Expo |
| [Expo iOS Deployment](skills/app/expo-ios-deployment/) | Build and deploy Expo apps to Apple TestFlight and the App Store |
| [EAS Build + Submit](skills/app/eas-build-submit/) | Build and submit Expo apps using EAS services |
| [App Store Listing](skills/app/app-store-listing/) | Create effective app store listings for iOS and Google Play |
| [Google Play Listing](skills/app/google-play-listing/) | Create effective Google Play Console listings |
| [App Icon Asset Generation](skills/app/app-icon-asset-generation/) | Generate app icons and adaptive icon assets for iOS and Android |
| [Supabase Edge Functions](skills/app/supabase-edge-functions/) | Deploy serverless functions to Supabase Edge Functions |
| [Supabase Auth Email](skills/app/supabase-auth-email/) | Configure Supabase transactional auth email — custom SMTP, branded templates via the Management API, and reliable confirm/reset flows |

### Web skills

| Skill | Description |
|---|---|
| [Static Website Hosting](skills/web/static-website-hosting/) | Deploy static websites using GitHub Pages, Netlify, or Vercel |
| [Website SEO and Indexing](skills/web/website-seo-and-indexing/) | Optimise website structure and content for search engine indexing |
| [Web Print PDF](skills/web/web-print-pdf/) | Produce reliable print and PDF output from an HTML page with print-specific CSS |

### Infrastructure skills

| Skill | Description |
|---|---|
| [Docker Compose Database Lab](skills/infra/docker-compose-database-lab/) | Set up local Docker Compose database environments with correct volume mounts, configuration, and network access |
| [GitHub Org Repository Setup](skills/infra/github-org-repository-setup/) | Set up a new GitHub repository in an organisation with correct access, security, and baseline branch protection |
| [Git Secret Remediation](skills/infra/git-secret-remediation/) | Remove committed secrets from Git history safely and verify remediations across local and remote repositories |

### Domain-specific skills

| Skill | Description |
|---|---|
| [Time Series Use Case Assessment](skills/domain/time-series-use-case-assessment/) | Assess whether a use case is suitable for time series analysis and select an appropriate approach |

### AI skills

| Skill | Description |
|---|---|

---

## Repository structure

```
mtx-skills/
├── README.md (this file)
├── docs/
│   ├── README.md (documentation hub)
│   ├── users/ (for skill users)
│   ├── contributors/ (for skill developers)
│   └── reference/ (background reading)
├── contribute/
│   ├── README.md (contributor setup)
│   ├── CONTRIBUTING.md (full contributor workflow)
│   ├── install.sh / install.ps1 (setup scripts)
│   ├── commands/ (Claude Code commands — /mtx)
│   └── templates/ (skill template)
├── skills/ (the skill library)
│   ├── data/
│   ├── app/
│   ├── web/
│   ├── infra/
│   ├── domain/
│   └── ai/
└── .github/ (CI and PR templates)
```

---

## Learn more

- [Roadmap](docs/reference/roadmap.md) — planned features
- [Databricks Genie Integration](docs/reference/databricks-genie-code.md) — Genie-specific patterns
