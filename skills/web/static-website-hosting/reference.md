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

## SWA CLI deploy from a workstation

For built output (Vite `dist`, Expo web export) deployed from a machine with no stored token. Build once in a fresh worktree; interrupted or overlapping exports left `dist` without its `public/` root files.

```powershell
'<root-file-1>', '<root-file-2>' | ForEach-Object {             # the public/ files the app needs at the site root
    if (-not (Test-Path "dist/$_")) { throw "dist is missing $_ - rebuild cleanly" }
}
$env:SWA_CLI_DEPLOYMENT_TOKEN = az staticwebapp secrets list --name <swa> --resource-group <rg> --query properties.apiKey -o tsv   # never printed
try { npx @azure/static-web-apps-cli deploy ./dist --env production }    # = swa deploy ./dist --env production
finally { Remove-Item Env:SWA_CLI_DEPLOYMENT_TOKEN -ErrorAction SilentlyContinue }
```

Then smoke-test the live site: key assets 200, no 4xx, main canvas/content painted. Run the same test once against a build without `public/` and confirm it fails.

## Publishing a held change

```powershell
# on the PR branch: final publish-prep commit — visible "Last updated" dates and sitemap <lastmod> = publish date
gh pr ready <n>
gh pr merge <n> --merge --delete-branch
$sha = (gh pr view <n> --json mergeCommit | ConvertFrom-Json).mergeCommit.oid
# poll rather than gh run watch (it once hung past ten minutes); repeat until status is completed
gh run list --limit 5 --json headSha,status,conclusion | ConvertFrom-Json | Where-Object headSha -eq $sha
# then, for each changed page, until the new strings appear:
curl.exe -s "https://<host>/<page>?cb=$(Get-Random)" | Select-String -SimpleMatch '<new string>'
```
