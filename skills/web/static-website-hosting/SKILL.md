---
name: static-website-hosting
description: Provision and deploy a static website on Azure Static Web Apps with Bicep IaC, GitHub Actions CI/CD, deploy tokens, region choice, and multi-site layouts
author: PowerData
version: 2.0.0
license: MIT
---

# Static Website Hosting

## Purpose

Design and stand up a production-ready static website on Azure Static Web Apps — resource naming, Bicep template, deploy scripts, GitHub Actions workflow with the deploy token, and a baseline `staticwebapp.config.json` — with decisions recorded so the deployment can be reproduced or handed over. Custom domains, DNS and TLS are covered by `azure-swa-custom-domains`; routes, headers, CSP and live-site edits by `static-website-config-and-csp`.

## When to use

Use this skill when setting up a new static website, migrating one from click-ops to infrastructure-as-code, or adding a second site (subfolder or subdomain) to an existing repo. Apply it when the site needs:

- Repeatable infrastructure deployments (not click-ops)
- Automated deployment on push to main, including sites whose Azure resource does not exist yet
- Clear operator documentation for future maintenance

Also useful when auditing an existing deployment for gaps in IaC coverage or CI hygiene.

## Inputs expected

Provide as many of the following as available. Partial inputs are acceptable — the AI should identify gaps and ask structured follow-up questions only where needed.

- Domain name (e.g. `example.com`) and preferred primary host (default `www`)
- Hosting platform preference (default: Azure Static Web Apps Free tier) and audience location (drives region)
- Azure subscription and preferred resource group naming convention
- GitHub repository name and branch to deploy from (default: `main`)
- Static site output folder (default: `/` for pre-built HTML, or build output path); whether a second site lives in a subfolder
- Security header requirements (default: `nosniff`, `SAMEORIGIN`, `same-origin`)
- Any existing infrastructure to preserve or migrate from

## Guiding principles

