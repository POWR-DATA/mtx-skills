---
name: flet-aca-deploy
description: Deploy a Flet web app to Azure Container Apps — covers all pitfalls: container startup, WebSocket transport, GHCR auth, ACA provisioning, revision forcing, and health diagnosis
author: POWR-DATA
version: 2.1.0
license: MIT
---

# Flet ACA Deploy

## Purpose

Deploy a Flet web app to Azure Container Apps (ACA) and stand up its CI/CD deploy job — covering the container-startup, WebSocket-transport, GHCR-auth, provisioning, and revision-forcing pitfalls that otherwise leave the container running but the Flet UI unable to connect. Use alongside `flet-multiplatform-build`, which builds and publishes the Docker image.

## When to use

After the Flet web Docker image is building and pushing to GHCR successfully (see `flet-multiplatform-build`). Apply when:

- Deploying the web app to Azure Container Apps for the first time
- An existing ACA deployment is broken — WebSocket timeout, `ImagePullBackOff`, or container crash on startup
- Setting up the CI/CD deploy job
- Debugging a container that starts but whose Flet UI never connects

## Inputs expected

- Working Dockerfile with `python main.py` as CMD and `FLET_HOST=0.0.0.0`
- GitHub repository with GHCR image publishing configured (`build-web.yml` from `flet-multiplatform-build`)
- Azure subscription (free tier is sufficient for initial deployment)
- Preferred Azure region (e.g. `australiaeast`)
- App name — used for resource group, container app, and service principal naming

---

## Guiding principles

- **Run `python main.py`, never `flet run --web`, in the container.** Even in web mode the `flet` CLI imports `flet_desktop`, which needs native GUI libs absent from `python:3.12-slim` — the container crashes with `ModuleNotFoundError: No module named 'flet_desktop'`. Configure web mode in code with `ft.run()` (not the deprecated `ft.app()`) and a `FLET_HOST` env var so the bind address differs between local (`localhost`) and container (`0.0.0.0`).
- **`flet-web` must be pinned in `requirements.txt`.** It auto-installs at runtime but not at build time, so Dockerfile `RUN python -c "import flet_web …"` asset steps fail with `ModuleNotFoundError` without it. Pin the same version as `flet`.
- **Overwrite branding assets inside the `flet_web` package, not the project root.** Flet does not serve `/favicon.png` from the project root; the real defaults live in `flet_web/web/` (favicon) and `flet_web/web/icons/` (PWA icons, `loading-animation.png`). Patch them in one Dockerfile `RUN` step, and patch the `scale()` CSS in `index.html` (it appears twice — portrait and landscape).
- **Force ACA ingress to HTTP/1.1.** The default `transport: Auto` may negotiate HTTP/2, which has no WebSocket upgrade — the Flutter client loads but the WebSocket never connects ("stream timeout"). Set `--transport http` immediately after container creation.
- **Make the GHCR package public — every private-pull approach fails.** Classic PATs 404 on private manifests, `GITHUB_TOKEN` expires before ACA's async pull (`ImagePullBackOff`), and stored registry creds persist even after going public. The image is a compiled artefact; the source repo stays private. Remove any previously stored ACA registry credentials.
- **Set ACA min replicas to 1.** With 0, the first browser request arrives before the container is ready and the WebSocket cold-starts into a timeout.
- **Bootstrap, then deploy.** Create the app with the helloworld placeholder image at `--target-port 8550`, then let CI deploy the real image — the deploy step updates the image, not the port.
- **Force a new revision on every deploy.** `az containerapp update --image ...:latest` may reuse a revision if the tag is unchanged; add `--revision-suffix r${{ github.run_number }}`. Use `az containerapp update` directly rather than `container-apps-deploy-action@v2`, which does not support revision suffixes.
- **`az containerapp create --yaml <file>` still requires `-n` and `-g` on the command line** even though the YAML carries name and resource group; without them the extension prints usage and exits 2.
- **A custom domain with a managed certificate can bind but stay `bindingType: Disabled`.** `az containerapp hostname bind` with a managed certificate can leave the binding Disabled after the certificate has issued (TLS still not serving 30 minutes later despite the "up to 20 minutes" note). Fix: confirm `az containerapp env certificate list --managed-certificates-only` shows the cert `Succeeded`, then re-run `hostname bind ... --certificate <managed-cert-name>`; `bindingType` flips to `SniEnabled` and TLS serves within minutes. Working order overall: publish CNAME plus `asuid.<host>` TXT, verify both via DoH and soak about 15 minutes, `hostname add`, `hostname bind`, poll the cert, re-bind with the cert name, then prove with `openssl s_client -servername <host>` showing `CN=<host>`. See *Custom domain* in `reference.md`.
- **Script all provisioning in `infra/setup-azure.sh`.** Register `Microsoft.App` and `Microsoft.OperationalInsights` before creating the environment; build the SP credentials JSON manually (`--sdk-auth` is deprecated in CLI 2.37+); prefix `az` calls passing `/subscriptions/...` paths in Git bash with `MSYS_NO_PATHCONV=1`.

---

## Process

Commands and templates for every step are in [`reference.md`](reference.md).

