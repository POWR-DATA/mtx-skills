---
name: google-play-listing
description: Sign and publish an Android app (AAB) to the Google Play Store — covers keystore generation, Play Console setup, store listing content, App Content declarations, and CI automation
author: POWR-DATA
version: 1.3.0
aliases: [flet-store-submission]
license: MIT
---

# Google Play Listing

## Purpose

Guide the Android signing and Google Play Store publication process — from keystore generation through to internal testing and CI automation — for any Android app that produces an APK or AAB regardless of the build framework used.

## When to use

After the app builds successfully and produces an unsigned APK or AAB. Apply when setting up code signing for the first time, when preparing a first Play Store release, or when automating AAB uploads from CI. For iOS/App Store submission, enrol at developer.apple.com/programs/enroll ($99 USD/year) — that process is not covered here.

## Inputs expected

- Working unsigned APK or AAB from any Android build pipeline
- Google Play Developer account (existing or to be created)
- App name, package name (bundle ID), version, and build number confirmed
- Privacy policy URL (live and publicly accessible) — required before any release is promoted
- App description, screenshots, and app icon prepared

---

## Guiding principles

- **The Android upload keystore is permanent.** Once uploaded to Google Play, the keystore must be kept forever — losing it means creating a new Play Store listing. Store the base64 value, passwords, and alias in a password manager immediately after generation.
- **Required GitHub Secrets for signed builds:** `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD`. These must be set before the signed build workflow runs. PKCS12 format uses one password for store and key — set them identically.
- **Upload a signed AAB, not APK, to Google Play.** Gate the AAB build on `workflow_dispatch` — it should only run when intentionally preparing a release, not on every push.
- **Google Play org accounts do not require a D-U-N-S number.** Unlike Apple, Google does not require D-U-N-S for organisation accounts. The one-time $25 USD fee is the only requirement. The "developer name" is the public-facing name shown on every listing — use your trading name exactly as customers should see it.
- **Privacy policy must be a publicly accessible URL.** Play Console will not accept a file upload or email address. Host it on your website or use a privacy policy generator service.
- **Data deletion URL is required if any account data is collected.** Play Store requires a deletion request URL or in-app deletion option when users have accounts.
- **Use dedicated reviewer credentials, not a real user account.** Create a shared mailbox (e.g. `app_reviewer@yourdomain.com`) and a dedicated app account using that email for Google's review team.
- **GitHub free tier artifact storage fills quickly with APK/AAB builds.** Use `gh release create` to publish binaries as GitHub Releases instead — Release assets do not count against the Actions artifact storage quota.
- **When migrating frameworks, match the bundle ID exactly and prepare testers for a full reinstall.** Replacing one build framework (e.g. Flet) with another (e.g. Expo) in an existing Play Store listing requires the new app's bundle ID to match the original exactly. The signing key will differ between frameworks — existing device installs require a full uninstall before the new build can be installed. The Play Store listing itself is unaffected.
- **Resetting the upload key triggers a mandatory ~2 day server-enforced wait.** After requesting an upload key reset, the new key is not valid until the waiting period passes. There is no workaround — both manual AAB uploads and automated CI deploys fail until the window closes. Plan key rotations around this delay.
- **A draft release with no AAB shows −100% device support — this is an artefact, not a regression.** The figure comes from comparing an empty draft against the previous release. Discard the empty draft and return once a valid AAB is attached.
- **Chrome DevTools device emulation produces store-ready screenshots without a physical device.** Set a custom device using CSS pixel dimensions (not physical pixels) and a DPR that multiplies up to the required output resolution, then Ctrl+Shift+P → "Capture screenshot" exports at full physical resolution. Setting the viewport to physical pixels at DPR 1 renders content tiny — CSS pixels × DPR = physical output is the rule.
- **Promoting Internal Testing → Production reuses the tested bundle — no re-upload.** The "Create production release" page pre-populates with the tested bundle. Countries/regions are configured at the track level (Production → Countries/regions), not per release — the release page errors if no countries are set at track level.
- **The `r0adkll/upload-google-play` action requires a `whatsNewDirectory`.** Point it at a directory containing release-notes files (e.g. `whatsnew/whatsnew-en-AU`). If the directory does not exist, the deploy job fails — create it with at least one locale file before the first deploy.
- **The 512×512 store-listing icon must be a flat square with no pre-applied rounded corners.** Google applies its own shaping; baked-in rounded corners produce a visible double-rounding gap. Export a flat square version for the store listing — the adaptive icon layers (foreground/background) are separate and handled differently.

## Process

### Android signing setup

1. Generate the upload keystore in CI to avoid requiring Java/keytool locally. Add `ANDROID_STORE_PASSWORD` and `ANDROID_KEY_PASSWORD` as repo secrets first, then run a one-time `workflow_dispatch` workflow:
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
   Copy the base64 output → add as `ANDROID_KEYSTORE_BASE64` secret. Also add `ANDROID_KEY_ALIAS` (e.g. `upload`). Store all four secrets in a password manager before closing the browser tab. Delete the workflow file from the repo after use.

2. Decode the keystore and pass signing env vars in the release workflow:
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

### Google Play Console setup

3. Create a Google Play Developer account at play.google.com/console ($25 USD one-off, no annual fee). Register as an **Organisation** account if publishing under a company name — no D-U-N-S number required. The "developer name" is public-facing; the "experience description" (how you plan to use the Play Store) is not visible to users.

