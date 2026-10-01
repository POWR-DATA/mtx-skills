---
name: static-website-config-and-csp
description: Configure and safely change a live static site on Azure Static Web Apps — staticwebapp.config.json routes, headers, caching and MIME types, Content Security Policy, and the front-end gotchas of editing a static HTML site in production
author: PowerData
version: 1.3.0
license: MIT
---

# Static Website Config and CSP

## Purpose

Own the `staticwebapp.config.json` and front-end layer of a live static site: security headers, cache policy, MIME types and routes (hidden files, redirects, rewrites), a Content Security Policy that is tightened without breaking pages, and the hard-won rules for editing a multi-page static HTML site that is already in production. Split from `static-website-hosting`, which provisions and deploys the site.

## When to use

After the site is live (see `static-website-hosting`), whenever you:

- Add or change headers, cache rules, MIME types, redirects, or rewrites in `staticwebapp.config.json`
- Introduce or tighten a CSP, or add JavaScript/CSS to a CSP-protected site
- Reuse another site's icons or images under `img-src 'self'` — copy the files into the repo; do not hotlink
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
- **SWA rejects `statusCode` combined with `rewrite` on a route** ("Status code cannot be specified for a rule with Rewrite") — the deploy fails config validation in about 30 seconds and the site keeps serving the previous version. To mask blocked paths as a branded 404 page, put `"allowedRoles": ["administrator"]` on the routes plus a `"401": { "rewrite": "/404.html", "statusCode": 404 }` responseOverride — `statusCode` plus `rewrite` IS allowed inside `responseOverrides`.
- **An `<iframe srcDoc=...>` (about:srcdoc) inherits the EMBEDDING page's CSP**, so images/fonts loaded inside the iframe from an external host (e.g. an email preview pulling template images from the marketing site) are blocked unless the parent page's `img-src` allows that host — widen the global CSP `img-src`, not anything on the iframe.
- **A strict `img-src 'self'` CSP blocks hotlinking any cross-origin image**, so to reuse another site's icons or images you must copy the asset files into the repo and reference them same-origin. Widening `img-src` (the iframe case above) is for hosts that must load at runtime — not a substitute for copying assets you intend to serve.
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
- **The SWA edge serves the previous HTML for a minute or two after a successful deploy.** A check run straight after `gh run watch` showed five of seven pages still on old content and looked like a partial deploy. Verify with a cache-busting query string plus a `Cache-Control: no-cache` request header before concluding anything failed.
- **Scope every bulk edit to its own block.** A site's nav and footer can contain the same link pairs, so a regex meant to add a footer link also rewrote the nav and put a fifth item in the main nav on seven pages — pages whose nav link carried `aria-current` escaped only by accident. Anchor the edit inside `<nav ...>...</nav>` or the footer `<div>`, and afterwards verify the nav's exact item list rather than checking the new link exists somewhere on the page.
- **Specificity turns a span into a nav link the moment you make it an anchor.** `.site-nav a` (0,1,1) beats a bare `.nav-pill` (0,1,0), so a pill silently adopts the nav link's padding, radius and colour; carry both selectors (`.nav-pill, .site-nav a.nav-pill`). For a two-row mobile header, put the login link outside `<nav>` as a sibling of the brand, give the header wrapper `flex-wrap: wrap`, let `.brand { margin-right: auto }` push the login link right on row one with the nav at `width: 100%` on row two, and swap `order` at desktop widths so the login link sits furthest right.
- **A shortened link label must still appear in its `aria-label`.** WCAG 2.5.3 (Label in Name) means voice-control users saying "click Login" match nothing if the accessible name says "Practitioner portal". Changing a visible label from "Portal" to "Login" therefore also means changing `aria-label="Practitioner portal"` to `aria-label="Practitioner login"`.
- **Self-hosted MP4s need an explicit MIME mapping to stream.** Map `.mp4` to `video/mp4` in `mimeTypes` and byte-range requests return 206; set CSS `aspect-ratio` to the encoded dimensions so the player reserves its space before the poster loads. Because `/assets/*` carries a long cache, reference videos and posters with `?v=N` and bump it whenever a file is replaced.
- **Check that every referenced asset actually resolves when touching a page's head.** Pages carried a `<script src="/canonical.js">` for a file that did not exist, so it 404ed on every load of three pages and left them with no canonical tag at all. Prefer a static `<link rel="canonical">` over a script-injected one.
- **A narrow headless window is not a phone viewport.** Headless Edge with `--window-size=412,...` did not produce a true phone-width layout; rendering the page inside a 412 px-wide iframe in a larger window and cropping the column produced the real mobile layout. Use the iframe wrapper for phone screenshots when a narrow window renders oddly.

