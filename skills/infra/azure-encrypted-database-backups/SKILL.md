---
name: azure-encrypted-database-backups
description: Run encrypted, immutable Postgres backups on Azure — a scheduled Container Apps job with Key Vault credentials, age encryption to two recipients, locked blob retention, restore rehearsal, and alerts that do not page falsely
author: PowerData
version: 1.0.0
license: MIT
---

# Azure Encrypted Database Backups

## Purpose

Design, build and prove an off-platform backup of a Postgres database (including Supabase) on Azure: a scheduled Container Apps job dumps with a read-only role whose credentials live in Key Vault, encrypts each dump to two age recipients, and writes it to Blob Storage under a locked immutability policy — with a rehearsed restore and alerts that fire on real failures and nothing else.

## When to use

When a database needs backups that sit outside the database provider and cannot be altered or deleted by a compromised credential — for example a monthly `pg_dump` of a Supabase project kept for a fixed retention period. Apply before creating the storage account (redundancy and locked retention are hard or impossible to change later), again when wiring alerts, and whenever a restore has not yet been rehearsed.

## Inputs expected

Partial inputs are acceptable — state assumptions for the rest.

- The database: provider (Supabase or plain Postgres), major version, size, and noisy tables such as job history
- Backup frequency, retention period, and the local time zone the run should land in
- The Azure region, and whether a second in-country copy is required
- Who holds the operator age key, and where the offline recovery key will be sealed
- Who must be alerted, and at which email addresses
- Which of Container Registry, Key Vault and Log Analytics already exist

For running `az` and passing JSON from PowerShell, see `windows-cli-gotchas`; for the throwaway restore database, see `docker-compose-database-lab`.

---

## Guiding principles

- **Choose redundancy at creation.** Create the storage account as GZRS from the start. Converting an existing account is a background live migration that took more than a day and blocked every account update and template deploy until it finished. Sydney's geo pair is fixed as Melbourne (there is no Brisbane region), which still keeps the second copy in Australia.
- **Container-level time-based immutability is the protection — drop blob versioning, which it makes redundant.** Once the policy is locked, the container, and so the account, cannot be deleted until every blob is past retention **and** deleted. Rehearse with a 1-day retention and lock it to prove locking works. A template redeploy that sets an already-locked policy fails, so detect the lock first and leave it alone.
- **Dump with a dedicated read-only role, never the admin login.** Grant `pg_read_all_data`, set `default_transaction_read_only`, give it a low connection limit, and set its password as a SCRAM-SHA-256 verifier computed locally so the plain text never leaves your machine except into Key Vault. Never reset a production admin password from a script — a mid-run network drop left a reset password stored nowhere.
- **Credentials come from Key Vault through the job's managed identity**, never as plain job secrets.
- **Encrypt every backup to two age recipients** — the operator key plus a sealed offline recovery key — and refuse to run with fewer than two. Validate the recipients file so a pasted `AGE-SECRET-KEY` is rejected. Locked backups can never be re-encrypted, so an exposed private key plus storage access is a breach of the whole retained dataset — treat it as one.
- **Create unwired, grant, then wire.** A job that pulls from a private registry with its own managed identity cannot be created with the registry set, because `AcrPull` can only be granted once the identity exists. Tag the image by a hash of the job's files, not the commit, and check the tag exists before pointing the job at it.
- **The schedule is UTC, and a missing run is silent.** Job cron is UTC — `0 16 1 * *` (16:00 on the 1st) is 2 am on the 2nd in AEST. A run that never starts raises no failure, so add a separate missed-run check job.
- **Alert on failures, not warnings.** Job console output did not reach Log Analytics (only platform events did), a clean job finish is logged as a Warning, and Key Vault secret-refresh timeouts (`context canceled`) appear as transient warnings — so a warning-based failure rule pages falsely. Alert on failed executions, or on warnings not followed by a healthy event within 5 minutes, and replay old and new rule queries over real logs before applying.
- **An alert that fired is not an email that arrived.** An action group delivers nothing to an address until it is verified with the one-time code within 30 minutes of saving, even though the alert shows as fired. An unchanged re-save does not resend the code: remove the address, save, add it back and save. Once verified it holds tenant-wide. Prove delivery with the action group's test notification rather than trusting "action ran".
- **Restore access is temporary, and "restore finished" proves nothing.** Subscription Owner cannot read blob contents — grant a temporary Storage Blob Data Reader at resource-group scope, because a `CanNotDelete` lock on the storage account also blocks removing role assignments scoped to the account. Close the firewall and remove the role in a `finally` step every time. Prove the dump by comparing per-table content hashes and row counts against live.

## Process

