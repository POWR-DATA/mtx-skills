# Git Secret Remediation

Remove committed secrets from Git history safely and verify remediations across local and remote repositories.

## What this skill does

Guides you through a practical secret-removal workflow using `git filter-repo`, including incident containment, rewrite planning, verification, and team recovery. Includes a Windows-specific fix for BOM-corrupted replacement files that cause silent no-op rewrites.

## When to use it

- Sensitive values were committed to Git history
- You need a repeatable and auditable history rewrite procedure
- You are remediating secrets on Windows with PowerShell tooling
- You need collaborator-safe force-push and reset guidance

## Example use cases

- Token committed in `.env` and merged into default branch
- Password leaked in config and propagated to release tags
- `git filter-repo` replace-text run appears successful but did not rewrite due to BOM issues

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide repository scope, leaked patterns, and platform constraints, then apply the generated remediation plan.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
