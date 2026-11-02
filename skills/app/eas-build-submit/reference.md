# EAS Build and Submit — Reference Excerpts

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Production OTA publish

`app.config.js` picks the variant from `APP_VARIANT` in the publishing shell, and EAS environment variables load only with `--environment` — set both, every time.

```powershell
if (git status --porcelain) { throw 'Working tree is dirty — commit first' }
try {
  $env:APP_VARIANT = 'production'
  npx eas update --channel production --environment production --message "<message>"
} finally { Remove-Item Env:APP_VARIANT -ErrorAction SilentlyContinue }
# then fetch the published manifest and assert extra.appEnv, scheme and backend URL
```

### Manifest read-back

Ask the update server for what a production phone would receive, once per platform. No dashboard view shows these values.

```bash
curl -s "https://u.expo.dev/<eas-project-id>" \
  -H "expo-protocol-version: 1" \
  -H "expo-platform: ios" \
  -H "expo-runtime-version: <runtime-version>" \
  -H "expo-channel-name: production" \
  -H "accept: multipart/mixed"
# Multipart response: the manifest part's JSON carries the resolved app config (extra.expoClient).
# Assert name, scheme, extra.appEnv, bundle id / package and backend URL are the production values.
```

## Gated production OTA workflow

```yaml
on:
  workflow_dispatch:            # not push: release/** — a push must not deploy to production
jobs:
  publish:
    runs-on: ubuntu-latest
    environment: production     # required reviewers configured on this GitHub environment
    steps:
      # ... checkout, Node, expo/expo-github-action with EXPO_TOKEN
      - run: <publish-ota-wrapper> -Channel production   # the preview workflow calls the same wrapper
        shell: pwsh
```
