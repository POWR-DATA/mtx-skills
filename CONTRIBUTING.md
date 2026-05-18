# Contributing to PowerData Skills

Thank you for considering a contribution to this library.

## Principles

- Follow the standard skill structure (see [templates/skill-template/](templates/skill-template/)).
- Include `SKILL.md` and `README.md` in every skill; include example files where they meaningfully aid understanding.
- Avoid sensitive, confidential, or organisation-specific information.
- Use realistic but generic examples.
- Prefer practical, opinionated guidance over vague best-practice lists.
- Avoid vendor lock-in unless the skill is clearly and explicitly vendor-oriented.
- Keep the target user and use case in mind throughout.

## Skill quality bar

A good skill should:

- Define clearly when it should be used.
- State minimum required inputs.
- Give the AI agent a structured procedure to follow, not just a goal.
- Produce a consistent, predictable output format.
- Include decision rules and practical trade-offs.
- Make assumptions explicit.
- Be useful on its own, without needing additional private context.

## File length and format

Each skill folder contains four files. Keep each file focused and purposeful:

| File | Target length | Purpose |
|---|---|---|
| `SKILL.md` | 80–150 lines | The skill definition — procedure, output format, and principles |
| `README.md` | 40–60 lines | Human-facing summary for GitHub browsing and discovery |
| `example-input.md` | 15–40 lines | Realistic input example — not a template or placeholder |
| `example-output.md` | Proportional to output | Demonstrates the full output format defined in `SKILL.md` |

If `SKILL.md` exceeds 150 lines, the skill is likely too broad. Consider splitting it into two focused skills.

All four files must be complete and free of placeholder text before submission. Do not submit files with `[Fill this in]`, bracketed examples, or incomplete sections.

## How to submit

- Submit one skill per pull request where possible.
- Include `SKILL.md` and `README.md` in every skill. Include `example-input.md` and `example-output.md` where a worked example adds meaningful value — skip them if the skill is self-explanatory or the output cannot be usefully represented in Markdown.
- Place data skills under `skills/data/`, app skills under `skills/app/`, website skills under `skills/web/`, AI skills under `skills/ai/`, and domain-specific skills under `skills/domain/`.
- Follow the folder naming convention: lowercase, hyphen-separated.
- Include YAML frontmatter at the top of `SKILL.md` (required for Skillfish compatibility — see the [skill template](templates/skill-template/SKILL.md) for the correct format).
- Write a short description in your pull request explaining the skill, the target user, and the intended use case.

> **Note:** Skill contributions go under `skills/`. The `.claude/commands/` directory contains Claude Code slash commands — repo workflow tools, not library skills. Do not add library skills there.

## Style

- Use Australian/British English where natural (modelling, standardisation, prioritisation).
- Keep headings concise.
- Avoid excessive marketing language.
- Write in plain, professional English.
