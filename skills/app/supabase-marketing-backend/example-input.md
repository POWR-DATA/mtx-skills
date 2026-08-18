# Example Input

## Context

Northwind Analytics runs a five-page static marketing site on Azure Static Web Apps (Free tier — no access logs) with a `script-src 'self'` CSP. They already use Supabase for their product. Two flyers with QR codes are about to go out and marketing wants to know how many people land on the promo pages and to capture "register interest" sign-ups.

## Input provided

**Supabase:** project ref `<project-ref>`, SQL access via the dashboard, anon key available for the site

**Forms:** one "register interest" form on `/promotions/spring` and one on `/promotions/winter` — fields: name, email; each campaign capped at 200 sign-ups; one entry per email per campaign; the first 50 in each get a voucher (issued manually by marketing)

**Page hits:** count visits to `/`, `/promotions/*`, `/services` and the 404 page (mistyped printed URLs). No cookies, no personal data — the privacy policy must be able to say so.

**Readers:** marketing wants to open sign-ups and daily hit counts in Excel; a `reporting` role is acceptable

**Site constraints:** static HTML + one `scripts.js`; the auth pages `/reset-password` and `/confirm-email` must not run any tracking; a previous attempt at a success card stayed visible on load despite `hidden`

**Ask:** SQL, policies, front-end wiring, the CSP change, the reader role, and proof that the anon key cannot read anything.
