# Website SEO and Indexing — Reference Templates

Load-on-demand templates for [`SKILL.md`](SKILL.md). Illustrative excerpts — load-bearing lines only; replace `<...>` placeholders.

---

## Post-deploy Indexing API CI job

Submits every `<loc>` in `sitemap.xml` to the Google Indexing API after a successful deploy. The sitemap is the single source of truth for what gets submitted. The job **no-ops when the secret is absent** so it never blocks a deploy, and never fails the build on per-URL errors.

```yaml
index_job:
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  needs: build_and_deploy_job
  steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-python@v5
    - env:
        GOOGLE_INDEXING_SA_KEY: ${{ secrets.GOOGLE_INDEXING_SA_KEY }}
      run: |
        [ -z "$GOOGLE_INDEXING_SA_KEY" ] && echo "no key — skip" && exit 0
        pip install -q google-auth google-api-python-client
        python ci-index-submit.py   # reads sitemap.xml, POSTs each <loc> to the Indexing API
```

## Loading the service-account key as a secret

```bash
gh secret set GOOGLE_INDEXING_SA_KEY < service-account-key.json   # uploads encrypted; never printed or committed
```

Extract only the non-secret `client_email` (for the Search Console owner step) — never `cat` the whole key or place it in the repo:

```bash
python -c "import json;print(json.load(open('service-account-key.json'))['client_email'])"
```

## Indexing API credentials

Which credential works depends on the Search Console property type:

| Property type | Works with | Notes |
|---|---|---|
| Domain (`example.com`) | OAuth Desktop credentials | a service-account email is rejected with "email not found" |
| URL-prefix (`https://www.example.com/`) | Service account as **Owner** | Full/Restricted permissions do not work |

A common setup is to keep the Domain property for reporting and add a URL-prefix property alongside it purely so CI can submit with a service account.

**OAuth flow:** first run opens a browser login and writes access and refresh tokens to `token.json`; later runs refresh silently. Both `oauth-client.json` and `token.json` grant write access to the property — gitignore them.

**Service account:** enable the Web Search Indexing API in the *same* Google Cloud project that owns the account; calls are attributed to that project, so enabling it in another one fails silently with no useful error.

## Search Console ownership and verification

- Domain-property verification is per Google account: a user added via Users and permissions shows Owner but not Verified and only works while a verified owner still exists. To make a business account self-standing, sign in as it, go Settings → Ownership verification → DNS record, and publish its second, different `google-site-verification` TXT token at the apex alongside the first (both coexist permanently). Add the business account as Owner on every company property, not just the new one.
- Search Console living on a personal Google account is low-risk because Domain-property ownership is anchored to DNS and can be re-verified by anyone controlling the zone — but Play Console and Apple Developer accounts should be organisation accounts owned by the company from day one, because those are painful or impossible to migrate later.
- Confirm the `google-site-verification` TXT via a public DoH resolver before pressing Verify, then still expect Google's own check to lag: a record visible worldwide within seconds of saving at the registrar failed the first Verify click and passed about an hour later with no change. Sitemap status flips to Success the same day but the Performance and Indexing panels show "processing data" for a day or more — normal for a new property.

## Diagnosing a GSC duplicate

- Audit existing canonical tags before adding new ones. The tag may already exist and be correct — if it is, the redirect and internal links are the more likely cause of any GSC duplicate signal, not a missing canonical.
- A 301 redirect on `/index.html → /` is only half the fix for a GSC duplicate. Googlebot follows internal links before encountering redirects — if navigation or anchor links still reference `index.html`, the duplicate persists. The redirect and internal link cleanup are required together.
- When one `.html` URL duplicate is found in GSC, check all pages for the same pattern. If `index.html` creates a duplicate on one page, it almost certainly exists across the whole site.

## Sitemap and robots.txt

Both must be real static files at the site root, not framework routes that can return HTML.

```xml
<!-- /sitemap.xml — one <url> per public page -->
<url>
  <loc>https://www.<domain>/</loc>
  <lastmod>2026-09-30</lastmod>          <!-- real content change; never a future date -->
  <changefreq>monthly</changefreq>
  <priority>1.0</priority>               <!-- homepage 1.0; other pages 0.7–0.9 -->
</url>
```

```text
# /robots.txt
User-agent: *
Allow: /
Sitemap: https://www.<domain>/sitemap.xml
```

Serving checks: `sitemap.xml` must return `Content-Type: application/xml` and `robots.txt` `text/plain`. On Azure Static Web Apps that means an explicit `/sitemap.xml` route and an `.xml` entry in `mimeTypes`.

## Per-page head elements

```html
<link rel="canonical" href="https://www.<domain>/<slug>" />   <!-- no trailing slash off-root -->
<title><!-- unique, 50–60 chars, correct brand name --></title>
<meta name="description" content="<!-- unique, 120–160 chars -->" />
<link rel="icon" type="image/png" href="/favicon.png" />
```
