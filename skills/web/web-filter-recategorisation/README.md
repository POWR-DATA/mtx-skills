# Web Filter Recategorisation

Diagnose and fix a corporate web filter blocking a young domain — proving it is the filter not the site, and requesting a category from each major filtering vendor.

## What this skill does

A newly launched domain is often blocked on corporate and institutional networks for no reason other than being uncategorised. This skill shows how to prove that quickly — by comparing the custom domain against the hosting platform's default hostname and reading the filter's own plain-HTTP 403 — then how to request a category from each major vendor, with the per-vendor quirks that make each submission different.

## When to use it

- A new site works for you but not for staff at a hospital, bank, school or large employer
- `curl` reports a connection reset over HTTPS from a managed machine
- An agent or web-fetch tool on a filtered machine cannot reach production
- A domain is about to launch to an audience that sits behind corporate proxies

## Example use cases

- Prove a Zscaler `CATEGORY_DENIED` block rather than debugging the static host
- Submit a health site to Zscaler, Broadcom/Symantec and Fortinet for one honest category
- Check Palo Alto and Cisco Talos, which may already have categorised the domain correctly
- Get a `go.<domain>` short-link host categorised alongside the main site

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the domain, the hosting platform's default hostname, and what the site honestly is, then follow the structured output. Treat it as a launch task rather than an incident response — uncategorised is a blocking reason on its own.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
