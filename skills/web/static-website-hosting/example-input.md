# Example Input

## Context

A solo consultant is setting up a new professional website. They have purchased the domain `example.com.au` through VentraIP (an Australian domain registrar). They have an Azure subscription and a private GitHub repository containing a few static HTML files. They want the site provisioned with Bicep and deployed automatically on every push to `main`; the custom domain (`www.example.com.au`) will be bound as a follow-up step.

## Input provided

**Domain name:** `example.com.au`

**Primary domain:** `www.example.com.au` (apex should redirect to www)

**DNS provider:** VentraIP (manual portal — no API access)

**Hosting platform:** Azure Static Web Apps (Free tier preferred)

**Azure resource naming:** CAF conventions — `rg-example-prod`, `stapp-example-prod`

**Azure region:** `australiaeast`

**GitHub repository:** `https://github.com/my-org/example-website`

**Branch:** `main`

**Site structure:** Pre-built static HTML — no build step. Files sit at the repo root. Output location is `/`.

**Pages:**
- Homepage: `/`
- Services: `/services`
- Contact: `/contact`

**Security headers needed:** Standard set — `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`

**Other files at root:** `sitemap.xml`, `robots.txt`

**Existing infrastructure:** None — this is a greenfield setup.
