---
name: website-seo-and-indexing
description: Prepare a static website for search engine indexing and submit it to Google Search Console
author: PowerData
version: 1.0.0
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
- Submit the sitemap in GSC after verification. Use the URL Inspection tool to check individual pages after submission.
- `lastmod` dates in `sitemap.xml` should reflect actual content changes. Do not set future dates. Priority values (0.0–1.0) are relative — the homepage is typically 1.0.
- Avoid duplicate indexing by ensuring the non-canonical URL (apex, http) redirects to the canonical before Google crawls it. On Azure SWA, the apex → www redirect is automatic but takes 20–30 minutes to activate after domain validation.

## Process

1. **Confirm the canonical base URL** — the primary domain, protocol, and www/apex decision. This is used in all canonical tags and the sitemap.

2. **Audit existing pages**
   - List all public HTML pages
   - Check each for `<link rel="canonical">`, `<title>`, and `<meta name="description">`

3. **Add canonical tags**
   - Add `<link rel="canonical" href="https://www.<domain>/<path>" />` to the `<head>` of every HTML page
   - Homepage: `https://www.<domain>/`
   - Other pages: `https://www.<domain>/<slug>` (no trailing slash for non-root pages)

4. **Write `sitemap.xml`**
   - Include one `<url>` block per public page
   - Fields: `<loc>`, `<lastmod>` (YYYY-MM-DD format), `<changefreq>`, `<priority>`
   - Homepage priority: 1.0; other pages: 0.7–0.9 depending on importance
   - Place at the site root (`/sitemap.xml`)

5. **Write `robots.txt`**
   - Allow all crawlers: `User-agent: *` / `Allow: /`
   - Add `Sitemap: https://www.<domain>/sitemap.xml`
   - Place at the site root (`/robots.txt`)

6. **Verify static file serving**
   - Confirm `sitemap.xml` is served with `Content-Type: application/xml`
   - Confirm `robots.txt` is served with `Content-Type: text/plain`
   - On Azure SWA: add explicit route for `/sitemap.xml` in `staticwebapp.config.json` and register `.xml` MIME type

7. **Check per-page meta tags**
   - Each page should have a unique `<title>` and `<meta name="description">`
   - Title: 50–60 characters; description: 120–160 characters
   - Avoid identical titles or descriptions across pages

8. **Add a favicon**
   - Place `favicon.png` or `favicon.ico` at the site root
   - Add `<link rel="icon" type="image/png" href="favicon.png" />` to each page's `<head>`

9. **Set up Google Search Console**
   - Go to [Google Search Console](https://search.google.com/search-console)
   - Create a **Domain property** for `<domain>` (without protocol or www)
   - Add the provided DNS TXT verification record to the domain's DNS at the registrar or DNS host
   - Wait for DNS to propagate, then click **Verify**

10. **Submit the sitemap**
    - In GSC: go to **Sitemaps** → enter `sitemap.xml` → **Submit**
    - Wait 24–72 hours for initial crawl

11. **Inspect URLs**
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
- [ ] Google Search Console Domain property created and verified
- [ ] Sitemap submitted in GSC
- [ ] URL Inspection confirms Google can render the homepage
- [ ] Apex and http URLs redirect to the canonical (www, https) before indexing

## Avoid

- Do not use the URL-prefix property in GSC unless the DNS TXT record approach is not available — it only covers a single protocol/subdomain variant
- Do not set `lastmod` to future dates or generic dates that don't reflect real content changes
- Do not omit canonical tags on any public page, even a simple landing page — duplicate content signals accumulate across http/https and www/apex variants
- Do not serve `sitemap.xml` through a SPA fallback — verify the actual `Content-Type` header in a browser dev tools network tab
- Do not add `Disallow: /` to `robots.txt` while testing and forget to remove it before launch — this blocks all crawlers
- Do not assume GSC verification via DNS is instant — allow up to 24–48 hours for TXT record propagation

## Example usage

> My site is live at `https://www.powrdata.com.au` — it has a homepage and one other page (`/ai-agent-skills`). Both are plain HTML files. I want to get the site indexed in Google. What do I need to add or change, and how do I set up Google Search Console?

---

_Source: This skill is sourced from the [PowerData Skills](https://github.com/POWR-DATA/skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
