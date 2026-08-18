# Azure SWA Custom Domains — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## DNS records

| Hostname | Type | Value | Notes |
|---|---|---|---|
| `www` | CNAME | `<defaultHostname>.azurestaticapps.net` | CNAME validation, no TXT |
| `go` (any subdomain) | CNAME | `<defaultHostname>.azurestaticapps.net` | same |
| `@` (apex) | ALIAS / ANAME / flattened CNAME | `<defaultHostname>.azurestaticapps.net` | preferred |
| `@` (apex, fallback) | A | `<IP from nslookup <defaultHostname>>` | document the IP; can go stale |
| `@` (apex, during validation) | TXT | `<dns-txt-token from az rest>` | remove after `Ready` if desired |

## Subdomain binding with retry

```bash
until az staticwebapp hostname set -n <site> -g <rg> --hostname www.<domain> 2>/dev/null; do
  echo "CNAME not yet visible to Azure — retrying in 3 min"; sleep 180     # old-record TTL can mask for hours
done
az staticwebapp hostname list -n <site> -g <rg> -o table                     # trust this, not the exit code
```

## Apex TXT validation

```bash
az rest --method put \
  --uri "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/staticSites/<site>/customDomains/<domain>?api-version=2022-09-01" \
  --body '{"properties":{"validationMethod":"dns-txt-token"}}'
# add the returned validationToken as TXT at @, then:
az staticwebapp hostname set -n <site> -g <rg> --hostname <domain>
```

## Default-domain ARM PUT (apex → www canonicalisation)

`PATCH` returns Method Not Allowed; `PUT` with `cname-delegation` adopts the already-`Ready` www domain in place.

```bash
az rest --method PUT \
  --url "https://management.azure.com/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/staticSites/<site>/customDomains/www.<domain>?api-version=2024-04-01" \
  --body '{"properties": {"isDefault": true, "validationMethod": "cname-delegation"}}'
curl -sI "http://<domain>/x?y=1" | grep -i location      # → https://www.<domain>/x?y=1 (301)
```

## Proving TLS

```bash
az staticwebapp hostname show -n <site> -g <rg> --hostname www.<domain> --query "{status:status,ssl:sslState}"
curl -sI https://www.<domain> | head -1
openssl s_client -servername www.<domain> -connect www.<domain>:443 </dev/null 2>/dev/null | openssl x509 -noout -subject
# Ready + sslState null + "internal error" alert → delete and re-add the hostname, allow ~15 min
```

## Wedged-hostname diagnostics

```bash
az monitor activity-log list --resource-group <rg> --offset 24h --query "[?contains(resourceId,'customDomains')].{op:operationName.value,status:status.value,corr:correlationId,t:eventTimestamp}" -o table
```

Escape route: serve the hostname from a different Azure service (e.g. Azure Container Apps running a Caddy redirect/static container — see `branded-link-qr-service` *ACA escape hatch*).
