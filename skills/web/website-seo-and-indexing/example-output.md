# Example Output

*This output was generated using the Website SEO and Indexing skill applied to the example input in `example-input.md`.*

---

## Canonical tag additions

**`index.html`** — add to `<head>` after the existing meta tags:
```html
<link rel="canonical" href="https://www.powrdata.com.au/" />
```

**`ai-agent-skills.html`** — add to `<head>` after the existing meta tags:
```html
<link rel="canonical" href="https://www.powrdata.com.au/ai-agent-skills" />
```

---

## `sitemap.xml`

Place at the site root (`/sitemap.xml`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://www.powrdata.com.au/</loc>
    <lastmod>2026-05-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://www.powrdata.com.au/ai-agent-skills</loc>
    <lastmod>2026-05-15</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

---

## `robots.txt`

Place at the site root (`/robots.txt`):

```
User-agent: *
Allow: /

Sitemap: https://www.powrdata.com.au/sitemap.xml
```

---

## `staticwebapp.config.json` changes required

The Azure SWA SPA fallback would intercept `sitemap.xml` requests without an explicit route. Add the following to `staticwebapp.config.json`:

```json
{
  "routes": [
    {
      "route": "/sitemap.xml",
      "headers": { "Content-Type": "application/xml" }
    }
  ],
  "mimeTypes": {
    ".xml": "application/xml"
  }
}
```

---

## Per-page meta tag review

| Page | Title | Description | Issues |
|---|---|---|---|
| Homepage | `POWR Data \| Data engineering, architecture and analytics advisory` | 77 chars. Present. | Title is slightly long (>60 chars) but acceptable for a brand + descriptor pattern |
| AI Agent Skills | `AI Agent Skills for Data Engineering \| PowerData` | 50 chars. Present. | Good length |
| Homepage | *(description)* `POWR Data provides principal-led data engineering...` | 120 chars. Present. | Good |
| AI Agent Skills | *(description)* `Reusable AI agent skills and lightweight delivery...` | 107 chars. Present. | Good |

Both pages have unique titles and descriptions. No duplicates. No changes required.

---

## Google Search Console setup

### 1. Create a Domain property

1. Go to [Google Search Console](https://search.google.com/search-console)
2. Click **Add property**
3. Choose **Domain** (not URL prefix)
4. Enter: `powrdata.com.au` (no protocol, no www)
5. Google will show a DNS TXT record to add — copy the value (format: `google-site-verification=<token>`)

### 2. Add DNS TXT record at VentraIP

1. Log in to VentraIP → **Domains** → `powrdata.com.au` → **Manage DNS**
2. Add a new TXT record:
   - **Host/Name:** `@`
   - **Value:** `google-site-verification=<token from GSC>`
   - **TTL:** 3600
3. Save

### 3. Verify in GSC

1. Return to Google Search Console
2. Click **Verify**
3. Allow up to 24–48 hours for DNS propagation if verification fails immediately

### 4. Submit the sitemap

1. In GSC, go to **Sitemaps** (left sidebar)
2. Enter `sitemap.xml` in the input field
3. Click **Submit**
4. Status should change to **Success** within 24–72 hours

### 5. Inspect key URLs

After 24 hours, use the **URL Inspection** tool:
- Enter `https://www.powrdata.com.au/` → should show as indexed or indexable
- Enter `https://www.powrdata.com.au/ai-agent-skills` → same check
- Confirm Google reports the canonical URL matches what is in the `<link rel="canonical">` tag

---

## Verification checklist

- [ ] `<link rel="canonical">` present in `<head>` on both pages
- [ ] `https://www.powrdata.com.au/sitemap.xml` returns `Content-Type: application/xml`
- [ ] `https://www.powrdata.com.au/robots.txt` returns `Content-Type: text/plain` and contains `Sitemap:` directive
- [ ] Google Search Console Domain property created for `powrdata.com.au`
- [ ] DNS TXT verification record added at VentraIP
- [ ] GSC property verified
- [ ] Sitemap submitted and showing Success in GSC
- [ ] URL Inspection confirms both pages are crawlable
