# EAS Build and Submit

Build and submit Expo apps to Google Play using EAS — service account credential setup, eas.json configuration, and the EAS CLI submission workflow

## What this skill does

Guides the end-to-end EAS (Expo Application Services) submission process for Google Play, covering the Google Service Account credential requirements, `eas.json` submit profile configuration, Play Console role assignment, and CLI submission. Complements `expo-react-native-app` for development setup and `google-play-listing` for Play Console store listing content.

## When to use it

- Setting up EAS Submit for Google Play for the first time
- Diagnosing EAS submission failures related to credentials or `eas.json` configuration
- Configuring separate submission profiles for internal testing and production tracks

## Example use cases

- Auto-submit an iOS build to internal TestFlight with `--auto-submit` and a `submit.<profile>` ASC key block
- Generating a Google Service Account JSON key from Play Console and wiring it to `eas.json`
- Granting the Release Manager role to a service account in Play Console Users and permissions
- Configuring separate `eas.json` profiles for internal testing and production submission tracks
- Running `eas submit --platform android` after a successful EAS Build

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into Claude Code when preparing an Expo app for Google Play submission via EAS. Use alongside `google-play-listing` for store listing content and App Content declarations, and `expo-react-native-app` for development setup.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
