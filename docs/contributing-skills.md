# Contributing Skills

This guide is for contributors who want to create, update, or improve skills in the Matrix Skills library using Claude Code.

If you are looking for how to use skills in your own projects, see [Usage Patterns](usage-patterns.md).

---

## The `/mtx` command

The `/mtx` command is a global Claude Code slash command that automates the contributor workflow — capturing discoveries, creating new skills, updating existing ones, and checking quality before submitting a PR.

> **Global command — available in every Claude Code session.**
>
> `/mtx` is installed at `~/.claude/commands/mtx.md` on your machine. It is available in any project. The `capture` and `capture reset` actions work anywhere. The `new`, `update`, `validate`, and `review` actions require the skills repo — `/mtx` checks for this automatically and stops with a clear message if you are in the wrong project. `/mtx` is not installed by Skillfish; it must be set up manually (see below).

### Actions

Invoke `/mtx` with an action and an optional target. Omit arguments to be prompted.

| Action | Invocation | What it does |
|---|---|---|
| `capture` | `/mtx capture` | Record a discovery from the current session into `mtx-captures.md`. Works in any project. Reads session history since the last capture run to find what is new. |
| `capture reset` | `/mtx capture reset` | Archive `mtx-captures.md` and start fresh. |
| `new` | `/mtx new` | Create a new skill from scratch. Guides you through category, purpose, and inputs, then generates all four files and updates the root README. _(skills repo only)_ |
| `update` | `/mtx update <path>` | Sync all skills from a captures file — reads `mtx-captures.md` from the given project path, groups entries by skill, updates matching skills, proposes new skills for unmatched entries, and applies drift-based name review. _(skills repo only)_ |
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

Copy the command file to your global Claude Code commands directory:

```
~/.claude/commands/mtx.md       # macOS / Linux
C:\Users\<you>\.claude\commands\mtx.md   # Windows
```

