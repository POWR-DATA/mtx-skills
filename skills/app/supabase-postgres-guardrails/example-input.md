# Example Input — Supabase Postgres Guardrails

> Review our next migration before it goes near production. Anon must not be able to call anything it shouldn't, and home gardens must stay masked for signed-out visitors. Fix what's unsafe and give us SQL tests that run in CI.

**App:** GardenTrack — members add community and home gardens to a public map; visitors browse without signing in. Home gardens show a snapped location to everyone except their owner.

**Migration under review:** `supabase/migrations/20261101090000_garden_contacts.sql`

- `owner_contact(p_garden uuid)` — `security definer`; returns the owner's email and street address for the garden page
- `is_member_of(p_user uuid, p_club uuid)` — helper called inside RLS policies
- `add_garden(p_place_id text, p_lat float8, p_lng float8, p_label text)` — checks no live garden exists at the place, then inserts; the app only offers geocoder results in a dropdown
- `gardens_near(p_lat float8, p_lng float8, p_radius_m int)` — returns snapped lat/lng for home gardens, but filters and orders on `geom` and returns `distance_m` for every row
- `update_garden(p_garden uuid, p_patch jsonb)` — `where id = p_garden and owner_id is not distinct from auth.uid()`; raises `'Garden not found' using errcode = 'P0002'`
- `recompute_garden(p_garden uuid)` — sets `verified`/`unverified` from confirmations and keeps `removed`
- Trigger `profiles_phone_changed` — `if new.phone <> old.phone then new.phone_verified := false`

**Statuses:** `unverified`, `verified`, `hidden`, `moderation_hold`, `removed`. Admin-created gardens have a null `owner_id`; deleting an account sets `owner_id` to null.

**Known behaviour:** some app screens save an empty phone as `''`, others as null. A tester produced two identical gardens with a double tap.

**Existing grants:** an early migration ran `revoke execute on all functions in schema public from anon`.

**Tests today:** a Node script that checks the migration text contains `security definer` and `auth.uid()`.
