# Contributing Skills

This guide is for contributors who want to create, update, or improve skills in the PowerData Skills library using Claude Code.

If you are looking for how to use skills in your own projects, see [Usage Patterns](usage-patterns.md).

---

## The `/skill` command

The `/skill` command is a Claude Code slash command that automates the contributor workflow — creating new skills, updating existing ones, and checking quality before submitting a PR.

> **Claude Code only — and only within this repo.**
>
> `/skill` writes to `skills/`, updates the root `README.md`, and follows conventions specific to this library. It must be run with Claude Code opened in the skills repo root. It will not work from another project directory. It is not installed by Skillfish.

### Actions

Invoke `/skill` with an action and an optional skill name or category path. Omit arguments to be prompted.

| Action | Invocation | What it does |
|---|---|---|
| `new` | `/skill new` | Create a new skill from scratch. Guides you through category, purpose, and inputs, then generates all four files and updates the root README. |
| `update` | `/skill update <skill or category>` | Edit a skill or all skills in a category. Reads current files, asks what needs changing, makes targeted edits, and bumps the version. |
| `validate` | `/skill validate <skill or category>` | Structural check — frontmatter, required sections, file lengths, placeholder text, attribution, root README listing. Read-only. |
| `review` | `/skill review <skill or category>` | Content quality assessment — whether principles are opinionated, process steps are actionable, examples are realistic, skill is well-scoped. Read-only. |

**Category paths:** pass a category name to run an action across all skills in it.

```
/skill validate web          # validates all skills under skills/web/
/skill review data           # reviews all skills under skills/data/
/skill update web            # lists web skills, asks which to update
```

`new` and `update` support up to two rounds of clarifying questions before generating anything. `validate` and `review` are read-only and make no file changes.

The full procedure for each action is in [`.claude/commands/skill.md`](../.claude/commands/skill.md).

---

## Example session

The following shows all four actions using a skill created from notes gathered in an external AI session. The skill is an IT managed service provider onboarding assessment.

---

**`/skill new`** — create the skill from scratch

```
/skill new
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

**`/skill update`** — improve the skill after a follow-up session

```
/skill update it-client-onboarding-assessment
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

**`/skill validate`** — structural check before raising a PR

```
/skill validate it-client-onboarding-assessment
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

**`/skill review`** — content quality assessment

```
/skill review it-client-onboarding-assessment
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

A common scenario: you have been working in a separate session (ChatGPT, Copilot, another Claude session) on a website, app, or client project, and you have learned something worth capturing in the skills library. You cannot run `/skill` from that other session.

**1. Finish your work in the other session**

Note what you learned — a better process step, a new guiding principle, a failure mode, or enough new material for a new skill.

**2. Use an extraction prompt before closing the session**

Ask the AI in the other session to summarise what was learned in a structured way. Use one of the prompts below.

**3. Open the skills repo in Claude Code**

Open a separate Claude Code session in the PowerData Skills repository.

**4. Paste the summary first, then run the command**

The `/skill` command checks the conversation for context before asking questions. Pasting first skips the clarifying questions and goes straight to proposing edits.

```
[paste your structured summary here]
```

```
/skill update static-website-hosting
```

If you prefer the interactive flow, run the command first — it will ask what needs updating and you can paste then.

**5. Raise a PR and merge**

Once done, push your branch and open a PR. CI validates file structure and README listing automatically.

**6. Update your local skills with Skillfish**

After merging to `main`:

```bash
npx skillfish add POWR-DATA/skills
```

---

## Extraction prompts

Use these at the end of a session in ChatGPT, Copilot, another Claude session, or any other AI tool. Paste the response into your Claude Code session before running `/skill`.

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
