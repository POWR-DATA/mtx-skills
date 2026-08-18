---
name: website-seo-and-indexing
description: Prepare a static website for search engine indexing and submit it to Google Search Console
author: PowerData
version: 1.5.0
license: MIT
---

# Website SEO and Indexing

## Purpose

Prepare a static website for search engine discovery and indexing by implementing the core technical SEO requirements — canonical URLs, sitemap, robots.txt, meta tags, and Google Search Console verification — so that pages are crawled correctly and appear in search results.

## When to use

Use this skill when launching a new website or auditing an existing one for indexing gaps. Apply it after the site is live and accessible via HTTPS on its primary domain.

This skill covers the technical SEO layer. It does not cover content strategy, keyword research, backlink building, or paid search.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Primary domain (e.g. `https://www.example.com`) — this is the canonical base URL
- List of pages and their URLs
- Hosting platform (affects how `sitemap.xml`, `robots.txt`, and static files are served)
- Whether Google Search Console access is available
- Whether a DNS TXT record can be added to the domain (required for Domain property verification in GSC)
- Any existing `sitemap.xml`, `robots.txt`, or `<meta>` tags in place

## Guiding principles

- The canonical URL should be the `www` version of the domain. Canonical tags must match the domain that actually serves the page — if the site redirects apex to www, the canonical must use `www`.
- Every page needs a `<link rel="canonical">` tag. Even on a single-page site, it prevents duplicate content signals if the page is ever accessible at multiple URLs (apex and www, http and https).
- `sitemap.xml` must be a real static file, not served via a CMS or framework route that could return HTML. Verify it returns `Content-Type: application/xml`. On Azure SWA, this requires an explicit route in `staticwebapp.config.json`.
- `robots.txt` must be a static file at the root. Do not route it through a SPA fallback. The `Sitemap:` directive in `robots.txt` should reference the full absolute URL.
- Use a **Domain property** in Google Search Console, not a URL-prefix property. A Domain property tracks all variants (http, https, www, apex) in a single view and requires a DNS TXT verification record.
- Submit the sitemap in GSC after verification. Use the URL Inspection tool to check individual pages after submission. "Invalid sitemap address" when the URL is correct means you are inside the wrong property (check the property selector top-left) — a sitemap can only be submitted inside a property that covers its host, so create or switch to the Domain property for that domain first.
- Domain-property verification is per Google account: a user added via Users and permissions shows Owner but not Verified and only works while a verified owner still exists. To make a business account self-standing, sign in as it, go Settings → Ownership verification → DNS record, and publish its second, different `google-site-verification` TXT token at the apex alongside the first (both coexist permanently). Add the business account as Owner on every company property, not just the new one.
- Confirm the `google-site-verification` TXT via a public DoH resolver before pressing Verify, then still expect Google's own check to lag: a record visible worldwide within seconds of saving at the registrar failed the first Verify click and passed about an hour later with no change. Sitemap status flips to Success the same day but the Performance and Indexing panels show "processing data" for a day or more — normal for a new property.
- `lastmod` dates in `sitemap.xml` should reflect actual content changes. Do not set future dates. Priority values (0.0–1.0) are relative — the homepage is typically 1.0.
- Avoid duplicate indexing by ensuring the non-canonical URL (apex, http) redirects to the canonical before Google crawls it. On Azure SWA, the apex → www redirect is automatic but takes 20–30 minutes to activate after domain validation.
- GSC shows a robots.txt entry for every URL variant it has crawled. Only the canonical (HTTPS www) needs to return a valid response. A 404 on the HTTP non-www variant is harmless if the HTTPS www version shows "Fetched".
- Audit existing canonical tags before adding new ones. The tag may already exist and be correct — if it is, the redirect and internal links are the more likely cause of any GSC duplicate signal, not a missing canonical.
- A 301 redirect on `/index.html → /` is only half the fix for a GSC duplicate. Googlebot follows internal links before encountering redirects — if navigation or anchor links still reference `index.html`, the duplicate persists. The redirect and internal link cleanup are required together.
- When one `.html` URL duplicate is found in GSC, check all pages for the same pattern. If `index.html` creates a duplicate on one page, it almost certainly exists across the whole site.
- OG image must use a solid background and be exactly 1200×630px and under 600KB. Transparent PNGs appear invisible or broken on social share cards — platforms render cards on varying backgrounds. WhatsApp in particular rejects oversized or transparent images. This failure only surfaces when a URL is actually shared, not during local testing.
- `width` and `height` attributes on `<img>` elements serve aspect ratio reservation for CLS prevention, not display sizing. The browser uses them to pre-allocate space before the image loads. The ratio matters; exact pixel values do not need to match CSS dimensions.
- "Discovered – currently not indexed" in Search Console is not a technical error — it means Google knows the page exists but has not yet crawled it. The fix is URL Inspection → Request Indexing, not Validate Fix. Validate Fix is only for confirmed code changes that resolved a prior error.
- The Google Indexing API requires OAuth Desktop app credentials, not a service account, when the Search Console property is a Domain property — Domain properties reject service account emails with "email not found". Either create a URL-prefix property (`https://www.<domain>/`) alongside the Domain property and add the service account as Owner there, or use OAuth with the Google account that owns the property.
- The OAuth flow for the Indexing API saves access and refresh tokens to `token.json` after first browser login; subsequent runs refresh silently. Both `oauth-client.json` and `token.json` must be gitignored — they grant write access to your Search Console property.
- For a folder that mixes public landing pages with noindex auth/utility pages, do not blanket-noindex the folder. Apply `X-Robots-Tag: noindex` per auth route only, and keep `robots.txt` crawlable (do not `Disallow` the path) — Google must be able to fetch the page to read the noindex directive.
- Automate indexing on deploy with a post-deploy CI job that submits every `sitemap.xml` URL to the Google Indexing API using a service-account key (stored as a secret), making the sitemap the single source of truth for what gets submitted. Guard the job to no-op when the secret is absent so it never blocks a deploy, and never fail the build on per-URL errors. See *Post-deploy Indexing API CI job* in [`reference.md`](reference.md).
- For the Indexing API via a service account, the account must be added as an **Owner** of the Search Console property (Full/Restricted permissions do not work), and the Web Search Indexing API must be enabled **in the same Google Cloud project that owns the service account** — API calls are attributed to the SA's project, so enabling it in a different project silently fails.
- Load the service-account JSON into a GitHub Actions secret with `gh secret set NAME < key.json` (uploads encrypted, never printed or committed). Extract only the non-secret `client_email` for the Search Console owner step; never `cat` the whole key or place it in the repo. See *reference.md*.

