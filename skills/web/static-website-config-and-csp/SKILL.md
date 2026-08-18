---
name: static-website-config-and-csp
description: Configure and safely change a live static site on Azure Static Web Apps — staticwebapp.config.json routes, headers, caching and MIME types, Content Security Policy, and the front-end gotchas of editing a static HTML site in production
author: PowerData
version: 1.0.0
license: MIT
---

# Static Website Config and CSP

## Purpose

Own the `staticwebapp.config.json` and front-end layer of a live static site: security headers, cache policy, MIME types and routes (hidden files, redirects, rewrites), a Content Security Policy that is tightened without breaking pages, and the hard-won rules for editing a multi-page static HTML site that is already in production. Split from `static-website-hosting`, which provisions and deploys the site.

## When to use

After the site is live (see `static-website-hosting`), whenever you:

- Add or change headers, cache rules, MIME types, redirects, or rewrites in `staticwebapp.config.json`
- Introduce or tighten a CSP, or add JavaScript/CSS to a CSP-protected site
- Reorganise pages into subfolders, add a mobile menu, or edit shared markup across pages
- Need to hide committed internal files, serve unusual file types (`.vcf`, extensionless well-known files), or host an auth page on the static site

## Inputs expected

Partial inputs are fine — infer from the repo and ask only where needed.

- The current `staticwebapp.config.json` and the site's folder layout
- The current CSP (if any) and where scripts/styles live (inline vs external)
- Which pages/URLs are public, transient (auth), or app deep-link targets
- What is being changed (new page, moved page, new script, header change, new file type)

---

## Guiding principles

- **Keep `staticwebapp.config.json` in source control** and use it for headers, MIME types, and explicit routes for files (e.g. `sitemap.xml`) that the SPA fallback would otherwise intercept.
- **Security headers go in `globalHeaders`, not a `/*` route.** Route-based headers apply only to HTML responses; `globalHeaders` covers CSS, JS, images — every response type.
- **Cache: `Cache-Control: public, must-revalidate, max-age=30` globally on Free tier** (no long-lived invalidation), then override per asset type with routes placed *before* the `/*` catch-all: `/*.css` and `/*.js` at `max-age=3600`, `/assets/*` at `max-age=86400`, HTML at `max-age=0, must-revalidate`. Route order matters — the catch-all must be last.
- **Everything under `app_location` is public unless a route hides it.** A committed doc, script or infra file is fetchable; a route with `"statusCode": 404` and no rewrite/redirect returns 404 without serving the body (verified live). Wildcards match only at the END of a route (`/docs/*`), so `/*.md` is unreliable — block directories plus exact-match root files (`/OPERATIONS.md`, `/.gitignore`). Dot-path routes work (`/.github/*`); the built-in `/.well-known/assetlinks.json` route proves it. See *Hiding internal files* in [`reference.md`](reference.md).
- **Register MIME types explicitly** — `.xml application/xml`, `.txt text/plain` (crawlers), `.json`, `.vcf text/vcard` (iOS/Android "add to contacts" is unreliable on octet-stream). Extensionless files such as `apple-app-site-association` are served with the wrong content type unless an explicit route sets `Content-Type: application/json`.
- **A static `redirect` route drops the query string** (`/x?a=1` → bare target). Fine for a QR encoding a bare path; revisit if a link needs UTM pass-through.
- **`script-src 'self'` silently blocks inline `<script>` blocks *and* inline handler attributes (`onclick`, `onchange`).** They work locally (`file://` has no CSP) and fail on the live site. All JS lives in external same-origin `.js` files; attach handlers with `addEventListener`.
- **`style-src` still needs `'unsafe-inline'` until every `<style>` block and `style=` attribute is externalised** — extracting scripts alone does not let you tighten it. Deploy any new CSP as `Content-Security-Policy-Report-Only` first and clear the DevTools Console violations before enforcing.
- **Guard every shared-script DOM lookup with a null check.** `document.getElementById('year').textContent = …` on a page without that element throws and halts *all* later script on the page. Write `var el = …; if (el) el.textContent = …`.
- **Cache-bust JS/CSS with a version query string** (`scripts.js?v=2`) and bump it whenever a change would break cached behaviour; after deploying, verify against the live URL (or hard refresh, Ctrl+Shift+R) — at `max-age=3600` the user may still be seeing the old file.
- **On a templating-free static site every shared component is a separate copy per page.** Read each page's actual nav markup before editing — CTA text, hrefs and aria attributes routinely differ.
- **Mobile menu dropdowns live inside `<header>`, not after it** — a sticky header is a containing block; a nav outside it loses `backdrop-filter` and sticky positioning. When adding a hamburger menu, audit and replace stale mobile media-query rules for the nav rather than appending.
- **Reorganising into subfolders: redirect every old URL** — 301 for public/SEO pages, 302 for transient/auth pages — so links and app deep-links keep working. SWA serves `index.html` for a directory and `foo.html` for `/foo`; add an explicit `rewrite` for the no-trailing-slash folder URL to pin the canonical. Convert relative asset references (`styles.css`, `assets/…`) to root-absolute (`/styles.css`) on any relocated page — they otherwise 404.
- **A static page can double as a Supabase auth page** (password reset): read the recovery token from the URL hash, load supabase-js from a CDN, `setSession` then `updateUser`; give its route a `rewrite` to the `.html` and a per-route CSP allowing `connect-src https://<project-ref>.supabase.co` and `script-src … https://cdn.jsdelivr.net`. See `supabase-auth-email` for hardening those pages.
- **A page that is an App Link / Universal Link target is verified domain-wide by `.well-known/assetlinks.json`** (`handle_all_urls`) — moving its URL needs no assetlinks edit, but the app's intent-filter paths and any auth redirect URLs must be updated app-side.

