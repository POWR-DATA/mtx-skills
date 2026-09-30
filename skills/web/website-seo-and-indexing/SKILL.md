---
name: website-seo-and-indexing
description: Prepare a static website for search engine indexing and submit it to Google Search Console
author: PowerData
version: 1.8.0
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
- Domain-property verification is **per Google account** and anchored to DNS, so ownership survives account changes and a second account simply publishes its own TXT token alongside the first. Expect Google's own check to lag behind public DNS. See *Search Console ownership and verification* in [`reference.md`](reference.md).
- `lastmod` dates in `sitemap.xml` should reflect actual content changes. Do not set future dates. Priority values (0.0–1.0) are relative — the homepage is typically 1.0.
- Avoid duplicate indexing by ensuring the non-canonical URL (apex, http) redirects to the canonical before Google crawls it. On Azure SWA, the apex → www redirect is automatic but takes 20–30 minutes to activate after domain validation.
- GSC shows a robots.txt entry for every URL variant it has crawled. Only the canonical (HTTPS www) needs to return a valid response. A 404 on the HTTP non-www variant is harmless if the HTTPS www version shows "Fetched".
- A GSC duplicate is usually internal links, not a missing canonical: audit the existing tag first, fix the `.html` links as well as the redirect, and check every page for the same pattern once you find one. See *Diagnosing a GSC duplicate* in `reference.md`.
- OG image must use a solid background and be exactly 1200×630px and under 600KB. Transparent PNGs appear invisible or broken on social share cards — platforms render cards on varying backgrounds. WhatsApp in particular rejects oversized or transparent images. This failure only surfaces when a URL is actually shared, not during local testing.
- `width` and `height` attributes on `<img>` elements serve aspect ratio reservation for CLS prevention, not display sizing. The browser uses them to pre-allocate space before the image loads. The ratio matters; exact pixel values do not need to match CSS dimensions.
- In the Page indexing report, apex/http/non-canonical variants listed as "not indexed" ("Page with redirect", "Alternative page with proper canonical tag", "Duplicate without user-selected canonical") are canonicalisation working, not defects; the number to watch is indexed pages matching the sitemap. Do not press "Validate fix" on them — nothing is broken, and the recrawl just returns a "Failed" badge on a correct state. Variants keep stale classifications from their last-crawled date until Google recrawls, so a URL that 301s today may still display its old reason.
- "Discovered – currently not indexed" in Search Console is not a technical error — it means Google knows the page exists but has not yet crawled it. The fix is URL Inspection → Request Indexing, not Validate Fix. Validate Fix is only for confirmed code changes that resolved a prior error.
- Indexing API credentials depend on the property type: a **Domain** property rejects service-account emails ("email not found"), so use OAuth Desktop credentials, or add a URL-prefix property alongside it and make the service account an Owner there. Whichever route, the credential files (`oauth-client.json`, `token.json`, or the SA key) grant write access to the property and must be gitignored. See *Indexing API credentials* in [`reference.md`](reference.md).
- For a folder that mixes public landing pages with noindex auth/utility pages, do not blanket-noindex the folder. Apply `X-Robots-Tag: noindex` per auth route only, and keep `robots.txt` crawlable (do not `Disallow` the path) — Google must be able to fetch the page to read the noindex directive.
- Automate indexing on deploy with a post-deploy CI job that submits every `sitemap.xml` URL to the Google Indexing API using a service-account key (stored as a secret), making the sitemap the single source of truth for what gets submitted. Guard the job to no-op when the secret is absent so it never blocks a deploy, and never fail the build on per-URL errors. See *Post-deploy Indexing API CI job* in [`reference.md`](reference.md).
- A service account needs **Owner** on the property (Full/Restricted do not work) and the Web Search Indexing API enabled **in the project that owns the service account** — calls are attributed to the SA's project, so enabling it elsewhere silently fails. Load the key with `gh secret set NAME < key.json` and extract only `client_email` for the owner step. See *reference.md*.

- `noindex` never makes a page private — anyone with the URL can read it. It only keeps a binding public document such as the terms out of search results.
- An unlisted public page needs **three** separate exclusions: a `noindex` robots meta tag, omission from the sitemap and navigation, and removal from any automated indexing-submission script's route list. Missing the third submits the page to search engines despite the noindex.
- Making an unlisted page discoverable means undoing all of them: remove `noindex` from **both** the route's `X-Robots-Tag` header and the page's `<meta name="robots">` (both are commonly in force), add it to the sitemap, and link it from the navigation or footer.

## Process

1. **Confirm the canonical base URL** — primary domain, protocol, and the www/apex decision. Everything else derives from it.
2. **Audit existing pages** — canonical tag, `<title>`, `<meta name="description">`, OG tags, and any `.html` URL variants. Titles are invisible in browser UI, so brand-name inconsistencies survive indefinitely without a deliberate pass.
3. **Audit internal links for `.html` references** — Googlebot follows links before it meets redirects, so a nav pointing at `index.html` recreates the duplicate whatever the redirect does.
4. **Add or verify canonical tags** on every page, absolute and pointing at the canonical host.
5. **Write `sitemap.xml` and `robots.txt`** as real static files at the root, with the `Sitemap:` directive absolute. See *Sitemap and robots.txt* in [`reference.md`](reference.md).
6. **Verify static file serving** — `sitemap.xml` as `application/xml`, `robots.txt` as `text/plain`; on Azure SWA that needs an explicit route and MIME registration.
7. **Check per-page meta tags** — unique title (50–60 chars) and description (120–160 chars) on every page.
8. **Add a favicon** at the root and link it from every `<head>`.
9. **Set up Google Search Console** — Domain property, DNS TXT verification confirmed via DoH before pressing Verify, and a second owner account with its own token. See *Search Console ownership and verification* in `reference.md`.
10. **Submit the sitemap** and allow 24–72 hours for the initial crawl.
11. **Inspect URLs** — confirm Google renders the page and reports the canonical you intended.

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
- [ ] Unlisted pages excluded three ways: `noindex`, out of sitemap/nav, and out of the indexing script's route list
- [ ] A page being made discoverable has `noindex` removed from the `X-Robots-Tag` header *and* the meta tag
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
- Do not treat `noindex` as privacy — the page is still readable by anyone with the URL
- Do not leave an unlisted page in the indexing script's route list, or remove only one of the two `noindex` mechanisms when publishing it

## Example usage

> My site is live at `https://www.powrdata.com.au` — it has a homepage and one other page (`/ai-agent-skills`). Both are plain HTML files. I want to get the site indexed in Google. What do I need to add or change, and how do I set up Google Search Console?

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
