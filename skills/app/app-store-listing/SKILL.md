---
name: app-store-listing
description: Prepare and submit an iOS app to the App Store — App Store Connect setup, screenshot dimensions, App Privacy, TestFlight, review submission, and ASC API key
author: PowerData
version: 1.0.0
license: MIT
---

# App Store Listing

## Purpose

Guide the App Store Connect listing and submission process for an iOS app — from API key setup and store screenshots through App Privacy declarations, TestFlight internal testing, and the review submission gate — so the app reaches reviewers and testers without the silent blockers that stall first-time submissions.

## When to use

After an iOS app builds successfully and produces a signed `.ipa` (typically via EAS Build). Apply when preparing a first App Store release, setting up TestFlight, configuring the App Store Connect API key for automated submission, or diagnosing why "Add for Review" is unavailable. For Android/Google Play, use `google-play-listing`. For the EAS build and submit mechanics, use `eas-build-submit`.

## Inputs expected

- A working signed iOS build (or an EAS build ID)
- An Apple Developer Program membership ($99 USD/year)
- App name, bundle identifier, and the app created in App Store Connect
- Privacy policy URL (live and publicly accessible)
- Screenshots, app icon, and store description prepared (or source screens to capture)

---

## Guiding principles

- **App Store Connect API key creation requires requesting access first.** Go to Users and Access → Integrations → App Store Connect API → Request Access; approval arrives by email, usually the same day. The p8 private key can only be downloaded **once** at creation — store it securely. The Key ID and Issuer ID (top of the API keys page) are also required for EAS credential registration.
- **Three fields gate "Add for Review" with no clear error.** Primary Category (App Information), Price (Pricing and Availability → Free or a tier), and Content Rights (App Information → Content Rights) must all be completed before the review submission button becomes available. Missing any one blocks submission silently — check all three first.
- **App Privacy requires declaring every data type the app collects.** For an app with authentication and a backend, declare each type explicitly — e.g. Name, Email Address, User ID, and Other Usage Data (in-app activity). Set "linked to identity = Yes" and "used for tracking = No" where that reflects reality. Read the actual service and database files to answer accurately — do not guess from memory.
- **iPhone 6.5" Display screenshots must be 1242×2688px (portrait).** In Chrome DevTools, set a custom device of 414×896 at DPR 3 (414×3=1242, 896×3=2688) and use Ctrl+Shift+P → "Capture screenshot". This single slot covers all large iPhones — Apple scales it up for newer models.
- **iPad 13" Display screenshots must be exactly 2064×2752px or 2048×2732px — never a mix.** For 2064×2752 use DevTools 516×688 at DPR 4; for 2048×2732 use 512×683 at DPR 4. Do not mix values across the two accepted sizes (e.g. 512×688 at DPR 4 = 2048×2752, which is rejected).
- **Apple burns the build number even on a failed submission.** If `eas submit` (or any upload) fails mid-upload, Apple still registers that build number as used. Re-submitting the same build ID fails immediately with "build number already used". The fix is a fresh build with `autoIncrement: true` in `eas.json` so the next number is assigned automatically.
- **TestFlight internal testing needs a group, testers, and an assigned build.** Create a group under TestFlight → Internal Testing, add testers by Apple ID email, and assign a build via the Builds tab. Internal testers receive no email invitation — the app appears directly in TestFlight once a build is assigned. Builds must be in "Ready to Test" status before they can be installed.
- **The screenshot DPR is the mechanism, not the viewport size.** Setting the DevTools viewport to the physical pixel dimensions at DPR 1 renders content tiny. The correct approach is always CSS pixels × DPR = required physical output.

## Process

1. **Request and create the App Store Connect API key.** Users and Access → Integrations → App Store Connect API → Request Access. Once approved, create the key, download the p8 once, and record the Key ID and Issuer ID.
2. **Create the app in App Store Connect.** Register the bundle identifier and create the app record. Note the numeric App ID (`ascAppId`) for `eas.json`.
3. **Complete the three submission-gating fields.** Set Primary Category, Price, and Content Rights before anything else — they block "Add for Review" otherwise.
4. **Capture store screenshots.** Use Chrome DevTools device emulation: iPhone 6.5" at 414×896 DPR 3; iPad 13" at 516×688 DPR 4 (or 512×683 DPR 4). Capture at full physical resolution.
5. **Complete the store listing.** App name, subtitle, description, keywords, app icon, and screenshots for each required device class.
6. **Complete App Privacy.** Declare every data type collected, reading the actual service/database code to answer the linkage and tracking questions correctly.
7. **Set up TestFlight internal testing.** Create a group, add testers by Apple ID, assign a "Ready to Test" build.
8. **Submit for review.** Once the three gating fields, listing, and App Privacy are complete, "Add for Review" becomes available — submit.

## Output format

1. **API key setup summary** — access requested, key created, Key ID and Issuer ID recorded, p8 stored
2. **Submission-gate checklist** — Primary Category, Price, Content Rights confirmed complete
3. **Screenshot spec** — exact DevTools device settings per required slot, with output dimensions
4. **App Privacy declarations** — each data type, linkage, and tracking flag
5. **TestFlight setup** — group created, testers added, build assigned
6. **Submission status** — "Add for Review" available, app submitted

## Quality checklist

- [ ] App Store Connect API key created, p8 stored securely, Key ID and Issuer ID recorded
- [ ] Primary Category, Price, and Content Rights all completed (the "Add for Review" gate)
- [ ] iPhone 6.5" screenshots are exactly 1242×2688px
- [ ] iPad 13" screenshots are exactly 2064×2752px or 2048×2732px (not a mixed size)
- [ ] App Privacy declares every collected data type, answered from actual code
- [ ] TestFlight group created, testers added, a "Ready to Test" build assigned
- [ ] Privacy policy URL is live and publicly accessible
- [ ] A fresh build with `autoIncrement: true` is used after any failed submission

## Avoid

- Assuming the App Store Connect API key can be created instantly — access must be requested first and is approved by email
- Losing the p8 private key — it can only be downloaded once at creation
- Hunting for an error when "Add for Review" is greyed out — it is almost always one of Primary Category, Price, or Content Rights left incomplete
- Guessing App Privacy answers from memory — read the actual service and database files
- Mixing iPad screenshot dimensions across the two accepted sizes — Apple rejects e.g. 2048×2752
- Setting the DevTools viewport to physical pixels at DPR 1 — content renders tiny; use CSS pixels × DPR
- Re-submitting the same build number after a failed upload — Apple has already burned it; build fresh with `autoIncrement: true`
- Expecting TestFlight internal testers to get an email invite — the app simply appears once a "Ready to Test" build is assigned

## Example usage

> "My iOS app builds via EAS and the binary is uploaded to App Store Connect. Walk me through getting the listing review-ready: screenshots at the right dimensions, App Privacy, TestFlight for my internal testers, and submitting for review. Submission keeps failing on a build-number conflict too."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