## Process

1. **Confirm the canonical base URL** — the primary domain, protocol, and www/apex decision. This is used in all canonical tags and the sitemap.

2. **Audit existing pages**
   - List all public HTML pages
   - Check each for `<link rel="canonical">`, `<title>`, and `<meta name="description">`
   - Check OG tags: `og:title`, `og:description`, `og:image` — note any missing or using a transparent image
   - Check for `.html` URL variants (e.g. `/index.html`, `/page.html`) that could create GSC duplicate entries
   - Check that `<title>` tags are unique across all pages and use the correct brand name — these are invisible in browser UI and inconsistencies persist without an explicit audit

3. **Audit internal links for `.html` references**
   - If redirects exist for `.html` → clean URL paths, check that navigation and anchor links do not reference the `.html` form
   - Googlebot follows links before encountering redirects — internal links pointing to `index.html` will direct Googlebot to the duplicate regardless of the redirect

4. **Add or verify canonical tags**
   - Add `<link rel="canonical" href="https://www.<domain>/<path>" />` to the `<head>` of every HTML page
   - Homepage: `https://www.<domain>/`
   - Other pages: `https://www.<domain>/<slug>` (no trailing slash for non-root pages)

5. **Write `sitemap.xml`**
   - Include one `<url>` block per public page
   - Fields: `<loc>`, `<lastmod>` (YYYY-MM-DD format), `<changefreq>`, `<priority>`
   - Homepage priority: 1.0; other pages: 0.7–0.9 depending on importance
   - Place at the site root (`/sitemap.xml`)

6. **Write `robots.txt`**
   - Allow all crawlers: `User-agent: *` / `Allow: /`
   - Add `Sitemap: https://www.<domain>/sitemap.xml`
   - Place at the site root (`/robots.txt`)

7. **Verify static file serving**
   - Confirm `sitemap.xml` is served with `Content-Type: application/xml`
   - Confirm `robots.txt` is served with `Content-Type: text/plain`
   - On Azure SWA: add explicit route for `/sitemap.xml` in `staticwebapp.config.json` and register `.xml` MIME type

8. **Check per-page meta tags**
   - Each page should have a unique `<title>` and `<meta name="description">`
   - Title: 50–60 characters; description: 120–160 characters
   - Avoid identical titles or descriptions across pages

9. **Add a favicon**
   - Place `favicon.png` or `favicon.ico` at the site root
   - Add `<link rel="icon" type="image/png" href="favicon.png" />` to each page's `<head>`

