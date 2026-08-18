# M365 Email Authentication

Enable DKIM, SPF and DMARC for a Microsoft 365 custom domain — the Defender portal path, per-domain CNAME values, negative-cache delays, and cross-resolver DNS verification.

## What this skill does

Walks a Microsoft 365 custom domain from "MX and SPF only" to fully authenticated mail: publishing DMARC safely first, finding the DKIM page in the Defender portal (its search box will not), creating the keys and copying the tenant's real per-domain CNAME targets, proving the DNS chain on two resolvers, and knowing when a failing enable toggle is negative caching rather than a DNS mistake.

## When to use it

- A new domain is being added to the tenant or a website launch is touching the domain's DNS
- DKIM shows `NoDKIMKeys` for a custom domain, or no `_dmarc` record exists
- The DKIM enable toggle keeps saying "CNAME record does not exist" after the records are public
- Two DNS lookups disagree about whether a record exists

## Example use cases

- Authenticate two custom domains on one tenant without reusing the first domain's DKIM shard
- Publish `p=none` DMARC with aggregate reports before turning DKIM on
- Diagnose a "verified" DKIM record that was actually predicted rather than copied
- Decide whether to wait or re-edit DNS when the enable toggle fails 20 minutes after publishing

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — record table, DoH check commands, Defender path |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the domain(s), DNS host and a DMARC report mailbox, then follow the per-domain audit → records → verify → enable → tighten sequence. Pairs naturally with the DNS work in [Azure SWA Custom Domains](../../web/azure-swa-custom-domains/).

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
