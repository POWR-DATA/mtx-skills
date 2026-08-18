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
| Apex domain | `example.com.au` (bound next via Azure SWA Custom Domains) |

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
    }
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

## GitHub Actions workflow — `.github/workflows/deploy.yml`

```yaml
name: Deploy site
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_SWA_TOKEN }}
          action: upload
          app_location: "/"
          api_location: ""
          output_location: "/"
```

Token: `$t = (az staticwebapp secrets list -n stapp-example-prod -g rg-example-prod | ConvertFrom-Json).properties.apiKey.Trim(); gh secret set AZURE_SWA_TOKEN --body $t` — not piped.

---

## Hand-off notes

- **Custom domains / DNS / TLS** → *Azure SWA Custom Domains*: `www` CNAME → `<swa-default-hostname>.azurestaticapps.net`; apex A record (VentraIP has no ALIAS) + `dns-txt-token` validation; make `www` the default domain for the apex redirect; prove TLS.
- **Routes / caching / CSP** → *Static Website Config and CSP*: per-asset cache tiers, hidden-file 404 routes, CSP Report-Only → enforce.

---

## Post-deployment checklist

- [ ] Bicep deployed successfully, SWA resource exists in `rg-example-prod`
- [ ] GitHub Actions workflow running on push to `main`
- [ ] Site returns 200 on `https://<swa-default-hostname>.azurestaticapps.net/`
- [ ] `sitemap.xml` reachable and returns `Content-Type: application/xml`
- [ ] `robots.txt` reachable at `/robots.txt`
- [ ] Security headers present on CSS/JS/image responses too (set via `globalHeaders`)
- [ ] `AZURE_SWA_TOKEN` secret set via `--body`; no token in any file
- [ ] Hand-off items queued: custom domains (Azure SWA Custom Domains), routes/CSP (Static Website Config and CSP)
