# Using these skills with Databricks Genie Code

This guide explains how to install skills from this repository into Databricks Genie Code so they are available during agent sessions.

---

## How Genie Code discovers skills

Databricks Genie Code discovers skills by scanning a `.assistant/skills/` directory. Each subfolder in that directory is treated as a separate skill. For Genie Code to recognise a skill, the folder must contain a `SKILL.md` file.

There are two locations where skills can be installed:

| Location | Path | Who can use it |
|---|---|---|
| User-level | `/Users/<username>/.assistant/skills/` | The individual Databricks user only |
| Workspace-level | `Workspace/.assistant/skills/` | Anyone with access to the workspace (requires write permission) |

Genie Code does not consume a GitHub repository URL directly. The skill files must be physically present in the `.assistant/skills/` directory — either copied there manually or synchronised by an external tool.

---

## Recommended folder structure

After installation, your `.assistant/skills/` directory should look like this:

```
.assistant/
  skills/
    use-case-to-data-requirements/
      SKILL.md
    dimensional-model-designer/
      SKILL.md
    medallion-architecture-designer/
      SKILL.md
    data-pipeline-designer/
      SKILL.md
    flet-supabase-framework/
      SKILL.md
    flet-multiplatform-build/
      SKILL.md
    flet-aca-deploy/
      SKILL.md
    app-icon-asset-generation/
      SKILL.md
    time-series-use-case-assessment/
      SKILL.md
```

Genie Code requires only `SKILL.md` in each folder to recognise a skill. Including additional files such as `README.md` and example files is optional but harmless — they do not interfere with skill discovery.

---

## Manual installation — user-level

User-level skills are available only to your Databricks user account. This is the recommended starting point.

**Step 1 — Clone or download the repository**

Clone the repository to your local machine or to a Databricks Repo:

```bash
git clone https://github.com/POWR-DATA/skills.git
```

Or, if working directly inside a Databricks workspace, add `https://github.com/POWR-DATA/skills` as a Git-backed Repo under **Workspace → Repos**.

**Step 2 — Create the skills directory**

In your Databricks workspace file browser or via a notebook, create the target directory:

```
/Users/<your-username>/.assistant/skills/
```

Replace `<your-username>` with your Databricks account username (typically your email address).

**Step 3 — Copy each skill folder**

Copy only the individual skill folders — not the entire repository. Each folder you copy must contain a `SKILL.md` file.

From a Databricks notebook or terminal:

```python
import shutil
import os

# Adjust source_root to wherever you cloned or synced the repository
source_root = "/Workspace/Repos/<your-username>/skills"
target_root = f"/Users/{dbutils.notebook.entry_point.getDbutils().notebook().getContext().userName().get()}/.assistant/skills"

skill_dirs = [
    "skills/data/use-case-to-data-requirements",
    "skills/data/dimensional-model-designer",
    "skills/data/medallion-architecture-designer",
    "skills/data/data-pipeline-designer",
    "skills/app/flet-supabase-framework",
    "skills/app/flet-multiplatform-build",
    "skills/app/flet-aca-deploy",
    "skills/app/app-icon-asset-generation",
    "skills/domain/time-series/time-series-use-case-assessment",
]

os.makedirs(target_root, exist_ok=True)

for skill_path in skill_dirs:
    skill_name = os.path.basename(skill_path)
    src = os.path.join(source_root, skill_path)
    dst = os.path.join(target_root, skill_name)
    if os.path.isdir(src):
        shutil.copytree(src, dst, dirs_exist_ok=True)
        print(f"Installed: {skill_name}")
    else:
        print(f"Not found, skipping: {src}")
```

**Step 4 — Reload Genie Code**

After copying, reload or restart your Genie Code session for the new skills to be picked up.

---

## Manual installation — workspace-level

Workspace-level skills are available to all users in the Databricks workspace. This is appropriate for shared team or organisation standards.

**Requirements:** You must have write permission to `Workspace/.assistant/skills/`. Contact your workspace administrator if you do not.

The process is the same as user-level installation, with a different target path:

```python
target_root = "/Workspace/.assistant/skills"
```

Replace the `target_root` in the Step 3 script above and run the same copy loop.

---

## Agent Mode prompt — automated installation

Paste the following prompt into a Genie Code Agent Mode session. The agent will clone the repository, find every skill, copy it into your user skills folder, validate each skill, and report the result.

Before pasting, replace `https://github.com/POWR-DATA/skills` with a different repository URL if you are installing from a fork or private copy. For workspace-level installation, replace the target path with `/Workspace/.assistant/skills`.

