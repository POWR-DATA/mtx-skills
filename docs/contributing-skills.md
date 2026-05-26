# Contributing Skills

This guide is for contributors who want to create, update, or improve skills in the Matrix Skills library using Claude Code.

If you are looking for how to use skills in your own projects, see [Usage Patterns](usage-patterns.md).

---

## The `/mtx` command

The `/mtx` command is a global Claude Code slash command that automates the contributor workflow — capturing discoveries from any project session, and updating or validating skills in the library.

> **Global command — available in every Claude Code session.**
>
> `/mtx` is installed at `~/.claude/commands/mtx.md` on your machine. It is available in any project. The `capture` and `capture reset` actions work anywhere. The `update`, `validate`, and `review` actions require the skills repo — `/mtx` checks for this automatically and stops with a clear message if you are in the wrong project. `/mtx` is not installed by Skillfish; it must be set up manually (see below).

### Actions

Invoke `/mtx` with an action and an optional target. Omit arguments to be prompted.

| Action | Invocation | What it does |
|---|---|---|
| `capture` | `/mtx capture` | Record a discovery from the current session into `mtx-captures.md`. Works in any project. Reads session history since the last capture run to find what is new. |
| `capture reset` | `/mtx capture reset` | Archive `mtx-captures.md` and start fresh. |
| `update` | `/mtx update <path>` | Sync all skills from a captures file — reads `mtx-captures.md` from the given project path, groups entries by skill, updates matching skills, creates new skills for unmatched entries. _(skills repo only)_ |
| `update` | `/mtx update <skill or category>` | Edit a specific skill or all skills in a category. _(skills repo only)_ |
| `validate` | `/mtx validate <skill or category>` | Structural check — frontmatter, required sections, file lengths, placeholder text, attribution, root README listing. Read-only. _(skills repo only)_ |
| `review` | `/mtx review <skill or category>` | Content quality assessment — whether principles are opinionated, process steps are actionable, examples are realistic, skill is well-scoped. Read-only. _(skills repo only)_ |

**Category paths:** pass a category name to run an action across all skills in it.

```
/mtx validate web              # validates all skills under skills/web/
/mtx review data               # reviews all skills under skills/data/
/mtx update ../App_Test        # syncs all skills from App_Test/mtx-captures.md
/mtx update web                # lists web skills, asks which to update
```

### Setting up the global command

The command file is versioned in this repo at `commands/mtx.md`. Copy it to your global Claude Code commands directory:

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

Once installed, `/mtx` is available in every Claude Code session on your machine. To update it, repeat the copy after pulling the latest version of this repo.

---

## How new skills enter the library

Skills are built from real project experience — not invented from scratch. The standard path is:

1. Work on a project in any Claude Code session
2. Run `/mtx capture` when you discover something worth preserving
3. Open the skills repo and run `/mtx update <path>` — it reads the captures file, routes entries to matching skills, and creates new skills for entries that don't match anything existing

The update process handles both existing skill updates and new skill creation from the same captures file. New skills created this way are grounded in real-world discoveries rather than speculative structure.

---

## Example session

The following shows the capture-centric workflow: discoveries made in an external project session are captured, then brought into the skills repo via `/mtx update`.

---

**Working in a project session — run `/mtx capture`**

During or at the end of a session where something notable was learned:

```
/mtx capture
```

> Last capture was 2026-05-24T14:30:00. Reviewing session from that point forward.
>
> Found 3 new discoveries:
> - `[it-msp-onboarding]` — cyber insurance status should be confirmed before completing the assessment
> - `[it-msp-onboarding]` — document the existing environment before making any changes
> - `[new-skill: network-diagram-generator]` — pattern for auto-generating network diagrams from asset inventory
>
> Written to `mtx-captures.md`.

---

**Open the skills repo — run `/mtx update`**

```
/mtx update ../my-project
```

> Reading `my-project/mtx-captures.md`...
>
> **Skills to update:** it-msp-onboarding (2 entries)
> **New skills to create:** network-diagram-generator (1 entry)
>
> Proceed with all, or adjust?

```
yes
```