10. **Set up Google Search Console**
   - Go to [Google Search Console](https://search.google.com/search-console)
   - Create a **Domain property** for `<domain>` (without protocol or www)
   - Add the provided DNS TXT verification record to the domain's DNS at the registrar or DNS host
   - Confirm the TXT via a public DoH resolver, click **Verify**; if it fails, wait ~1 h and retry without changing DNS
   - Verify the business Google account as a second owner (its own TXT token) so ownership does not hinge on one personal account

11. **Submit the sitemap**
    - In GSC: go to **Sitemaps** → enter `sitemap.xml` → **Submit**
    - Wait 24–72 hours for initial crawl

12. **Inspect URLs**
    - Use the **URL Inspection** tool in GSC on the homepage and key pages
    - Check that Google can render the page and that the canonical reported by Google matches the intended canonical

## Output format

The AI should produce:

1. **Canonical tag additions** — the exact `<link rel="canonical">` line for each page
2. **`sitemap.xml`** — complete file content with all pages
3. **`robots.txt`** — complete file content
4. **`staticwebapp.config.json` changes** (if applicable) — explicit sitemap route and MIME type
5. **Per-page meta tag review** — flag any missing or duplicate titles/descriptions
6. **Google Search Console setup steps** — step-by-step for Domain property creation, TXT verification, and sitemap submission
7. **Verification checklist** — what to check and how after setup

## Quality checklist

- [ ] Every HTML page has `<link rel="canonical">` in `<head>`
- [ ] Canonical URLs use the primary domain (www, https) consistently
- [ ] `sitemap.xml` exists at `/sitemap.xml` and returns `Content-Type: application/xml`
- [ ] `robots.txt` exists at `/robots.txt` with `Sitemap:` directive
- [ ] Every page has a unique `<title>` and `<meta name="description">`
- [ ] Favicon is present and linked on every page
- [ ] Google Search Console Domain property created and verified — by the business account too (second TXT token), and it is Owner on every company property
- [ ] Sitemap submitted in GSC
- [ ] URL Inspection confirms Google can render the homepage
- [ ] Apex and http URLs redirect to the canonical (www, https) before indexing
- [ ] Internal links do not reference `.html` URLs where redirects exist for those paths
- [ ] OG image uses a solid background — no transparency, exactly 1200×630px, under 600KB
- [ ] All `<title>` tags are unique and use the correct brand name, including secondary pages
- [ ] "Discovered – currently not indexed" pages actioned via URL Inspection → Request Indexing, not Validate Fix
- [ ] If using the Indexing API manually: OAuth credentials with `oauth-client.json` and `token.json` gitignored
- [ ] If automating via CI: service account added as **Owner** of the Search Console property, Web Search Indexing API enabled in the SA's own GCP project, key stored as a secret via `gh secret set`
- [ ] Post-deploy index job no-ops when the secret is absent and never fails the build on per-URL errors
- [ ] Mixed public/auth folders use per-route `X-Robots-Tag: noindex`, not a blanket folder rule, with `robots.txt` left crawlable

## Avoid

- Do not use the URL-prefix property in GSC unless the DNS TXT record approach is not available — it only covers a single protocol/subdomain variant
- Do not set `lastmod` to future dates or generic dates that don't reflect real content changes
- Do not omit canonical tags on any public page, even a simple landing page — duplicate content signals accumulate across http/https and www/apex variants
- Do not serve `sitemap.xml` through a SPA fallback — verify the actual `Content-Type` header in a browser dev tools network tab
- Do not add `Disallow: /` to `robots.txt` while testing and forget to remove it before launch — this blocks all crawlers
- Do not assume GSC verification via DNS is instant — confirm the TXT via DoH, then allow Google's own check to lag (~1 h seen), up to 24–48 hours
- Do not fight "Invalid sitemap address" by editing the URL — you are in the wrong property; switch to the Domain property that covers the host
- Do not leave Search Console ownership hanging on a single personal account's verification — verify the business account with its own TXT token
- Do not add a canonical tag without first checking whether one already exists and is correct — if it is, the redirect and internal links are the more likely cause of any GSC duplicate signal
- Do not treat a 301 redirect on `/index.html → /` as a complete fix — internal links pointing to `index.html` must also be updated, or Googlebot will still follow them to the duplicate URL
- Do not stop at the first `.html` duplicate found — check all pages, as the pattern typically exists across the whole site
- Do not assume `<title>` tags are correct — they are invisible in browser UI and brand name inconsistencies on secondary pages can persist indefinitely without a deliberate audit pass
- Do not treat a 404 on the HTTP non-www robots.txt entry in GSC as an error — if the canonical HTTPS www version is fetched successfully, the non-canonical 404 is expected and requires no action
- Do not click Validate Fix for a "Discovered – currently not indexed" page — that status is not an error; use URL Inspection → Request Indexing instead
- Do not add a service account to Search Console with Full/Restricted permissions and expect the Indexing API to work — it must be an **Owner** of the property; on a Domain property a non-Owner SA is rejected with "email not found", so use OAuth Desktop credentials, a URL-prefix property, or add the SA as Owner
- Do not enable the Web Search Indexing API in a different project from the one that owns the service account — calls are attributed to the SA's project and silently fail otherwise
- Do not `cat` or commit the service-account key — load it with `gh secret set NAME < key.json` and extract only `client_email` for the owner step
- Do not blanket-`noindex` a folder that mixes public and auth pages, and do not `Disallow` it in robots.txt — apply `X-Robots-Tag: noindex` per route and keep the path crawlable so Google can read the directive
- Do not commit `oauth-client.json` or `token.json` — they grant write access to your Search Console property

## Example usage

> My site is live at `https://www.powrdata.com.au` — it has a homepage and one other page (`/ai-agent-skills`). Both are plain HTML files. I want to get the site indexed in Google. What do I need to add or change, and how do I set up Google Search Console?

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
