---
name: m365-email-authentication
description: Enable DKIM, SPF and DMARC for a Microsoft 365 custom domain — the Defender portal path, per-domain CNAME values, negative-cache delays, and cross-resolver DNS verification
author: PowerData
version: 1.2.0
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
- **DMARC aggregate reports are the audit trail and the tightening evidence.** Reports arrive daily at the `rua` mailbox from each provider that handled your mail (Microsoft and Google within days of the record existing); reports predating DKIM enablement show SPF-only passes, so keep them as the audit trail and use the post-enablement run as the evidence for moving `p=none` to `p=quarantine`. An inbox rule shunting them to a subfolder keeps a shared mailbox usable.
- **A shared mailbox's display name is the sender name recipients see.** Audit it against brand rules when working in a tenant — one mailbox display-named with the domain-style name leaked off-brand naming into every email it sent; fix under admin.microsoft.com → Teams & groups → Shared mailboxes.
- **Cross-check two public resolvers before declaring a record missing.** Google DoH (`dns.google/resolve`) can keep serving a stale negative answer from your own earlier lookup while Cloudflare DoH (`cloudflare-dns.com/dns-query` with `accept: application/dns-json`) already shows the record. See *DoH checks* in [`reference.md`](reference.md).
- **A cross-domain `rua` needs the receiving domain's permission record.** When a domain's DMARC `rua` points at a mailbox on a different organisational domain, that domain must publish `<policy-domain>._report._dmarc.<report-domain>` TXT `v=DMARC1;` or Google and Microsoft silently drop every report. A domain can also publish DMARC with no `rua` at all and look healthy for months while producing zero reports — check the record itself, not just the policy.
- **Aggregate reports only show streams receivers actually saw.** A low-volume M365 stream was completely absent from weeks of reports while the app mailer dominated them. Close an unobserved stream with a seed test to an external Gmail address and read Google's Authentication-Results in *Show original* — but note a send between two accepted domains inside the same M365 tenant never leaves Microsoft and proves nothing.
- **Microsoft's own `dkim=none (message not signed)` header is meaningless.** That `authentication-results` line is the internal pre-egress check and always says none, because signing happens on egress. Judge alignment only from the receiving server's line: `dkim=pass header.i=@<domain>` with `s=selector1`, `spf=pass smtp.mailfrom=<addr>@<domain>`, and `dmarc=pass`.
- **Tighten in stages, and mind subdomain inheritance.** Move the root domains to `p=quarantine` once every live stream is observed passing, but hold a campaign sending subdomain that has its own `_dmarc` record at `p=none` until its first real send has delivered at volume. With `sp` unset, any new sending subdomain of a quarantined root inherits quarantine and needs its own record. Do not add `ruf` — forensic reports copy failing message headers and content into a mailbox, an unnecessary PII channel.
- **Parse aggregate reports with reverse DNS, and end with a go/no-go.** Handle zip, gz or plain XML, group by source IP and header-from, reverse-resolve every IP so unknown senders are named, and finish with an explicit recommendation on tightening. Reverse DNS is what turns an anonymous IP into "amazonses ap-northeast-1" or "outbound.protection.outlook.com" — how you tell a legitimate but unaligned tool from spoofing.

## Process

1. **Inventory** — for each domain: MX, SPF (`v=spf1 … include:spf.protection.outlook.com`), any `selector1/2._domainkey` CNAMEs, `_dmarc` TXT. Note the DNS host.
2. **DMARC first** — publish `_dmarc` TXT `v=DMARC1; p=none; rua=mailto:<monitored-mailbox>` per domain.
3. **DKIM keys** — Defender → Email authentication settings → DKIM → click the domain name → Create DKIM keys → copy both CNAME hosts and targets exactly.
4. **Publish the CNAMEs** at the domain's DNS host; do not reuse another domain's shard letter.
5. **Verify the chain** — resolve `selector1._domainkey.<domain>` → CNAME target → TXT `v=DKIM1; k=rsa; p=…` on two DoH resolvers.
6. **Enable** — toggle DKIM on; on "CNAME record does not exist", wait (30–60+ min) and retry without changing DNS; enable never-looked-up domains first.
7. **Tighten** — once DKIM signs and the post-enablement DMARC aggregate reports look clean, move `p=none` → `quarantine` → `reject`; add an inbox rule filing the daily reports to a subfolder.
8. **Audit sender display names** — check each shared mailbox's display name against brand rules while in the tenant.
8. **Confirm reports are actually arriving** — check the `rua` value exists, and publish the `_report._dmarc` permission record on the receiving domain when it differs from the policy domain.
9. **Seed-test any unobserved stream** to an external mailbox and read the receiving server's Authentication-Results, not Microsoft's internal one.
10. **Parse a few weeks of reports** grouped by source IP with reverse DNS, then decide `p=none` → `quarantine` per domain, holding new sending subdomains until they have sent at volume.

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
- [ ] `rua` present, and a `<policy-domain>._report._dmarc.<report-domain>` TXT published wherever reports cross domains
- [ ] Every live sending stream observed passing in reports or closed out with an external seed test
- [ ] Alignment judged from the receiving server's Authentication-Results, never Microsoft's pre-egress `dkim=none`
- [ ] Sending subdomains carry their own `_dmarc` record, held at `p=none` until their first real send at volume
- [ ] No `ruf` configured

## Avoid

- Searching "DKIM" in the Defender search box — it searches security data, not settings
- Ticking the domain checkbox instead of clicking its name — the key panel never opens
- Guessing `.onmicrosoft.com`-style or another domain's shard in the CNAME target
- Trusting a single resolver's negative answer, or your own earlier lookup on Google DoH
- Editing DNS again when the enable toggle fails minutes after publishing — it is negative caching; wait
- Skipping DMARC because "DKIM isn't on yet" — `p=none` with `rua` is safe and informative from day one
- Assuming a published DMARC policy means reports are arriving — check for `rua` and the cross-domain permission record
- Seed-testing between two accepted domains in the same M365 tenant — the message never leaves Microsoft
- Reading Microsoft's internal `dkim=none (message not signed)` as a failure
- Quarantining a root domain without giving a new sending subdomain its own `p=none` record first
- Adding `ruf` — it pipes failing message content into a mailbox for no operational gain

## Example usage

> "New domain on our Microsoft 365 tenant, website going live this week. Mail works but I don't think DKIM or DMARC are set up — the Defender portal search for DKIM shows nothing, and on our other domain the enable button keeps saying the CNAME record doesn't exist even though I can resolve it. Get both domains fully authenticated."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
