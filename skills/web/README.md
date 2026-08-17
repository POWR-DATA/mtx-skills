# Web Skills

Skills for planning, deploying, and optimising public-facing websites.

These skills cover the delivery lifecycle for static websites: infrastructure setup, DNS configuration, CI/CD deployment, and search engine indexing. They are designed to be applied in sequence — hosting must be in place before SEO configuration is meaningful.

## Skills

| Skill | Description | Typical next skill |
|---|---|---|
| [Static Website Hosting](static-website-hosting/) | Plan and deploy a static website on Azure Static Web Apps with custom domains, DNS, IaC, and CI/CD | Website SEO and Indexing |
| [Website SEO and Indexing](website-seo-and-indexing/) | Prepare a static website for search engine indexing and submit it to Google Search Console | — |
| [Web Print PDF](web-print-pdf/) | Produce reliable print and PDF output from an HTML page with print-specific CSS | — |
| [Branded Link QR Service](branded-link-qr-service/) | Build a permanent branded short-link and QR code service on a static host — 302 indirection, link registry, CI drift checks, validated QR generation | — |

## Suggested delivery sequence

```
Static Website Hosting
    -> Website SEO and Indexing
```

Apply Static Website Hosting first to get the site live and accessible via HTTPS on its primary domain. Then apply Website SEO and Indexing once the site is reachable — Google Search Console verification and sitemap submission require a live, publicly accessible URL.

Web Print PDF and Branded Link QR Service are standalone additions: use them when a page must also print cleanly, or when printed QR codes need a permanent, repointable short link (Branded Link QR Service builds on Static Website Hosting for the `go.<domain>` site itself).

## Adding a new web skill

Use the [skill template](../../contribute/templates/skill-template/) as your starting point. See [CONTRIBUTING.md](../../contribute/CONTRIBUTING.md) for submission guidance.
