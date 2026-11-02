# Azure Encrypted Database Backups — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Storage

Create the account as GZRS from the start (`--sku Standard_GZRS`); converting later is a live migration that blocks every update and deploy until it finishes. In `australiaeast` (Sydney) the geo pair is `australiasoutheast` (Melbourne).

**Detect a locked policy before any redeploy** — setting an already-locked policy fails the deployment:

```bash
state=$(az storage container immutability-policy show -g <rg> --account-name <account> \
          --container-name <container> --query state -o tsv)      # Locked | Unlocked | empty
```

```bicep
param immutabilityLocked bool          // from the check above; true = leave the policy alone
resource policy 'Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies@2023-05-01' = if (!immutabilityLocked) {
  parent: container
  name: 'default'
  properties: { immutabilityPeriodSinceCreationInDays: retentionDays }
}
// no blob versioning: container immutability makes it redundant
```

Lock (irreversible): `az storage container immutability-policy lock -g <rg> --account-name <account> -c <container> --if-match <etag>`

**Rehearsal teardown order** (1-day retention, locked). The container — and so the account — cannot be deleted until every blob is past retention and deleted:

```bash
az storage account blob-service-properties update -g <rg> -n <account> \
  --enable-delete-retention false --enable-container-delete-retention false       # 1. soft delete off
az role assignment create --assignee-object-id <your-object-id> --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope /subscriptions/<subscription-id>/resourceGroups/<rg>   # 2. temporary data role
az storage account network-rule add -g <rg> --account-name <account> --ip-address <your-public-ip>     # 3. firewall
az storage blob delete-batch --auth-mode login --account-name <account> -s <container>                # 4. blobs (past retention)
# remove any CanNotDelete management lock (az lock delete ...) before the next two
az storage container delete --auth-mode login --account-name <account> -n <container>                 # 5. container
az group delete -n <rg> --yes                                                                          # 6. resource group
```

## Credentials

Read-only backup role — never the admin login:

```sql
create role <backup_role> login connection limit 2;
grant pg_read_all_data to <backup_role>;
alter role <backup_role> set default_transaction_read_only = on;
alter role <backup_role> password 'SCRAM-SHA-256$4096:<salt>$<stored-key>:<server-key>';  -- verifier, not the password
```

Compute the verifier locally so the plain text is never sent over SQL or written to statement logs:

```python
import base64, hashlib, hmac, os, secrets, string
pw = ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(40))  # ASCII: SASLprep is a no-op
salt, it = os.urandom(16), 4096
salted = hashlib.pbkdf2_hmac('sha256', pw.encode(), salt, it)
client_key = hmac.new(salted, b'Client Key', 'sha256').digest()
server_key = hmac.new(salted, b'Server Key', 'sha256').digest()
b64 = lambda b: base64.b64encode(b).decode()
verifier = f"SCRAM-SHA-256${it}:{b64(salt)}${b64(hashlib.sha256(client_key).digest())}:{b64(server_key)}"
# send pw straight to Key Vault; print only the verifier
```

Never reset a production admin password from a script — a dropped connection mid-run can leave the new password stored nowhere.

## Encryption

Job entrypoint — validate recipients, then dump straight into `age`:

```bash
set -euo pipefail                                   # a failed pg_dump must fail the run, not upload an empty file
keys=$(grep -vE '^\s*(#|$)' "$RECIPIENTS_FILE")
if grep -q 'AGE-SECRET-KEY' <<<"$keys"; then echo "recipients file contains a private key" >&2; exit 1; fi
if grep -vqE '^age1[a-z0-9]{58}$' <<<"$keys"; then echo "invalid recipient line" >&2; exit 1; fi
[ "$(wc -l <<<"$keys")" -ge 2 ] || { echo "need at least two recipients" >&2; exit 1; }

pg_dump "$PG_URL" -Fc --exclude-table-data=cron.job_run_details \
  | age -R "$RECIPIENTS_FILE" > "/tmp/<db>-$(date -u +%Y%m).dump.age"
# az login --identity; az storage blob upload --auth-mode login ...
```

Install a `pg_dump` client of the server's major version in the image.

## Job wiring

Order matters — the system-assigned identity must exist before `AcrPull` can be granted:

```bash
az containerapp job create -n <job> -g <rg> --environment <aca-env> \
  --trigger-type Schedule --cron-expression "0 16 1 * *" \
  --image mcr.microsoft.com/k8se/quickstart-jobs:latest --mi-system-assigned    # 1. unwired; cron is UTC
pid=$(az containerapp job show -n <job> -g <rg> --query identity.principalId -o tsv)    # 2. grant
az role assignment create --assignee-object-id $pid --assignee-principal-type ServicePrincipal --role AcrPull --scope <acr-id>
az role assignment create --assignee-object-id $pid --assignee-principal-type ServicePrincipal --role "Key Vault Secrets User" --scope <kv-id>
az role assignment create --assignee-object-id $pid --assignee-principal-type ServicePrincipal --role "Storage Blob Data Contributor" --scope <container-id>
az containerapp job registry set -n <job> -g <rg> --server <acr>.azurecr.io --identity system    # 3. wire
az containerapp job secret set -n <job> -g <rg> --secrets "pg-url=keyvaultref:<kv-secret-uri>,identityref:system"
az containerapp job update -n <job> -g <rg> --image <acr>.azurecr.io/pg-backup:$tag --set-env-vars PG_URL=secretref:pg-url
```

