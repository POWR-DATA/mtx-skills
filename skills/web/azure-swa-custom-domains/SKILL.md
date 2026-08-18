---
name: azure-swa-custom-domains
description: Bind and troubleshoot custom domains on Azure Static Web Apps — DNS records, apex and subdomain validation, www canonicalisation, managed TLS, cutover, and wedged-domain recovery
author: PowerData
version: 1.1.0
license: MIT
---

# Azure SWA Custom Domains

## Purpose

Take a provisioned Azure Static Web App from its `*.azurestaticapps.net` hostname to a live, HTTPS-served custom domain — apex, `www`, and any subdomains — with the right DNS records, validation method, canonical redirect, and TLS binding, plus a diagnosis path for the platform's stalls and wedges. Split from `static-website-hosting`, which provisions and deploys the site itself.

## When to use

After the SWA exists and deploys (see `static-website-hosting`), whenever you:

- Add `www`, the apex, or another subdomain (e.g. `go.<domain>`) to a Static Web App
- Move a domain from previous hosting onto SWA (cutover)
- See `Ready` domains that still fail TLS, "CNAME Record is invalid", or a hostname stuck in `Failed`/`Deleting`
- Need apex → www canonicalisation or want to verify DNS/HTTPS/redirects after a change

## Inputs expected

Partial inputs are fine — ask only for what is missing.

- Domain name and which host is primary (default: `www` primary, apex redirects)
- DNS provider and whether it supports ALIAS/ANAME/CNAME-flattening at the apex
- SWA name, resource group, subscription, and its default hostname
- Any existing records on the domain (parking A records, old hosting, mail records) and their TTLs

---

## Guiding principles

- **Use `www` as the primary domain, and canonicalise apex → www by making `www` the app's default domain.** SWA route rules cannot match on host, so the redirect is done by ARM `PUT` on the `www` customDomains resource with `properties.isDefault: true` (`PATCH` returns Method Not Allowed; include `validationMethod: cname-delegation` so a `Ready` domain is adopted in place). The apex then 301s to www with path and query preserved. Keep the apex on its ALIAS/CNAME-flattening record to the default hostname; do not re-point it at the `stableInboundIP` just to obtain a redirect. See *Default-domain ARM PUT* in [`reference.md`](reference.md).
- **Validate the apex with `dns-txt-token` via the REST API** (`az rest --method put`). The standard `az staticwebapp hostname set` fails for apex domains when DNS has not yet propagated.
- **A subdomain (www or `go.<domain>`) uses CNAME validation — no TXT.** Add `<sub>` CNAME → `<defaultHostname>.azurestaticapps.net`, then bind it (`az staticwebapp hostname set` or Bicep `customDomains` behind a bool param that stays `false` until the CNAME exists) and Azure auto-issues the managed TLS cert. Hostname `status: Ready` means validated and certificate issued.
- **"CNAME Record is invalid" is usually timing, not a typo.** Registering a `www` hostname fails until Azure's own resolvers observe the new record, and a just-changed record can be masked for hours by the old record's TTL (a 4-hour parking A record, for instance). Script a retry every few minutes rather than treating the first failure as terminal.
- **`Ready` with `sslState: null` and a TLS internal-error alert is a stalled binding.** The domain reports Ready but the edge answers with no certificate (browsers show `ERR_SSL_PROTOCOL_ERROR`). Fix by deleting and re-adding the hostname to force fresh certificate issuance; a `www` re-add validates instantly over an existing CNAME. Allow up to 15 minutes propagation after the re-add. This fix applies only when status is Ready with null sslState — never after a Failed add.
- **Static apex A records go stale.** Azure can change the underlying IP; document the current IP with a note to re-verify after any Azure infrastructure event, and prefer ALIAS/ANAME/CNAME-flattening to the default hostname where the DNS provider supports it.
- **After a cutover, clients keep resolving the old IP for up to the old record's TTL.** A parking host with no certificate presents as `ERR_SSL_PROTOCOL_ERROR` even though the new hosting is healthy. Diagnose with fresh `curl` connections from another resolver before touching the server; fix clients with `ipconfig /flushdns` and a browser restart.
- **Custom-domain operations can wedge permanently — recognise it early and escape sideways.** `hostname set` goes `RetrievingValidationToken` → `Failed` ("unknown error"), the follow-up delete sticks in `Deleting` indefinitely, and CLI, direct ARM `DELETE` and Portal deletes all accept-then-fail about 10 minutes later with no customer-side force-delete (a Basic support plan cannot even file a ticket; Resource Health does not support `staticSites`, so harvest correlation IDs from `az monitor activity-log list --resource-group <rg> --offset 24h` filtered on `customDomains`). The stuck claim follows the *hostname*, not the resource: rebuilding the SWA under a new name re-wedges, `az staticwebapp delete` on such a resource silently no-ops (`show` still succeeds and a same-name Bicep redeploy reuses it). Treat "Operation returned an invalid status 'OK'" from `hostname set`/`delete` as a CLI poller quirk — verify with `hostname list`, not the exit code — and escape a wedged name by serving it from a different Azure service entirely (e.g. an Azure Container App; see `branded-link-qr-service`).
- **Never let automation register or delete a hostname inside a fragile platform loop.** The community workaround for a wedged domain (delete the CNAME at the registrar, wait 30–60 minutes, re-issue the delete) cleared the stuck record once — but an automated watcher immediately re-registered the hostname into empty DNS and re-wedged it, and the second attempt never cleared. After changing or deleting a DNS record, budget a full old-TTL soak (60 minutes seen, negative caching included) before a single *manual* registration attempt; watchers observe and report, a human performs the mutating step.
- **SWA Free tier appears to cap custom domains at 2 per app** (apex + www consumed both); verify the current limit before planning more subdomains, and plan additional subdomains as separate SWA resources rather than extra domains on the same app.
- **Write a validation script that checks DNS, HTTPS, and redirect behaviour on every hostname**, and run it after every deployment or DNS change.

