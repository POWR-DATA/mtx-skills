# M365 Email Authentication — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — replace `<...>` placeholders.

---

## Records per domain

| Host | Type | Value |
|---|---|---|
| `_dmarc.<domain>` | TXT | `v=DMARC1; p=none; rua=mailto:<monitored-mailbox>` (tighten to `quarantine`/`reject` later) |
| `selector1._domainkey.<domain>` | CNAME | `selector1-<domain-dashed>._domainkey.<tenant>.<shard>-v1.dkim.mail.microsoft` — **copy from the Defender panel** |
| `selector2._domainkey.<domain>` | CNAME | `selector2-<domain-dashed>._domainkey.<tenant>.<shard>-v1.dkim.mail.microsoft` |
| `<domain>` | TXT (SPF) | `v=spf1 include:spf.protection.outlook.com -all` (confirm, usually present) |

`<shard>` differs per domain within one tenant (e.g. `n` for one, `r` for the next).

## DoH checks (two resolvers)

```bash
# Cloudflare
curl -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=selector1._domainkey.<domain>&type=CNAME' | jq '.Answer[]?.data'
# Google (may keep serving your own earlier negative answer for a while)
curl -s 'https://dns.google/resolve?name=selector1._domainkey.<domain>&type=CNAME' | jq '.Answer[]?.data'
# then prove the target
curl -s -H 'accept: application/dns-json' 'https://cloudflare-dns.com/dns-query?name=<cname-target>&type=TXT' | jq '.Answer[]?.data'   # v=DKIM1; k=rsa; p=...
```

## Defender path

`https://security.microsoft.com/authentication?viewid=DKIM` → click the **domain name** (not the checkbox) → Create DKIM keys → copy both CNAMEs → publish → verify on two resolvers → Enable. On "CNAME record does not exist": wait 30–60+ min and retry; do not edit DNS.