Image tag from the job's files, built only when missing, and confirmed before `job update`:

```bash
tag=$(cat job/Dockerfile job/*.sh job/recipients.txt | sha256sum | cut -c1-12)
az acr repository show -n <acr> --image pg-backup:$tag >/dev/null 2>&1 || az acr build -r <acr> -t pg-backup:$tag job/
az acr repository show -n <acr> --image pg-backup:$tag >/dev/null       # fail here, not at the next scheduled run
```

**Missed-run check** — a second scheduled job (Storage Blob Data Reader) that exits non-zero when this period's blob is absent, so the failed-execution alert covers a run that never started:

```bash
latest=$(az storage blob list --auth-mode login --account-name <account> -c <container> \
          --query "max_by([], &properties.creationTime).properties.creationTime" -o tsv)
[ "$(date -u -d "$latest" +%Y%m)" = "$(date -u +%Y%m)" ] || { echo "no backup this month" >&2; exit 1; }
```

## Alerting

Read console output while it exists — it did not reach Log Analytics, and finished attempts' logs disappear within minutes:

```bash
az containerapp job execution list -n <job> -g <rg> -o table
az containerapp job logs show -n <job> -g <rg> --execution <execution-name> --container <container-name>
```

Rule shape: warnings not followed by a healthy event for the same execution within 5 minutes. Column names differ between `ContainerAppSystemLogs_CL` and the resource-specific table — check yours, and take the reason values from replayed real logs:

```kusto
let logs = ContainerAppSystemLogs_CL | where JobName_s == "<job>";
let healthy = logs | where Reason_s in (<healthy-reasons>) | project ExecutionName_s, HealthyAt = TimeGenerated;
logs
| where Type_s == "Warning" and Reason_s !in (<healthy-reasons>)   // a clean finish is itself a Warning
| where TimeGenerated < ago(5m)                                     // too new to judge yet
| join kind=leftouter healthy on ExecutionName_s
| summarize Recovered = countif(HealthyAt between (TimeGenerated .. TimeGenerated + 5m)) by ExecutionName_s, Reason_s, TimeGenerated
| where Recovered == 0
```

Replay old and new queries over the last few real runs and list what each would have fired on — a Key Vault `context canceled` refresh and a clean finish must not.

**Action group email:** enter the one-time code within 30 minutes of saving. If it expired, remove the address, save, add it back, save. Then send the action group's test notification and confirm the email arrived.

## Restore

Owner cannot read blobs. Grant at **resource-group** scope (a `CanNotDelete` lock on the account blocks removing account-scoped assignments) and always clean up:

```powershell
$scope = '/subscriptions/<subscription-id>/resourceGroups/<backup-rg>'
$me = az ad signed-in-user show --query id -o tsv
try {
  az role assignment create --assignee-object-id $me --assignee-principal-type User --role 'Storage Blob Data Reader' --scope $scope | Out-Null
  az storage account network-rule add -g <backup-rg> --account-name <account> --ip-address <your-public-ip> | Out-Null
  # assignments and rules take a minute or two to apply; retry the download
  az storage blob download --auth-mode login --account-name <account> -c <container> -n <blob> -f backup.dump.age
} finally {
  az storage account network-rule remove -g <backup-rg> --account-name <account> --ip-address <your-public-ip> | Out-Null
  az role assignment delete --assignee $me --role 'Storage Blob Data Reader' --scope $scope
}
```

Rehearse into a throwaway Postgres of the **same major version**:

```bash
age -d -i <operator-key-file> backup.dump.age > backup.dump
docker run -d --name restore-test -e POSTGRES_PASSWORD=<local-only> -p 5433:5432 postgres:<live-major>
psql -h localhost -p 5433 -U postgres -c "create role anon nologin; create role authenticated nologin;
  create role service_role nologin; create role authenticator noinherit login; create role supabase_admin;
  create role supabase_auth_admin; create role supabase_storage_admin;"   # add any role pg_restore reports missing
pg_restore -h localhost -p 5433 -U postgres -d postgres backup.dump 2>&1 | tee restore.log
grep -i error restore.log      # every error should name a pg_cron, pg_net or Vault object
```

Per-table content hash and row count — run the same file against live (backup role) and the restore, then diff:

```sql
set timezone = 'UTC';
select format('select %L as tbl, count(*) as n, md5(coalesce(string_agg(t::text, %L order by t::text), %L)) as h from %I.%I t',
              schemaname || '.' || tablename, E'\n', '', schemaname, tablename)
from pg_tables
where schemaname not in ('pg_catalog', 'information_schema', 'cron', 'net', 'vault')
order by 1 \gexec
```

Explain every difference (tables written since the dump will drift). This proves completeness only — rehearse a restore into a fresh Supabase project separately before relying on it.
