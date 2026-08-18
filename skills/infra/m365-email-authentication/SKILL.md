---
name: m365-email-authentication
description: Enable DKIM, SPF and DMARC for a Microsoft 365 custom domain — the Defender portal path, per-domain CNAME values, negative-cache delays, and cross-resolver DNS verification
author: PowerData
version: 1.0.0
license: MIT
---

# M365 Email Authentication

## Purpose

Bring a Microsoft 365 custom domain up to full email authentication — DKIM enabled with the tenant's real per-domain CNAMEs, SPF confirmed, DMARC published and tightened over time — with the DNS verification discipline that avoids the wrong-record and "wait longer" traps.

## When to use

Whenever a new domain is stood up or DNS is being touched for a site launch: audit email authentication as part of the DNS work. Apply when a tenant has MX and SPF but DKIM shows `NoDKIMKeys`, when no `_dmarc` record exists, when the DKIM enable toggle keeps failing, or when two resolvers disagree about a record.

## Inputs expected

- The custom domain(s) on the tenant and access to their DNS host (which may differ from the registrar or web host)
- Admin access to the Microsoft Defender portal
- A monitored mailbox for DMARC aggregate reports
- Which resolvers/tools are available for verification (DoH via curl is enough)

---

## Guiding principles

- **Audit email authentication as part of any new-domain DNS work.** A Microsoft 365 tenant typically has MX and SPF but no DKIM selectors until DKIM is enabled in the Defender portal, and no DMARC record at all. Add DMARC at `p=none` with `rua` to a monitored mailbox first, then tighten after DKIM is live.
- **The Defender portal search box does not find settings pages.** It searches security data (devices, users, alerts), so searching "DKIM" finds nothing; go straight to `https://security.microsoft.com/authentication?viewid=DKIM` (Email & collaboration → Policies & rules → Threat policies → Email authentication settings → DKIM).
- **Click the domain name itself to create the keys.** Custom domains show `NoDKIMKeys` until you click the domain name (not its checkbox) to open the panel and create the keys, which then displays two CNAMEs; in current tenants the targets are `selectorN-<domain-dashed>._domainkey.<tenant>.<shard>-v1.dkim.mail.microsoft`, not the older `.onmicrosoft.com` form. The `<tenant>.onmicrosoft.com` row needs nothing from you.
- **Never predict the second domain's CNAMEs from the first.** The DKIM shard letter differs per domain inside one tenant (`n-v1` for one domain, `r-v1` for the next); a predicted record "verified" against its own prediction for ten hours. Always copy the values from the Defender panel, and prove the chain end to end by resolving your CNAME and then the target TXT until you see `v=DKIM1; k=rsa; p=...`.
- **The enable toggle can fail "CNAME record does not exist" for 30–60+ minutes after correct records are public** because Microsoft's resolvers negative-cache the earlier miss (the dialog's "up to 4 days" is boilerplate); it succeeded hours later with no DNS change. Enable the domain Microsoft has never looked up first, and retry the other one later rather than touching DNS again.
- **Cross-check two public resolvers before declaring a record missing.** Google DoH (`dns.google/resolve`) can keep serving a stale negative answer from your own earlier lookup while Cloudflare DoH (`cloudflare-dns.com/dns-query` with `accept: application/dns-json`) already shows the record. See *DoH checks* in [`reference.md`](reference.md).

## Process

1. **Inventory** — for each domain: MX, SPF (`v=spf1 … include:spf.protection.outlook.com`), any `selector1/2._domainkey` CNAMEs, `_dmarc` TXT. Note the DNS host.
2. **DMARC first** — publish `_dmarc` TXT `v=DMARC1; p=none; rua=mailto:<monitored-mailbox>` per domain.
3. **DKIM keys** — Defender → Email authentication settings → DKIM → click the domain name → Create DKIM keys → copy both CNAME hosts and targets exactly.
4. **Publish the CNAMEs** at the domain's DNS host; do not reuse another domain's shard letter.
5. **Verify the chain** — resolve `selector1._domainkey.<domain>` → CNAME target → TXT `v=DKIM1; k=rsa; p=…` on two DoH resolvers.
6. **Enable** — toggle DKIM on; on "CNAME record does not exist", wait (30–60+ min) and retry without changing DNS; enable never-looked-up domains first.
7. **Tighten** — once DKIM signs and DMARC reports look clean, move `p=none` → `quarantine` → `reject`.

## Output format

1. **Per-domain audit table** — MX / SPF / DKIM / DMARC status before and after
2. **DNS records to add** — exact host, type, value per domain (copied from the Defender panel)
3. **Verification log** — resolver, query, answer for each record on two DoH resolvers
4. **Enable + tighten plan** — order of DKIM enables, retry timing, DMARC policy ramp

## Quality checklist

- [ ] DMARC `p=none` + `rua` published for every domain before any tightening
- [ ] DKIM CNAME values copied from the Defender panel for **each** domain — no shard-letter reuse
- [ ] Chain proven: CNAME → target TXT shows `v=DKIM1; k=rsa; p=`
- [ ] Records confirmed on two DoH resolvers (Google + Cloudflare)
- [ ] DKIM enable retried on a timer, not by re-editing DNS
- [ ] `<tenant>.onmicrosoft.com` row left alone

## Avoid

- Searching "DKIM" in the Defender search box — it searches security data, not settings
- Ticking the domain checkbox instead of clicking its name — the key panel never opens
- Guessing `.onmicrosoft.com`-style or another domain's shard in the CNAME target
- Trusting a single resolver's negative answer, or your own earlier lookup on Google DoH
- Editing DNS again when the enable toggle fails minutes after publishing — it is negative caching; wait
- Skipping DMARC because "DKIM isn't on yet" — `p=none` with `rua` is safe and informative from day one

## Example usage

> "New domain on our Microsoft 365 tenant, website going live this week. Mail works but I don't think DKIM or DMARC are set up — the Defender portal search for DKIM shows nothing, and on our other domain the enable button keeps saying the CNAME record doesn't exist even though I can resolve it. Get both domains fully authenticated."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
