# Static Website Config and CSP — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Route order: hidden files, MIME routes, per-asset cache, catch-all

```json
{
  "routes": [
    { "route": "/sitemap.xml", "headers": { "Content-Type": "application/xml" } },
    { "route": "/.well-known/apple-app-site-association", "headers": { "Content-Type": "application/json" } },

    { "route": "/docs/*",        "statusCode": 404 },
    { "route": "/infra/*",       "statusCode": 404 },
    { "route": "/scripts/*",     "statusCode": 404 },
    { "route": "/.github/*",     "statusCode": 404 },
    { "route": "/OPERATIONS.md", "statusCode": 404 },
    { "route": "/.gitignore",    "statusCode": 404 },

    { "route": "/*.css",   "headers": { "Cache-Control": "public, max-age=3600" } },
    { "route": "/*.js",    "headers": { "Cache-Control": "public, max-age=3600" } },
    { "route": "/assets/*", "headers": { "Cache-Control": "public, max-age=86400" } },

    { "route": "/old-page", "redirect": "/new/page", "statusCode": 301 },
    { "route": "/account",  "rewrite": "/account/index.html" },
    { "route": "/*",        "headers": { "Cache-Control": "public, max-age=0, must-revalidate" } }
  ],
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Referrer-Policy": "same-origin",
    "Cache-Control": "public, must-revalidate, max-age=30",
    "Content-Security-Policy-Report-Only": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:"
  },
  "mimeTypes": {
    ".json": "application/json",
    ".xml":  "application/xml",
    ".txt":  "text/plain",
    ".vcf":  "text/vcard"
  }
}
```

Hidden files: wildcards match only at the end of a route, so list root files exactly. Verify live: `curl -sI https://<host>/OPERATIONS.md` → `404`, body not served.

## Per-route CSP for a hosted Supabase auth page

```json
{
  "route": "/reset-password",
  "rewrite": "/reset-password.html",
  "headers": {
    "Content-Security-Policy": "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; connect-src https://<project-ref>.supabase.co; style-src 'self' 'unsafe-inline'"
  }
}
```

## Null-guarded shared script + cache-bust

```html
<script src="/scripts.js?v=3"></script>   <!-- bump ?v= whenever cached behaviour would break -->
```

```js
var y = document.getElementById('year'); if (y) y.textContent = new Date().getFullYear();
var btn = document.getElementById('menu-toggle'); if (btn) btn.addEventListener('click', toggleMenu);   // never onclick=""
```
