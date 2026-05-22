# Static Website Hosting

Plan and deploy a static website on Azure Static Web Apps with custom domains, DNS, IaC, and CI/CD.

## What this skill does

This skill guides an AI through the full setup of a production-ready static website: creating Azure infrastructure via Bicep, configuring DNS records for custom domains (www and apex), wiring up GitHub Actions for automated deployment, and writing the `staticwebapp.config.json` configuration for security headers and correct MIME types. The output is a complete, reproducible deployment covering every layer from IaC to DNS to CI/CD.

## When to use it

- Starting a new static website and want a properly structured, repeatable deployment
- Migrating a site from click-ops to infrastructure-as-code
- Adding a custom domain to an existing Azure Static Web Apps deployment
- Auditing an existing setup for missing IaC, security headers, or DNS hygiene
- Rebuilding or moving a site to a new resource group with CAF naming

## Example use cases

- Set up `www.example.com` on Azure Static Web Apps with DNS at VentraIP
- Migrate a manually deployed static site to Bicep + GitHub Actions
- Add an apex domain with HTTPS to an existing Azure SWA deployment
- Write a validation script to check DNS, HTTPS, and redirect behaviour after a deployment

## Files in this folder

| File | Required | Description |
|---|---|---|
| `SKILL.md` | Yes | Full skill definition |
| `README.md` | Yes | Short navigation guide for this skill (this file) |
| `example-input.md` | Optional | Example input — include when it helps users frame their request |
| `example-output.md` | Optional | Example output — include when it sets a useful quality bar or the output is a concrete artefact |

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
