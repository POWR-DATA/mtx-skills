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

### Install all Matrix Skills

```bash
npx skillfish add POWR-DATA/mtx-skills
```

This detects which AI coding agents are installed on your machine and copies the skills into the appropriate directory for each one.

### Install Skillfish globally (optional)

If you use Skillfish regularly, install it globally:

```bash
npm install -g skillfish
skillfish add POWR-DATA/mtx-skills
```

### Pin to a specific version

```bash
npx skillfish add POWR-DATA/mtx-skills@v1.0.0
```

### Team projects

Add a `skillfish.json` manifest to your project so team members can install all required skills with one command:

```json
{
  "version": 1,
  "skills": ["POWR-DATA/mtx-skills"]
}
```

Then any team member can run:

```bash
npx skillfish install
```

> **Note:** Matrix Skills uses a monorepo structure (multiple skills in one repo). Skillfish behaviour with monorepos should be tested on your machine. If individual skill paths are required, reference them as `POWR-DATA/mtx-skills/skills/data/dimensional-model-designer` or similar.

---

## Claude.ai (web)

There are three practical ways to use these skills in Claude.ai, depending on what your account supports.

---

### Option A: Bootstrap prompt (recommended starting point)

This approach asks Claude to read the skills repo and use the skills automatically throughout your conversation. It works best when your Claude.ai account has web access enabled.

Paste this into a new Claude.ai conversation:

```
I have a set of reusable skills here:
https://github.com/POWR-DATA/mtx-skills

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

**Slash commands** are invoked directly in Claude Code with a `/` prefix. They are workflow tools — not content skills. This library provides one: `/mtx`, a global command installed at `~/.claude/commands/mtx.md`. It captures discoveries from any project session (`/mtx capture`), and updates, validates, and reviews skills when run from the skills repo. New skills enter the library through the capture path — run `/mtx capture` during project work, then `/mtx update <path>` in the skills repo to sync discoveries into skills. Slash commands are a Claude Code-specific mechanism with no cross-tool equivalent at this stage. Other AI tools (Cursor, Copilot, Windsurf) have their own analogous patterns but use different formats and invocation methods — this repo does not currently provide equivalents for those tools. See [Contributing Skills](contributing-skills.md) for setup and usage.

If you are using skills from this library in a project, you want the library skills approach below. If you are contributing a new skill to this repo using Claude Code, see [Contributing Skills](contributing-skills.md).

### Using library skills in a project

Claude Code works best with skills stored locally in your project. The recommended approach is to copy the skills you need into a `.claude/skills/` folder within your project, so Claude Code can reference them directly.

### Setup

```bash
# Clone the skills repo
git clone https://github.com/POWR-DATA/mtx-skills.git

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

## Cursor (native Agent Skills)

Cursor supports the same `SKILL.md` format this library uses, through its [Agent Skills](https://cursor.com/docs/skills) feature — so these skills run natively, with no conversion needed.

> **Skills, not Rules.** Cursor *Rules* (`.cursor/rules/*.mdc`) are project conventions and constraints — a different feature. These are *skills*, so they belong in Cursor's skills directories, not the rules folder.

Cursor auto-discovers skills on startup from several locations, including:

- `.cursor/skills/` — project-scoped (committed to the repo)
- `~/.cursor/skills/` — global (available in every project)

**Easiest — install with Skillfish:**

```bash
npx skillfish add POWR-DATA/mtx-skills
```

Skillfish installs into Cursor's global skills directory (`~/.cursor/skills/`), where Cursor picks the skills up automatically.

**Manual — drop a skill folder in:**

Copy a whole skill folder (e.g. `skills/app/flet-supabase-framework/`) into `.cursor/skills/<skill-name>/`, keeping `SKILL.md` and any `reference.md` intact. Cursor loads it on the next start.

**Using a skill:** Cursor's agent selects one automatically based on its `description`, or you can type `/` in the Agent chat and search for it by name.

Cursor requires a skill's folder name to match its `name` frontmatter field — a convention this library already follows — and it loads linked files like `reference.md` on demand, so the progressive-disclosure structure behaves exactly as it does in Claude Code.

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
