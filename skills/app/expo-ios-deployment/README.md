# Expo iOS Deployment

Produce an EAS iOS development build for testing on registered physical devices.

## What this skill does

Walks through the EAS iOS development build loop: installing `expo-dev-client`, generating credentials automatically, registering test devices by UDID, and building an ad hoc development build that installs on those devices. It also records the `eas.json` iOS fields needed later for production submission. This is the development testing path — not App Store submission.

## When to use it

- Testing an Expo iOS app on a real device when Expo Go is unavailable (SDK 56+) or native modules are needed
- Setting up EAS-managed iOS credentials for the first time
- Registering physical devices for ad hoc distribution
- Preparing `eas.json` iOS config ahead of production submission

## Example use cases

- An SDK 56 Expo app needs on-device iOS testing without Expo Go
- A developer on Windows needs an iOS build on a plugged-in iPhone
- A new project needs EAS to generate the distribution certificate and provisioning profile
- `eas.json` needs the Apple Team ID and `ascAppId` before the first `eas submit`

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into your AI tool with your bundle ID and target device on hand. Pair with `expo-react-native-app` for development setup and `eas-build-submit` / `app-store-listing` for production release.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
