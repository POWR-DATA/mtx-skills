# App Store Listing

Prepare and submit an iOS app to the App Store, covering the App Store Connect steps that silently block first-time submissions.

## What this skill does

Guides an iOS app through App Store Connect: API key setup, store screenshots at the exact required dimensions, App Privacy declarations, TestFlight internal testing, and the review submission gate. It focuses on the non-obvious blockers — the greyed-out "Add for Review" button, rejected screenshot sizes, and burned build numbers — that stall a first release.

## When to use it

- Preparing a first App Store release for an iOS app
- Setting up the App Store Connect API key for automated EAS submission
- Configuring TestFlight internal testing
- Diagnosing why "Add for Review" is unavailable or why submission fails

## Example use cases

- An Expo app builds via EAS and needs a complete, review-ready App Store Connect listing
- A submission fails with "build number already used" after a mid-upload error
- App Privacy needs to be completed accurately from the app's actual data model
- Internal testers need TestFlight access before public release

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into your AI tool alongside your app's bundle ID, build details, and data model. The skill works best when paired with `eas-build-submit` (build/submit mechanics) and `expo-react-native-app` (app development).

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
