# Contributing to Matrix Skills

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

A skill folder contains four core files, plus an optional `reference.md`:

| File | Target length | Purpose |
|---|---|---|
| `SKILL.md` | 80–150 lines | The skill definition — procedure, output format, and principles |
| `README.md` | 40–60 lines | Human-facing summary for GitHub browsing and discovery |
| `example-input.md` | 15–40 lines | Realistic input example — not a template or placeholder |
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

## Using `/mtx` to contribute

The `/mtx` Claude Code command automates the contributor workflow — capturing discoveries from any project session, and updating or validating skills in the library. It is a global command installed at `~/.claude/commands/mtx.md` — available in any project, not just this repo.

### Installing `/mtx`

The command file is versioned in this repo at [`commands/mtx.md`](commands/mtx.md). To install it:

**macOS/Linux:**
```bash
mkdir -p ~/.claude/commands
cp commands/mtx.md ~/.claude/commands/mtx.md
```

**Windows:**
```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\commands"
Copy-Item commands\mtx.md "$env:USERPROFILE\.claude\commands\mtx.md"
```

After copying, `/mtx` is available in any Claude Code session on your machine. To update it, repeat the copy after pulling the latest version of this repo.

**The standard contribution path:**

1. Work on a project in any Claude Code session
2. Run `/mtx capture` to record discoveries into `mtx-captures.md` in that project's root
3. Open the skills repo and run `/mtx update <path>` — it reads the captures file, groups entries by skill, updates matching skills, and creates new skills for entries that don't match anything existing

New skills enter the library through this capture-centric path. Skills built from real project experience are more reliable than skills written speculatively from scratch.

**Direct skill editing:**

Run `/mtx update <skill-name>` to edit a specific skill when you have relevant context in the current session or want to make a targeted improvement.

The `update`, `validate`, and `review` actions require the skills repo — `/mtx` checks for this and stops with a clear message otherwise. `/mtx` is not installed by Skillfish; see [Contributing Skills](docs/contributing-skills.md) for setup instructions.

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