1. **Fix the parameters** — frequency, retention, the UTC cron for the intended local time, region and geo pair, key custody, alert recipients.
2. **Rehearse the lock** in a scratch resource group: container immutability at 1 day, lock it, confirm deletes are refused, then tear down in order — soft delete off, temporary data role, firewall open to your IP, delete the blobs, and only then the container and resource group (*Storage* in [`reference.md`](reference.md)).
3. **Create the real storage** as GZRS with container-level immutability at the real retention (unlocked for now), versioning off, a `CanNotDelete` lock and the firewall closed. Make templates check the policy state and skip a locked policy.
4. **Create the read-only role** with the locally computed SCRAM-SHA-256 verifier; store the connection secret in Key Vault (*Credentials*).
5. **Generate the age keys** — operator and offline recovery; seal the recovery key; the recipients file holds public `age1...` keys only and the job validates it (*Encryption*).
6. **Build the image** tagged by a hash of the job's files; build only when that tag is missing; confirm it exists before use.
7. **Create the job unwired** with a placeholder image and a system-assigned identity, grant `AcrPull`, Key Vault and storage write roles, then set the registry, Key Vault secret references and the real image. Dump with `--exclude-table-data=cron.job_run_details` — pg_cron's job history, which can run to 100k+ rows (*Job wiring*, *Encryption*).
8. **Add the missed-run check job** — it fails when no new backup blob exists for the period, which surfaces through the failed-execution alert.
9. **Write the alert rules** on failed executions or unrecovered warnings; replay old and new queries over real logs and record what each would have fired on (*Alerting*).
10. **Verify every alert email** within the 30-minute window, then send the action group's test notification and confirm it arrived.
11. **Run the first backup manually** and read its output immediately with `az containerapp job logs show` — finished attempts' logs disappear within minutes.
12. **Rehearse the restore** with access granted and revoked in `try`/`finally`: restore into a throwaway local Postgres of the same major version with the Supabase roles pre-created, accept errors only from pg_cron, pg_net and Vault objects, and compare per-table hashes and row counts against live (*Restore*).
13. **Lock the real policy** once the restore matches — locking is irreversible.
14. **Rehearse a restore into a fresh Supabase project** separately before relying on the backups; plain Postgres proves completeness only.

## Output format

1. **Design summary** — region and geo pair, redundancy, retention, schedule in UTC and local time
2. **Storage protection** — immutability policy and lock state, versioning, delete lock, firewall, redeploy lock check, teardown order
3. **Credentials and identity** — read-only role, verifier method, Key Vault secrets, role assignments for each job identity
4. **Encryption and key custody** — recipients, validation rules, where each private key lives, breach stance
5. **Job wiring** — creation order, image tag scheme, cron, dump flags, missed-run check
6. **Alerting** — rule logic, replay results, action group verification and test notification
7. **Restore runbook and evidence** — access grant with cleanup, restore steps, expected errors, hash and count comparison, Supabase rehearsal status

## Quality checklist

- [ ] Storage account created as GZRS, not converted; geo pair stated
- [ ] Container-level time-based immutability set; blob versioning off
- [ ] Locking proven on a 1-day rehearsal and torn down in the documented order
- [ ] Templates detect an already-locked policy and leave it alone
- [ ] Backup role has `pg_read_all_data`, `default_transaction_read_only` and a low connection limit; password set as a locally computed SCRAM-SHA-256 verifier
- [ ] Job reads credentials from Key Vault with its managed identity; no plain job secrets; no script resets an admin password
- [ ] Encryption refuses fewer than two recipients and rejects a pasted `AGE-SECRET-KEY`; recovery key sealed offline
- [ ] Job created unwired, granted, then wired; image tag is a files hash confirmed to exist
- [ ] Cron written in UTC with the local time stated; missed-run check job in place
- [ ] Alerts fire on failed executions or unrecovered warnings, and were replayed over real logs
- [ ] Every alert address verified and a test notification received
- [ ] Restore role granted at resource-group scope; firewall closed and role removed in `finally`
- [ ] Restore into same-major Postgres matched live on per-table hashes and row counts; `cron.job_run_details` excluded
- [ ] Restore into a fresh Supabase project done, or flagged as outstanding

## Avoid

- Converting an existing storage account to GZRS — every update and deploy is blocked until the migration finishes
- Enabling blob versioning alongside container immutability
- Locking a real policy before a 1-day rehearsal has proven both the lock and the teardown
- Deleting the container or resource group before the blobs — a locked policy refuses it
- Redeploying a template that re-sets a locked immutability policy
- Dumping with the admin login, sending the plain-text password over SQL, or resetting a production admin password from a script
- Storing database credentials as plain job secrets
- Encrypting to one recipient, or accepting a recipients file that contains a private key
- Creating the job with the registry already set, or tagging the image by commit
- Alerting on Warning-level job events — clean finishes and Key Vault `context canceled` refreshes are warnings
- Trusting "fired" or "action ran" as proof an email was delivered
- Granting restore access on the locked storage account itself — you will not be able to remove it
- Treating "restore finished", or a plain-Postgres restore, as proof a Supabase project can be rebuilt

## Example usage

> "We need monthly encrypted backups of our Supabase database kept in Azure for 400 days where nobody, including us, can delete them early. Last time the GZRS conversion blocked our deploys for a day, the failure alert paged on a clean run, and as subscription Owner I couldn't even download a backup to test it. Design this properly and give me a restore runbook."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
