# Azure Encrypted Database Backups

Run encrypted, immutable Postgres backups on Azure — a scheduled Container Apps job with Key Vault credentials, age encryption to two recipients, locked blob retention, restore rehearsal, and alerts that do not page falsely.

## What this skill does

Designs and proves an off-platform backup for a Postgres or Supabase database: a Container Apps job dumps with a read-only role, encrypts to an operator key and a sealed recovery key, and writes to GZRS Blob Storage under a locked time-based immutability policy. It covers the parts that are irreversible or silently wrong — lock rehearsal and teardown order, job wiring order, UTC schedules and missed runs, alert rules that page on clean finishes, unverified alert emails, and the access a restore actually needs — and ends with a restore whose content is compared table by table against live.

## When to use it

- You need backups outside the database provider that nobody can alter or delete before retention ends
- You are about to create the storage account or lock a retention policy
- A backup job is running but you have never restored from it
- A failure alert pages on clean runs, or alert emails never arrive
- You hold subscription Owner and still cannot download a backup

## Example use cases

- Stand up a monthly encrypted `pg_dump` of a Supabase project into immutable Blob Storage in Australia
- Rehearse a 1-day locked policy and tear it down in the order the lock allows
- Replace a warning-based alert that fires on every clean finish with one that fires only on failures
- Write a restore runbook that grants temporary access, restores locally and compares per-table hashes with live

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — lock detection and teardown order, read-only role SQL and SCRAM verifier, recipient validation, job wiring order, missed-run check, alert query shape, restore access and hash comparison |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the database, frequency, retention, region, key custody and alert recipients, then work through the structured output. Load `reference.md` for the commands, SQL and query shapes. Related skills: `windows-cli-gotchas` for running `az` from PowerShell, and `docker-compose-database-lab` for the throwaway restore database.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
