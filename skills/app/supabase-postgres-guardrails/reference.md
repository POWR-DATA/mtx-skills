# Supabase Postgres Guardrails — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Grants and anon audit

In the migration that creates each function:

```sql
create or replace function public.<internal_helper>(p_account uuid) returns boolean
language sql stable security definer set search_path = '' as $$ ... $$;

revoke execute on function public.<internal_helper>(uuid) from public, anon, authenticated;
grant  execute on function public.<internal_helper>(uuid) to authenticated;   -- or service_role, or nobody
```

Once, so Supabase's defaults stop granting new functions to `anon` and `authenticated`:

```sql
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;
```

Default privileges only affect functions created later by the role that ran the statement, and Postgres documents that a schema-scoped revoke cannot remove a grant made globally — PUBLIC's EXECUTE is one. Keep the per-function revoke and the audit regardless.

Audit — expect zero rows:

```sql
select p.oid::regprocedure as fn
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and has_function_privilege('anon', p.oid, 'execute')
  and p.proname <> all (array['<public_read_fn>']);   -- the allow-list of intentionally public functions
```

Call as anon through PostgREST:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST "https://<your-project-ref>.supabase.co/rest/v1/rpc/<internal_helper>" \
  -H "apikey: <anon-key>" -H "Content-Type: application/json" -d '{"p_account":"<uuid>"}'
# 401/403 (42501 permission denied) expected; a 200 means anon can still execute it
```

## Null-safe ownership

```sql
where owner_id is not distinct from auth.uid()            -- wrong: true when owner_id is null and the caller is signed out
where auth.uid() is not null and owner_id = auth.uid()    -- right
```

## Masked location reads

`geom` is the exact point; `public_geom` is the snapped point (e.g. `st_snaptogrid(geom, <cell>)`). Pick one point per row and use it for everything:

```sql
select r.id, st_y(g.pt) as lat, st_x(g.pt) as lng,
       case when m.masked then null else st_distance(g.pt::geography, here) end as distance_m   -- no distance for masked rows
from public.<records> r
cross join lateral (select <caller may not see the exact point> as masked) m
cross join lateral (select case when m.masked then r.public_geom else r.geom end as pt) g
where st_dwithin(g.pt::geography, here, greatest(p_radius_m, <min_radius_m>))   -- filter on the point you return
order by g.pt::geography <-> here;                                               -- and sort on it
```

Box reads: widen any box below `<min_box_m2>` to the minimum (or refuse with P0001) before filtering, and filter masked rows with `public_geom && <box>`, never `geom`.

## Atomic duplicate check

```sql
-- option A: let a unique partial index decide
create unique index if not exists <records>_one_live_per_place
  on public.<records> (<normalised_place_key>) where status <> 'removed';
-- in the RPC:
exception when unique_violation then
  raise exception 'That place is already listed' using errcode = 'P0001';

-- option B: serialise the check inside the RPC
perform pg_advisory_xact_lock(hashtext('<record>:' || <normalised_place_key>));
if exists (select 1 from public.<records> where <place_key> = <normalised_place_key> and status <> 'removed') then
  raise exception 'That place is already listed' using errcode = 'P0001';
end if;
```

Existing duplicates must be resolved before option A's index can be created.

## Status recompute that respects moderation

```sql
update public.<records> r
set status = case
      when r.status in ('removed', 'hidden', 'moderation_hold') then r.status   -- not recompute's to change
      when c.confirmations >= <threshold> then 'verified'
      else 'unverified' end
from (select count(*) filter (where <confirming>) as confirmations
      from public.<record>_votes where <record>_id = p_id) c
where r.id = p_id;
```

Every vote, rating and clear RPC, before it writes:

```sql
if not exists (select 1 from public.<records> where id = p_id and status in ('verified', 'unverified')) then
  raise exception 'This entry is not open for votes' using errcode = 'P0001';
end if;
```

Moderation restore: put back the prior status, then `perform public.recompute_<record>(p_id);`.

## Server-side resolution of provider ids

The client sends only the provider's place id; the server looks it up and stores what the provider returned.

```ts
// Edge Function (see supabase-edge-functions); body = { place_id }
const place = await lookupPlace(place_id);              // server-to-geocoder call; a fabricated "lat,lng" id resolves to nothing
if (!place || !inRegion(place)) return refuse(400, "Choose an address from the list");
await admin.rpc("add_<record>_verified", { p_place_id: place.id, p_lat: place.lat, p_lng: place.lng, p_label: place.label });
// add_<record>_verified: EXECUTE granted to service_role only
```

## Trigger patterns

Normalised change detection:

```sql
if nullif(btrim(new.<field>), '') is distinct from nullif(btrim(old.<field>), '') then
  new.<field>_verified := false;
end if;
```

Two-table sync with row-level AFTER triggers — each write is a no-op when the other side already agrees, so the opposite trigger does not fire again:

```sql
-- AFTER UPDATE OF <flag> ON <accounts>, when the flag turns on
insert into public.<allowlist> (email) values (new.email) on conflict do nothing;   -- no target: also covers unique (lower(email))
-- AFTER DELETE ON <allowlist>
update public.<accounts> set <flag> = false where lower(email) = lower(old.email) and <flag>;
```

Hold a value instead of failing the write:

```sql
-- BEFORE INSERT OR UPDATE ON <profiles>
if <caller may not set <field>> then
  new.<field> := case when tg_op = 'INSERT' then <default> else old.<field> end;
end if;
return new;
```

## PostgREST error codes

| SQLSTATE | HTTP | Use |
|---|---|---|
| P0001 (bare `raise exception`) | 400, message passed through | User-facing refusals |
| P0002 and other P0xxx | 500 | Never for something the user should read |
| 23505 unique violation | 409 | Catch and re-raise as P0001 with a readable message |
| 42501 insufficient privilege | 401/403 | What anon should get from a revoked function |

`select … into strict` with no row also raises P0002 — check `found` and raise P0001 instead.

## SQL tests in CI

`supabase/tests/<area>_test.sql` (pgTAP; runs inside a transaction that is rolled back):

```sql
begin;
select plan(4);
insert into auth.users (id, email) values ('<uuid-a>', 'a@example.com'), ('<uuid-b>', 'b@example.com');
insert into public.<records> (id, owner_id) values ('<rec-a>', '<uuid-a>'), ('<rec-null>', null);

set local role anon;                                                   -- signed-out visitor
select throws_ok($$ select public.<internal_helper>('<uuid-a>') $$, '42501', null, 'anon cannot run internal helpers');
select is((select count(*) from public.my_<records>()), 0::bigint,   -- an owner-filtered read anon may call
          'anon matches no null-owner row');
select is((select count(*) from public.<record>_near(<lat>, <lng>, 1) where masked and distance_m is not null),
          0::bigint, 'no distance for masked rows');

set local role authenticated;                                          -- another signed-in user
select set_config('request.jwt.claims', '{"sub":"<uuid-b>","role":"authenticated"}', true);
select throws_ok($$ select public.update_<record>('<rec-a>', '{}') $$, 'P0001', null, 'B cannot edit A''s record');

select * from finish();
rollback;
```

```yaml
# .github/workflows/db-tests.yml (excerpt)
- uses: supabase/setup-cli@v1
  with: { version: latest }
- run: supabase db start   # local Postgres with supabase/migrations applied
- run: supabase test db    # runs supabase/tests/*.sql
```
