# Contributing to Matrix Skills

Thank you for considering a contribution to this library.

## Quick start

To set up the contributor environment, run the install script **once** from the repo root:

**macOS/Linux:**
```bash
./contribute/install.sh
```

**Windows (PowerShell):**
```powershell
.\contribute\install.ps1
```

This installs the `/mtx` command globally. The full workflows are below.

> **Important — Claude Code only.** The `/mtx` command is installed into `~/.claude/commands/` and only runs in **Claude Code** (Anthropic's CLI or VS Code extension). It will **not** work in GitHub Copilot CLI, Cursor, or other agent tools — even when they're using a Claude model. In those harnesses, typing `/mtx capture` is treated as plain text and the model will improvise a summary instead of running the capture workflow (no `mtx-captures.md` is created).
>
> If you're working in a non–Claude Code environment and need to capture a session's discoveries before the context is lost, ask the agent to read `contribute/commands/mtx.md` from this repo and follow the **Capture workflow** using the current conversation as source material (skip the JSONL session-history lookup step). Then continue in Claude Code for the update workflow.

---

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

A skill folder contains four core files, plus an optional `reference.md`:

| File | Target length | Purpose |
|---|---|---|
| `SKILL.md` | 80–150 lines | The skill definition — procedure, output format, and principles |
| `README.md` | 40–60 lines | Human-facing summary for GitHub browsing and discovery |
| `example-input.md` | 5–40 lines | Realistic input example — not a template or placeholder |
| `example-output.md` | Proportional to output | Demonstrates the full output format defined in `SKILL.md` |
| `reference.md` *(optional)* | Not line-capped | Load-on-demand templates/excerpts kept out of `SKILL.md` |

### The `SKILL.md` length standard

`SKILL.md` is the **always-loaded instruction core** — it competes for the agent's attention with the user's actual task, so it must stay lean. The length standard applies to `SKILL.md` only:

| Range | Meaning | Action |
|---|---|---|
| ≤ 150 lines | Healthy | None |
| 150–200 | Review zone | Tighten, or move bulky material into `reference.md` |
| > 200 | Action zone | **Must** reference or split before merge (see below) |

This is a guideline, not a CI gate — but it is the bar reviewers hold skills to.

### Reference vs split

When a `SKILL.md` reaches the action zone, decide between two fixes:

| | **Reference** | **Split** |
|---|---|---|
| What it is | One skill, one job — bulky *material* moves to `reference.md` in the same folder | Two skills — the file is doing *more than one job* |
| Do it when | Long because of **material** (code, config, tables) | Long because of **multiple jobs** (distinct triggers/lifecycle moments) |
| The test | "Is this still one skill that happens to carry appendices?" | "Would someone ever want one of these jobs *without* the other?" → yes = split |

**Rule of thumb:** long because of material → reference; long because of multiple jobs → split.

### `reference.md` excerpts must be minimal and illustrative

`reference.md` is *not* line-capped, but it is **not a code dump**. Excerpts show the load-bearing parts only:

- Include only the lines that demonstrate the pattern or the gotcha.
- Elide boilerplate, imports, and repetition with `# ...`.
- Replace project-specific values with placeholders (`<your-project-ref>`).
- Test: "Could a competent developer reconstruct the rest from this?" If yes, cut more.
- If any single excerpt exceeds ~40 lines, question whether every line is load-bearing.

All core files must be complete and free of placeholder text before submission. Do not submit files with `[Fill this in]`, bracketed examples, or incomplete sections.

---

## How to submit

- Submit one skill per pull request where possible.
- Include `SKILL.md` and `README.md` in every skill. Include `example-input.md` and `example-output.md` where a worked example adds meaningful value — skip them if the skill is self-explanatory or the output cannot be usefully represented in Markdown.
- Place data skills under `skills/data/`, app skills under `skills/app/`, website skills under `skills/web/`, infrastructure skills under `skills/infra/`, AI skills under `skills/ai/`, and domain-specific skills under `skills/domain/`.
- Follow the folder naming convention: lowercase, hyphen-separated.
- Include YAML frontmatter at the top of `SKILL.md` (required for Skillfish compatibility — see the [skill template](templates/skill-template/SKILL.template.md) for the correct format).
- Write a short description in your pull request explaining the skill, the target user, and the intended use case.
- Merge with **Delete branch** (`gh pr merge <n> --merge --delete-branch`). A PR whose base is another feature branch only retargets to `main` if that base branch is deleted when it merges — otherwise it lands on the stale branch, not `main`. Avoid stacking PRs where you can; if you must, merge and delete the base first.

> **Note:** Skill contributions go under `skills/`. The `commands/` directory contains Claude Code slash commands — repo workflow tools, not library skills. Do not add library skills there.

## Style

- Use Australian/British English where natural (modelling, standardisation, prioritisation).
- Keep headings concise.
- Avoid excessive marketing language.
- Write in plain, professional English.

---

## Full contributor workflows

See [Contributing Skills Guide](../docs/contributors/contributing-skills.md) for detailed workflows using the `/mtx` command:

- **`/mtx capture`** — Record discoveries from any project session into `mtx-captures.md`
- **`/mtx update`** — Create new skills or update existing ones from captures
- **`/mtx validate`** — Structural checks before submitting a PR
- **`/mtx review`** — Content quality assessment