## Process

1. **Read the current config and CSP**, and list every page and its shared components (nav, footer, scripts).
2. **Headers & cache** — security headers in `globalHeaders`; global short cache; per-asset routes before `/*`.
3. **MIME & routes** — sitemap/robots/well-known/`.vcf` entries; 404 routes for internal files (directory + exact-match); redirects/rewrites for moved pages.
4. **CSP** — externalise scripts and handlers, then styles; copy reused third-party images into the repo (same-origin) rather than hotlinking under `img-src 'self'`; deploy Report-Only, clear violations, enforce; per-route CSP for pages that need CDN/Supabase.
5. **Front-end edits** — inspect each page's markup, place mobile nav in `<header>`, replace stale media rules, null-guard shared scripts, root-absolute assets on moved pages, bump `?v=`.
6. **Deploy and verify live** — fetch the live URL for headers, 404s on hidden files, redirects, CSP console; hard refresh for cached JS/CSS.
7. **Verify the deploy past the edge cache** — cache-busting query plus `Cache-Control: no-cache`, on every page you changed, not just one.
8. **Re-check the nav's exact item list** after any bulk markup edit, and confirm every asset referenced from a changed `<head>` resolves.

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
- [ ] Reused third-party images/icons copied into the repo and referenced same-origin — not hotlinked under `img-src 'self'`
- [ ] Shared-script DOM lookups null-guarded
- [ ] Relocated pages: 301/302 redirects from old URLs, rewrite for the folder URL, root-absolute asset paths
- [ ] Mobile nav inside `<header>`; stale mobile media rules replaced
- [ ] `?v=` bumped on changed JS/CSS and behaviour verified against the live URL
- [ ] Post-deploy verification used a cache-busting query and `no-cache`, not a bare fetch
- [ ] Bulk edits anchored inside their own block; nav item list verified exactly afterwards
- [ ] New nav anchors carry both selectors so nav-link specificity does not override them
- [ ] `aria-label` contains the visible label text (WCAG 2.5.3)
- [ ] `.mp4` mapped in `mimeTypes`, `aspect-ratio` set, media referenced with `?v=N`
- [ ] Every asset referenced from a changed `<head>` resolves; canonical is a static `<link>`

## Avoid

- Adding security headers to the `/*` route — they only reach HTML responses
- Hiding files with `/*.md`-style wildcards — wildcards match only at the end of a route
- Combining `statusCode` with `rewrite` on a route — config validation rejects it and the deploy fails; that combination lives in `responseOverrides` only
- Adding CSP directives to an `<iframe srcDoc>` — it inherits the parent page's policy; fix the parent's `img-src`
- Hotlinking a cross-origin image on an `img-src 'self'` site — copy the file into the repo and reference it same-origin
- Assuming a `redirect` route forwards the query string — it drops it
- Adding inline scripts or handler attributes to a `script-src 'self'` site — they pass locally and fail live
- Dropping `'unsafe-inline'` from `style-src` before every inline style is extracted
- Enforcing a new CSP without a Report-Only pass
- Leaving shared-script DOM lookups unguarded — one missing element halts the page's JS
- Keeping relative asset paths when moving a page into a subfolder — they 404
- Assuming nav markup is identical across pages, or placing a mobile menu after `</header>`
- Judging a JS/CSS deploy from a normally-cached tab — verify the live URL or hard refresh
- Concluding a deploy half-failed from a fetch made seconds after it completed — the edge is still serving the old HTML
- Running a link-pair regex across a whole page when nav and footer share the same pairs
- Styling a new nav pill with a bare class and expecting it to beat `.site-nav a`
- Shortening a visible link label without updating its `aria-label`
- Serving self-hosted MP4s without a `mimeTypes` entry, or replacing a cached asset without bumping `?v=`
- Injecting the canonical tag from a script, or leaving a reference to a deleted file in `<head>`
- Taking phone screenshots by shrinking the headless window — render in an iframe at the target width

## Example usage

> "Our marketing site is live on Azure Static Web Apps. I need to move `/reset-password.html` into `/account/`, add a hamburger menu, tighten the CSP to `script-src 'self'`, and make sure the `docs/` folder and `OPERATIONS.md` in the repo aren't publicly fetchable — without breaking the app's deep links."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
