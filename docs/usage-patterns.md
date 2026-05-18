# Usage Patterns

This page describes how to use skills from this library across common AI tools.

The skills in this repo are plain Markdown files. They do not require installation. You load them into an AI tool by pasting, referencing, or copying them — the method depends on which tool you are using.

---

## Skillfish (multi-agent install)

[Skillfish](https://github.com/knoxgraeme/skillfish) is an npm-based CLI tool that installs skills from a GitHub repository into every supported AI coding agent on your machine in a single command. It supports over 30 agents including Claude Code, Cursor, Windsurf, GitHub Copilot, and Gemini CLI.

**Prerequisites:** Skillfish requires Node.js. If `npx` is not found, install Node.js first:

```bash
# Windows (winget)
winget install OpenJS.NodeJS --accept-source-agreements --accept-package-agreements

# macOS (Homebrew)
brew install node
```

Restart your terminal after installing before running any `npx` command.

### Install all PowerData skills

```bash
npx skillfish add POWR-DATA/skills
```

This detects which AI coding agents are installed on your machine and copies the skills into the appropriate directory for each one.

### Install Skillfish globally (optional)

If you use Skillfish regularly, install it globally:

```bash
npm install -g skillfish
skillfish add POWR-DATA/skills
```

### Pin to a specific version

```bash
npx skillfish add POWR-DATA/skills@v1.0.0
```

### Team projects

Add a `skillfish.json` manifest to your project so team members can install all required skills with one command:

```json
{
  "version": 1,
  "skills": ["POWR-DATA/skills"]
}
```

Then any team member can run:

```bash
npx skillfish install
```

> **Note:** PowerData Skills uses a monorepo structure (multiple skills in one repo). Skillfish behaviour with monorepos should be tested on your machine. If individual skill paths are required, reference them as `POWR-DATA/skills/skills/data/dimensional-model-designer` or similar.

---

## Claude.ai (web)

There are three practical ways to use these skills in Claude.ai, depending on what your account supports.

---

### Option A: Bootstrap prompt (recommended starting point)

This approach asks Claude to read the skills repo and use the skills automatically throughout your conversation. It works best when your Claude.ai account has web access enabled.

Paste this into a new Claude.ai conversation:

```
I have a set of reusable skills here:
https://github.com/POWR-DATA/skills

Please:
1. Read the skills in the repo
2. Summarise what skills are available
3. Decide when each should be used
4. Use them automatically when relevant in this conversation

Confirm once loaded.
```

Claude will read the repo, summarise the available skills, and apply them when relevant for the rest of that conversation.

> **Note:** This works best when web access is enabled on your Claude.ai account. If Claude cannot fetch the URL, use Option B instead.

---

### Option B: Paste a single skill

If you want to use one specific skill, open the `SKILL.md` file for that skill, copy the full content, and paste it into Claude with this instruction:

```
Here is a skill. Use it when relevant:

[paste SKILL.md content here]
```

Then provide your inputs as described in the skill's **Inputs expected** section and ask Claude to apply it.

This works on any Claude.ai account without needing web access or custom skill upload.

---

### Option C: Skill upload (where available)

Some Claude.ai accounts support uploading custom skills directly through the UI. If your account has this feature:

1. Go to [claude.ai](https://claude.ai)
2. Open **Customize**
3. Go to **Skills**
4. Look for a **Create skill** or **Upload skill** option

If you only see a **Directory** or marketplace view, custom skill upload is not yet available on your account. Use Option A or Option B instead.

When upload is available, you can upload a zipped skill folder containing the `SKILL.md` and any supporting files. The skill will then be available to apply in future conversations.

---

### GitHub connector note

Claude.ai supports connecting a GitHub account to read repository content as context. This is useful for giving Claude awareness of your codebase or project files.

However, connecting GitHub is not the same as installing skills. It gives Claude read access to a repo during a conversation — it does not persistently load skills or make them available across sessions.

You can still paste the GitHub repo URL as context even if the custom skill upload UI is unavailable. Used alongside the bootstrap prompt in Option A, this is an effective way to work with the full skills library.

---

## Claude Code

There are two distinct ways skills integrate with Claude Code. Understanding the difference matters before you start.

### Library skills vs. slash commands

**Library skills** are the skills in this repository (`skills/data/`, `skills/app/`, `skills/web/`, `skills/ai/`, `skills/domain/`). They are plain Markdown files you copy into a project so Claude Code can read them as context. Claude Code treats them as instructions to follow when relevant.

**Slash commands** live in `.claude/commands/` and are invoked directly in Claude Code with a `/` prefix. They are repo workflow tools — not content skills. This repo ships one: `/skill`, which creates, updates, validates, and reviews skills following the library's conventions. Slash commands are a Claude Code-specific mechanism with no cross-tool equivalent at this stage. Other AI tools (Cursor, Copilot, Windsurf) have their own analogous patterns but use different formats and invocation methods — this repo does not currently provide equivalents for those tools.

If you are using skills from this library in a project, you want the library skills approach below. If you are contributing a new skill to this repo using Claude Code, use `/skill`.

### `/skill` command reference

> **Claude Code only — and only within this repo.**
>
> The `/skill` command is a contributor tool for the PowerData Skills library. It writes to `skills/`, updates the root `README.md`, and follows conventions specific to this repo. It must be run with Claude Code opened in the skills repo root. Running it from another project (a website, an app, a client repo) will not work — the required paths and structure will not be found.
>
> Library skills (the `SKILL.md` files in `skills/`) are cross-tool and work in any AI assistant. The `/skill` command is separate from the library skills and is not installed by Skillfish.

The `/skill` command supports four actions. Invoke it with an action keyword and optional skill name, or with no arguments to be prompted.

| Action | Invocation | What it does |
|---|---|---|
| `new` | `/skill new` | Create a new skill from scratch. Guides you through category, purpose, and inputs, then generates all four files and updates the root README. |
| `update` | `/skill update <skill-name>` | Edit an existing skill. Reads current files, asks what needs changing, makes targeted edits, and bumps the version number. |
| `validate` | `/skill validate <skill-name>` | Structural check — verifies frontmatter, required sections, file lengths, placeholder text, attribution, and root README listing. Read-only. |
| `review` | `/skill review <skill-name>` | Content quality review — assesses whether principles are opinionated, process steps are actionable, examples are realistic, and the skill is well-scoped. Read-only. |

`new` and `update` support up to two rounds of clarifying questions before generating anything. `validate` and `review` are read-only and make no file changes.

The full procedure for each action is defined in [`.claude/commands/skill.md`](.claude/commands/skill.md).

### Example session

The following example shows all four actions using a single skill created from notes gathered in an external AI session (e.g. ChatGPT, Copilot). The skill is an IT managed service provider onboarding assessment.

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
consultant or MSP. Category: domain/it-services.
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

After a further session refining the security assessment step:

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
- Process steps are actionable and sequenced logically; each has a clear
  deliverable

Suggested improvements
- When to use: missing lifecycle position — add "Apply before any technical
  work begins; output feeds directly into the statement of work"
- Guiding principles: "understand the client's risk tolerance" is too vague;
  replace with something measurable, e.g. "Ask the client to state their
  acceptable downtime in hours — this determines backup frequency and
  whether failover is required"
- Avoid section: only 2 items — consider adding "Do not begin remote access
  setup before completing the environment inventory"
- example-output.md: Priority action list is 3 lines; expand to match the
  depth of the Environment assessment section

Scope
Well-scoped — covers discovery only, stops before solution design. No
overlap with existing skills. Could pair with a future IT Statement of
Work skill but works independently as-is.
```

### Using `/skill` from another project session

A common scenario: you have been working in a separate Claude Code session on a website, an app, or a client project, and you have learned something worth capturing in the skills library. You cannot run `/skill` from that other session — the command will not find the skills library structure.

The correct workflow is:

**1. Finish your work in the other project session**

Complete the task. Note what you learned — a better process step, a new guiding principle, a failure mode worth adding to the Avoid section, or enough new material for a new skill entirely.

**2. Open the skills repo in Claude Code**

Open a new Claude Code session in the PowerData Skills repository. This is the session where `/skill` will work.

**3. Use an extraction prompt in the other session before you close it**

Before switching sessions, ask the AI in the other session to summarise what was learned in a structured way. This makes it much easier to bring useful context across. Use one of the prompts below depending on what you want to do.

---

#### Extraction prompts

Use these at the end of a session in ChatGPT, Copilot, another Claude session, or any other AI tool.

**Creating a new skill** — use this when a whole new process or workflow emerged from the session:

> Before we finish, please summarise what we worked out as if you were writing a procedure for an AI agent to follow this same process in future. Structure your answer as:
> - **What it does** — one or two sentences describing the purpose
> - **Who would use it** — the target user and when they would reach for this
> - **What they provide** — the minimum inputs needed to get started
> - **The process** — the step-by-step procedure we followed, as numbered steps
> - **Key principles** — the most important rules and decision points we discovered
> - **What a good result looks like** — the structure and content of a useful output
> - **What to avoid** — mistakes, shortcuts, or assumptions that caused problems

**Updating an existing skill** — use this when a session improved on an existing approach:

> We've refined things during this session. Before we finish, summarise specifically what is new or different compared to a standard approach. Focus on:
> - Any process steps that worked better than expected, and why
> - New rules or principles that emerged — especially ones that were non-obvious
> - Failure modes or edge cases we encountered that should be documented
> - Anything about the output format or structure that should change
> Keep it focused on the delta — what is genuinely new, not a full recap.

**Capturing failure modes** — use this when a session uncovered what goes wrong:

> Before we finish, I want to capture the failure modes we encountered for future reference. Please list:
> - What approaches we tried that did not work, and specifically why
> - Any assumptions we made that turned out to be wrong
> - Edge cases that the obvious approach does not handle well
> - Anything a practitioner following this process should explicitly avoid

**Mid-session principle capture** — use this when you want to lock in a decision or rule before moving on:

> Can you state the rule or principle we just worked out as a single, specific, opinionated sentence? Something a practitioner could apply directly without needing further context.

---

**4. Paste the summary into the Claude Code chat first, then run the command**

The `/skill` command checks the conversation for context before asking questions. If you paste your structured summary first and then run the command, it will skip the "what needs updating?" step and go straight to proposing edits for your confirmation.

**Recommended flow — paste first, then run:**

```
[paste your structured summary from the other session here]
```

Then:

```
/skill update static-website-hosting
```

The command reads your summary from the conversation, reads the existing skill files, and immediately presents proposed changes for you to confirm.

**Alternative — run first, then answer interactively:**

If you run the command without pasting anything first, it will ask what needs updating. You can paste or describe the changes in response. This works just as well — it just adds one extra round of back-and-forth.

```
/skill update static-website-hosting
```

> What needs updating?

```
[paste your structured summary here, or describe what changed]
```

**5. Run `/skill update <skill-name>` or `/skill new`**

The command reads the existing skill, takes your context, proposes targeted edits, and bumps the version. From here the normal update workflow applies.

**6. Merge and update locally with Skillfish**

Once the PR is merged to `main`, run:

```bash
npx skillfish add POWR-DATA/skills
```

This updates the library skills in all your local AI tools. The `/skill` command itself is not installed by Skillfish — it is only available when Claude Code is opened in the skills repo.

---

### Using library skills in a project

Claude Code works best with skills stored locally in your project. The recommended approach is to copy the skills you need into a `.claude/skills/` folder within your project, so Claude Code can reference them directly.

### Setup

```bash
# Clone the skills repo
git clone https://github.com/POWR-DATA/skills.git

# In your project, create the skills folder
mkdir -p .claude/skills

# Copy the skill you want to use
cp -r /path/to/skills/skills/data/dimensional-model-designer .claude/skills/
```

Then open Claude Code from your project directory:

```bash
claude
```

### Using a skill

Once Claude Code is open, reference the skill naturally:

```
Use the dimensional model designer skill in .claude/skills/ to design a
star schema for this reporting use case.
```

Or reference the file directly:

```
Apply the skill defined in .claude/skills/dimensional-model-designer/SKILL.md
to the following use case: [your input]
```

### Using multiple skills

To make several skills available across a project, copy all the skill folders you need into `.claude/skills/`. You can also add a reference to them in your project's `CLAUDE.md` file so Claude Code is aware of them at the start of every session:

```markdown
## Available skills

The following reusable skills are available in `.claude/skills/`:

- `dimensional-model-designer` — design star schemas and dimensional models
- `medallion-architecture-designer` — design bronze/silver/gold lakehouse layers
- `data-pipeline-designer` — design source-to-target data pipelines

Apply these skills when the user's request matches their purpose.
```

> **Note:** `.claude/skills/` is a convention, not a built-in Claude Code path. The skills work because Claude Code reads files from your project. The folder name helps keep things organised — you can use any location that makes sense for your project.

---

## GitHub Copilot

Skills can be adapted into Copilot prompt files:

- Place the skill content in a `.github/prompts/` file in your repository.
- Reference it as a reusable instruction in Copilot Chat.
- Adjust the format if needed to match Copilot's expected prompt structure.

---

## Cursor or similar tools

- Paste the skill content into a custom agent instruction, system prompt, or project rules file.
- Skills work well as agent instructions in tools that support persistent context.

---

## Creating private team versions

Public skills in this repository are intentionally generic. You can extend them privately by:

- Forking or copying the skill into a private repository.
- Adding organisation-specific context such as naming conventions, platform standards, governance requirements, security rules, and architectural constraints.
- Treating the public skill as the baseline and the private extension as the overlay.

This approach lets teams benefit from shared patterns while keeping sensitive details private.

---

## Versioning and review

Because skills are stored as Markdown in a Git repository, they can be:

- Reviewed via pull requests.
- Versioned alongside the code they support.
- Compared over time to track how delivery approaches evolve.

This makes skills more trustworthy than prompts saved in personal notes or chat history.

---

## What skills are not

- Skills are not magic prompts that guarantee correct output.
- Skills are not a replacement for domain knowledge or project-specific context.
- Skills are not standalone. The user still needs to review and validate the AI output.

Skills reduce the activation energy for structured, repeatable AI-assisted delivery. They do not replace engineering judgement.
