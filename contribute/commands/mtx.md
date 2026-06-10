# MTX

$ARGUMENTS

You are helping the user work with the Matrix Skills library.

---

## Determine the action and target

Parse `$ARGUMENTS` into two parts: **action** and **target**.

**Action** is the first word:
- `update` or `edit` → **Update Skill** workflow _(requires skills repo)_
- `validate` or `check` → **Validate Skill** workflow _(requires skills repo)_
- `review` → **Review Skill** workflow _(requires skills repo)_
- `capture` → **Capture** workflow _(works in any project)_
- `capture reset` → **Capture Reset** workflow _(works in any project)_
- Empty or unclear → ask the user to choose (see below)

**Target** is everything after the action word (not applicable to `capture`). For `update`, the target determines the mode:

- A **path** (contains `/`, `\`, or starts with `.`) → **capture-centric mode**: read `mtx-captures.md` from that location and drive all updates from its contents (e.g. `update ../App_Test` or `update ../App_Test/mtx-captures.md`)
- A **skill name** → **skill-centric mode**: update that specific skill (e.g. `update static-website-hosting`)
- A **category path** → run skill-centric mode across all skills in that category (e.g. `update web`)
- Empty → ask whether to provide a captures file path or a skill name

For `validate` and `review`, the target is always a skill name or category path.

**Category paths** map as follows: `web` → `skills/web/`, `data` → `skills/data/`, `app` → `skills/app/`, `ai` → `skills/ai/`, `domain` → `skills/domain/`, `infra` → `skills/infra/`. List all skill subdirectories found under the path and apply the workflow to each.

If action is empty or unclear, ask in a single message:

  > What would you like to do?
  > - **update \<path\>** — sync all skills from a captures file (e.g. `update ../App_Test`) _(run from skills repo)_
  > - **update \<skill-name or category\>** — edit a specific skill (e.g. `update web`) _(run from skills repo)_
  > - **validate \<skill-name or category\>** — structural check (e.g. `validate web`) _(run from skills repo)_
  > - **review \<skill-name or category\>** — content quality assessment (e.g. `review data`) _(run from skills repo)_
  > - **capture** — record a discovery from this session for later incorporation into a skill _(works in any project)_

Do not start any workflow until the action is confirmed.

---

## Verify repo context (for update, validate, review only)

**Skip this section entirely if the action is `capture` or `capture reset`.** For all other actions, confirm you are running inside the Matrix Skills repository.

For all other actions, confirm you are running inside the Matrix Skills repository by checking that a `skills/` directory exists at the project root and that `README.md` contains the skill category tables.

If those are not present, stop immediately and tell the user:

> This action must be run from within the Matrix Skills repository. It writes to `skills/`, updates the root `README.md`, and follows conventions specific to this library — it will not work from another project directory.
>
> **To capture a discovery from this session for later use:**
> Run `/mtx capture` — this works in any project and saves your discovery to `mtx-captures.md` here. When you next open the skills repo, `/mtx update` will automatically find and apply it.
>
> **To run skill workflows:**
> 1. Open the Matrix Skills repo in Claude Code as a separate session
> 2. Bring your learnings across as context — paste notes, describe what changed, or summarise what you discovered
> 3. Run `/mtx update <skill-name>` there

Do not proceed until the repo context is confirmed.

---

## Example content — use generic placeholders, never real values

_(Applies to the update workflow and the create skill procedure.)_

All example files (`example-input.md`, `example-output.md`) and any code snippets in `SKILL.md` must use generic placeholders in place of anything specific to a real deployment, person, or project. The skills library is public — no identifying information should appear in any file.

**Always replace with a placeholder:**
- Usernames and account handles (e.g. `stevenpower83` → `<your-username>`)
- Real repository names (e.g. `App_Test` → `<your-repo>`)
- Real app names tied to an app under development (use a fictional name like `GardenTrack` or `TrackMyPlants` instead)
- Real Supabase project refs (e.g. `https://xyzabc.supabase.co` → `https://<your-project-ref>.supabase.co`)
- Real Azure resource names, ACA environment IDs, or deployment URLs (e.g. `myapp.mangofield-818b0a7d.australiaeast.azurecontainerapps.io` → `<your-app>.<env-id>.australiaeast.azurecontainerapps.io`)
- Azure subscription IDs, tenant IDs, client IDs
- Email addresses
- Any domain, URL, or identifier tied to a real private project

**Acceptable in examples:**
- Fictional app names that do not match a real app being developed (e.g. `GardenTrack`, `TrackMyPlants`, `myapp`)
- Generic org names (e.g. `myorg`)
- Public company domains when documenting that company's own publicly-visible site (e.g. `powrdata.com.au`)
- Platform and region names that are not identifying (e.g. `australiaeast`, `ghcr.io`, `australiaeast.azurecontainerapps.io`)
- `<placeholder>` syntax for values the user must supply

This rule applies when creating new skills and when updating existing ones — scan all example and code content before finalising any file.

---

## Create skill procedure

This procedure is called internally by the Update Skill workflow when a `[new-skill: <name>]` group is confirmed in the plan. It is not a user-invocable action. New skills enter the library through the capture-centric update path — work on a project, run `/mtx capture`, then run `/mtx update <path>` in the skills repo.

The skill name, category, and source entries are determined by the Update workflow's plan step before this procedure begins. Start directly at file generation.

### Generate the skill files

Create the four core files in full — `SKILL.md`, `README.md`, `example-input.md`, `example-output.md` — plus a `reference.md` if `SKILL.md` would otherwise exceed the length standard (see below). **No placeholders, no `[Fill this in]`, no bracketed examples left in place.**

#### `SKILL.md`

**Target length: 80–150 lines** (always-loaded instruction core). 150–200 is the review zone; over 200 you **must** reference or split before finishing — long because of *material* (code, config) → move it to `reference.md`; long because of *multiple jobs* → split into separate skills. See CONTRIBUTING.md for the full standard.

If a `reference.md` is warranted, keep its excerpts minimal and illustrative — load-bearing lines only, boilerplate elided with `# ...`, placeholders for project-specific values, and add a `reference.md` row to the skill's README files table.

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

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
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
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
```

#### `example-input.md`

**Target length: 5–40 lines.** Realistic and specific — not a template or placeholder.

#### `example-output.md`

**Target length: proportional to the skill's output complexity.** Every section from the Output format must appear. Not skeletal.

### Update root `README.md`

Add the new skill to the correct category table:

```markdown
| [Skill Display Name](skills/<category>/<skill-name>/) | Short description matching SKILL.md frontmatter |
```

If the category has no section yet, add one after the last existing category section and before the Repository structure section, following the existing pattern.

---

## Update Skill workflow

There are two modes depending on the target. Determine the mode first, then follow the appropriate path below.

---

### Capture-centric mode — `/mtx update <path>`

Use when the target is a path to a project directory or `mtx-captures.md` file. Reads the captures file and drives all updates from its contents.

#### Step 1: Read the captures file

Resolve the path:

- **If a file path to `mtx-captures.md` was given** → read that single file.
- **If a directory was given** → search it **recursively** for *all* `mtx-captures.md` files beneath it (e.g. one per project subfolder), not just one directly inside the given directory. On Windows use the PowerShell tool (`Get-ChildItem <path> -Filter mtx-captures.md -Recurse`); on macOS/Linux use the Bash tool (`find <path> -name mtx-captures.md`).
  - **Multiple found** → list them, tell the user which projects have pending captures, and process them **all** in this run. Treat every file's entries as one combined pool grouped by skill tag.
  - **One found** → proceed with it.
  - **None found** → tell the user no captures files exist under that path and stop.

Read the full content of every captures file found. Ignore `[capture-log]` entries.

Group all remaining entries by skill tag across all files. Track which file each entry came from so the entry lifecycle in Step 4 writes deletions and re-tags back to the correct source file.

#### Step 2: Assess each group

For each skill tag group:

**Name review** — after applying updates, read the full skill body and assess whether the name still accurately describes what the skill actually covers. This is drift detection, not a per-run suggestion — stay silent unless the evidence is clear.

- **Name is accurate** → say nothing, proceed
- **Emerging drift** (content is trending toward something more specific, but the name is still broadly correct) → mention it once, softly, no action required: _"Worth noting — content is trending toward Google Play specifically. No action needed yet."_
- **Clear mismatch** (the bulk of the skill body now consistently describes something more specific than the name implies, visible across the current content after multiple rounds of updates) → surface a concrete suggestion with two options:

  > The skill now consistently covers Google Play Console setup and listing. Suggest renaming to `google-play-listing` — keeps scope tight and leaves room for a separate Apple skill later. **Do it now**, or **flag for later** (no action, just noted)?

  Default to **flag for later**. "Do it now" is a non-trivial operation: it renames the skill folder, updates the frontmatter `name` field, updates the root `README.md` table entry, and checks for any cross-references. Only proceed if the user explicitly confirms.

Name review is especially important for `new-skill` candidates — the tag name was a first guess at capture time and may need refinement. For existing skills, the threshold for surfacing a suggestion should be higher — consistent, visible drift across the full skill body, not just one round of new content.

**Skill match** — determine whether the tag matches an existing skill in `skills/`:
- Matches an existing skill → will update it
- Tagged `new-skill: <suggested-name>` or no match found → will propose creating a new skill

**Category fit** (for new skills only) — assess whether the proposed skill fits an existing category or requires a new one:

- **Existing category is a clear fit** (e.g., a data design skill belongs in `data/`, a multi-platform app skill belongs in `app/`) → note the category, proceed
- **Skill could fit multiple categories** (e.g., infrastructure setup used by both data and app developers) → present the options:

  > **docker-compose-database-lab** could fit:
  > - **app/** — developers building apps need local databases
  > - **data/** — data engineers use Docker Compose for local infrastructure
  > - **infra/** (new) — encapsulate infrastructure and DevOps skills separately
  >
  > Which category, or create new? (Rationale: _infrastructure skills are operationally distinct from design skills in data/ and building skills in app/._)

- **No existing category is appropriate** → propose a new category with a short rationale:

  > **devops-ci-cd** (new category) — Docker Compose setup, CI/CD pipelines, container orchestration. _Why new: these are operational skills, distinct from application building (app/), design (data/), or domain-specific work (domain/)._

Present the category decision as part of the plan in Step 3. Do not create skill files until the user confirms category placement.

#### Step 3: Present the plan

Present a single consolidated plan before touching anything:

> **Skills to update:** flet-multiplatform-build (4 entries), flet-supabase-framework (3 entries)
> **New skills to create:** google-play-listing (6 entries — renamed from `app-store-listing`, scope narrowed to Google Play)
> **Categories:** google-play-listing → `app/` (fits existing app delivery skills)
> **Name suggestions:** none
>
> Proceed with all, or adjust?

If the user adjusts (e.g. skips a skill, changes a name, disputes a category placement), update the plan and confirm before proceeding. **Do not create any files or run commits until the user has explicitly approved the plan including category decisions.**

#### Step 4: Execute in sequence

**Capture entries are authoritative.** Each entry was produced in a session with full context — far more than is available during an update run. Do not fact-check, reword, or correct the technical content of an entry. Apply it as written. Your job is routing (which skill does this belong to?) and structural integration (which section does it fit in, how does it connect to existing content?) — not accuracy review.

For each skill in the confirmed plan, apply the entry lifecycle:

**Applied** — entry adds new information not already in the skill → apply it to the skill verbatim (or structurally integrated without changing its technical meaning), then delete the entry from the captures file. After updating SKILL.md, check README.md, example-input.md, and example-output.md for consistency — if the update affects the skill's purpose, description, process, or output format, update the affected supporting files in the same run. Do not flag for later.

**Already covered** — entry describes something already present in the skill → delete the entry. No skill change needed.

**Mistagged** — entry does not belong to this skill but belongs to another existing skill → re-tag the entry in the captures file. In capture-centric mode, process it in the same run when that skill's group is reached.

**New territory** — entry does not fit this skill and does not match any existing skill → re-tag to `[new-skill: suggested-name]` in the captures file and include it in the new skill group for this run.

**Tentative entries** (prefixed `~`) — flag these to the user before applying. They need confirmation before being treated as applied.

For new skills: gather all entries for that group and run the Create skill procedure using them as source material, with the confirmed name and category.

#### Step 5: Bump versions

For each updated skill, increment the version per the versioning rules (see skill-centric mode Step 6).

#### Step 6: Refresh the skills catalog

After all skill updates are complete, regenerate `<user-home>/.claude/mtx-catalog.md`. Read the frontmatter `description` from each `SKILL.md` found under `skills/*/` (all category subdirectories). Write the catalog in this format:

```markdown
# MTX Skills Catalog
_Last refreshed: YYYY-MM-DDTHH:MM:SS_

## <category>/
- <skill-name>: <description from SKILL.md frontmatter>
```

Group skills by category folder. Use the correct user-home path for the platform (Windows: `C:\Users\<username>\.claude\`, macOS/Linux: `~/.claude/`). This file is read by the capture workflow in other projects to identify existing skills before routing discoveries.

#### Step 7: Report

List every skill updated, every skill created, and the final state of the captures file (entries remaining, entries deleted).

---

### Skill-centric mode — `/mtx update <skill-name>`

Use when the target is a specific skill name or category. Focused update for known skills.

#### Step 1: Identify the skill

If the target is a skill name, use it directly. If it is a category (e.g. `update web`), list all skills in that category and ask which to update or whether to update all in sequence.

If no target was given, ask: provide a captures file path (for capture-centric mode) or a skill name?

#### Step 2: Read all existing files

Read `SKILL.md`, `README.md`, `example-input.md`, and `example-output.md`. Confirm the skill name and current version.

#### Step 3: Check for captures

Scan for `mtx-captures.md` files in sibling directories of this repo (`../*/mtx-captures.md`). Extract entries whose skill tag matches this skill name.

If matching entries are found:

> Found captured discoveries for `<skill-name>` in `<project>/mtx-captures.md`:
> - [entry summary]
>
> These will be used as source material. Anything to add or override?

Flag tentative entries (`~`) and ask the user to confirm before applying them.

If no captures are found, check the current conversation for context. If neither is present, ask what needs updating (one question, maximum two rounds).

#### Step 4: Confirm the proposed changes

Summarise before editing:
- Which file(s) will change
- Exactly what will be added, removed, or reworded
- Whether example files need updating

Ask the user to confirm or adjust. Only proceed after confirmation.

#### Step 5: Make targeted edits

**Capture entries are authoritative.** Do not fact-check, reword, or correct the technical content of capture entries — the capture was produced with full session context. Apply the entry as written. Your role is structural integration: deciding which section the entry belongs in and how to connect it to existing content, not evaluating whether the content is accurate.

Edit only what needs changing. Do not regenerate files from scratch. Preserve all existing content that is still correct.

After updating SKILL.md, always check README.md, example-input.md, and example-output.md for consistency. If the update affects purpose, description, process, or output format — update the affected supporting files in the same run. If the skill was renamed, update the README.md header and description and any references within example files. Do not flag for later — update now.

Only touch the root `README.md` if the skill's one-line description or name has changed.

After applying edits, run the name review: read the full updated skill body and assess whether the skill name still accurately describes what the skill covers. Apply the same drift detection and thresholds as in capture-centric mode — stay silent unless drift is clear, and always default to "flag for later" rather than renaming automatically.

#### Step 6: Bump the version

- Small corrections (wording, clarity, typos): patch — `1.0.0` → `1.0.1`
- New content (new principles, steps, output sections): minor — `1.0.0` → `1.1.0`
- Structural overhaul (new purpose, redesigned output format): major — `1.0.0` → `2.0.0`

#### Step 7: Apply entry lifecycle to captures

For each capture entry that was assessed during this run:
- **Applied** → delete from captures file
- **Already covered** → delete from captures file
- **Mistagged** → re-tag to the correct skill in the captures file (leave as pending)
- **New territory** → re-tag to `[new-skill: suggested-name]` in the captures file

Entries for other skills that were not part of this run remain untouched.

#### Step 8: Refresh the skills catalog

After all edits are complete, regenerate `<user-home>/.claude/mtx-catalog.md` using the same format and rules as capture-centric Step 6. Read descriptions from all `skills/*/SKILL.md` files and write the catalog grouped by category. This keeps the catalog current even when only a single skill was updated.

#### Step 9: Report

List every file changed and what was modified. Note the old and new version number.

---

## Validate Skill workflow

Structural and mechanical check. Read-only — no file changes.

### Step 1: Identify the skill

If the target is a specific skill name (e.g. `/mtx validate static-website-hosting`), validate that skill. If the target is a category (e.g. `/mtx validate web`), read `skills/<category>/` to find all skills and run validation on each in sequence, presenting a combined report. If no target was given, ask which skill or category to validate.

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
- Length zone: ≤150 healthy; 150–200 flag as review zone; **>200 is a fail** — must be referenced or split (see CONTRIBUTING.md)
- Attribution footer present at the end of the file
- No placeholder text remaining (`[Fill this in]`, bracketed examples, lorem ipsum)
- No real usernames, account handles, repository names, deployment URLs, subscription IDs, or project-specific identifiers (see Example content rules above)

**`README.md`**
- Length within 40–60 lines (flag actual line count if outside)
- Files table present
- Source and attribution table present at the bottom
- No placeholder text remaining

**`example-input.md`**
- File exists and has content
- Length within 5–40 lines (flag if outside)
- No placeholder text remaining (`[Fill this in]`, etc.)
- No real usernames, repo names, deployment URLs, or project-specific identifiers

**`example-output.md`**
- File exists and has content
- No placeholder text remaining
- No real usernames, repo names, deployment URLs, or project-specific identifiers

**`reference.md`** *(only if present — it is optional)*
- Listed in the skill's README files table
- Not line-capped, but excerpts are minimal and illustrative — load-bearing lines only, boilerplate elided, no full code dumps
- No placeholder-as-incomplete (`[Fill this in]`) and no real usernames, repo names, deployment URLs, or project-specific identifiers

**Repository**
- Skill path listed in root `README.md`

### Step 4: Report

Present the checklist with ✓ or ✗ for each item. For any failures, quote the specific text or line that is the issue. Conclude with a summary: how many checks passed, how many failed, and whether the skill is ready to submit.

No file changes. If failures need fixing, the user can follow up with `/mtx update`.

---

## Review Skill workflow

Qualitative content review. Read-only — no file changes.

### Step 1: Identify the skill

If the target is a specific skill name (e.g. `/mtx review static-website-hosting`), review that skill. If the target is a category (e.g. `/mtx review web`), read `skills/<category>/` to find all skills and run the review on each in sequence, presenting a combined report. If no target was given, ask which skill or category to review.

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
- **Length zone** — count `SKILL.md` lines. ≤150 is healthy; 150–200 is the review zone (suggest tightening or moving bulky material to `reference.md`); over 200 is the action zone — flag that it **must** be referenced or split. Apply the reference-vs-split test: long because of *material* (code, config, tables) → recommend moving it to `reference.md` (one skill, load-on-demand); long because of *multiple jobs* (distinct triggers/lifecycle moments someone would invoke separately) → recommend splitting into separate skills. If a `reference.md` exists, check its excerpts are minimal and illustrative (load-bearing lines only, boilerplate elided, no full dumps).
- Is this skill under-developed? Check both: fewer than 5 guiding principles, and fewer than 50 lines of content (excluding frontmatter and attribution footer). If both are true, assess whether it shares significant subject matter with an existing skill. If it does, flag it as a merge candidate — name the candidate skill and phrase it as an observation, not a recommendation: _"This skill is thin and shares territory with `<skill-name>` — worth monitoring. If it does not grow after two or three update cycles, consider merging."_ If the skill is thin but genuinely standalone (no meaningful overlap with anything in the library), note the thinness only and suggest more captures are needed.

### Step 5: Report

Present findings in this structure:

1. **Structural validation** — pass/fail summary (reference validate results)
2. **Strengths** — what is working well and why
3. **Suggested improvements** — specific, actionable items with the section they apply to
4. **Scope assessment** — is the skill well-scoped, too broad, or overlapping with another skill?
5. **Merge candidate** (only if triggered) — name the candidate skill, state what subject matter is shared, and use the observation phrasing from Step 4. Omit this section entirely if the skill is not a merge candidate — do not include it with a "none" value.

No file changes. If the user wants to apply suggestions, follow up with `/mtx update`.

---

## Capture workflow

Records notable discoveries from the current session into `mtx-captures.md` for later incorporation into the Matrix Skills library. Works in any project. Each run is incremental — it only captures what has happened since the last capture.

**Source of truth is the session context.** The capture process reads the session JSONL and current context window to faithfully encode what was actually discovered, demonstrated, or learned. Any accuracy assessment must be grounded in that material — what the session showed, proved, or revealed. Do not verify entries against external sources, documentation, or general knowledge. Do not use general AI knowledge to second-guess or correct what the session found. If something in the session context seems uncertain or unconfirmed, mark it tentative (`~`) — do not resolve the uncertainty by looking outside the session.

### Step 1: Prepare the captures file

Read `mtx-captures.md` in the current project root if it exists. Before doing anything else, validate the file is in good shape and fix what can be fixed automatically.

**Health checks — run in this order:**

- **File does not exist** → first ever capture for this project. Before creating the file, check for `.gitignore` in the project root. If `.gitignore` exists and does not already contain `mtx-captures.md`, append `mtx-captures.md` to it. If no `.gitignore` exists, create one containing `mtx-captures.md`. Tell the user: "Added `mtx-captures.md` to `.gitignore`." Create `mtx-captures.md` when writing entries in Step 6. No further checks needed — skip to Step 2.
- **Missing `[capture-log]` but entries already present** → pre-migration file. Add a `[capture-log]` entry timestamped to now and tell the user: "Capture anchor initialised — this is a one-time setup." Proceed.
- **Multiple `[capture-log]` entries** → keep only the most recent, remove the others silently.
- **Rolling window exceeded for any skill** → trim oldest entries per skill back to 10 before proceeding. Report how many were trimmed.
- **Malformed entry headers** (wrong bracket format, missing date, unrecognised tag structure) → flag each issue clearly and stop. Do not proceed until resolved — a corrupted entry could cause future update runs to mis-route discoveries.
- **Entries missing tags** → flag to the user and ask whether to add tags now or remove the entry.
- **File is healthy** → proceed silently. No output needed if everything is in order.

**Establish the capture window** — once the file is validated, find the most recent `[capture-log]` entry and extract its timestamp.

**If a timestamp is found:**
- Tell the user: "Last capture was [timestamp]. Reviewing session from that point forward."
- Locate the session JSONL. The base path is `<user-home>\.claude\projects\<project-path-slug>\` on all platforms:
  - **Windows:** `C:\Users\<username>\.claude\projects\<project-path-slug>\`
  - **macOS/Linux:** `~/.claude/projects/<project-path-slug>/`
  The `project-path-slug` is the absolute path of the current working directory with all separators replaced by `--` and spaces/special characters normalised, lowercased (e.g. a project at `C:\Users\StevenPower\Documents\POWR DATA\GitHub\App_Test` becomes `c--users-stevenpower--documents--powr-data--github--app-test`). Find the most recently modified `.jsonl` file in that directory.
- **Use the correct tool for the platform.** On Windows, use the PowerShell tool for all filesystem discovery steps — Bash tool commands like `dir` or mixed `2>$null` syntax fail on Windows. On macOS/Linux, use the Bash tool.
- Read the JSONL and filter to conversation turns after the last-capture timestamp.
- Use those turns combined with the current context window as the source for identifying discoveries.

**If no timestamp is found** (first capture, or after a reset):
- Tell the user: "No previous capture found. Reviewing full session history."
- Read the JSONL from the beginning and use the full content plus current context window as the source.

**If the JSONL is inaccessible** (file not found, directory missing):
- Fall back to current context window only.
- Warn the user: "Could not read session history — the JSONL path may be wrong for this environment, or the file has not been written yet. Expected location: `<user-home>\.claude\projects\<project-slug>\`. Check that directory manually if history lookup is important. Capturing from current context only — discoveries scrolled out of context will be missed."
- Suggest running `/mtx capture` more frequently during long sessions to avoid losing context.

### Step 2: Identify the skill

Before identifying skills, do a complete pass through all source material in scope. Do not stop at the most obvious or most recent discoveries. Ask yourself for each meaningful exchange, decision, error, fix, or workaround encountered in the session:

- Did this reveal a non-obvious rule or failure mode?
- Would a practitioner following this as a rule avoid a real mistake?
- Has this already been captured in `mtx-captures.md`?

Only move on to writing entries once you have exhausted the full source material. A second run of `/mtx capture` immediately after the first should find nothing new. If it does, the first run was incomplete.

Once the full pass is done, check the skills catalog before routing any discovery. Look for `<user-home>/.claude/mtx-catalog.md` (Windows: `C:\Users\<username>\.claude\mtx-catalog.md`, macOS/Linux: `~/.claude/mtx-catalog.md`). If it exists, read it — it lists every skill name and its one-line description. Use it to match discoveries to existing skills before considering `new-skill`. A discovery should only be tagged `new-skill` if nothing in the catalog is a reasonable home for it.

If the catalog is absent, proceed without it and note at the end: "Skills catalog not found — run `/mtx update` from the skills repo to generate it."

Then determine which Matrix Skills library skill each discovery relates to. Use the skill name exactly as it appears in the catalog or library (e.g. `flet-supabase-framework`, `static-website-hosting`, `flet-aca-deploy`).

If a discovery does not clearly map to an existing skill, note it as `new-skill` and include a suggested skill name in the entry text.

If it is ambiguous between two skills, ask the user to choose before proceeding — one question only.

### Step 3: Distil the discovery

Summarise each discovery in one to three sentences. Be specific and opinionated — encode the rule, the failure mode, or the principle directly. Do not write a vague observation.

Ask yourself: would a practitioner following this as a rule avoid a real mistake? If not, sharpen it.

### Step 4: Assign tags

Generate one to three `#hashtags` per entry that describe the topic area within the skill. Tags should be lowercase, hyphen-separated where needed (e.g. `#android`, `#keystore`, `#app-listing`, `#websocket`, `#csp`). Tags reflect the specific aspect of the skill — not the skill name itself.

### Step 5: Assess confidence

Confidence is assessed relative to the session context — not against external sources. If the session clearly demonstrated or confirmed something, write it as a plain statement. If it emerged as a working hypothesis, was observed once, or has not been fully confirmed within the session, prefix the entry text with `~`. Do not use general knowledge or external documentation to upgrade a tentative entry to confirmed — that resolution belongs in a future session.

### Step 6: Write the entries

Append all new entries to `mtx-captures.md` in the current project root. Create the file if it does not exist.

Entry format:

```markdown
## [skill-name] YYYY-MM-DD
#tag1 #tag2
Entry text here. One to three sentences maximum.
```

Tentative entry:

```markdown
## [skill-name] YYYY-MM-DD
#tag1 #tag2
~ Entry text here — verify before applying to skill.
```

**Reference attachment (optional, use sparingly).** The 3-sentence limit governs the distilled *rule*. When the session produced a concrete *artefact* whose exact form is the value — and re-synthesising it at update time would risk losing what actually worked (e.g. a working YAML block, a tricky config) — attach it after the entry text with a `[reference: <anchor>]` marker and a fenced code block. The prose still obeys the 3-sentence limit; the attachment is exempt because it is artefact, not instruction. At update time the prose routes to `SKILL.md` and the attachment routes to the skill's `reference.md` under that anchor. Keep the attachment minimal and illustrative — load-bearing lines only, boilerplate elided with `# ...`, placeholders for project-specific values. Default to no attachment; most discoveries are rules, not artefacts.

```markdown
## [skill-name] YYYY-MM-DD
#tag1 #tag2
Three-sentence rule the artefact embodies.

[reference: <anchor>]
​```yaml
# minimal load-bearing excerpt
​```
```

### Step 7: Enforce the rolling window

After appending, count the entries for each skill written in this run. If any skill has more than 10 entries in the file, remove the oldest entries for that skill until it has 10. Entries for other skills and `[capture-log]` entries are unaffected.

### Step 8: Update the capture-log marker

Write or replace the `[capture-log]` entry in `mtx-captures.md` using the current timestamp. There is always exactly one `[capture-log]` entry — if one already exists anywhere in the file, replace it in place; if none exists, append it at the end.

Format:

```markdown
## [capture-log] YYYY-MM-DDTHH:MM:SS
Capture run complete.
```

### Step 9: Confirm to the user

Report each captured entry on its own line. Do not show the full file.

Example:
```
Captured → [flet-aca-deploy] #websocket #ingress
Captured → [flet-aca-deploy] #csp — marked tentative.
```

---

## Capture Reset workflow

### Step 1: Archive

Copy `mtx-captures.md` to `mtx-captures-YYYY-MM-DD.md` in the same directory, using today's date. If `mtx-captures.md` does not exist, tell the user and stop.

### Step 2: Clear

Delete or empty `mtx-captures.md` so it starts fresh.

### Step 3: Confirm

Report: `Reset complete. Archived to mtx-captures-YYYY-MM-DD.md. Ready for new captures.`

---

## Capture rules

- Maximum 10 entries per skill in the file at any time — oldest drops when exceeded
- Maximum 3 sentences per entry — force distillation at capture time, not at update time
- Maximum 3 tags per entry
- Skill name must match an existing Matrix Skills library skill exactly, or use `new-skill` with a suggested name
- Never rewrite or summarise existing entries — only append and trim the oldest when the window is exceeded
- This command works in any project — the captures file always lives in the current project root
- `[capture-log]` entries use ISO 8601 timestamp format (`YYYY-MM-DDTHH:MM:SS`). There is always at most one per file — replace in place when updating, never accumulate. The rolling window limit does not apply to `[capture-log]` entries.
