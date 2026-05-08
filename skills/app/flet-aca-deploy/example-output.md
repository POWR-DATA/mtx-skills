# Example Output

## Step 1 — Make the GHCR package public

Before provisioning, make the package public so ACA can pull it without credentials:

```
GitHub → Profile → Packages → myapp → Package settings → Change visibility → Public
```

Private packages cannot be reliably pulled by ACA — PATs expire during async image pulls and stored credentials cause `ImagePullBackOff` even after being revoked.

---

## Step 2 — infra/setup-azure.sh

```bash
#!/usr/bin/env bash
set -e
AZ="/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin/az"
GH="/c/Program Files/GitHub CLI/gh.exe"
RESOURCE_GROUP="rg-myapp"
LOCATION="australiaeast"
APP_NAME="myapp"
REPO="myorg/myapp"

"$AZ" provider register -n Microsoft.App --wait --output none
"$AZ" provider register -n Microsoft.OperationalInsights --wait --output none
"$AZ" group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
"$AZ" containerapp env create \
    --name "${APP_NAME}-env" --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" --logs-destination none --output none

"$AZ" containerapp create \
    --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" \
    --environment "${APP_NAME}-env" \
    --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
    --target-port 8550 --ingress external \
    --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1.0Gi \
    --output none

"$AZ" containerapp ingress update \
    --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" \
    --transport http --output none

SUBSCRIPTION_ID=$("$AZ" account show --query id -o tsv)
SP=$(MSYS_NO_PATHCONV=1 "$AZ" ad sp create-for-rbac \
    --name "sp-${APP_NAME}-github" --role Contributor \
    --scopes "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
    --output json 2>/dev/null)

CLIENT_ID=$(echo "$SP" | python3 -c "import sys,json; print(json.load(sys.stdin)['appId'])")
CLIENT_SECRET=$(echo "$SP" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
TENANT_ID=$(echo "$SP" | python3 -c "import sys,json; print(json.load(sys.stdin)['tenant'])")
SP_JSON=$(printf '{"clientId":"%s","clientSecret":"%s","subscriptionId":"%s","tenantId":"%s"}' \
    "$CLIENT_ID" "$CLIENT_SECRET" "$SUBSCRIPTION_ID" "$TENANT_ID")
echo "$SP_JSON" | "$GH" secret set AZURE_CREDENTIALS --repo "$REPO"
echo "Done. AZURE_CREDENTIALS set on $REPO."
```

Run once: `bash infra/setup-azure.sh`

---

## Step 3 — Deploy job to add to build-web.yml

Add this `deploy` job after `build-and-push`:

```yaml
  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Azure login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy to Azure Container Apps
        run: |
          az containerapp update \
            --name myapp \
            --resource-group rg-myapp \
            --image ghcr.io/myorg/myapp:latest \
            --revision-suffix r${{ github.run_number }} \
            --output none
```

---

## Notes

- The placeholder image (`containerapps-helloworld`) bootstraps the container app before CI deploys the real image. Without it, `containerapp create` requires a working image on port 8550 immediately.
- `--revision-suffix r${{ github.run_number }}` guarantees ACA creates a new revision on every push. Without it, ACA may reuse the previous revision if the image tag (`latest`) hasn't changed in its cache.
- Ingress transport is set to `http` (HTTP/1.1) — required for Flet's WebSocket connection. `Auto` may negotiate HTTP/2, which does not support WebSocket upgrades.
- Min replicas 1 prevents WebSocket cold-start failures on the first browser connection.

---

## Next recommended step

Push to `main` to trigger `build-web.yml`. Confirm the deploy job completes, then visit the ACA FQDN (shown in Azure Portal → Container App → Overview) to verify the Flet UI loads and the WebSocket connects.