> **it-msp-onboarding** — updated (v1.1.0 → v1.2.0)
> - Added cyber insurance principle
> - Added "document before you change anything" principle
>
> **network-diagram-generator** — created (v1.0.0)
> - `skills/domain/network-diagram-generator/SKILL.md`
> - `skills/domain/network-diagram-generator/README.md`
> - `skills/domain/network-diagram-generator/example-input.md`
> - `skills/domain/network-diagram-generator/example-output.md`
> - Root `README.md` updated
>
> `my-project/mtx-captures.md` — all entries applied, capture-log updated.

---

**`/mtx validate`** — structural check before raising a PR

```
/mtx validate network-diagram-generator
```

```
Validating: network-diagram-generator (v1.0.0)

Frontmatter        ✓ all fields present and valid
SKILL.md structure ✓ all 9 sections present, 112 lines (within 80–150)
README.md          ✓ 48 lines (within 40–60)
example-input.md   ✓ 22 lines (within 15–40)
example-output.md  ✓ proportional to output complexity
Repository         ✓ listed in root README.md

Result: 15/15 passed. Ready to submit.
```

---

**`/mtx review`** — content quality assessment

```
/mtx review network-diagram-generator
```

```
Reviewing: network-diagram-generator (v1.0.0)

Strengths
- Purpose is specific and actionable
- Process steps are sequenced correctly
- Guiding principles encode real decision rules, not generic advice

Suggested improvements
- When to use: missing lifecycle position — add when in the project lifecycle this applies
- Avoid section: only 2 items — consider whether the session uncovered additional failure modes

Scope: well-scoped, no overlap with existing skills.
```

---

**Raise a PR and merge**

Once done, push your branch and open a PR. CI validates file structure and README listing automatically.

**Update your local skills with Skillfish**

After merging to `main`:

```bash
npx skillfish add POWR-DATA/mtx-skills
```

---

## Cross-session workflow

A common scenario: you have been working in a separate Claude session on a website, app, or client project, and you have learned something worth capturing in the skills library.

### Lightweight: use `/mtx capture` in the moment

`/mtx capture` is a global command — it works in any project session, not just the skills repo. When you discover something worth preserving, run it immediately before the context is lost.

```
/mtx capture
```

Claude reads the session history since the last capture, distils the discovery into 1–3 sentences, assigns topic tags, and appends an entry to `mtx-captures.md` in your current project root.

When you next run `/mtx update <path>` in the skills repo, it reads that file and routes entries to matching skills (or creates new ones).

### Structured: use an extraction prompt before closing a session

For more substantial changes — new process steps, redesigned output format, enough material for a new skill — ask the AI to summarise what was learned before you close the session. Use one of the extraction prompts below, paste the response into a skills repo session, then run `/mtx update`.

The `/mtx` command checks the conversation for context before asking questions. Pasting first skips the clarifying questions and goes straight to proposing edits.

```
[paste your structured summary here]
```

```
/mtx update static-website-hosting
```

---

## Extraction prompts

Use these at the end of a session in ChatGPT, Copilot, another Claude session, or any other AI tool. Paste the response into your Claude Code session before running `/mtx update`.

---

**Updating an existing skill** — use when a session improved on an existing approach:

> We've refined things during this session. Before we finish, summarise specifically what is new or different. Structure your answer as:
> - **Process steps that worked better than expected** — what changed and why it was more effective
> - **New rules or principles that emerged** — especially non-obvious ones; state each as a specific, actionable rule, not a vague guideline
> - **Failure modes and edge cases to document** — what went wrong, what assumption was incorrect, what the obvious approach misses; be specific about the mechanism, not just the outcome
> - **Output format or structure changes** — only if the way results should be presented genuinely changed
>
> Keep it focused on the delta — what is genuinely new, not a full recap. Avoid restating things that are already standard practice.

---

**Capturing failure modes** — use when a session uncovered what goes wrong:

> Before we finish, I want to capture the failure modes we encountered. Please list:
> - What approaches we tried that did not work, and the specific reason why (not just "it failed")
> - Assumptions we made that turned out to be wrong
> - Edge cases the obvious approach does not handle well
> - Anything a practitioner following this process should explicitly avoid, stated as a rule

---

**Mid-session principle capture** — use to lock in a specific rule before moving on:

> State the rule or principle we just worked out as a single, specific, opinionated sentence. Something a practitioner could apply directly without needing further context — name the condition, the action, and the reason.
