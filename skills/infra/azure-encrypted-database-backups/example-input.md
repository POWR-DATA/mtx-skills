# Example Input

## Context

GardenTrack runs on a Supabase project (Postgres 15, about 1.8 GB). Supabase's own backups are the first line of defence, but the business wants an independent monthly copy in Azure that nobody — including the team — can delete or alter for 400 days. The Azure subscription already has a Container Registry, a Key Vault and a Log Analytics workspace in `australiaeast`.

## Input provided

**Frequency and timing:** monthly, landing in the early hours of the 2nd, Sydney time.

**Retention:** 400 days, cannot be shortened once set.

**Keys:** the operations lead holds the day-to-day key. The director wants a recovery key that lives offline in the office safe.

**Alerts:** the operations shared mailbox and the director's address.

**What happened on a first attempt in a test subscription:**

1. The account was created LRS and switched to GZRS afterwards; no template deploy or account change worked for over a day.
2. The failure alert rule (any Warning from the job) paged on a run that had finished cleanly.
3. The alert showed as fired, but no email ever arrived.
4. As subscription Owner, downloading a backup failed with an authorisation error. After granting a data role on the storage account, removing it failed because of the delete lock.
5. The script that created the backup role also reset the `postgres` password; the Wi-Fi dropped mid-run and the new password was never saved.

**Database notes:** `pg_cron` runs several jobs hourly; `cron.job_run_details` holds over 100,000 rows. `pg_net` and Vault are enabled.

**Ask:** design the production set-up, the alerting, and a restore runbook we can rehearse.
