# Skill Authoring Guide

This guide explains how to write a high-quality skill for this library.

---

## What makes a good skill?

A skill is not a prompt. It is a lightweight delivery procedure for an AI agent. A good skill reduces ambiguity, enforces consistent output, and encodes practical trade-offs so the user does not have to make them all themselves.

---

## Structure

Every skill must begin with YAML frontmatter, followed by the standard sections:

```
---
name: skill-name
description: One-line description of what this skill does
author: Your name or organisation
version: 1.0.0
license: MIT
---

# Skill Name

## Purpose
## When to use
## Inputs expected
## Guiding principles
## Process
## Output format
## Quality checklist
## Avoid
## Example usage
```

The frontmatter is required for [Skillfish](https://github.com/knoxgraeme/skillfish) compatibility, which allows users to install skills across multiple AI agents in a single command.

**Frontmatter field rules:**
- `name` — lowercase, hyphen-separated, no spaces, maximum 64 characters (e.g. `dimensional-model-designer`)
- `description` — one sentence, plain English
- `version` — use semantic versioning (`1.0.0`)
- `license` — use `MIT` unless you have a specific reason not to

Use the [skill template](../templates/skill-template/SKILL.md) as your starting point.

---

## Guidance per section

### Purpose

One to two sentences. What does this skill do? Be specific. Avoid vague language like "helps with data tasks."

### When to use

Be explicit. Describe the trigger — when should someone reach for this skill? Include context about the type of work, the user's position in the delivery lifecycle, and what problem they are trying to solve.

### Inputs expected

List the minimum information an AI agent needs to produce useful output. State that partial inputs are acceptable, and that the AI should identify gaps and ask structured follow-up questions where needed.

Do not require exhaustive inputs. Real-world users will often arrive with incomplete context.

### Guiding principles

This is the most important section. Encode your opinionated, practical heuristics here.

- Be specific. "Define the grain before selecting measures" is good. "Follow best practices" is not.
- Include decision rules: what to do when inputs are ambiguous, incomplete, or conflicting.
- Capture the trade-offs practitioners actually face.
- Keep principles focused. Five strong principles are better than fifteen weak ones.

### Process

Step-by-step procedure the AI should follow. Keep it ordered and practical. This is not a narrative — it is an operating procedure.

### Output format

Define a consistent structure. Use numbered sections or a clear heading pattern. This ensures outputs are predictable and comparable across runs.

### Quality checklist

A short list of checks the AI should apply before finalising the output. This helps catch common omissions.

### Avoid

Things the AI should not do. This is where you encode common failure modes — over-engineering, skipping the grain, jumping to implementation before understanding requirements, hallucinating source systems, and so on.

### Example usage

A short illustrative prompt. This does not need to be a full worked example — just enough to show the skill in context.

---

## Public-safe content

All skills in this repository should be public-safe. This means:

- No internal company names, system names, or platform details.
- No confidential architecture decisions.
- No real customer examples or data.
- No commercially sensitive implementation patterns.

Use realistic but generic examples. A skill about designing a retail star schema can reference "a point-of-sale system" without naming a real company or internal ERP.

If you want to extend a baseline skill with organisation-specific context — naming conventions, platform rules, governance requirements, security constraints — do that privately.

---

## Making assumptions explicit

A good skill makes assumptions visible. If the skill assumes that the target platform is a lakehouse, say so. If the skill assumes CDC-based ingestion by default, say so. Users should be able to evaluate whether the skill's assumptions are appropriate for their context.

---

## Attribution guidance

Keep attribution lightweight and unobtrusive.

Each `SKILL.md` file should remain focused on the skill itself. Do not add heavy front matter or detailed attribution metadata to the top of the file. Instead, add a small source footer at the very bottom:

```
---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
```

Each skill `README.md` can include a slightly more structured footer at the bottom:

```
---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
```

Avoid repeating promotional links throughout the skill body. Attribution should be clear, useful and unobtrusive.

---

## Discoverability guidance

When creating or updating a skill, write the opening sections so they are clear to both humans and search engines.

Keep this lightweight. Do not keyword-stuff or write marketing copy. The goal is simply to make each skill understandable when viewed on GitHub or discovered through search.

Each skill README should include:

- A clear H1 title using the skill name
- A one-sentence summary that explains the practical purpose of the skill
- A short "What this skill does" section that naturally includes the relevant domain terms
- A "When to use it" section that describes the real-world scenarios where the skill applies
- A few example use cases using plain language

Use specific, natural terms where relevant: data engineering, analytics engineering, data modelling, data pipeline design, lakehouse architecture, semantic modelling, time-series data, operational data, multi-platform app development, mobile app deployment, Android, iOS, Azure Container Apps, static website hosting, web deployment, SEO, AI-assisted development. If a term does not naturally describe the skill, leave it out.

---

## Common mistakes to avoid

- Writing a skill that is just a list of questions, not a procedure.
- Encoding so many decision points that the skill becomes unusable in practice.
- Being too generic to produce useful output.
- Being too specific to a particular tool or vendor without making that explicit.
- Duplicating content between `SKILL.md` and `README.md`.
- Adding example files to every skill without considering whether they add value — example files are optional; include them when a worked example meaningfully aids understanding.
