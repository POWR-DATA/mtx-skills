# Static Website Hosting

Provision and deploy a static website on Azure Static Web Apps with Bicep IaC, GitHub Actions CI/CD, deploy tokens, region choice, and multi-site layouts.

## What this skill does

This skill guides an AI through standing up a production-ready static website: Azure infrastructure via Bicep (token-deployed, no repository properties), the GitHub Actions deploy workflow with the deployment token stored correctly, region choice, gating for not-yet-provisioned resources, second sites from a subfolder, and a baseline `staticwebapp.config.json`. It hands off to [Azure SWA Custom Domains](../azure-swa-custom-domains/) for DNS/TLS and to [Static Website Config and CSP](../static-website-config-and-csp/) for routes, caching and CSP.

## When to use it

- Starting a new static website and want a properly structured, repeatable deployment
- Migrating a site from click-ops to infrastructure-as-code
- Auditing an existing setup for missing IaC or CI hygiene
- Rebuilding or moving a site to a new resource group with CAF naming
- Adding a second SWA (e.g. `go.<domain>` or an authenticated portal subdomain) from a subfolder of the same repo

## Example use cases

- Provision `stapp-example-prod` with Bicep and deploy it from GitHub Actions on push to `main`
- Migrate a manually deployed static site to Bicep + GitHub Actions
- Deploy a subfolder as its own SWA, gated in CI until the resource is provisioned
- Decide where an authenticated Supabase portal should live relative to the marketing site

## Files in this folder

| File | Required | Description |
|---|---|---|
| `SKILL.md` | Yes | Full skill definition |
| `README.md` | Yes | Short navigation guide for this skill (this file) |
| `example-input.md` | Optional | Example input — include when it helps users frame their request |
| `example-output.md` | Optional | Example output — include when it sets a useful quality bar or the output is a concrete artefact |
| `reference.md` | Optional | Load-on-demand excerpts — subfolder SWA workflow, token-deployed Bicep, deploy token into secrets, baseline config |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide the expected inputs, then review the structured output.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
