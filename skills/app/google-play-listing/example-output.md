# Example Output — Google Play Listing

## Signing setup summary

- Keystore alias: `upload`
- Required GitHub Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`
- Workflow change: add keystore decode and signing env vars to the AAB build step

---

## Step 1 — Generate the Android keystore

Add `ANDROID_STORE_PASSWORD` and `ANDROID_KEY_PASSWORD` as GitHub Secrets first, then create `.github/workflows/generate-keystore.yml`:

```yaml
name: Generate Android Keystore (one-time setup)
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
            -dname "CN=<AppName>, OU=Mobile, O=<OrgName>, L=<City>, S=<State>, C=AU"
          echo "==== COPY THIS ===="
          base64 -w 0 release.keystore
          echo "==== END ===="
```

Run via `workflow_dispatch`. Copy the base64 output → add as `ANDROID_KEYSTORE_BASE64` secret. Add `ANDROID_KEY_ALIAS` with value `upload`. **Delete this workflow file immediately after use.** Store all four secret values in a password manager — this keystore cannot be recovered if lost.

---

## Step 2 — Updated AAB build step (signed)

Add to the existing `workflow_dispatch`-gated AAB build:

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

---

## Play Console checklist

### Account setup ($25 USD one-off)

- [ ] Create account at play.google.com/console
- [ ] Register as Organisation — no D-U-N-S number required (Google does not require it, unlike Apple)
- [ ] Use your trading name exactly as it should appear to customers in the "developer name" field
- [ ] Trigger the signed AAB build via `workflow_dispatch`
- [ ] Upload signed AAB to Play Console → Internal testing

### Store listing

- [ ] **App name** (50 chars max): `TrackMyPlants`
- [ ] **Short description** (80 chars max): `Track your plants, never miss a watering.`
- [ ] **Full description** (4,000 chars max): drafted below
- [ ] **App icon**: 512×512 PNG, max 1 MB
- [ ] **Feature graphic**: 1024×500 PNG or JPEG — required even if not being promoted
- [ ] **Screenshots**: minimum 2 phone screenshots

**Full description draft:**

```
Track your plants, never miss a watering. TrackMyPlants logs your collection
and reminds you when each plant needs attention.

- Log your entire plant collection with species, watering schedule, and last-watered date
- Get reminders when plants are due for watering
- Works on Android — data syncs automatically via your account
- No ads, no tracking
```

### App Content declarations

- [ ] **Privacy policy**: `https://www.example.com/privacy` (public URL confirmed live)
- [ ] **Ads**: No ads
- [ ] **App access**: Restricted — provide reviewer credentials (see below)
- [ ] **Content ratings**: complete IARC questionnaire — category: Lifestyle, no violence/sexual content/controlled substances
- [ ] **Target audience**: 18+
- [ ] **Data safety**: Email address (required, account management), Name (optional), User IDs (required). Shared with third parties: None. Encrypted in transit: Yes. Include data deletion URL.

### Reviewer credentials

Create a shared mailbox `app_reviewer@yourdomain.com` and a dedicated app account using that email. Enter credentials in **App access → Restricted access → Manage instructions**.

### Internal Testing

- [ ] Go to **Testing → Internal testing**, create a release, upload the signed AAB
- [ ] Under **Testers** tab, add tester email addresses (must be Google accounts)
- [ ] Copy the opt-in URL and share with testers — they must open it on their Android device
- [ ] Promote release — goes live to testers immediately, no review process

---

## CI automation config

```yaml
- name: Upload to Google Play
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}
    packageName: com.myorg.trackmyplants
    releaseFiles: build/<your-app>.aab
    track: internal
    status: completed
```

Setup: Play Console → **Setup → API access** → create service account with "Release manager" role → download JSON → add as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret → grant service account access in Play Console under Users and permissions.
