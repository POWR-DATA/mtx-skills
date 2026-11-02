# EAS Build and Submit

Build and submit Expo apps to Google Play and the App Store using EAS, and publish OTA updates safely — credential setup, eas.json configuration, CI/CD integration, and the EAS CLI submission and update workflow

## What this skill does

Guides the end-to-end EAS (Expo Application Services) build and submission process, covering the Google Service Account credential requirements, `eas.json` submit profile configuration, Play Console role assignment, and CLI submission. It also covers EAS Update: publishing to production channels with the right app variant, reading the published manifest back, and gating production updates behind an approval. Complements `expo-react-native-app` for development setup and `google-play-listing` for Play Console store listing content.

## When to use it

- Setting up EAS Submit for Google Play for the first time
- Diagnosing EAS submission failures related to credentials or `eas.json` configuration
- Configuring separate submission profiles for internal testing and production tracks
- Publishing an OTA update with `eas update` to a production channel, by hand or from CI

## Example use cases

- Auto-submit an iOS build to internal TestFlight with `--auto-submit` and a `submit.<profile>` ASC key block
- Generating a Google Service Account JSON key from Play Console and wiring it to `eas.json`
- Granting the Release Manager role to a service account in Play Console Users and permissions
- Configuring separate `eas.json` profiles for internal testing and production submission tracks
- Running `eas submit --platform android` after a successful EAS Build
- Publishing a production OTA through a variant-setting wrapper and asserting the published manifest per platform

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — production OTA publish wrapper, manifest read-back, gated OTA workflow |

## How to use

Load `SKILL.md` into Claude Code when preparing an Expo app for store submission via EAS, or before publishing an OTA update to a production channel. Use alongside `google-play-listing` for store listing content and App Content declarations, and `expo-react-native-app` for development setup.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
