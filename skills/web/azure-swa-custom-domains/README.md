# Azure SWA Custom Domains

Bind and troubleshoot custom domains on Azure Static Web Apps — DNS records, apex and subdomain validation, www canonicalisation, managed TLS, cutover, and wedged-domain recovery.

## What this skill does

Takes a provisioned Static Web App from its `azurestaticapps.net` hostname to a live HTTPS custom domain: the right DNS records per host type, apex TXT versus subdomain CNAME validation, making `www` the default so the apex redirects, proving the managed certificate actually serves, and recognising the platform's stalls (Ready-but-no-TLS, "CNAME Record is invalid", hostnames stuck in Failed/Deleting) with a tested recovery or escape route for each.

## When to use it

- Adding `www`, the apex, or a subdomain such as `go.<domain>` to a Static Web App
- Cutting a domain over from previous hosting and clients still see the old site or a TLS error
- A domain shows `Ready` but the browser reports `ERR_SSL_PROTOCOL_ERROR`
- `hostname set` keeps failing with "CNAME Record is invalid"
- A custom-domain operation is stuck in `Failed` or `Deleting` and every delete accepts-then-fails

## Example use cases

- Move `example.com.au` + `www.example.com.au` onto SWA with DNS at a registrar that has a parking A record
- Add a `go.example.com` subdomain for a second SWA and prove its certificate before printing QR codes
- Fix a `www` domain that validated but never got a certificate bound
- Diagnose a wedged hostname from the activity log and re-home it on another Azure service

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — record table, retry loop, apex TXT validation, default-domain PUT, TLS proof, wedge diagnostics |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt after the site is provisioned with [Static Website Hosting](../static-website-hosting/). Provide the domain, DNS provider, SWA name and default hostname, then follow the structured output. Load `reference.md` for the exact `az` commands.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