## Process

1. **Inventory DNS** — current records at apex/www/subdomains, their TTLs, and any parking or old-hosting records that will mask a change.
2. **Publish records** — `www` (and other subdomains): CNAME → SWA default hostname; apex: ALIAS/ANAME/flattened CNAME to the default hostname, or an A record to the SWA IP (`nslookup <defaultHostname>`) if that is all the provider offers.
3. **Confirm records from a public resolver** (`nslookup … 8.8.8.8` / DoH) — then still expect Azure's resolvers to lag by the old TTL.
4. **Bind subdomains** — `az staticwebapp hostname set` (retry every few minutes on "CNAME Record is invalid") or Bicep with `deployCustomDomain=true`.
5. **Bind the apex** — `az rest --method put` with `validationMethod: dns-txt-token`, add the returned TXT at `@`, complete validation. See *Apex TXT validation* in `reference.md`.
6. **Wait for `Ready` and prove TLS** — `az staticwebapp hostname list`, then `curl -sI https://<host>` and `openssl s_client -servername <host>` showing the right CN. Ready + `sslState: null` + TLS alert → delete and re-add the hostname.
7. **Canonicalise** — ARM PUT `isDefault: true` on `www`; confirm `http://<apex>/x?y=1` → 301 → `https://www.<apex>/x?y=1`.
8. **Run the validation script** and record hostnames, IP, records, and TTLs in the operator notes.
9. **If a hostname wedges** (Failed / stuck Deleting) — collect activity-log correlation IDs, stop retrying against SWA, and serve that hostname from another service. If you try the delete-CNAME-and-wait workaround, disable any watcher/automation first, soak a full old TTL, then make one manual attempt.

## Output format

1. **DNS record table** — hostname, type, value, TTL, and any old record to retire
2. **Binding commands** — subdomain `hostname set`, apex `az rest` TXT validation, default-domain PUT
3. **TLS/redirect verification** — `hostname list` status, `curl`/`openssl` output, apex → www redirect check
4. **Validation script** — DNS, HTTPS, redirect checks for every hostname
5. **Operator notes** — current IP, TTLs, retry/cutover expectations, and the wedge escape plan

## Quality checklist

- [ ] `www` is the SWA default domain (ARM PUT `isDefault: true`); apex 301s to www with path + query preserved
- [ ] Apex validated via `dns-txt-token`; subdomains via CNAME — no TXT for subdomains
- [ ] Every hostname shows `Ready` **and** serves a certificate (`openssl s_client` CN correct); no `sslState: null` stalls
- [ ] "CNAME Record is invalid" handled by scripted retry, not by editing DNS again
- [ ] Apex on ALIAS/ANAME/flattening where possible; any A record IP documented with a re-verify note
- [ ] Old-record TTLs noted; cutover verified from a fresh resolver before blaming the server
- [ ] Validation script runs clean on all hostnames
- [ ] Wedged-hostname signals (Failed add, stuck Deleting, "invalid status 'OK'") recognised — verified with `hostname list`, escape route named
- [ ] No automation registers/deletes hostnames during DNS soaks; Free-tier 2-domain cap checked before planning subdomains

## Avoid

- Managing the apex domain in Bicep — its `dns-txt-token` validation is a separate lifecycle from provisioning
- Re-pointing the apex at the `stableInboundIP` to get a redirect — set `isDefault` on `www` instead
- Treating the first "CNAME Record is invalid" as terminal — Azure's resolvers lag; retry
- Trusting `Ready` alone — check `sslState` and an actual TLS handshake
- Applying the delete/re-add TLS fix after a **Failed** add — it only works on Ready + null sslState
- Trusting the exit code of `hostname set`/`delete` — "invalid status 'OK'" is a poller quirk; read `hostname list`
- Rebuilding a wedged SWA under a new name expecting the hostname to free up — the claim follows the hostname
- Debugging `ERR_SSL_PROTOCOL_ERROR` on the server when clients are still resolving the old IP — flush client DNS first
- Leaving a watcher or CI job free to re-register a hostname while you are clearing a wedge — it re-wedges it into empty DNS
- Planning a third custom domain on a Free-tier app — check the cap; use a separate SWA per extra subdomain

## Example usage

> "My Static Web App is deployed on its `azurestaticapps.net` hostname. Move `example.com.au` and `www.example.com.au` onto it — DNS is at VentraIP, there's a 4-hour parking A record on the apex right now — and make sure the apex redirects to www over HTTPS. Yesterday `www` showed Ready but the browser gave a TLS error."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
