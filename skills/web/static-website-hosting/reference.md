# Static Website Hosting — Reference Templates

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Subfolder SWA workflow

A second, independent SWA deployed from a subfolder of the same repo. Own workflow, own deploy-token secret, `paths:` filter so the main site never redeploys on a subfolder change, and a repository **variable** gate so the job stays skipped (green) until the SWA is provisioned.

```yaml
name: Deploy <subsite>
on:
  push:
    branches: [main]
    paths: ['<subfolder>/**']

jobs:
  deploy:
    if: vars.DEPLOY_<SUBSITE> == 'true'      # repository variable — secrets are NOT available in if:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_SWA_TOKEN_<SUBSITE> }}   # its own token, never the main site's
          action: upload
          app_location: '<subfolder>'
          skip_app_build: true
```

## Token-deployed Bicep

No repository properties — the workflow's deploy token feeds the site. The subdomain `customDomains` child is gated behind a bool because it fails validation until the CNAME exists (binding itself is covered by `azure-swa-custom-domains`).

```bicep
param siteName string
param location string = resourceGroup().location
param deployCustomDomain bool = false      // flip to true only after the CNAME resolves
param customDomain string = ''

resource swa 'Microsoft.Web/staticSites@2022-09-01' = {
  name: siteName
  location: location
  sku: { name: 'Free', tier: 'Free' }
  properties: {}                           // no repositoryUrl / provider / branch
}

resource domain 'Microsoft.Web/staticSites/customDomains@2022-09-01' = if (deployCustomDomain) {
  parent: swa
  name: customDomain
}
```

## Deployment token into GitHub Secrets (PowerShell)

```powershell
$t = (az staticwebapp secrets list -n <site> -g <rg> | ConvertFrom-Json).properties.apiKey.Trim()
gh secret set AZURE_SWA_TOKEN --body $t          # never pipe az output straight into gh secret set — it corrupted the token
```

## Baseline `staticwebapp.config.json`

```json
{
  "routes": [ { "route": "/sitemap.xml", "headers": { "Content-Type": "application/xml" } } ],
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff", "X-Frame-Options": "SAMEORIGIN", "Referrer-Policy": "same-origin",
    "Cache-Control": "public, must-revalidate, max-age=30"
  },
  "mimeTypes": { ".json": "application/json", ".xml": "application/xml" }
}
```

Hidden-file routes, cache tiers, redirects and CSP: see `static-website-config-and-csp`.