4. Set up Internal Testing: go to **Testing → Internal testing**, create a release, upload the signed AAB. Under the **Testers** tab, create an email list and add tester addresses (must be Google accounts). Copy the opt-in URL and share it — testers must open it on their Android device before the app appears in their Play Store. Internal Testing has no review process — the release goes live to testers immediately after promotion.

### Store listing

5. Complete the store listing — key fields and character limits:
   - **App name:** 50 characters max — title shown on the Play Store
   - **Short description:** 80 characters max — shown in search results and top of listing
   - **Full description:** 4,000 characters max — shown under "About this app"
   - **App icon:** 512×512 PNG, max 1 MB
   - **Feature graphic:** 1024×500 PNG or JPEG — shown at top of listing when promoted; required even if not featured
   - **Screenshots:** minimum 2 phone screenshots; 7-inch and 10-inch tablet screenshots can reuse phone screenshots — Play Console accepts this

### App Content declarations

6. Complete all App Content declarations before promoting any release:
   - **Privacy policy:** public URL only — required; not a file or email
   - **Ads:** declare whether the app contains ads; "No ads" requires no justification
   - **App access:** if login is required to access core functionality, provide reviewer credentials (see Step 7)
   - **Content ratings:** complete the IARC questionnaire — for a general lifestyle/entertainment app: category Entertainment, Violence: None, Sexual content: None. IARC generates ratings for all regions automatically; individual regional ratings cannot be overridden.
   - **Target audience:** declare minimum age. Selecting 18+ excludes the app from children's content policies.
   - **Data safety:** declare data collected. For an app with Supabase authentication: Email address (required, account management), Name (optional, personalisation), User IDs (required, analytics), App interactions (required, analytics). Data shared with third parties: None — Supabase is your backend, not a third party. Encrypted in transit: Yes (Supabase uses TLS). Include a data deletion URL if any account data is collected.

7. Add reviewer credentials under **App access → Restricted access → Manage instructions**: create a shared mailbox (e.g. `app_reviewer@yourdomain.com`), create a dedicated app account using that email, and enter the credentials. Avoid backticks and quotes in the password — they can break copy-paste in the Play Console form.

### CI automation

8. Automate AAB uploads to Play Console using `r0adkll/upload-google-play`:
   - In Play Console → **Setup → API access**, link a Google Cloud project and create a service account with "Release manager" role. Download the JSON key file.
   - Add the JSON as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` in GitHub Secrets.
   - Grant the service account email access in Play Console under Users and permissions with "Release apps to testing tracks" permission at minimum.
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
   `track` accepts `internal`, `alpha`, `beta`, or `production`. `status: completed` makes it live immediately; `status: draft` requires manual promotion in Play Console.

---

## Output format

1. **Signing setup summary** — keystore alias, GitHub Secrets list, workflow changes needed
2. **Signed build workflow snippet** — AAB build step with keystore decode and env vars
3. **Play Console checklist** — store listing fields completed, App Content declarations, reviewer credentials
4. **CI automation config** — r0adkll/upload-google-play workflow step with correct track and package name

## Quality checklist

- [ ] `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `ANDROID_STORE_PASSWORD` all set in GitHub Secrets
- [ ] Keystore base64, passwords, and alias stored in password manager immediately after generation
- [ ] Generate-keystore workflow deleted from repo after use
- [ ] AAB build gated on `workflow_dispatch` — not triggered on every push
- [ ] App name uses trading name exactly as customers should see it (50 chars max)
- [ ] Privacy policy URL is live and publicly accessible (not an email or file)
- [ ] Feature graphic (1024×500) uploaded — even if not promoting
- [ ] All App Content declarations completed before first release promotion
- [ ] Data deletion URL included if any account data is collected
- [ ] Reviewer credentials are for a dedicated account, not a real user account
- [ ] Internal Testing opt-in URL shared with testers before expecting them to see the app
- [ ] Service account email granted access in Play Console before CI automation runs

## Avoid

- Losing the Android upload keystore — it cannot be recovered; losing it means a new Play Store listing
- Uploading an unsigned APK or APK at all to Google Play — upload a signed AAB
- Building AAB on every push — gate it to `workflow_dispatch`; artifact storage fills quickly on the free tier
- Assuming Google Play org accounts require a D-U-N-S number — they do not (only Apple does)
- Using a real user account as reviewer credentials — use a dedicated account with a shared mailbox
- Providing a privacy policy as a file upload or email address — Play Console requires a public URL
- Skipping the Feature graphic — Play Console requires it even if the app is not being promoted
- Setting `ANDROID_STORE_PASSWORD` and `ANDROID_KEY_PASSWORD` to different values — PKCS12 format uses one password for both; mismatches cause hard-to-diagnose signing failures
- Expecting testers to update over the air when the signing key has changed (e.g. after a framework migration) — a changed signing key requires a full uninstall on the device before the new build can be installed
- Resetting the upload key right before a release — the ~2 day server-enforced validation wait blocks all uploads until it passes
- Panicking at a −100% device support figure on an empty draft release — it is an artefact of comparing against zero devices; attach a valid AAB
- Configuring an `r0adkll/upload-google-play` deploy without a `whatsNewDirectory` and locale file — the job fails
- Uploading a store-listing icon with baked-in rounded corners — Google double-rounds it; use a flat square 512×512

## Example usage

> "The Android build pipeline produces a signed AAB on manual trigger. Set up the Google Play Console listing, complete all App Content declarations, configure Internal Testing, and automate AAB uploads from CI."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
