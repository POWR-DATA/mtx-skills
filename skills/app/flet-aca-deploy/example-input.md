# Example Input

## User request

> The Flet web Docker image is building and pushing to GHCR successfully via GitHub Actions. I need to deploy it to Azure Container Apps. Set everything up from scratch — resource group, container app environment, the container app itself, and the GitHub Actions deploy job. The app is called `myapp`, the repo is `myorg/myapp`, and I want to deploy to `australiaeast`. Generate `infra/setup-azure.sh` and the deploy job to add to `build-web.yml`.

## Current state

- `build-web.yml` is already building and pushing `ghcr.io/myorg/myapp:latest` to GHCR
- The GHCR package is currently private
- No Azure resources exist yet
- Azure CLI and GitHub CLI are both installed and authenticated locally

## Requirements

- App should be available at a public HTTPS URL
- Minimum 1 replica (WebSocket requirement)
- No Log Analytics workspace needed
- `AZURE_CREDENTIALS` secret should be set automatically by the setup script
