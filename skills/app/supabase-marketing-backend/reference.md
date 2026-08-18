# Supabase Marketing Backend — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Public form table (insert-only for anon, one table for all campaigns)

```sql
create table public.interest_signups (
  id bigint generated always as identity primary key,
  campaign text not null default 'general',
  email text not null check (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  name text check (name is null or length(name) between 1 and 120),
  hp text,                                   -- honeypot: must stay null (check below)
  created_at timestamptz not null default now(),
  constraint hp_empty check (hp is null or hp = '')
);
create unique index on public.interest_signups (campaign, lower(email));

alter table public.interest_signups enable row level security;
create policy anon_insert on public.interest_signups for insert to anon with check (true);
-- no select policy for anon: an anon GET returns []

-- per-campaign cap
create or replace function public.cap_campaign() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.interest_signups where campaign = new.campaign) >= 200 then
    raise exception 'campaign full' using errcode = 'check_violation';
  end if;
  return new;
end $$;
create trigger cap_campaign before insert on public.interest_signups for each row execute function public.cap_campaign();
```

## Anon-key verification (run before shipping the client)

```bash
H='-H "apikey: <anon>" -H "Authorization: Bearer <anon>" -H "Content-Type: application/json"'
curl -s -o /dev/null -w '%{http_code}\n' $H -H "Prefer: return=minimal" -d '{"campaign":"spring","email":"a@example.com"}' https://<ref>.supabase.co/rest/v1/interest_signups   # 201
# same again → 409 (duplicate)        bad email → 400 (check)        curl $H https://<ref>.supabase.co/rest/v1/interest_signups → []
```

## Reader role, policy, and view revoke

```sql
create role reporting login password '<strong-password>';
grant usage on schema public to reporting;
grant select on public.interest_signups, public.page_hits to reporting;
create policy reporting_read on public.interest_signups for select to reporting using (true);   -- GRANT alone reads 0 rows
create policy reporting_read on public.page_hits       for select to reporting using (true);

create view public.hits_daily as select date_trunc('day', created_at) d, path, count(*) from public.page_hits group by 1,2;
revoke select on public.hits_daily from anon, authenticated;   -- views bypass RLS and are auto-granted
```

Session pooler: host `aws-0-<region>.pooler.supabase.com`, port `5432`, db `postgres`, user `reporting.<project-ref>`.

## Beacon (non-personal, schema-lag fallback)

```js
(function () {
  var tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  var full = { path: location.pathname, ref_host: document.referrer ? new URL(document.referrer).host : null,
               device: matchMedia('(max-width: 768px)').matches ? 'mobile' : 'desktop', tz_region: tz && tz.split('/')[0] };
  var minimal = { path: location.pathname };
  function post(body) { return fetch('https://<ref>.supabase.co/rest/v1/page_hits', { method: 'POST',
    headers: { apikey: '<anon>', Authorization: 'Bearer <anon>', 'Content-Type': 'application/json', Prefer: 'return=minimal' },
    body: JSON.stringify(body), keepalive: true }); }
  post(full).then(function (r) { if (r.status === 400) return post(minimal); });   // columns not migrated yet
})();
```

CSP: `connect-src 'self' https://<ref>.supabase.co`. Include on the 404 page; exclude auth pages.

```css
[hidden] { display: none !important; }
```
