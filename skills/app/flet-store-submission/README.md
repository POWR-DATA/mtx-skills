# Flet Store Submission

Sign and submit a Flet app to the Google Play Store and Apple App Store — covers keystore generation, signing config, store accounts, and app listing preparation

## What this skill does

Guides the complete app store submission process for a Flet Python app — from generating the Android upload keystore through to a live store listing. It covers code signing for both platforms, store account setup requirements, and how to prepare app listing content efficiently.

## When to use it

- Setting up Android signing for the first time before a Play Store release
- Preparing an iOS build for App Store or TestFlight distribution
- Creating Google Play or Apple Developer accounts for a new organisation
- Drafting app store listing content (description, screenshots, keywords)

## Example use cases

- First-time Play Store submission for a Flet app with a signed AAB
- Setting up Apple Developer Program enrollment for an organisation and submitting via TestFlight
- Generating an Android upload keystore in CI when Java isn't installed locally
- Preparing store listing content while waiting for developer account approval

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into Claude Code or any Claude session. Use alongside `flet-multiplatform-build` (which covers building the APK/AAB/IPA) and `flet-aca-deploy` (which covers web deployment).

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [PowerData Skills](https://github.com/POWR-DATA/skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