Download the file from the [Matrix Skills repository](https://github.com/POWR-DATA/mtx-skills) and place it there. Once installed, `/mtx` is available in every Claude Code session on your machine.

---

## Example session

The following shows the four repo-scoped actions using a skill created from notes gathered in an external AI session. The skill is an IT managed service provider onboarding assessment. See the Cross-session workflow section below for how `/mtx capture` fits into the process before these steps.

---

**`/mtx new`** — create the skill from scratch

```
/mtx new
```

> What should this skill do, who is the target user, and which category?

```
It should guide an AI through onboarding a new business client for an IT
managed service provider — covering discovery, network and security
assessment, documentation, and tool deployment. Target user is an IT
consultant or MSP. Category: domain.
```

> Here's the plan:
> - **Skill name:** `it-client-onboarding-assessment`
> - **Folder:** `skills/domain/it-client-onboarding-assessment/`
> - **Description:** Guide an IT managed service provider through structured client discovery and onboarding assessment
> - **Target user:** IT consultant or managed service provider
> - **Key inputs:** Client size, existing environment, current tooling, security posture
> - **Key output:** Environment assessment, security baseline gaps, priority action list
>
> Confirm to proceed?

```
yes
```

> Created:
> - `skills/domain/it-client-onboarding-assessment/SKILL.md`
> - `skills/domain/it-client-onboarding-assessment/README.md`
> - `skills/domain/it-client-onboarding-assessment/example-input.md`
> - `skills/domain/it-client-onboarding-assessment/example-output.md`
>
> Modified:
> - `README.md` — added to Domain skills table

---

**`/mtx update`** — improve the skill after a follow-up session

```
/mtx update it-client-onboarding-assessment
```

> I'm looking at `it-client-onboarding-assessment` v1.0.0. What needs updating?

```
The security baseline step is too vague. It needs to cover MFA status,
patch posture, and EDR. Also want a principle about checking cyber
insurance early.
```

> Proposed changes to `SKILL.md`:
>
> 1. **Process step 4** — expand to four sub-steps: password policy audit,
>    MFA status across email and remote access, patch posture review, EDR
>    coverage confirmation
> 2. **Guiding principles** — add: "Confirm cyber insurance status and policy
>    limits before completing the assessment — coverage gaps often determine
>    which remediation items are prioritised first."
>
> Version: `1.0.0` → `1.1.0`. No changes to example files or root README needed.
> Confirm?

```
yes
```

> Modified:
> - `skills/domain/it-client-onboarding-assessment/SKILL.md` — v1.0.0 → v1.1.0

---

**`/mtx validate`** — structural check before raising a PR

```
/mtx validate it-client-onboarding-assessment
```

```
Validating: it-client-onboarding-assessment (v1.1.0)

Frontmatter
✓ name: it-client-onboarding-assessment (valid)
✓ description: one sentence, no trailing period
✓ author, version, license present
✓ version: 1.1.0 (valid semver)

SKILL.md structure
✓ All 9 required sections present
✓ Length: 118 lines (within 80–150)
✓ Attribution footer present
✓ No placeholder text found

README.md
✓ Length: 52 lines (within 40–60)
✓ Files table and attribution table present
✓ No placeholder text

example-input.md
✓ File exists, 24 lines (within 15–40)
✓ No placeholder text

example-output.md
✗ Length: 183 lines — outside expected range. The Priority action list
  section runs 60+ lines. Consider trimming or confirm the output
  complexity warrants this length.

Repository
✓ Listed in root README.md

Result: 14/15 passed. 1 warning — no blocking issues. Ready to submit.
```

---

**`/mtx review`** — content quality assessment

```
/mtx review it-client-onboarding-assessment
```

```
Reviewing: it-client-onboarding-assessment (v1.1.0)

Structural validation: 14/15 passed (1 warning — see validate output)

Strengths
- Purpose is specific: states what the skill produces, not just what it
  "helps with"
- Cyber insurance principle and "document before you change anything" are
  the kind of opinionated heuristics that make a skill genuinely useful
- Process steps are actionable and sequenced logically

Suggested improvements
- When to use: missing lifecycle position — add "Apply before any technical
  work begins; output feeds directly into the statement of work"
- Guiding principles: "understand the client's risk tolerance" is too vague;
  replace with something measurable
- Avoid section: only 2 items — consider adding failure modes from the session

Scope
Well-scoped — covers discovery only, stops before solution design. No
overlap with existing skills.
```

---

## Cross-session workflow

A common scenario: you have been working in a separate Claude session on a website, app, or client project, and you have learned something worth capturing in the skills library.

### Lightweight: use `/mtx capture` in the moment

`/mtx capture` is a global command — it works in any project session, not just the skills repo. When you discover something worth preserving, run it immediately before the context is lost.

```
/mtx capture
```

Claude infers the relevant skill from context, distils the discovery into 1–3 sentences, assigns topic tags, and appends an entry to `mtx-captures.md` in your current project root.

When you next run `/mtx update` in the skills repo, it automatically scans sibling project directories for `mtx-captures.md` files and surfaces any entries matching the skill you are updating. Captured entries are removed from the source file once applied.

### Structured: use an extraction prompt before closing a session

For more substantial changes — new process steps, redesigned output format, enough material for a new skill — ask the AI to summarise what was learned before you close the session. Use one of the extraction prompts below, paste the response into a skills repo session, then run `/mtx update` or `/mtx new`.

The `/mtx` command checks the conversation for context before asking questions. Pasting first skips the clarifying questions and goes straight to proposing edits.

```
[paste your structured summary here]
```

```
/mtx update static-website-hosting
```

### Raise a PR and merge

Once done, push your branch and open a PR. CI validates file structure and README listing automatically.

### Update your local skills with Skillfish

After merging to `main`:

```bash
npx skillfish add POWR-DATA/mtx-skills
```

---

## Extraction prompts

Use these at the end of a session in ChatGPT, Copilot, another Claude session, or any other AI tool. Paste the response into your Claude Code session before running `/mtx`.

---

**Creating a new skill** — use when a whole new process or workflow emerged:

> Before we finish, please summarise what we worked out as if writing a procedure for an AI agent to follow this same process in future. Structure your answer as:
> - **What it does** — one or two sentences on the purpose and what it produces
> - **Who would use it** — the target user, their role, and when they would reach for this
> - **What they provide** — the minimum inputs needed, noting which are optional
> - **The process** — the exact step-by-step procedure we followed, as numbered steps with sub-steps where needed
> - **Key principles** — the most important rules and decision points we discovered, especially non-obvious ones
> - **What a good result looks like** — the sections and content a useful output should contain
> - **What to avoid** — specific mistakes, wrong shortcuts, or assumptions that caused problems; name the failure mode, not just "be careful"

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
