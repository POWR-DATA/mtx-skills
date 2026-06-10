---
name: git-secret-remediation
description: Remove committed secrets from Git history safely and verify remediations across local and remote repositories
author: PowerData
version: 1.0.0
license: MIT
---

# Git Secret Remediation

## Purpose

Remove accidentally committed secrets from Git history in a controlled, auditable way. This skill covers rewriting history, handling cross-platform text replacement pitfalls, and validating that sensitive values are removed from both local and remote history.

## When to use

- Secrets, tokens, keys, or passwords were committed to Git
- `.env` or config files with sensitive values entered repository history
- A history rewrite is required before a repository is shared broadly
- Rotated credentials still need forensic cleanup from Git objects

## Inputs expected

- Repository path and affected branches/tags
- Secret patterns to remove (exact values, regex-safe tokens, file paths)
- Preferred rewrite tooling (`git filter-repo`)
- Coordination constraints (team members, CI, forks, mirrors)

## Guiding principles

- **Rotate first, rewrite second.** Credential rotation reduces immediate risk while history cleanup is prepared.
- **Use deterministic replacement rules.** Build an explicit replacement map and verify exact matching before rewrite.
- **Windows encoding can silently break replacement maps.** In Windows PowerShell, `Set-Content -Encoding UTF8` writes a BOM that can prevent `git filter-repo --replace-text` matches.
- **Write replacement files as BOM-free UTF-8.** Use .NET UTF-8 encoding with BOM disabled to avoid hidden prefix bytes.
- **Treat force-push as a coordinated change event.** Notify collaborators and require fresh clones or hard resets after rewrite.

## Process

1. **Contain exposure.** Rotate compromised credentials and revoke old tokens.
2. **Scope contamination.** Identify affected commits, branches, tags, and file patterns.
3. **Create replacement rules file.** Build `git filter-repo --replace-text` mappings for each secret.
4. **Write replacement file safely on Windows.** Use BOM-free UTF-8 writing to avoid no-op rewrites.
5. **Run `git filter-repo`.** Rewrite history across required refs.
6. **Verify rewrite success.** Search full history and reflog for leaked values.
7. **Force-push rewritten refs.** Push all updated branches/tags and communicate reset instructions.
8. **Harden against recurrence.** Add ignore rules, pre-commit secret scanning, and checklist updates.

## Output format

1. **Incident scope summary** - what leaked and where
2. **Replacement rule file** - reproducible redaction mappings
3. **Rewrite command log** - exact commands run and refs touched
4. **Verification report** - proof that leaked values are absent post-rewrite
5. **Recovery actions** - collaborator reset instructions and prevention controls

## Quality checklist

- [ ] Compromised credentials were rotated before history rewrite
- [ ] Replacement rules were validated against known leaked samples
- [ ] Replacement file is BOM-free UTF-8 (especially on Windows)
- [ ] Rewritten history was verified across branches and tags
- [ ] Remote force-push completed for all affected refs
- [ ] Team reset instructions were distributed and acknowledged

## Avoid

- Rewriting history before rotating credentials.
- Using broad regex that can over-redact legitimate content.
- Writing replace-text files with UTF-8 BOM on Windows PowerShell.
- Assuming local rewrite is enough without remote force-push coordination.

## Example usage

> A secret was committed and merged into multiple branches. Help me run a safe `git filter-repo` remediation workflow on Windows, including a BOM-free replace-text file, verification commands, and collaborator recovery steps.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
