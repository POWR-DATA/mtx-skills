# Example Input

## Context

Northwind Analytics has two custom domains on one Microsoft 365 tenant: `example.com` (main mail domain, in use for years) and `example.com.au` (added last month for a new website). Mail flows fine on both. While setting up the website's DNS the consultant noticed there is no `_dmarc` record on either domain and Defender shows `NoDKIMKeys` for both.

## Input provided

**Tenant:** `<tenant>.onmicrosoft.com`; Global Admin access to the Defender portal

**Domains and DNS hosts:**
- `example.com` — DNS at Cloudflare
- `example.com.au` — DNS at VentraIP (registrar), web hosted on Azure

**Current records (both domains):** MX → `<domain-dashed>.mail.protection.outlook.com`; SPF `v=spf1 include:spf.protection.outlook.com -all`; no `_domainkey` CNAMEs; no `_dmarc`

**DMARC reports mailbox:** `dmarc-reports@example.com` (shared mailbox, monitored)

**What was tried:** searched "DKIM" in the Defender portal — no results. On `example.com` the consultant guessed the CNAMEs from a blog post using `.onmicrosoft.com` targets; the enable button reports "CNAME record does not exist".

**Ask:** DMARC and DKIM correctly set up on both domains, and a way to tell whether a failing enable is DNS or just waiting.
