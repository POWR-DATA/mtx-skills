# Skill

$ARGUMENTS

You are helping the user work with a skill in the PowerData Skills library.

---

## Before you start — verify repo context

Before doing anything else, confirm you are running inside the PowerData Skills repository by checking that a `skills/` directory exists at the project root and that `README.md` contains the skill category tables.

If those are not present, stop immediately and tell the user:

> This command must be run from within the PowerData Skills repository. It writes to `skills/`, updates the root `README.md`, and follows conventions specific to this library — it will not work from another project directory.
>
> **Correct workflow when learning from another Claude session:**
> 1. Finish your work in the other project session (website, app, etc.)
> 2. Open the PowerData Skills repo in Claude Code as a separate session
> 3. Bring your learnings across as context — paste notes, describe what changed, or summarise what you discovered
> 4. Run `/skill update <skill-name>` or `/skill new` here

Do not proceed until the repo context is confirmed.

---

## Determine the action and target

Parse `$ARGUMENTS` into two parts: **action** and **target**.

**Action** is the first word:
- `new` → **New Skill** workflow
- `update` or `edit` → **Update Skill** workflow
- `validate` or `check` → **Validate Skill** workflow
- `review` → **Review Skill** workflow
- Empty or unclear → ask the user to choose (see below)

**Target** is everything after the action word. It can be:
- A specific skill name: `update static-website-hosting`
- A category path: `validate web` or `review data` — runs the workflow across all skills in that category
- Empty: the workflow will ask which skill

**Category paths** map as follows: `web` → `skills/web/`, `data` → `skills/data/`, `app` → `skills/app/`, `ai` → `skills/ai/`, `domain` → `skills/domain/`. List all skill subdirectories found under the path and apply the workflow to each.

If action is empty or unclear, ask in a single message:

  > What would you like to do?
  > - **new** — create a new skill from scratch
  > - **update \<skill-name or category\>** — edit a skill or all skills in a category (e.g. `update web`)
  > - **validate \<skill-name or category\>** — structural check (e.g. `validate web`)
  > - **review \<skill-name or category\>** — content quality assessment (e.g. `review data`)

Do not start any workflow until the action is confirmed.

---

## New Skill workflow

### Step 1: Gather requirements

Check the current conversation for context first. If the user has already pasted a structured summary from another session, extract everything you can from it before asking any questions — only ask about what is genuinely missing. If the user has already described the skill idea in enough detail, extract:

- **Purpose** — what the skill does and what problem it solves
- **Target user** — who will use this skill
- **Category** — which skill category it belongs to
- **Key inputs** — what the user provides
- **Key output** — what the skill produces

If any of these are unclear, ask the following in a **single message**:

> 1. What should this skill do? (1–2 sentences: what problem does it solve, what does it produce?)
> 2. Who is the target user? (e.g. data engineer, AI practitioner, developer, solution architect)
> 3. Which category does it belong to?
>    - `data/` — data engineering, modelling, pipelines, lakehouse architecture
>    - `app/` — multi-platform app development and deployment
>    - `web/` — website hosting, SEO, and frontend delivery
>    - `ai/` — AI agent design, prompt engineering, LLM evaluation, RAG pipelines, agentic workflows
>    - `domain/<name>/` — industry or domain-specific (e.g. time-series, finance, retail)

If answers remain vague after one round, ask **one focused follow-up** on the specific gaps. **Maximum two rounds of questions.** Do not generate files until you have enough information to produce complete, realistic content.

### Step 2: Confirm the plan

Present a summary and ask the user to confirm or adjust:

- **Skill name:** lowercase, hyphen-separated (e.g. `ai-prompt-reviewer`)
- **Folder path:** `skills/<category>/<skill-name>/`
- **Description:** one-line description for the frontmatter
- **Target user**
- **Key inputs:** 3–5 bullet points
- **Key output**

Only proceed after confirmation.

### Step 3: Generate all four skill files

Create all four files in full. **No placeholders, no `[Fill this in]`, no bracketed examples left in place.**

#### `SKILL.md`

**Target length: 80–150 lines.** If it needs more, the skill is likely too broad.

Required YAML frontmatter:

```yaml
---
name: <skill-name>
description: <one-line description, plain English, no trailing period>
author: PowerData
version: 1.0.0
license: MIT
---
```

Frontmatter rules:
- `name`: lowercase, hyphen-separated, maximum 64 characters
- `description`: one sentence, no trailing period

Required sections in this order:

