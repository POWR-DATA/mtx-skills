# Example Output — Flet Store Submission

## Signing setup summary

**Android:**
- Keystore alias: `upload`
- Required GitHub Secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`
- Workflow change: add decode + signing env vars to `build-android.yml`

**iOS:**
- The AltStore crash is expected — Flet's Python runtime requires Apple Developer entitlements. AltStore cannot provide these. Use TestFlight once the Apple Developer account is active.
- Required GitHub Secrets (after enrollment): `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILE_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`

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
      - name: Generate keystore
        run: |
          keytool -genkey -v \
            -keystore upload-keystore.jks \
            -keyalg RSA -keysize 2048 -validity 10000 \
            -alias upload \
            -dname "CN=POWRDATA PTY LTD, O=POWRDATA PTY LTD, L=Sydney, ST=NSW, C=AU" \
            -storepass "${{ secrets.ANDROID_STORE_PASSWORD }}" \
            -keypass "${{ secrets.ANDROID_KEY_PASSWORD }}"
      - name: Output base64-encoded keystore
        run: |
          echo "==== COPY EVERYTHING BETWEEN THE MARKERS ===="
          base64 -w 0 upload-keystore.jks
          echo "==== END OF KEYSTORE ===="
```

Run via `workflow_dispatch`. Copy the base64 output → add as `ANDROID_KEYSTORE_BASE64` secret. **Delete this workflow file immediately after use.** Store base64, passwords, and alias in your password manager — this keystore cannot be recovered.

---

## Step 2 — Updated build-android.yml (signed build)

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > upload-keystore.jks

- name: Build signed APK
  run: flet build apk --verbose
  env:
    ANDROID_KEYSTORE_PATH: ${{ github.workspace }}/upload-keystore.jks
    ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
    ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
    ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}

- name: Build signed AAB (manual trigger only)
  if: github.event_name == 'workflow_dispatch'
  run: flet build aab --verbose
  env:
    ANDROID_KEYSTORE_PATH: ${{ github.workspace }}/upload-keystore.jks
    ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_STORE_PASSWORD }}
    ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
    ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
```

Add `ANDROID_KEY_ALIAS` secret with value `upload`.

---

## Store account checklist

### Google Play ($25 USD one-off)

- [ ] Create account at play.google.com/console
- [ ] Register as Organisation — requires D-U-N-S number and company email domain
- [ ] Verify D-U-N-S at dnb.com (free lookup) — allow 2–3 business days for Google verification
- [ ] Trigger `Build Android` workflow via `workflow_dispatch` to produce signed AAB
- [ ] Upload AAB (not APK) to Google Play Console

### Apple Developer Program ($99 USD/year)

- [ ] Enrol at developer.apple.com/programs/enroll as Organisation
- [ ] Obtain D-U-N-S number (free lookup at developer.apple.com)
- [ ] Apple verifies director authority via ASIC — allow 2–5 business days
- [ ] Once enrolled: add iOS signing secrets to GitHub
- [ ] Build and distribute via TestFlight first to confirm the app runs on device
- [ ] Submit to App Store review after TestFlight confirms success

---

## App listing draft — TrackMyPlants

### Google Play description

**Hook (visible before "more"):**
> Track your plants, never miss a watering. TrackMyPlants logs your collection and reminds you when each plant needs attention.

**Full description:**
- Log your entire plant collection with species, watering schedule, and last-watered date
- Get reminders when plants are due for watering
- Works on Android and web — data syncs automatically via your account
- No ads, no tracking

### App Store keywords (100 chars max)
`plants,garden,watering,plant tracker,houseplants,gardening,reminder,care`

### Screenshots
Run the app in Chrome DevTools → set device to iPhone 14 Pro Max (390×844 viewport) → capture key screens → resize to 1290×2796px using Snagit or similar. Minimum 3 screenshots required.

Required screens: login, plant list, plant detail, add plant form.

---

## Submission checklist

- [ ] Keystore stored in password manager (base64, store password, key password, alias)
- [ ] Generate-keystore workflow deleted from repo
- [ ] AAB builds successfully with signing env vars
- [ ] Google Play account active and verified
- [ ] Apple Developer account active and verified
- [ ] TestFlight install confirmed working on physical iOS device
- [ ] Privacy policy URL live: `https://www.example.com/privacy`
- [ ] Screenshots at 1290×2796px prepared for App Store
- [ ] Age rating questionnaire completed on both platforms
- [ ] App listing content drafted and ready to paste in
