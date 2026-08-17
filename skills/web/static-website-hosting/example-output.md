# Example Output

*This output was generated using the Static Website Hosting skill applied to the example input in `example-input.md`.*

---

## Resource naming summary

| Item | Value |
|---|---|
| Resource group | `rg-example-prod` |
| SWA resource name | `stapp-example-prod` |
| Region | `australiaeast` |
| SWA default hostname | `<assigned after deploy>.azurestaticapps.net` |
| Primary domain | `www.example.com.au` |
| Apex domain | `example.com.au` (redirects to www automatically) |

---

## `infra/main.bicep`

```bicep
param siteName string
param location string = resourceGroup().location
param skuName string = 'Free'

// Token-deployed SWA: no repositoryUrl / provider / branch — the GitHub Actions
// workflow's deploy token feeds the site. Custom domains are added post-deploy via CLI.
resource swa 'Microsoft.Web/staticSites@2022-09-01' = {
  name: siteName
  location: location
  sku: {
    name: skuName
    tier: skuName
  }
  properties: {}
}

output defaultHostname string = swa.properties.defaultHostname
output siteName string = swa.name
output resourceGroupName string = resourceGroup().name
```

---

## `infra/parameters/prod.parameters.json`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "siteName":        { "value": "stapp-example-prod" },
    "location":        { "value": "australiaeast" },
    "skuName":         { "value": "Free" }
  }
}
```

---

## `staticwebapp.config.json`

```json
{
  "routes": [
    {
      "route": "/sitemap.xml",
      "headers": {
        "Content-Type": "application/xml"
      }
    },
    { "route": "/infra/*",   "statusCode": 404 },
    { "route": "/scripts/*", "statusCode": 404 },
    { "route": "/.github/*", "statusCode": 404 },
    { "route": "/README.md", "statusCode": 404 }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html",
      "statusCode": 404
    }
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "SAMEORIGIN",
    "Referrer-Policy": "same-origin",
    "Cache-Control": "public, must-revalidate, max-age=30"
  },
  "mimeTypes": {
    ".json": "application/json",
    ".xml": "application/xml"
  }
}
```

---

## DNS records

| Hostname | Type | Value | TTL |
|---|---|---|---|
| `www` | CNAME | `<swa-default-hostname>.azurestaticapps.net` | 3600 |
| `@` (apex) | A | `<IP from nslookup of SWA hostname>` | 3600 |

> Obtain the A record IP after deploying: `nslookup <swa-default-hostname>.azurestaticapps.net 8.8.8.8`
> Document this IP — re-verify it if the site ever stops resolving at the apex.

---

## Custom domain CLI commands

```bash
# Add www domain (after CNAME propagates)
az staticwebapp hostname set \
  --name stapp-example-prod \
  --resource-group rg-example-prod \
  --hostname "www.example.com.au"

# Get TXT validation token for apex domain
az rest --method put \
  --uri "https://management.azure.com/subscriptions/<sub-id>/resourceGroups/rg-example-prod/providers/Microsoft.Web/staticSites/stapp-example-prod/customDomains/example.com.au?api-version=2022-09-01" \
  --body '{"properties":{"validationMethod":"dns-txt-token"}}'
# Add the returned dns-txt-token value as a TXT record at @ in VentraIP, then:
az staticwebapp hostname set \
  --name stapp-example-prod \
  --resource-group rg-example-prod \
  --hostname "example.com.au"

# Check status
az staticwebapp hostname list \
  --name stapp-example-prod \
  --resource-group rg-example-prod \
  --output table
```

---

## Post-deployment checklist

- [ ] Bicep deployed successfully, SWA resource exists in `rg-example-prod`
- [ ] GitHub Actions workflow running on push to `main`
- [ ] CNAME `www` → SWA hostname propagated (`nslookup www.example.com.au 8.8.8.8`)
- [ ] A record apex → SWA IP propagated (`nslookup example.com.au 8.8.8.8`)
- [ ] Both domains showing `Ready` in `az staticwebapp hostname list`
- [ ] HTTPS working: `https://www.example.com.au` returns 200
- [ ] Apex redirects to www: `http://example.com.au` → `https://www.example.com.au`
- [ ] `sitemap.xml` reachable and returns `Content-Type: application/xml`
- [ ] `robots.txt` reachable at `/robots.txt`
- [ ] Security headers present in response (on CSS/JS/image responses too — set via `globalHeaders`)
- [ ] Internal files return 404 on the live site: `curl -sI https://www.example.com.au/README.md` → `404`, body not served
