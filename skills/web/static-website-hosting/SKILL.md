---
name: static-website-hosting
description: Plan and deploy a static website on Azure Static Web Apps with custom domains, DNS, IaC, and CI/CD
author: PowerData
version: 1.2.0
license: MIT
---

# Static Website Hosting

## Purpose

Design and deploy a production-ready static website on Azure Static Web Apps with a custom domain, DNS configuration, infrastructure-as-code, and automated CI/CD deployment. The output covers every layer from Bicep template to DNS record to GitHub Actions workflow, with decisions recorded so the deployment can be reproduced or handed over.

## When to use

Use this skill when setting up a new static website or migrating an existing one to a properly structured hosting environment. Apply it when the site needs:

- A custom domain (e.g. `www.example.com`) with HTTPS
- Repeatable infrastructure deployments (not click-ops)
- Automated deployment on push to main
- Clear operator documentation for future maintenance

This skill is also useful when auditing an existing deployment for gaps in IaC coverage, DNS hygiene, or security headers.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Domain name (e.g. `example.com`)
- Preferred primary domain (apex or www — default: www is primary, apex redirects)
- DNS registrar or DNS hosting provider
- Hosting platform preference (default: Azure Static Web Apps Free tier)
- Azure subscription and preferred resource group naming convention
- GitHub repository name and branch to deploy from (default: `main`)
- Static site output folder (default: `/` for pre-built HTML, or build output path)
- Security header requirements (default: `nosniff`, `SAMEORIGIN`, `same-origin`)
- Any existing infrastructure to preserve or migrate from

## Guiding principles

- Use `www` as the primary domain. Azure Static Web Apps handles the apex → www redirect automatically once both domains are added. Do not try to reverse this without a good reason.
- Use Infrastructure-as-Code (Bicep) from the start. Click-ops deployments create undocumented state and are hard to reproduce. Even for a Free-tier SWA, a Bicep template takes 30 minutes to write and saves hours on every future change or rebuild.
- Name resources using CAF conventions: `rg-<workload>-<env>` for resource groups, `stapp-<workload>-<env>` for Static Web Apps.
- Store the deployment token in GitHub Secrets — never in code. The token grants full deployment access and must be rotated if it is ever exposed.
- For apex domain validation on Azure SWA, use the `dns-txt-token` validation method via the REST API (`az rest --method put`). The standard `az staticwebapp hostname set` command fails for apex domains when DNS hasn't yet propagated.
- Static A records for apex domains can become stale if Azure changes the underlying IP. Document the current IP and add a note to re-verify it after any Azure infrastructure event. Use ALIAS/ANAME records if the DNS provider supports them.
- Keep `staticwebapp.config.json` in source control. Use it to set security headers globally, configure MIME types for non-HTML files (XML, JSON), and add explicit routes for files like `sitemap.xml` that would otherwise be intercepted by the SPA fallback.
- Use `globalHeaders` in `staticwebapp.config.json` for security headers, not a `/*` route. Route-based headers only apply to HTML responses — CSS, JS, and image requests will be served without them. `globalHeaders` applies to every response type.
- Set `Cache-Control: public, must-revalidate, max-age=30` globally on Azure SWA Free tier. The Free tier does not support long-lived cache invalidation, so low max-age is the safe default.
- Write a validation script that checks DNS, HTTPS, and redirect behaviour on both domains. Run it after every deployment or DNS change.
- On a static HTML site with no templating, every shared component exists as a separate copy per page. Read each page's actual nav markup before editing — CTA text, hrefs, and aria attributes routinely differ between pages.
- Place mobile menu dropdowns inside `<header>`, not after it. A sticky header is a containing block — a mobile nav placed outside loses `backdrop-filter` and sticky positioning.
- When adding a hamburger menu to an existing stylesheet, audit all existing mobile media query rules for the nav. Stale rules conflict with new ones. Replace; don't just append.
- `script-src 'self'` in the CSP silently blocks inline `<script>` tags on the live site. Inline scripts work locally because no CSP is applied during local development. All JavaScript must live in external `.js` files served from the same origin. When adding interactive behaviour to a static site with this CSP, never use inline script blocks — always write to an existing or new `.js` file.
- After deploying JS or CSS changes, verify behaviour against the live URL using WebFetch or by instructing the user to hard refresh (Ctrl+Shift+R). JS and CSS are cached at `max-age=3600` — the user may be looking at the previous version without realising it.

## Process

1. **Confirm inputs** — Domain name, DNS provider, Azure subscription, GitHub repo. Ask for anything missing.

2. **Design the resource structure**
   - Resource group: `rg-<workload>-<env>` (e.g. `rg-powrdata-prod`)
   - SWA resource: `stapp-<workload>-<env>` (e.g. `stapp-powrdata-prod`)
   - Region: select based on proximity to primary audience

3. **Write the Bicep template** (`infra/main.bicep`)
   - Define SWA resource with `sku: { name: 'Free', tier: 'Free' }`
   - Use `existing` keyword if the resource already exists; otherwise create it
   - Output: `defaultHostname`, `siteName`, `resourceGroupName`
   - Do not hardcode custom domains in Bicep — manage them post-deploy via CLI

