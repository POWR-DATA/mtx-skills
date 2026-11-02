---
name: web-filter-recategorisation
description: Diagnose and fix a corporate web filter blocking a young domain — proving it is the filter not the site, and requesting a category from each major filtering vendor
author: PowerData
version: 1.1.0
license: MIT
---

# Web Filter Recategorisation

## Purpose

Work out why a new site is unreachable from corporate networks, prove the block is a web filter rather than the hosting, and get the domain categorised with each major filtering vendor so it stops being blocked for being unknown.

## When to use

When a recently launched domain fails to load on some networks but works on others — typically reported as "it doesn't work at my office" or "the hospital network can't open it". Apply as soon as a young domain is being shared with people on managed networks, and before any launch where the audience sits behind corporate or institutional proxies. Uncategorised is itself a blocking reason, so this is a launch task, not an incident-only one.

## Inputs expected

- The domain(s), including any short-link or redirect host
- The hosting platform's default hostname (e.g. `*.azurestaticapps.net`), which serves as the control
- Access to a machine on the blocking network, and a second network to test from
- What the site actually is, in one honest category

---

## Guiding principles

- **A young domain gets blocked simply for being uncategorised.** Filters default-deny what they do not recognise, so a brand-new site can be unreachable on a managed network while being perfectly healthy. This is not a misconfiguration to debug on the server.
- **Prove it is the filter by comparing against the host's default hostname.** From a Zscaler-protected machine, HTTPS to the custom domain failed with curl `(35) Recv failure: Connection was reset` and plain HTTP returned `403` with `Server: Zscaler` and `reasoncode=CATEGORY_DENIED`, while the site's own `*.azurestaticapps.net` hostname answered normally. Same origin, same content, different result — that is the filter, conclusively.
- **Read the plain-HTTP response, not just the HTTPS failure.** HTTPS gives you a reset with no explanation; HTTP often returns the filter's own branded 403 naming the vendor and the reason code. That response is the diagnosis.
- **A filtered network also blinds your tooling.** The block stops agents and web-fetch tools running on that machine from reaching production at all, so verification of the live site must move to another network — do not interpret an agent's fetch failure as a site outage.
- **Request one honest category, never two.** Some networks block a site if *any* of its categories is restricted, so an additional category can only add risk. Pick the single category that genuinely describes the site — for a corporate consulting site, one business-family category per vendor — and skip vendors that already rate it sensibly.
- **Submit the short-link host too.** A redirect host is a separate domain and is categorised separately; include a comment saying it only redirects to the main site.
- **Each vendor has its own quirks — expect a different form per vendor, not one submission.** See the table below. Several vendors share a database with their other products, so one submission can cover a family of filtering services.

| Vendor | Lookup | Notes |
|---|---|---|
| Zscaler | `sitereview.zscaler.com` | up to 3 URLs per request; the locked "Miscellaneous or Unknown" placeholder cannot be unticked, so just add the real category alongside it |
| Broadcom / Symantec WebPulse | `sitereview.bluecoat.com` | choose "Other" as the reason; any filtering service (e.g. Edge SWG) works — they all share one database |
| Fortinet | its public lookup | one URL per request; the lookup blocks scripted access, so submit by hand |
| Palo Alto, Cisco Talos | their public lookups | check first — both had already categorised the site correctly with no request needed |
| Forcepoint | customer hub | now requires a login, so non-customers cannot submit |

- **Script the lookups only where the vendor allows it.** For Cisco Talos, `GET https://talosintelligence.com/cloud_intel/url_reputation?url=<domain>` sent with a `Referer` of its lookup page returns JSON whose `aup_cat` gives the category. Broadcom's lookup returned nothing to scripts and Fortinet blocks them, so check those by hand.
- **Read each vendor's reply for what it actually means.** Zscaler's "URL Category Changed" and Fortinet's "URL Rating Update Notification" mean the change is done (both arrived within a day); Broadcom's "WebPulse Site Review Request Submitted" is only an acknowledgement, so re-check its lookup days later. Zscaler sends one email per submitted URL, each with its own case number.
- **Confirm the test machine is behind the filter before calling the block fixed.** `http://ip.zscaler.com` says whether traffic goes through Zscaler. A laptop that was blocked earlier was off the corporate proxy later, so a clean fetch from it proved nothing; test from a machine where `ip.zscaler.com` confirms the proxy, in a private window.

## Process

1. **Reproduce on the blocking network** — `curl` the custom domain over HTTPS and over plain HTTP, and capture both results.
2. **Run the control** — request the hosting platform's default hostname from the same machine. If it answers, the site is fine and the domain is being filtered.
3. **Read the 403 body and headers** for the vendor name and reason code.
4. **Move verification to another network** so tooling can see production while the block is being resolved.
5. **Check each vendor's public lookup** to see which already categorise the domain and which report it unknown — Talos by script, Broadcom and Fortinet by hand.
6. **Submit a single honest category** to every vendor that reports it unrated, including the short-link host with an explanatory comment; skip vendors that already rate it sensibly.
7. **Read each reply** — Zscaler's and Fortinet's confirmations mean done; Broadcom's acknowledgement means re-check its lookup days later.
8. **Re-check the lookups after a few days**, and re-test from the blocking network on a machine where `http://ip.zscaler.com` confirms the proxy, in a private window.

## Output format

1. **Diagnosis** — HTTPS result, HTTP result with vendor and reason code, control hostname result
2. **Vendor status table** — per vendor: current category, action needed, submitted or not
3. **Submissions made** — URLs, category requested, comment text, date, and each reply (done or acknowledgement only, case number)
4. **Verification plan** — when to re-check lookups, and re-testing from a machine confirmed behind the filter
5. **Notes** — any vendor that could not be submitted to, and why

## Quality checklist

- [ ] Block proven against the host's default hostname as a control
- [ ] Plain-HTTP response captured, with vendor and reason code recorded
- [ ] Live-site verification moved off the filtered network
- [ ] Every major vendor's lookup checked, not just the one that blocked you
- [ ] One category requested per domain — no second category added
- [ ] Short-link/redirect host submitted separately with an explanatory comment
- [ ] Re-check scheduled for the lookups and the blocking network
- [ ] Each vendor reply read for what it means; Broadcom's acknowledgement followed by a later lookup re-check
- [ ] Fix confirmed from a machine that `http://ip.zscaler.com` shows is behind the proxy, in a private window

## Avoid

- Debugging the server when only some networks fail — compare against the default hostname first
- Treating the HTTPS connection reset as the whole story; the HTTP 403 carries the reason
- Reading an agent or web-fetch failure on a filtered machine as a production outage
- Requesting two categories "to be safe" — any restricted category can block the site
- Submitting only to the vendor that blocked you, leaving the rest unrated
- Forgetting the short-link host, which is categorised as its own domain
- Assuming a submission is instant — allow days, then verify from the network that failed
- Treating Broadcom's "Site Review Request Submitted" email as a completed change
- Calling the block fixed from a machine that has since left the corporate proxy

## Example usage

> "Our new site loads fine for me but staff at two hospitals say it won't open. On their machine `curl` just says the connection was reset over HTTPS. The old `azurestaticapps.net` URL works for them. What's going on, and how do I get it fixed before launch?"

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
