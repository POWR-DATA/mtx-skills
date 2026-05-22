---
name: flet-store-submission
description: Sign and submit a Flet app to the Google Play Store and Apple App Store — covers keystore generation, signing config, store accounts, and app listing preparation
author: POWR-DATA
version: 1.0.0
license: MIT
---

# Flet Store Submission

## Purpose

Guide the Android and iOS signing and app store submission process for a Flet app — from keystore generation through to a live listing — including signing configuration, store account setup, and app listing content preparation.

## When to use

After the app builds successfully via `flet-multiplatform-build`. Apply when preparing for a first store release or when setting up code signing for the first time. This skill picks up where the build pipeline ends.

## Inputs expected

- Working unsigned APK/AAB (Android) or unsigned IPA (iOS) from `flet-multiplatform-build`
- Google Play Developer account status (existing or to be created)
- Apple Developer Program enrollment status
- App name, bundle ID, version, and build number confirmed in `pyproject.toml`
- Privacy policy URL, support URL, and app description drafted

---

## Guiding principles

- **The Android upload keystore is permanent.** Once uploaded to Google Play, the keystore must be kept forever — losing it means creating a new Play Store listing. Store the base64 value, passwords, and alias in a password manager immediately after generation.
- **Required secrets for signed Android builds:** `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`. These must be in GitHub Secrets before the signed build workflow runs.
- **Upload a signed AAB, not APK, to Google Play.** Gate the AAB build on `workflow_dispatch` — it should only run when intentionally preparing a release, not on every push.
- **Use TestFlight before App Store submission.** TestFlight uses proper Apple signing and is the only reliable way to confirm Flet's Python runtime initialises on a physical device. AltStore and free Apple ID certificates do not provide the required entitlements.
- **Organisation enrollment takes time.** Both Google Play (D-U-N-S verification) and Apple Developer Program (ASIC/registry check) require 2–7 business day manual reviews for organisation accounts. Prepare listing content while waiting.
- **Before store submission, confirm `pyproject.toml [tool.flet.app]`** has `name`, `bundle_id`, `version`, and `build_number` all set. The build will fail without `bundle_id`.
- **Draft listing content before the developer account is approved** — it can be pasted in immediately once access is active.

## Process

### Android signing

1. Generate the upload keystore. If Java is not installed locally, use a one-time GitHub Actions workflow — add `ANDROID_STORE_PASSWORD` and `ANDROID_KEY_PASSWORD` as repo secrets first, then run:
   ```yaml
   # .github/workflows/generate-keystore.yml (delete after use)
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
               -dname "CN=YOUR COMPANY PTY LTD, O=YOUR COMPANY PTY LTD, L=City, ST=State, C=AU" \
               -storepass "${{ secrets.ANDROID_STORE_PASSWORD }}" \
               -keypass "${{ secrets.ANDROID_KEY_PASSWORD }}"
         - name: Output base64-encoded keystore
           run: |
             echo "==== COPY EVERYTHING BETWEEN THE MARKERS ===="
             base64 -w 0 upload-keystore.jks
             echo "==== END OF KEYSTORE ===="
   ```
   Copy the base64 output from the workflow log → add as `ANDROID_KEYSTORE_BASE64` secret. Delete the workflow file after use.

   If Java is available locally (Windows PowerShell):
   ```powershell
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
   ```

2. Update `build-android.yml` to decode the keystore and pass signing env vars:
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

### iOS signing

3. iOS signing requires the paid Apple Developer Program. Required GitHub Secrets:
   - `APPLE_CERTIFICATE_BASE64`
   - `APPLE_CERTIFICATE_PASSWORD`
   - `APPLE_PROVISIONING_PROFILE_BASE64`
   - `APP_STORE_CONNECT_API_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY_BASE64`

4. Before building for submission, confirm `pyproject.toml [tool.flet.app]`:
   ```toml
   [tool.flet.app]
   name = "YourApp"
   bundle_id = "com.yourorg.yourapp"
   version = "1.0.0"
   build_number = 1
   ```
   Update platform-specific URL constants in the app (Play Store / App Store review URL).

### Google Play submission

5. Create a Google Play Developer account at play.google.com/console ($25 USD one-off, no annual fee).
   - Register as an **Organisation** account if publishing under a company name. Requires: D-U-N-S number, Google account on company email domain, company website verified in Google Search Console.

6. Trigger the `Build Android` workflow via `workflow_dispatch` to produce the signed AAB artifact. Upload the AAB (not APK) to Google Play.

7. Google Play requires: privacy policy URL, app description, screenshots (minimum 2), age rating questionnaire, content rating. First submission goes through manual review (typically 3–7 days).

### Apple App Store submission

8. Enrol in the Apple Developer Program at developer.apple.com/programs/enroll ($99 USD/year).
   - **Organisation enrollment** requires a D-U-N-S number (free, lookup at developer.apple.com) and 2–5 business day manual review. Apple verifies director authority via ASIC (Australia) or equivalent registry.

9. Use **TestFlight** for beta testing before App Store submission. Install TestFlight from the App Store on the test device. This confirms the app runs with proper signing before submitting for review.

10. App Store requires: privacy policy URL, support URL, screenshots at 1290×2796px (6.7" iPhone minimum), age rating questionnaire, description (4,000 chars max), keywords (100 chars max). First submission goes through manual review (typically 1–3 days).

### App listing content preparation

11. Draft listing content while the developer account is being approved:
    - **Description:** hook (2 lines visible before "more"), bullet points covering key features, no ads/tracking statement
    - **Keywords:** avoid repeating the app name; focus on search terms users would use
    - **Screenshots:** run the app in Chrome DevTools device emulation (390×844 viewport), capture and resize to 1290×2796px for App Store

---

## Output format

1. **Signing setup summary** — keystore alias, required GitHub Secrets list, workflow changes needed
2. **Updated workflow snippets** — signed APK/AAB build steps with env vars
3. **Store account checklist** — what is needed for Google Play and App Store accounts
4. **App listing draft** — description, keywords, screenshot guidance
5. **Submission checklist** — steps to complete before and after uploading to each store

## Quality checklist

- [ ] `ANDROID_KEYSTORE_BASE64` secret added to GitHub (base64 of upload-keystore.jks)
- [ ] `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD` secrets set
- [ ] Keystore base64, passwords, and alias stored in password manager
- [ ] Generate-keystore workflow file deleted from repo after use
- [ ] AAB build gated on `workflow_dispatch` — not triggered on every push
- [ ] `pyproject.toml [tool.flet.app]` has `name`, `bundle_id`, `version`, `build_number`
- [ ] iOS signing secrets added (if submitting to App Store)
- [ ] TestFlight install confirmed working before App Store submission
- [ ] Privacy policy URL live and accessible
- [ ] Screenshots at correct dimensions for each platform
- [ ] Age rating questionnaire completed

## Avoid

- Losing the Android upload keystore — store it in a password manager immediately; it cannot be recovered and losing it means creating a new Play Store listing
- Uploading an unsigned APK to Google Play — it will be rejected; upload a signed AAB
- Building AAB on every push — gate it to `workflow_dispatch` to avoid wasting CI minutes
- Attempting to test iOS store signing with AltStore or free Apple ID — Flet's Python runtime requires proper entitlements; use TestFlight
- Skipping TestFlight and submitting directly to App Store review — if the app has a signing issue, App Store review will reject it
- Starting store account enrollment the day before a deadline — organisation account review for both stores takes multiple business days

## Example usage

> "The app builds and runs. I want to submit it to Google Play and the App Store. Walk me through signing, setting up the developer accounts, and preparing the store listings."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