1. **Purpose** — 1–2 sentences, specific and practical
2. **When to use** — explicit triggers, lifecycle position, type of problem
3. **Inputs expected** — minimum inputs; state partial inputs are acceptable
4. **Guiding principles** — 5–10 opinionated, specific heuristics; encode decision rules and trade-offs, not generic advice
5. **Process** — numbered operating steps; a procedure, not a narrative
6. **Output format** — numbered sections defining a consistent, predictable output structure
7. **Quality checklist** — `- [ ]` items the AI applies before finalising output
8. **Avoid** — specific failure modes and things the AI must not do
9. **Example usage** — a short blockquote showing the skill in realistic context

End with:

```
---

_Source: This skill is sourced from the [PowerData Skills](https://github.com/POWR-DATA/skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
```

Write in Australian/British English (modelling, standardisation, prioritisation, organisation).

#### `README.md`

**Target length: 40–60 lines.** A discovery document, not a copy of the skill instructions.

Required structure:

```
# <Skill Display Name>

<One-line description>

## What this skill does
2–3 sentences on the practical purpose.

## When to use it
- Bullet list of specific, real-world triggers

## Example use cases
- 3–4 concrete, realistic scenarios

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use
Brief instructions for loading the skill into an AI tool.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [PowerData Skills](https://github.com/POWR-DATA/skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
```

#### `example-input.md`

**Target length: 15–40 lines.** Realistic and specific — not a template or placeholder.

#### `example-output.md`

**Target length: proportional to the skill's output complexity.** Every section from the Output format must appear. Not skeletal.

### Step 4: Update root `README.md`

Add the new skill to the correct category table:

```markdown
| [Skill Display Name](skills/<category>/<skill-name>/) | Short description matching SKILL.md frontmatter |
```

If the category has no section yet in the root `README.md`, add one following the existing pattern, placed after the last existing category section and before the Repository structure section:

```markdown
### AI skills

| Skill | Description |
|---|---|
| [Skill Name](skills/ai/<skill-name>/) | Description |
```

### Step 5: Report completion

List every file created and every file modified. Remind the user to:

1. Review the example files — they are often the first thing a reader opens on GitHub
2. Confirm the root `README.md` table entry looks correct
3. Push to a branch and open a PR — CI will validate file structure and README listing

---

## Update Skill workflow

### Step 1: Identify the skill

If the target is a specific skill name (e.g. `/skill update static-website-hosting`), use that directly.

If the target is a category (e.g. `/skill update web`), read `skills/<category>/` to list all skills present, then ask:

> Found these skills in `web/`: static-website-hosting, website-seo-and-indexing
> Which would you like to update, or update all in sequence?

If no target was given, ask which skill or category to update.

### Step 2: Read all existing files

Read `SKILL.md`, `README.md`, `example-input.md`, and `example-output.md` for the identified skill. Confirm back to the user which skill you are looking at and what version it is currently on.

### Step 3: Understand what needs changing

Check the current conversation for context first. If the user has already pasted a structured summary, notes, or description of what changed, extract the relevant changes from that and proceed directly to Step 4 without asking questions.

If the conversation contains no useful context, ask in a single message:

> What needs updating? For example:
> - A process step that is wrong or incomplete
> - A new guiding principle to add
> - Output format changes
> - Example files that no longer reflect the skill
> - A correction to the When to use or Avoid sections
>
> If you have a summary from another session, paste it here.

If answers are still vague after one round, ask one focused follow-up. **Maximum two rounds of questions.**

### Step 4: Confirm the proposed changes

Before editing anything, summarise:

- Which file(s) will change
- Exactly what will be added, removed, or reworded
- Whether example files need updating as a result

Ask the user to confirm or adjust. Only proceed after confirmation.

### Step 5: Make targeted edits

Edit only what needs changing. **Do not regenerate files from scratch.** Preserve all existing content that is still correct.

If changes to `SKILL.md` are significant (new sections, restructured output format, changed process), assess whether `example-input.md` or `example-output.md` also need updating and flag this to the user.

Do not touch the root `README.md` unless the skill's one-line description has changed — in which case update the description in the root README table to match.

### Step 6: Bump the version

Update the `version` field in `SKILL.md` frontmatter:

- Small corrections (wording, clarity, typos): increment patch — `1.0.0` → `1.0.1`
- New content (new principles, new process steps, new output sections): increment minor — `1.0.0` → `1.1.0`
- Structural overhaul (new purpose, redesigned output format): increment major — `1.0.0` → `2.0.0`

