# AGENTS.md — Working in the Matrix Skills repository

Guidance for AI coding agents (Claude Code, Cursor, Codex, Copilot, Gemini, and others) operating in this repository. This file follows the [AGENTS.md](https://agents.md) open standard and is read natively by most agents.

## Skills vs rules

This repository uses both layers of the open agent-tooling ecosystem, and they are different things:

- **Skills** (`skills/**/SKILL.md`) — reusable, portable *capabilities* an agent reaches for when relevant. This library is a collection of skills, built to the open `SKILL.md` standard.
- **Rules** (this file) — standing *conventions and constraints* for working in this repo. `AGENTS.md` is the open, cross-agent standard for this role (one file, read by 30+ tools), replacing per-tool files like `.cursor/rules`, `CLAUDE.md`, and `.github/copilot-instructions.md`.

If you are **using** a skill from this library, see [docs/users/usage-patterns.md](docs/users/usage-patterns.md). If you are **contributing** to this repo, follow the rules below.

## Repository layout

```
skills/<category>/<skill-name>/   # the skills (data, app, web, ai, domain, infra)
contribute/commands/mtx.md        # the /mtx contributor workflow command (versioned)
docs/                             # users/ (usage patterns), contributors/ (authoring guide, contributing), reference/
contribute/templates/skill-template/  # starting point for a new skill
contribute/CONTRIBUTING.md        # the full contribution standard (+ install.sh / install.ps1)
```

## Authoring rules (when creating or editing a skill)

- **Structure.** Every `SKILL.md` has frontmatter (`name`, `description`, `author`, `version`, `license`) and these sections in order: Purpose, When to use, Inputs expected, Guiding principles, Process, Output format, Quality checklist, Avoid, Example usage.
- **Naming.** The folder name must match the frontmatter `name` (lowercase, hyphen-separated). This is also required by Cursor's skills loader.
- **Length standard.** `SKILL.md` is the always-loaded instruction core: ≤150 lines healthy, 150–200 review zone, **>200 means refactor** — move bulky material (code, config, tables) into an optional `reference.md` in the same folder, or split the skill if it does more than one job. `reference.md` is loaded on demand, not line-capped, but its excerpts must be minimal and illustrative (load-bearing lines only). See [contribute/CONTRIBUTING.md](contribute/CONTRIBUTING.md) for the full standard.
- **Public-safe content.** No real usernames, repo names, app names, project refs, deployment URLs, subscription/tenant IDs, or emails. Use generic placeholders (`<your-project-ref>`).
- **Style.** Australian/British English (modelling, standardisation, prioritisation). Plain, professional, no marketing language.

## Contribution workflow

- **Skills are built from real project experience, not invented.** The path is: run `/mtx capture` during project work → run `/mtx update <path>` in this repo to route captured discoveries into skills. See [docs/contributors/contributing-skills.md](docs/contributors/contributing-skills.md).
- **Never push to `main` directly.** Branch (`feat/`, `fix/`, `docs/`), commit, push the branch, open a PR for review. Branch protection enforces this.
- **Merge with "Delete branch"** (`gh pr merge <n> --merge --delete-branch`). Merged branches are noise, and a PR stacked on another branch only retargets to `main` when its base branch is deleted at merge — otherwise it merges into the stale branch and never reaches `main`. Prefer not to stack; if you must, merge the base PR first, delete its branch, then merge the stacked one.
- **CI** validates that every skill folder has `SKILL.md` + `README.md` and is listed in the root `README.md`. Run `/mtx validate <skill>` before raising a PR.

## Pointers

- Full standard: [contribute/CONTRIBUTING.md](contribute/CONTRIBUTING.md)
- How to write a good skill: [docs/contributors/skill-authoring-guide.md](docs/contributors/skill-authoring-guide.md)
- The `/mtx` command: [contribute/commands/mtx.md](contribute/commands/mtx.md)