## Process

1. **Read the current config and CSP**, and list every page and its shared components (nav, footer, scripts).
2. **Headers & cache** — security headers in `globalHeaders`; global short cache; per-asset routes before `/*`.
3. **MIME & routes** — sitemap/robots/well-known/`.vcf` entries; 404 routes for internal files (directory + exact-match); redirects/rewrites for moved pages.
4. **CSP** — externalise scripts and handlers, then styles; deploy Report-Only, clear violations, enforce; per-route CSP for pages that need CDN/Supabase.
5. **Front-end edits** — inspect each page's markup, place mobile nav in `<header>`, replace stale media rules, null-guard shared scripts, root-absolute assets on moved pages, bump `?v=`.
6. **Deploy and verify live** — fetch the live URL for headers, 404s on hidden files, redirects, CSP console; hard refresh for cached JS/CSS.

## Output format

1. **`staticwebapp.config.json`** — complete file (routes in order, `globalHeaders`, `mimeTypes`, `responseOverrides`)
2. **CSP plan** — current → target policy, what must be externalised, Report-Only → enforce steps
3. **Page change list** — per page: markup/script/CSS edits, moved-page redirects and asset path fixes
4. **Live verification** — headers on non-HTML assets, hidden files 404, redirects, console clean, cache-busting confirmed

## Quality checklist

- [ ] Security headers in `globalHeaders`, present on CSS/JS/image responses
- [ ] Per-asset `Cache-Control` routes precede the `/*` catch-all
- [ ] Internal files return 404 live via directory + exact-match routes (no `/*.md` wildcards)
- [ ] `sitemap.xml`, `robots.txt`, extensionless well-known files, and `.vcf` served with correct `Content-Type`
- [ ] No inline `<script>` blocks or `onclick`-style attributes on a CSP site; new CSP deployed Report-Only first, console clean
- [ ] Shared-script DOM lookups null-guarded
- [ ] Relocated pages: 301/302 redirects from old URLs, rewrite for the folder URL, root-absolute asset paths
- [ ] Mobile nav inside `<header>`; stale mobile media rules replaced
- [ ] `?v=` bumped on changed JS/CSS and behaviour verified against the live URL

## Avoid

- Adding security headers to the `/*` route — they only reach HTML responses
- Hiding files with `/*.md`-style wildcards — wildcards match only at the end of a route
- Assuming a `redirect` route forwards the query string — it drops it
- Adding inline scripts or handler attributes to a `script-src 'self'` site — they pass locally and fail live
- Dropping `'unsafe-inline'` from `style-src` before every inline style is extracted
- Enforcing a new CSP without a Report-Only pass
- Leaving shared-script DOM lookups unguarded — one missing element halts the page's JS
- Keeping relative asset paths when moving a page into a subfolder — they 404
- Assuming nav markup is identical across pages, or placing a mobile menu after `</header>`
- Judging a JS/CSS deploy from a normally-cached tab — verify the live URL or hard refresh

## Example usage

> "Our marketing site is live on Azure Static Web Apps. I need to move `/reset-password.html` into `/account/`, add a hamburger menu, tighten the CSP to `script-src 'self'`, and make sure the `docs/` folder and `OPERATIONS.md` in the repo aren't publicly fetchable — without breaking the app's deep links."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