4. **Write the parameters file** (`infra/parameters/prod.parameters.json`)
   - Include `siteName`, `location`, `skuName`, `repositoryUrl`, `branch`
   - No secrets in parameters files

5. **Write deploy scripts** (`scripts/deploy-infra.ps1` and `scripts/deploy-infra.sh`)
   - Default `ResourceGroup` to the CAF-named resource group
   - Include `--what-if` flag support
   - Avoid `2>&1` on native executables in PowerShell 5.1 — use `2>$null` instead

6. **Write `staticwebapp.config.json`**
   - Add explicit route for `/sitemap.xml` with `Content-Type: application/xml`
   - Add security headers to `globalHeaders` (not `/*` — route headers only apply to HTML responses)
   - Add global `Cache-Control` header
   - Register `.xml` and `.json` MIME types

7. **Configure GitHub Actions**
   - Retrieve deployment token: `az staticwebapp secrets list --name <name> --resource-group <rg>`
   - Store as GitHub Secret via `gh secret set`
   - Workflow: single deploy job using the SWA deploy action with `app_location: "/"`, `api_location: ""`, `output_location: "/"`

8. **Configure DNS**
   - www: CNAME → `<swa-default-hostname>` (e.g. `ambitious-ground-xxx.azurestaticapps.net`)
   - Apex: A record → SWA IP (obtain via `nslookup <swa-default-hostname>`)
   - If DNS provider supports ALIAS/ANAME, use that for apex instead of a static A record

9. **Add custom domains to Azure SWA**
   - www: `az staticwebapp hostname set` — works after CNAME propagates
   - Apex: use `az rest --method put` with `validationMethod: dns-txt-token`, add the returned TXT record to DNS, then complete validation
   - Wait for both to reach `Ready` status

10. **Validate**
    - Run validation script: checks DNS, HTTPS cert, HTTP→HTTPS redirect, apex→www redirect
    - Verify `sitemap.xml` and `robots.txt` are reachable
    - Confirm security headers are present

11. **Document the deployment**
    - Record current SWA hostname, IP, resource names, deployment secret name, DNS records
    - Note that the apex A record IP may change after Azure infrastructure events

## Output format

The AI should produce:

1. **Resource naming summary** — resource group name, SWA name, region, DNS target hostname
2. **Bicep template** — complete `infra/main.bicep` content
3. **Parameters file** — complete `infra/parameters/prod.parameters.json` content
4. **Deploy scripts** — `deploy-infra.ps1` and `deploy-infra.sh`
5. **`staticwebapp.config.json`** — complete file content
6. **GitHub Actions workflow** — deploy job YAML
7. **DNS record table** — hostname, type, value, TTL for each required record
8. **Custom domain CLI commands** — `az staticwebapp hostname set` and `az rest` commands for apex validation
9. **Validation script** — checks DNS, HTTPS, redirects
10. **Post-deployment checklist** — confirm each layer is live

## Quality checklist

- [ ] Resources named using CAF conventions
- [ ] Deployment token stored in GitHub Secrets, not in any file
- [ ] `staticwebapp.config.json` has explicit route for `sitemap.xml`
- [ ] Security headers present on all response types — configured via `globalHeaders`, not `/*`
- [ ] Both www and apex domains added to SWA and showing `Ready`
- [ ] HTTPS working on both domains
- [ ] Apex redirecting to www (may take 20–30 min after domain validation)
- [ ] Validation script runs clean
- [ ] Apex A record IP documented with a note to re-verify if site stops resolving

## Avoid

- Do not hardcode deployment tokens, subscription IDs, or DNS passwords in any file committed to version control
- Do not manage custom domains in Bicep — Azure SWA domain validation is a separate lifecycle from infrastructure provisioning
- Do not skip the `staticwebapp.config.json` MIME type registration for `.xml` files — Azure SWA will serve `sitemap.xml` as HTML (falling through to the SPA fallback) without it
- Do not use `2>&1` on native Azure CLI commands in PowerShell 5.1 — it wraps stderr into error records and breaks `ConvertFrom-Json`
- Do not assume the apex A record IP is permanent — document it and verify if the site ever stops resolving at the apex
- Do not rely on the Azure portal for reproducible deployments — all configuration should be expressible as Bicep or CLI
- Do not add security headers to the `/*` route — they will only apply to HTML responses. Use `globalHeaders` to ensure headers are present on CSS, JS, image, and all other response types
- Do not assume nav markup is identical across pages — inspect each page individually before editing
- Do not place a mobile menu element after the closing `</header>` tag — it will not inherit backdrop-filter or sticky positioning
- Do not add inline `<script>` blocks to HTML pages when the site has a `script-src 'self'` CSP — they will be silently blocked on the live site but appear to work locally, making the failure hard to diagnose

## Example usage

> I'm setting up a static HTML website at `powrdata.com.au` with DNS managed at VentraIP. I want to host it on Azure Static Web Apps, deploy via GitHub Actions, and have both `www.powrdata.com.au` and the apex domain working with HTTPS. Give me the full setup.

---

_Source: This skill is sourced from the [PowerData Skills](https://github.com/POWR-DATA/skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
