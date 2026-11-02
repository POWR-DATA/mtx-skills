# Supabase Migration Promotion — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders. Never paste a token into a transcript.

---

## Find the production ref in the shipped bundle

`EXPO_PUBLIC_*` values are inlined into the JavaScript bundle at build time, so the deployed site tells you which project it talks to:

```bash
curl -s https://<your-site>/ | grep -oE '/_expo/static/js/web/[^"]+\.js' | sort -u \
  | while read -r js; do curl -s "https://<your-site>$js"; done \
  | grep -oE 'https://[a-z0-9]{20}\.supabase\.co' | sort -u
```

The same `grep` works on any shipped bundle. Compare the result with `.env`, the CI secrets and any connector configuration before naming a project "production".

## Deployed state per project

```bash
supabase link --project-ref <dev-ref>  && supabase migration list --linked
supabase link --project-ref <prod-ref> && supabase migration list --linked
```

A version with a Local value and an empty Remote value is pending on that project. Probe the behaviour too — print counts, never rows:

```bash
curl -s -X POST "https://<ref>.supabase.co/rest/v1/rpc/<public_read_fn>" \
  -H "apikey: <anon-key>" -H "Content-Type: application/json" -d '{<args>}' \
  | jq '{rows: length, unmasked: map(select(.masked != true)) | length}'   # adapt the predicate to your response
```

## Single-migration promotion via the query endpoint

```python
import json, os, sys, urllib.request
ref, path = sys.argv[1], sys.argv[2]                       # pass the ref explicitly; never rely on the linked project
req = urllib.request.Request(
    f"https://api.supabase.com/v1/projects/{ref}/database/query",
    data=json.dumps({"query": open(path, encoding="utf-8").read()}).encode(),
    headers={"Authorization": f"Bearer {os.environ['SUPABASE_ACCESS_TOKEN']}",
             "Content-Type": "application/json",
             "User-Agent": "<your-tool>/1.0"},             # default Python-urllib UA → Cloudflare "403 error code: 1010"
    method="POST")
print(urllib.request.urlopen(req).read().decode())        # only the LAST statement's result set comes back
```

| Response | Meaning |
|---|---|
| `403 error code: 1010` | Cloudflare blocked the client's User-Agent — set one explicitly |
| `401 Invalid access token` while `supabase projects list` works | The PAT expired or was revoked — rotate it; the CLI login is a separate credential |
| CLI rejects the token format | See `supabase-edge-functions` (new-format PATs and older CLIs) |

## Re-runnable DDL

```sql
create table if not exists public.<new_table> (...);
alter table public.<table> add column if not exists <col> text;
create index if not exists <idx> on public.<table> (<col>);
drop policy if exists <policy> on public.<table>;
create policy <policy> on public.<table> for select to authenticated using (...);
create or replace function public.<fn>(...) ...;          -- a changed return type needs drop function if exists first
drop trigger if exists <trg> on public.<table>;
create trigger <trg> ...;
```

## Live definition as the base

Fetch from the target project (through the query endpoint), save it, and diff it against the replacement:

```sql
select pg_get_functiondef('public.<fn>(<arg types>)'::regprocedure);
```

```bash
git diff --no-index live/<fn>.sql supabase/migrations/<version>_<name>.sql
```

The diff should show only the intended change. The saved live definition (it starts `CREATE OR REPLACE FUNCTION`) is the rollback for that function.

## One final SELECT for checks

```sql
-- ...migration statements above...
select json_build_object(
  'table_exists', (select to_regclass('public.<new_table>') is not null),
  'policies',     (select json_agg(policyname order by policyname) from pg_policies
                   where schemaname = 'public' and tablename = '<new_table>'),
  'audit_fn_ok',  (select pg_get_functiondef('public.<audit_fn>'::regproc) like '%<new_table>%'),
  'anon_exec',    (select json_agg(p.proname) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                   where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute'))
) as checks;
```

## Record the version (a separate request)

```sql
insert into supabase_migrations.schema_migrations (version, name)
values ('<yyyymmddhhmmss>', '<migration_name>')
on conflict (version) do nothing;
```

Or, once linked to that project, `supabase migration repair --status applied <version>`. If this request fails, the next `db push` re-applies the file — the reason it must be re-runnable.