1. **Confirm container startup config** — `main.py` uses `ft.run()` with the `FLET_HOST` guard and `web_renderer=CANVAS_KIT`; Dockerfile sets `ENV FLET_HOST=0.0.0.0` and `CMD ["python","main.py"]`. See *main.py web mode + Dockerfile*.
2. **Verify branding assets** — `flet-web` pinned in `requirements.txt`; Dockerfile `RUN` step overwrites favicon, PWA icons, and `loading-animation.png`, and patches the splash CSS scale. See *flet_web asset patch*.
3. **Provision Azure** — register providers, create resource group, environment (`--logs-destination none`), and the container app from the placeholder image at port 8550 with min-replicas 1. See *ACA provisioning* / *infra/setup-azure.sh*.
4. **Force ingress to HTTP/1.1** — `az containerapp ingress update --transport http`. See *ACA ingress*.
5. **Make the GHCR package public** and remove any stored ACA registry credentials. See *GHCR auth*.
6. **Create the service principal** and store `AZURE_CREDENTIALS` as a GitHub secret. See *infra/setup-azure.sh*.
7. **Add the deploy job** — `az containerapp update` with a lowercase image ref and `--revision-suffix r${{ github.run_number }}`. See *Deploy job*.
8. **Diagnose failures** if needed — inspect `runningStateDetails` and container logs to tell `ImagePullBackOff` from a startup crash. See *Diagnosing revision failures*.
9. **Custom domain (optional)** — CNAME + `asuid.<host>` TXT, DoH-verify and soak ~15 min, `hostname add`, `hostname bind`, poll the managed cert, re-bind with `--certificate <name>` if `bindingType` stays `Disabled`, prove with `openssl s_client`. See *Custom domain*.

---

## Output format

Present the deployment as:

1. **Provisioning summary** — resource group, environment, container app, region, replica config
2. **Files / config produced** — `infra/setup-azure.sh`, the deploy job YAML, any `main.py`/Dockerfile corrections (templates from `reference.md`)
3. **Connectivity checks** — ingress transport `Http`, GHCR package public, min-replicas 1
4. **Deploy result** — revision created with a unique suffix, app reachable, WebSocket connects (UI loads)

---

## Quality checklist

- [ ] Dockerfile CMD is `python main.py`, not `flet run --web`
- [ ] `main.py` uses `ft.run()` with `FLET_HOST` and `web_renderer=ft.WebRenderer.CANVAS_KIT`
- [ ] Dockerfile sets `ENV FLET_HOST=0.0.0.0`
- [ ] `flet-web==<version>` in `requirements.txt` (matches `flet`)
- [ ] Dockerfile RUN step overwrites favicon, PWA icons, `icons/loading-animation.png`, and patches the `index.html` scale
- [ ] ACA ingress transport set to `Http` (scripted in `infra/setup-azure.sh`)
- [ ] ACA target port 8550, min replicas 1
- [ ] GHCR package public; no registry credentials stored in ACA
- [ ] Deploy job uses `az containerapp update` with `--revision-suffix r${{ github.run_number }}` and a lowercase image ref
- [ ] `infra/setup-azure.sh` provisions everything from scratch; `AZURE_CREDENTIALS` secret set
- [ ] Any `--yaml` create/update also passes `-n`/`-g`; custom-domain binding shows `bindingType: SniEnabled` and `openssl s_client` returns `CN=<host>`

---

## Avoid

- `flet run --web` as Dockerfile CMD — crashes in slim containers; use `python main.py`
- `ft.app()` (deprecated) or `web_renderer="html"` (removed, raises `ValueError`) — use `ft.run()` + `CANVAS_KIT`
- Hardcoding `host="0.0.0.0"` in `ft.run()` — breaks local dev; use the `FLET_HOST` env var
- Expecting `assets/favicon.png` to appear as the tab icon — overwrite `flet_web/web/favicon.png` in the Dockerfile
- Omitting `flet-web` from `requirements.txt` — build-time `import flet_web` steps fail
- Targeting `flet_web/web/loading-animation.png` — it is in `web/icons/`
- ACA ingress transport `Auto` — may break WebSocket; force `Http`
- Pulling a private GHCR package from ACA — PATs and `GITHUB_TOKEN` both fail; make it public
- Leaving stale registry credentials in ACA after going public — remove them
- `az containerapp update --image ...:latest` without `--revision-suffix` — may not create a new revision
- `container-apps-deploy-action@v2` for forced revisions — no `--revision-suffix` support
- Min replicas 0 — WebSocket cold-start breaks the UI
- `--sdk-auth` with `az ad sp create-for-rbac` — deprecated in CLI 2.37+
- Unix-style paths in `az` from Git bash without `MSYS_NO_PATHCONV=1`
- `az containerapp create --yaml` without `-n`/`-g` — prints usage and exits 2
- Assuming a managed cert that shows `Succeeded` is serving — check `bindingType`; re-bind with `--certificate` if it is `Disabled`

---

## Example usage

> "The Flet web Docker image is building and pushing to GHCR. Set up Azure Container Apps and the GitHub Actions deploy job — provision everything from scratch with the az CLI, force HTTP/1.1 ingress for the WebSocket, and store AZURE_CREDENTIALS automatically."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
