# Example Input

## Context

A five-page static HTML marketing site (no build step, no templating) is live on Azure Static Web Apps at `www.example.com`. It was set up with the Static Website Hosting skill; `staticwebapp.config.json` currently has only a sitemap route and a `/*` route carrying the security headers. The repo root also contains `docs/`, `infra/`, `scripts/` and `OPERATIONS.md`, all of which turned out to be fetchable on the live site.

## Input provided

**Current config:** `/sitemap.xml` route + `/*` route with `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`; no cache rules, no CSP, no `mimeTypes`

**Pages:** `/`, `/services`, `/about`, `/contact`, `/reset-password.html` (Supabase password-reset page loading supabase-js from jsDelivr)

**Shared markup:** nav and footer copied into every page; a `scripts.js` sets the footer year and (only on `/contact`) wires a form

**Changes wanted this sprint:**
1. Hide `docs/`, `infra/`, `scripts/`, `.github/` and `OPERATIONS.md` from the live site
2. Add a hamburger menu for mobile
3. Move `/reset-password.html` to `/account/reset-password` — the mobile app deep-links to the old URL
4. Introduce a CSP with `script-src 'self'` — there are a couple of `onclick=""` attributes and one inline `<script>` on the contact page
5. Serve a `team/jane-citizen.vcf` contact card and the `/.well-known/apple-app-site-association` file correctly

**Constraint:** users reported seeing "the old JavaScript" for an hour after the last deploy.
