---
name: app-store-listing
description: Prepare and submit an iOS app to the App Store — App Store Connect setup, screenshot dimensions, App Privacy, TestFlight, review submission, and ASC API key
author: PowerData
version: 1.3.0
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
- **In-app account deletion is mandatory for any app with account creation.** Apple has required it since June 2022 (Guideline 5.1.1(v)). An external web form does **not** satisfy the requirement — verify before "Add for Review" that the app has a real in-app deletion flow whose delete action actually deletes, not just a link to a web delete page. In the same pass, check that any in-app Terms/Privacy links resolve to real, in-effect pages — a visible "DRAFT / not yet in effect" banner on a linked legal page is a rejection trigger.
- **Provision reviewer credentials in the PRODUCTION backend the release build points at.** Store-review demo sign-in and any sign-up/invite code must exist in prod, not just dev — a prod build carrying a dev-only reviewer account fails App Review sign-in and gets rejected. Verify or seed them against prod as a submission-prep step whenever the store build targets prod.
- **Select "Manually release this version" before submitting.** On approval the build sits in "Pending Developer Release" until you click, so you can bank Apple's review (the slow long-pole) ahead of legal/clinical sign-off without going public. Submitting for review is NOT the same as going live when manual release is set.
- **There is no manual 1024 app-icon upload on iOS.** The App Icon populates on the version page only after you attach a build in the Build section — the icon ships inside the binary. Contrast Google Play, which DOES have a manual 512×512 icon upload; don't hunt for an iOS icon field.
- **Pre-answer export compliance and IDFA to make the submit dialog prompt-free.** Set `ITSAppUsesNonExemptEncryption: false` in the build's Info.plist so export-compliance auto-resolves with no prompt, and answer the IDFA question "No" for an app with no ads/tracking.
- **A "Guideline 2.1 — Information Needed" is an info-request, not a rejection.** Resolve it by REPLYING in the Resolution Center (answers + screen recordings), which re-activates the review — the "Resubmit to App Review" button staying greyed for a metadata info-request is normal, not a bug. Record requested demo videos on a throwaway production account minted for the purpose and deleted in-app at the end.
- **An App Store URL without a storefront segment 404s for a single-country app.** `https://apps.apple.com/app/id<ID>` returns 404 when the app is published in one country; only the storefront form (`https://apps.apple.com/au/app/id<ID>`) works. Test the exact URL before staging it anywhere, and check the forced-update prompt and rate-this-app links inside the app — they commonly carry the same broken form.
- **Never restyle a store badge.** Apple and Google both prohibit altering their badge artwork, so a live badge must not carry "coming soon" treatment such as opacity or grayscale. Put the dimming on a modifier class used only for stores where the app is not yet published, leave the base badge class untouched, and keep clear space of a quarter of the badge height around each badge.
- **Audit what the App Store actually serves from `application/ld+json`.** Read the description out of that block in the apps.apple.com page source rather than a web-fetch summary, which paraphrased the text and invented a duplicated opening sentence. The served App Store copy carried drafting typos the Play listing did not, so compare the two listings side by side before each release.

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
- [ ] If the app supports account creation, an in-app account-deletion path exists (not just a web form)
- [ ] Every App Store link uses the storefront form and has been fetched; in-app update/rate links checked too
- [ ] Live store badges unmodified; any "coming soon" dimming confined to a modifier class for unpublished stores
- [ ] Served listing copy read from `application/ld+json` and compared against the Play listing

## Avoid

- Assuming the App Store Connect API key can be created instantly — access must be requested first and is approved by email
- Losing the p8 private key — it can only be downloaded once at creation
- Hunting for an error when "Add for Review" is greyed out — it is almost always one of Primary Category, Price, or Content Rights left incomplete
- Guessing App Privacy answers from memory — read the actual service and database files
- Mixing iPad screenshot dimensions across the two accepted sizes — Apple rejects e.g. 2048×2752
- Setting the DevTools viewport to physical pixels at DPR 1 — content renders tiny; use CSS pixels × DPR
- Re-submitting the same build number after a failed upload — Apple has already burned it; build fresh with `autoIncrement: true`
- Expecting TestFlight internal testers to get an email invite — the app simply appears once a "Ready to Test" build is assigned
- Relying on an external web form for account deletion — Apple requires the deletion path to be reachable inside the app for any app with account creation
- Staging a storefront-less `apps.apple.com/app/id...` URL — it 404s for a single-country app
- Applying opacity or grayscale to a live store badge, or crowding it below a quarter-badge-height of clear space
- Trusting a summarised fetch of the store page when auditing listing copy

## Example usage

> "My iOS app builds via EAS and the binary is uploaded to App Store Connect. Walk me through getting the listing review-ready: screenshots at the right dimensions, App Privacy, TestFlight for my internal testers, and submitting for review. Submission keeps failing on a build-number conflict too."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
