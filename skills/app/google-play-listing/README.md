# Google Play Listing

Sign and publish an Android app (AAB) to the Google Play Store — covers keystore generation, Play Console setup, store listing content, App Content declarations, and CI automation

## What this skill does

Guides the Android signing and Google Play Store publication process for any Android app that produces an APK or AAB, regardless of the build framework used. It covers keystore generation, signed build workflow configuration, Play Console account setup, store listing completion, App Content declarations, Internal Testing, and CI automation for AAB uploads.

## When to use it

- Setting up Android signing for the first time before a Play Store release
- Completing Play Console store listing and App Content declarations
- Setting up Internal Testing and sharing opt-in links with testers
- Automating AAB uploads from CI to a Play Console track

## Example use cases

- First-time Google Play submission for an Android app with a signed AAB
- Generating an Android upload keystore in CI when Java isn't installed locally
- Completing all App Content declarations (privacy policy, IARC ratings, data safety) before promoting a release
- Automating AAB uploads from GitHub Actions to the internal testing track

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into Claude Code or any Claude session. Use alongside the build skill for your framework (e.g. `flet-multiplatform-build` for Flet apps) which covers producing the signed AAB that this skill then submits.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