### Step 7: Report completion

List every file changed and describe what was modified. Note the old and new version number.

---

## Validate Skill workflow

Structural and mechanical check. Read-only — no file changes.

### Step 1: Identify the skill

If the target is a specific skill name (e.g. `/skill validate static-website-hosting`), validate that skill. If the target is a category (e.g. `/skill validate web`), read `skills/<category>/` to find all skills and run validation on each in sequence, presenting a combined report. If no target was given, ask which skill or category to validate.

### Step 2: Read all files

Read `SKILL.md`, `README.md`, `example-input.md`, and `example-output.md`.

### Step 3: Run the checklist

Check each item and mark as pass (✓) or fail (✗):

**Frontmatter**
- `name` field present, lowercase hyphen-separated, maximum 64 characters
- `description` field present, one sentence, no trailing period
- `author`, `version`, and `license` fields all present
- `version` follows semantic versioning (e.g. `1.0.0`)

**`SKILL.md` structure**
- All required sections present: Purpose, When to use, Inputs expected, Guiding principles, Process, Output format, Quality checklist, Avoid, Example usage
- Length within 80–150 lines (flag actual line count if outside)
- Attribution footer present at the end of the file
- No placeholder text remaining (`[Fill this in]`, bracketed examples, lorem ipsum)

**`README.md`**
- Length within 40–60 lines (flag actual line count if outside)
- Files table present
- Source and attribution table present at the bottom
- No placeholder text remaining

**`example-input.md`**
- File exists and has content
- Length within 15–40 lines (flag if outside)
- No placeholder text

**`example-output.md`**
- File exists and has content
- No placeholder text

**Repository**
- Skill path listed in root `README.md`

### Step 4: Report

Present the checklist with ✓ or ✗ for each item. For any failures, quote the specific text or line that is the issue. Conclude with a summary: how many checks passed, how many failed, and whether the skill is ready to submit.

No file changes. If failures need fixing, the user can follow up with `/skill update`.

---

## Review Skill workflow

Qualitative content review. Read-only — no file changes.

### Step 1: Identify the skill

If the target is a specific skill name (e.g. `/skill review static-website-hosting`), review that skill. If the target is a category (e.g. `/skill review web`), read `skills/<category>/` to find all skills and run the review on each in sequence, presenting a combined report. If no target was given, ask which skill or category to review.

### Step 2: Read all files

Read `SKILL.md`, `README.md`, `example-input.md`, and `example-output.md`. Note the current version and category.

### Step 3: Run structural validation first

Run the same checks as the Validate workflow. If there are structural failures, flag them clearly before proceeding — they should be fixed before a content review is meaningful.

### Step 4: Assess content quality

Evaluate each section against these criteria:

**Purpose**
- Is it specific and practical? ("Translate a business use case into structured data requirements" ✓ / "Helps with data tasks" ✗)
- Does it describe what the skill produces, not just what it does in the abstract?

**When to use**
- Does it describe a concrete trigger, not just a feature list?
- Is the lifecycle position clear (e.g. "apply before pipeline design begins")?

**Guiding principles**
- Are principles specific and opinionated, not generic advice?
- Do they encode real decision rules a practitioner would actually face?
- Count: fewer than 5 may be thin; more than 10 may indicate scope creep

**Process**
- Is each step actionable, not a vague goal?
- Could a practitioner follow this procedure without additional guidance?
- Are there implicit decision points that should be made explicit?

**Output format**
- Is the structure specific enough to produce consistent results across different runs?
- Would two different AI agents following this skill produce structurally similar output?

**Avoid**
- Are these concrete failure modes, not soft warnings?
- Do they cover the mistakes a practitioner would most commonly make with this skill?

**Example usage**
- Is the blockquote realistic? Would a real user invoke the skill this way?

**Example files**
- Does `example-input.md` feel like a real user's input, or a template?
- Does `example-output.md` demonstrate every section from the Output format?

**Scope**
- Is this skill trying to do too much? Would it be stronger as two focused skills?
- Does it overlap meaningfully with an existing skill in the library?

### Step 5: Report

Present findings in this structure:

1. **Structural validation** — pass/fail summary (reference validate results)
2. **Strengths** — what is working well and why
3. **Suggested improvements** — specific, actionable items with the section they apply to
4. **Scope assessment** — is the skill well-scoped, too broad, or overlapping with another skill?

No file changes. If the user wants to apply suggestions, follow up with `/skill update`.
