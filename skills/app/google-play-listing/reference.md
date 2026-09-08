# Google Play Listing — Reference Templates

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Generate-keystore workflow (one-time, delete after use)

```yaml
# .github/workflows/generate-keystore.yml (delete after use)
name: Generate Android Keystore
on:
  workflow_dispatch:
jobs:
  generate-keystore:
 runs-on: ubuntu-latest
 steps:
- uses: actions/setup-java@v4
  with:
 distribution: temurin
 java-version: "17"
- name: Generate and encode keystore
  run: |
 keytool -genkey -v -keystore release.keystore \
-alias upload -keyalg RSA -keysize 2048 -validity 10000 \
-storepass "${{ secrets.ANDROID_STORE_PASSWORD }}" \
-keypass "${{ secrets.ANDROID_KEY_PASSWORD }}" \
-dname "CN=<AppName>, OU=Mobile, O=<OrgName>, L=<City>, S=<State>, C=<CountryCode>"
 echo "==== COPY THIS ===="
 base64 -w 0 release.keystore
 echo "==== END ===="
```

Copy the base64 output → `ANDROID_KEYSTORE_BASE64` secret; add `ANDROID_KEY_ALIAS`. Store all four secrets in a password manager before closing the tab. Delete the workflow file after use.

## Signed-build step

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > release.keystore
- name: Build signed AAB
  if: github.event_name == 'workflow_dispatch'
  run: <your-build-command> appbundle
  env:
 ANDROID_KEYSTORE_PATH: ${{ github.workspace }}/release.keystore
 ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
 ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
 ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
```

## Upload-to-Play step

```yaml
- name: Upload to Google Play
  uses: r0adkll/upload-google-play@v1
  with:
 serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
 packageName: com.yourorg.yourapp
 releaseFiles: build/<your-app>.aab
 track: internal
 status: completed
```

`track`: `internal` / `alpha` / `beta` / `production`. `status: completed` goes live immediately; `status: draft` needs manual promotion. Requires a `whatsNewDirectory` with at least one locale file (e.g. `whatsnew/whatsnew-en-AU`).

## Screenshot capture (Chrome DevTools)

| Target | CSS device | DPR | Output |
|---|---|---|---|
| Phone 9:16 (phone density) | 360×640 | 3 | 1080×1920 |
| Phone 9:16 (alternative) | 432×768 | 2.5 | 1080×1920 |

Avoid 540×960@2 — same output size but airy, tablet-like density. Ctrl+Shift+P → "Capture screenshot" exports at physical resolution.
