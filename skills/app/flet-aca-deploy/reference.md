# Flet ACA Deploy — Reference Templates

Load-on-demand commands and templates for the steps in [`SKILL.md`](SKILL.md). Illustrative excerpts — load-bearing lines only. Replace `<app>`, `<rg>`, `<owner>/<repo>` placeholders.

---

## main.py web mode + Dockerfile

`ft.AppView.WEB_BROWSER` starts the Flet HTTP + WebSocket server headless. `web_renderer` valid values in 0.84: `AUTO`, `CANVAS_KIT`, `SKWASM` (`"html"` was removed — raises `ValueError`).

```python
# main.py
if __name__ == "__main__":
    import os
    host = os.environ.get("FLET_HOST", "localhost")   # localhost local, 0.0.0.0 in container
    ft.run(main, host=host, port=8550,
           view=ft.AppView.WEB_BROWSER, web_renderer=ft.WebRenderer.CANVAS_KIT)
```

```dockerfile
ENV FLET_HOST=0.0.0.0
CMD ["python", "main.py"]
```

## flet_web asset patch (Dockerfile RUN)

Overwrites favicon, PWA icons, and loading animation, and patches the splash CSS scale — all after `COPY . .`. Requires `flet-web` in `requirements.txt` (it auto-installs at runtime but not at build time).

```dockerfile
RUN python -c "\
import flet_web, os, shutil; \
web = os.path.join(os.path.dirname(flet_web.__file__), 'web'); \
shutil.copy('assets/favicon.png', os.path.join(web, 'favicon.png')); \
# ... copy PWA icons (icon-192/512, maskable, apple-touch) into web/icons/; \
shutil.copy('assets/logo_512.png', os.path.join(web, 'icons', 'loading-animation.png')); \
idx = os.path.join(web, 'index.html'); \
open(idx,'w').write(open(idx).read().replace('scale(0.4)','scale(0.8)').replace('scale(0.35)','scale(0.75)')) \
"
```

> `loading-animation.png` lives in `web/icons/`, not the web root. The `scale()` values appear twice (portrait + landscape) — patch both. Flet does **not** serve `/favicon.png` from the project root, so the in-package copy must be overwritten.

## ACA ingress — force HTTP/1.1

ACA defaults to `transport: Auto`, which may negotiate HTTP/2 (no WebSocket upgrade) → "stream timeout" in the browser.

```bash
az containerapp ingress update --name <app> --resource-group <rg> --transport http
```

## GHCR auth — make the package public

Every private-pull approach fails, so publish the image (a compiled artefact — the source repo stays private):

| Approach | Why it fails |
|---|---|
| Classic PAT with `write:packages` | manifest pulls return 404 for private packages |
| `GITHUB_TOKEN` in deploy job | expires before ACA's async pull → `ImagePullBackOff` |
| `az containerapp registry set` | stored creds persist even after going public → stale creds block pulls |

```
GitHub → Packages → <package> → Package settings → Change visibility → Public
```

```bash
az containerapp registry remove --name <app> --resource-group <rg> --server ghcr.io   # clear stale creds
```

## ACA provisioning

```bash
az provider register -n Microsoft.App --wait --output none
az provider register -n Microsoft.OperationalInsights --wait --output none
# env: use --logs-destination none to skip Log Analytics
# create: bootstrap with the helloworld placeholder image, --target-port 8550, --min-replicas 1
# --sdk-auth is deprecated (CLI 2.37+) — build the credentials JSON manually
# prefix az calls passing /subscriptions/... in Git bash with MSYS_NO_PATHCONV=1
```

## Forcing a new revision

`az containerapp update --image ...:latest` may reuse a revision if the tag is unchanged — force one with a unique suffix:

```bash
az containerapp update --name <app> --resource-group <rg> \
  --image ghcr.io/<owner>/<repo-lowercase>:latest \
  --revision-suffix r${{ github.run_number }} --output none
```

## Diagnosing revision failures

```bash
az containerapp revision show --name <app> --resource-group <rg> --revision <name> \
  --query "properties.runningStateDetails" -o tsv
az containerapp logs show --name <app> --resource-group <rg> --revision <name> --tail 50
```

| `runningStateDetails` | Meaning | Fix |
|---|---|---|
| `Pending:ImagePullBackOff` | image cannot be pulled | fix registry auth / make package public |
| `Container crashing` | image pulled, app crashes on startup | check container logs |

## Deploy job (GitHub Actions)

`az containerapp update` directly — simpler than the deploy action and supports `--revision-suffix`. Image ref must be lowercase; package must be public (no auth fields).

```yaml
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with: { creds: ${{ secrets.AZURE_CREDENTIALS }} }
      - run: |
          az containerapp update \
            --name <appname> --resource-group rg-<appname> \
            --image ghcr.io/<owner>/<repo-lowercase>:latest \
            --revision-suffix r${{ github.run_number }} --output none
```

## infra/setup-azure.sh

Provisions everything reproducibly and writes the `AZURE_CREDENTIALS` secret.

```bash
#!/usr/bin/env bash
set -e
RG="rg-<appname>"; LOCATION="australiaeast"; APP="<appname>"; REPO="<owner>/<repo>"

az provider register -n Microsoft.App --wait --output none
az provider register -n Microsoft.OperationalInsights --wait --output none
az group create --name "$RG" --location "$LOCATION" --output none
az containerapp env create --name "${APP}-env" --resource-group "$RG" \
  --location "$LOCATION" --logs-destination none --output none
az containerapp create --name "$APP" --resource-group "$RG" --environment "${APP}-env" \
  --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
  --target-port 8550 --ingress external --min-replicas 1 --max-replicas 2 \
  --cpu 0.5 --memory 1.0Gi --output none
az containerapp ingress update --name "$APP" --resource-group "$RG" --transport http --output none
# no registry credentials — GHCR package is public

SUB=$(az account show --query id -o tsv)
SP=$(MSYS_NO_PATHCONV=1 az ad sp create-for-rbac --name "sp-${APP}-github" \
  --role Contributor --scopes "/subscriptions/${SUB}/resourceGroups/${RG}" --output json)
# ... extract appId/password/tenant from $SP, assemble the SP JSON, then:
echo "$SP_JSON" | gh secret set AZURE_CREDENTIALS --repo "$REPO"
```
