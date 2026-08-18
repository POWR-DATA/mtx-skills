# Static Website Config and CSP

Configure and safely change a live static site on Azure Static Web Apps — `staticwebapp.config.json` routes, headers, caching and MIME types, Content Security Policy, and the front-end gotchas of editing a static HTML site in production.

## What this skill does

Covers everything that happens to a static site *after* it is provisioned and deployed: getting security headers onto every response type, setting a sane cache policy, hiding committed internal files, serving unusual file types correctly, tightening a CSP without silently breaking pages, and making structural edits (moved pages, mobile menus, shared scripts) to a templating-free multi-page site without regressions.

## When to use it

- Editing `staticwebapp.config.json` — headers, cache rules, MIME types, redirects, rewrites
- Adding JavaScript or CSS to a site that has (or is getting) a `script-src 'self'` CSP
- Moving pages into subfolders, adding a hamburger menu, or touching shared nav/footer markup
- Repo files such as `docs/`, `infra/`, or `OPERATIONS.md` are fetchable on the live site
- A `.vcf`, `apple-app-site-association`, or `sitemap.xml` is served with the wrong content type

## Example use cases

- Move a CSP from Report-Only to enforced after externalising inline scripts and handlers
- Hide `docs/*` and root-level `.md` files with 404 routes and prove it live
- Reorganise `/reset-password.html` into `/account/` with 302s, a folder rewrite and root-absolute assets
- Add per-asset cache headers and a `?v=` bump so a JS change actually reaches users

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — ordered route block, per-route CSP for an auth page, null-guarded script + cache-bust |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt once the site is live via [Static Website Hosting](../static-website-hosting/). Provide the current config, CSP and the change you want, then apply the structured output and verify against the live URL.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