```
Install AI skills from this GitHub repository into my Genie Code user skills folder:
https://github.com/POWR-DATA/skills

Follow these steps exactly using Python. Do not use dbutils.fs, workspace CLI commands, or Databricks REST API calls — use only subprocess and shutil.

1. Resolve the target path:
   - Get the current Databricks username with: spark.sql("SELECT current_user()").collect()[0][0]
   - Target path: /Users/<resolved-username>/.assistant/skills
   - Do not prompt me for the username — resolve it from the environment.

2. Clone the repository to a temporary directory:
   - If /tmp/powr-skills-install already exists, delete it with shutil.rmtree before cloning.
   - Clone using: subprocess.run(["git", "clone", "--depth", "1", "https://github.com/POWR-DATA/skills", "/tmp/powr-skills-install"], check=True)

3. Find every skill folder:
   - Walk /tmp/powr-skills-install recursively.
   - A skill folder is any directory that directly contains a SKILL.md file.
   - Exclude any folder whose path contains a "templates" component.

4. For each skill folder found:
   - Use only the deepest folder name as the install name (e.g. skills/domain/time-series/time-series-use-case-assessment installs as time-series-use-case-assessment).
   - If two skills resolve to the same install name, prefix each with its immediate parent category name separated by a hyphen (e.g. data-assessment and domain-assessment) and print a warning.
   - Copy the entire skill folder — including SKILL.md, README.md, example-input.md, example-output.md, and any other files present — to <target_root>/<install-name>/ using shutil.copytree with dirs_exist_ok=True.
   - Do not copy repo-level files or folders (docs/, .github/, templates/, LICENSE, CONTRIBUTING.md, README.md at the repo root).

5. Validate each installed SKILL.md:
   - Parse the YAML front matter (the block between --- delimiters at the top of the file) using yaml.safe_load(). Fall back to a regex check if the yaml module is unavailable.
   - Confirm that at minimum the name and description fields are present.
   - If validation fails for a skill, print a warning and continue — do not abort the installation.

6. Clean up and report:
   - Delete /tmp/powr-skills-install using shutil.rmtree.
   - Print a summary table showing: skill install name, number of files copied, and validation status (OK / WARNING).
   - Print the final folder tree of the installed skills directory.
```

---

## Validating the installation

After installation, confirm the skills are available by running the following in a notebook:

```python
import os

skills_root = f"/Users/{dbutils.notebook.entry_point.getDbutils().notebook().getContext().userName().get()}/.assistant/skills"

installed = []
for name in sorted(os.listdir(skills_root)):
    skill_path = os.path.join(skills_root, name)
    if os.path.isdir(skill_path) and os.path.isfile(os.path.join(skill_path, "SKILL.md")):
        installed.append(name)
    else:
        print(f"WARNING: {name} — missing SKILL.md or not a directory")

print(f"\n{len(installed)} skill(s) installed:")
for name in installed:
    print(f"  - {name}")
```

If a skill folder is listed but missing `SKILL.md`, Genie Code will not recognise it as a skill.

---

## Referencing skills in Genie Code

Once installed, reference a skill by name using the `@` prefix followed by the skill folder name:

```
@dimensional-model-designer

I have a retail sales use case. We track transactions, products, customers, and stores.
Design a star schema for reporting on daily sales revenue by product category and store region.
```

```
@medallion-architecture-designer

Source: transactional Postgres database with orders, order_lines, and customers tables.
Target: Databricks lakehouse. Design the bronze, silver, and gold layers.
```

```
@use-case-to-data-requirements

Use case: weekly churn report for a subscription product. Stakeholder wants to see
churn rate by cohort, month, and product tier. Translate this into structured data requirements.
```

The skill instructs Genie Code on how to interpret your input and what structure to follow for the response.

---

## Keeping skills up to date

Genie Code does not automatically synchronise with the GitHub repository. When the repository is updated, you need to re-copy the relevant skill folders.

**Option 1 — Pull and re-copy manually**

```bash
# In your Databricks Repo or local clone
git pull origin main
```

Then re-run the copy script from the installation steps above. Use `dirs_exist_ok=True` in `shutil.copytree` to overwrite existing files.

**Option 2 — Use Skillfish or a similar CLI**

Tools such as [Skillfish](https://github.com/knoxgraeme/skillfish) can sync skills from a GitHub repository. If using an external CLI tool, confirm that the installed files end up in the correct `.assistant/skills/` path — tools designed for other AI coding agents may install to a different location that Genie Code does not read.

**Option 3 — Schedule a sync notebook**

Create a Databricks notebook that runs the copy script on a schedule using Databricks Workflows. This keeps the installed skills in sync with the repository without manual intervention.

---

## Troubleshooting

**Skills not appearing in Genie Code**

- Confirm the skill folder exists at the correct path: `/Users/<username>/.assistant/skills/<skill-name>/`
- Confirm the folder contains a `SKILL.md` file
- Reload or restart your Genie Code session — newly copied skills may not appear until the session is refreshed

**Missing SKILL.md**

If you copied a skill folder but forgot to include `SKILL.md`, Genie Code will not recognise it. Re-copy the folder and confirm the file is present:

```python
skill_path = "/Users/<username>/.assistant/skills/dimensional-model-designer"
print(os.path.isfile(os.path.join(skill_path, "SKILL.md")))  # should be True
```

**Invalid YAML front matter**

Each `SKILL.md` in this repository includes a YAML front matter block at the top (between `---` delimiters). If the front matter is malformed, Genie Code may fail to parse the skill. Confirm the front matter is valid:

```yaml
---
name: skill-name
description: One-line description
author: POWR-DATA
version: 1.0.0
license: MIT
---
```

Do not modify the front matter unless you are extending the skill for internal use.

**Permissions error writing to Workspace/.assistant/skills/**

Workspace-level skill installation requires write access to the `Workspace/.assistant/` path. If you receive a permissions error, either:
- Install at user-level instead (`/Users/<username>/.assistant/skills/`)
- Ask your workspace administrator to grant write permission or to perform the installation on your behalf

**Accidentally copying the whole repository**

A common mistake is copying the top-level repository folder rather than individual skill folders. The `.assistant/skills/` directory should contain one subfolder per skill, not a single `skills/` folder containing everything.

Incorrect:
```
.assistant/skills/skills/data/dimensional-model-designer/SKILL.md   ← wrong
```

Correct:
```
.assistant/skills/dimensional-model-designer/SKILL.md   ← correct
```

If you see an extra nesting level, delete the incorrectly copied folder and re-run the installation script, which copies each skill folder directly by name.