- Use Infrastructure-as-Code (Bicep) from the start. Click-ops deployments create undocumented state and are hard to reproduce. Even for a Free-tier SWA, a Bicep template takes 30 minutes to write and saves hours on every future change or rebuild.
- Name resources using CAF conventions: `rg-<workload>-<env>` for resource groups, `stapp-<workload>-<env>` for Static Web Apps.
- Azure SWA is offered in only five regions (none in Australia); static content is served from a global edge network regardless, so the region choice mainly affects attached Functions. East Asia is the standard pick for Australian audiences.
- For a token-deployed SWA, omit repository properties from the Bicep entirely — `provider: 'GitHub'` + `repositoryUrl` without a `repositoryToken` adds friction, while a bare `Microsoft.Web/staticSites` deploys cleanly and is fed by the workflow's deploy token. Gate any `customDomains` child behind a bool param (`if (deployCustomDomain)`) because it fails validation until DNS exists. See *Token-deployed Bicep* in [`reference.md`](reference.md).
- Store the deployment token in GitHub Secrets — never in code. The token grants full deployment access and must be rotated if it is ever exposed. Set it with `gh secret set --body` on a trimmed variable; piping the `az` CLI output straight into `gh secret set` from PowerShell corrupted the token and produced "deployment_token provided was invalid" at deploy time.
- Gate a not-yet-provisioned deploy job with a repository VARIABLE in the job `if:` (`vars.X == 'true'`) — GitHub secrets are NOT available in `if:` conditions but repository variables are — so the workflow stays skipped (green CI) until you provision the resource and set the variable.
- Run a second independent SWA from one repo by deploying only a subfolder: a dedicated GitHub Actions workflow with `app_location: <subfolder>`, `skip_app_build: true`, its OWN deploy-token secret (never the main site's), and a `paths:` filter so a subfolder change never redeploys the whole site. See *Subfolder SWA workflow* in `reference.md`.
- Host an authenticated SPA (e.g. a Supabase-auth portal) on its OWN subdomain, not as a subdirectory of the marketing site: a subdomain is a distinct browser origin, so the SPA localStorage/PKCE tokens, CSP, and XSS blast radius are isolated, and it deploys as two independent Static Web Apps (each with its own managed TLS + CI) instead of a reverse-proxy / Front Door subpath. Caveat: a subdomain is NOT a cookie trust boundary (the registrable domain is), so use host-only / `__Host-` cookies and never wildcard the CSP to `*.yourdomain`.
- Azure SWA cancels an in-progress deployment when a newer push arrives, producing a GitHub Actions failure notification even though the site deploys correctly from the later commit. Verify no deployment is running (`gh run list --limit 3`) before pushing to avoid spurious failure alerts.
- Ship a baseline `staticwebapp.config.json` with the first deploy — security headers in `globalHeaders` (not a `/*` route), a short global `Cache-Control`, `.xml`/`.json` MIME types and an explicit `/sitemap.xml` route — then hand the file to `static-website-config-and-csp` for caching tiers, hidden files, redirects and CSP.
- Custom domains are a separate lifecycle from provisioning: publish DNS, bind and prove TLS with `azure-swa-custom-domains` after this skill's deploy is green.

## Process

1. **Confirm inputs** — domain, audience region, Azure subscription, GitHub repo, single vs multi-site layout. Ask for anything missing.

2. **Design the resource structure**
   - Resource group: `rg-<workload>-<env>`; SWA: `stapp-<workload>-<env>` (one per site — marketing, `go.<domain>`, portal)
   - Region: East Asia for Australian audiences (edge-served regardless)

3. **Write the Bicep template** (`infra/main.bicep`)
   - Bare `Microsoft.Web/staticSites` with `sku: { name: 'Free', tier: 'Free' }`, `properties: {}` — no repository properties
   - Optional `customDomains` child behind `if (deployCustomDomain)`, default `false`
   - Use `existing` if the resource already exists; outputs `defaultHostname`, `siteName`, `resourceGroupName`

4. **Write the parameters file** (`infra/parameters/prod.parameters.json`) — `siteName`, `location`, `skuName` (+ `deployCustomDomain`/`customDomain` if used); no secrets

5. **Write deploy scripts** (`scripts/deploy-infra.ps1` and `.sh`) — default to the CAF resource group, support `--what-if`, avoid `2>&1` on native executables in PowerShell 5.1

6. **Write the baseline `staticwebapp.config.json`** — `globalHeaders` security headers + `Cache-Control: public, must-revalidate, max-age=30`, `.xml`/`.json` MIME types, `/sitemap.xml` route

7. **Configure GitHub Actions**
   - Deployment token: `az staticwebapp secrets list --name <name> --resource-group <rg>` → `$t = (…).properties.apiKey.Trim()` → `gh secret set AZURE_SWA_TOKEN --body $t`
   - Workflow: single deploy job with `app_location: "/"`, `api_location: ""`, `output_location: "/"`
   - Not yet provisioned? `if: vars.<FLAG> == 'true'` on the job; set the variable after Bicep succeeds
   - Second SWA from a subfolder: separate workflow, `app_location: <subfolder>`, `skip_app_build: true`, its own token secret, `paths:` filter

8. **Deploy and confirm** — Bicep `--what-if` then deploy; push; `gh run watch`; fetch `https://<defaultHostname>/`

9. **Hand off** — custom domains, DNS and TLS → `azure-swa-custom-domains`; routing, caching, CSP, hidden files → `static-website-config-and-csp`

10. **Document the deployment** — SWA name(s), default hostname(s), secret and variable names, workflow files, subfolder layout

## Output format

The AI should produce:

1. **Resource naming summary** — resource group, SWA name(s), region, default hostname(s)
2. **Bicep template** — complete `infra/main.bicep` content
3. **Parameters file** — complete `infra/parameters/prod.parameters.json` content
4. **Deploy scripts** — `deploy-infra.ps1` and `deploy-infra.sh`
5. **Baseline `staticwebapp.config.json`** — headers, cache, MIME, sitemap route
6. **GitHub Actions workflow(s)** — deploy job YAML, `vars.<FLAG>` gating, any subfolder-SWA workflow, secret/variable names
7. **Hand-off notes** — what `azure-swa-custom-domains` and `static-website-config-and-csp` pick up next
8. **Post-deployment checklist** — confirm each layer is live on the default hostname

## Quality checklist

- [ ] Resources named using CAF conventions; region chosen deliberately (East Asia for AU audiences)
- [ ] Bicep for a token-deployed SWA has no repository properties; any `customDomains` child gated behind a bool
- [ ] Deployment token stored via `gh secret set --body` on a trimmed value — never piped, never in a file
- [ ] Not-yet-provisioned deploy jobs gated with `vars.<FLAG> == 'true'`, not a secret
- [ ] Second subfolder SWA has its own token secret and `paths:` filter
- [ ] Authenticated SPA lives on its own subdomain/SWA, with `__Host-` cookies and no `*.domain` CSP wildcard
- [ ] Baseline config: security headers via `globalHeaders`, MIME types, `/sitemap.xml` route
- [ ] No deployment running (`gh run list`) before pushing
- [ ] Site reachable on the default hostname; hand-off items listed

## Avoid

- Do not hardcode deployment tokens, subscription IDs, or DNS passwords in any file committed to version control
- Do not pipe `az` output straight into `gh secret set` from PowerShell — trim into a variable and use `--body`
- Do not put `repositoryUrl`/`provider: 'GitHub'` in Bicep for a token-deployed SWA — without a `repositoryToken` it only adds friction
- Do not manage the apex domain in Bicep — its validation is a separate lifecycle (see `azure-swa-custom-domains`)
- Do not gate a job on a secret in `if:` — secrets are unavailable there; use a repository variable. Do not reuse the main site's deploy token for a second SWA
- Do not host an authenticated portal as a subpath of the marketing site — give it its own subdomain and SWA
- Do not add security headers to the `/*` route — they only reach HTML responses; use `globalHeaders`
- Do not use `2>&1` on native Azure CLI commands in PowerShell 5.1 — it wraps stderr into error records and breaks `ConvertFrom-Json`
- Do not rely on the Azure portal for reproducible deployments — all configuration should be expressible as Bicep or CLI
- Do not push while an Azure SWA deployment is still running — the cancelled run reports a spurious failure; check `gh run list --limit 3` first

## Example usage

> I'm setting up a static HTML website at `powrdata.com.au` with the repo on GitHub. Provision it on Azure Static Web Apps with Bicep, wire up GitHub Actions with the deploy token, and lay it out so I can add a `go.` short-link site from a subfolder later. Give me the full setup — I'll do the DNS/custom domain step next.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
