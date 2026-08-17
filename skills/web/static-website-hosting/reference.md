# Static Website Hosting — Reference Templates

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Hiding internal files

Azure SWA serves everything under `app_location`. Route wildcards match only at the **end** of a route, so block directories with `/dir/*` and list each root-level internal file explicitly. A `statusCode: 404` route with no `rewrite`/`redirect` returns 404 and never serves the file body. Place these before the `/*` catch-all.

```json
"routes": [
  { "route": "/docs/*",        "statusCode": 404 },
  { "route": "/infra/*",       "statusCode": 404 },
  { "route": "/scripts/*",     "statusCode": 404 },
  { "route": "/.github/*",     "statusCode": 404 },
  { "route": "/OPERATIONS.md", "statusCode": 404 },
  { "route": "/.gitignore",    "statusCode": 404 }
]
```

Verify after deploy: `curl -sI https://<host>/OPERATIONS.md` → `404`, and the body is not the file.

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

No repository properties — the workflow's deploy token feeds the site. The subdomain `customDomains` child is gated behind a bool because it fails validation until the CNAME exists.

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

## Subdomain custom domain (CNAME validation)

```text
<sub>   CNAME   <defaultHostname>.azurestaticapps.net
```

```bash
az staticwebapp hostname set  -n <site> -g <rg> --hostname <sub>.<domain>   # or redeploy Bicep with deployCustomDomain=true
az staticwebapp hostname show -n <site> -g <rg> --hostname <sub>.<domain> --query status   # "Ready" = validated + managed TLS cert issued
```

## Extra MIME types

```json
"mimeTypes": {
  ".json": "application/json",
  ".xml":  "application/xml",
  ".vcf":  "text/vcard"
}
```
