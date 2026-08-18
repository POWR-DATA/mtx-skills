# Example Input

## Context

A consultant has just deployed a static site to Azure Static Web Apps (`stapp-example-prod` in `rg-example-prod`, default hostname `<swa-default-hostname>.azurestaticapps.net`). The domain `example.com.au` is registered at VentraIP and currently points at the registrar's parking page. They want the site live on `www.example.com.au` with the apex redirecting, over HTTPS, today.

## Input provided

**Domain:** `example.com.au` — `www` primary, apex should redirect

**DNS provider:** VentraIP (manual portal, no ALIAS/ANAME support at the apex)

**Existing records:**
- `@` A → parking IP, TTL 14400 (4 hours)
- `www` CNAME → parking hostname, TTL 3600
- MX/SPF for Microsoft 365 — must not be touched

**SWA:** `stapp-example-prod` / `rg-example-prod` / subscription `<sub-id>`

**Symptoms so far:** yesterday's attempt to add `www` failed with "CNAME Record is invalid" twice, then went `Ready` — but the browser still shows `ERR_SSL_PROTOCOL_ERROR` on `https://www.example.com.au`. `az staticwebapp hostname show` reports `status: Ready` and `sslState: null`.

**Ask:** get both hostnames serving with valid certificates, apex → www redirect working, and a script I can re-run after any DNS change.
