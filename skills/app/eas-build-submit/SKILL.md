---
name: eas-build-submit
description: Build and submit Expo apps to Google Play using EAS — service account credential setup, eas.json configuration, and the EAS CLI submission workflow
author: PowerData
version: 1.0.0
license: MIT
---

# EAS Build and Submit

## Purpose

Guide the configuration and execution of Expo Application Services (EAS) Build and Submit for Google Play — covering service account credential setup, `eas.json` submit profile configuration, Play Console role assignment, and the EAS CLI submission workflow.

## When to use

After an Expo React Native app builds successfully and produces a signed AAB via EAS Build. Apply when setting up Google Play submission for the first time, or when diagnosing credential or configuration errors during submission. Use alongside `expo-react-native-app` for app development setup and `google-play-listing` for Play Console store listing content.

## Inputs expected

- EAS CLI installed (`npm install -g eas-cli`)
- Expo project with `app.json` / `app.config.js` and `eas.json` present or to be created
- Google Play Developer account with the app created in Play Console
- Access to Google Play Console → Setup → API access

---

## Guiding principles

- **EAS Submit requires a GCP service account JSON key — not your personal Google account.** The credential for `eas submit` is a JSON key file downloaded from a GCP service account, not your Play Console login. Generate it in Play Console → Setup → API access → Create new service account → follow the GCP link → download JSON key.
- **The Release Manager role must be granted in Play Console, not just in GCP.** Creating the GCP service account and assigning GCP roles is not sufficient. The account must also be added and granted Release Manager in Play Console → Users and permissions. Both steps are required.
- **Reference the key file via `serviceAccountKeyPath` in `eas.json` — never inline credentials.** Store the JSON file outside version control (gitignored) and reference it as `"serviceAccountKeyPath": "./google-service-account.json"` in the submit profile. Commit the path, not the file.
- **Configure separate `eas.json` submit profiles for each track.** Use named profiles (`production`, `internal`) to target different Play Console tracks. Each profile sets its own `track` and `releaseStatus` so internal test releases and production releases don't share configuration.
- **Run `eas submit` from the directory containing `eas.json`.** The CLI reads credentials and configuration from `eas.json` in the working directory. If the file is missing or the profile name doesn't match, submission will fail or prompt for manual input.

## Process

1. **Create the service account.** In Play Console → Setup → API access, link or create a GCP project. Click Create new service account → follow the GCP console link → create the account → download the JSON key → save as `google-service-account.json` in the project root.
2. **Grant the Play Console role.** In Play Console → Users and permissions → Invite new users, enter the service account email and grant Release Manager under Account permissions.
3. **Gitignore the key file.** Add `google-service-account.json` to `.gitignore` immediately. Never commit it.
4. **Configure the `eas.json` submit profile.** Add a `submit` section with `serviceAccountKeyPath` and `track` set for the target Play Console track.
5. **Build via EAS.** Run `eas build --platform android --profile <profile>` or use an existing build ID.
6. **Submit.** Run `eas submit --platform android --profile <profile>`. Pass `--id <build-id>` to target a specific build directly.

## Output format

1. **Credential setup summary** — service account created, JSON key downloaded, Play Console role assigned
2. **`eas.json` submit profile** — the relevant JSON block configured for the target track
3. **Submission result** — build submitted, track confirmed, any errors surfaced with resolution

## Quality checklist

- [ ] GCP service account JSON key downloaded from Play Console → Setup → API access
- [ ] Service account email granted Release Manager in Play Console → Users and permissions
- [ ] `google-service-account.json` added to `.gitignore` — not committed
- [ ] `serviceAccountKeyPath` and `track` set in `eas.json` submit profile
- [ ] `eas submit --platform android` completes and build appears in the target Play Console track

## Avoid

- Using a personal Google account credential for `eas submit` — it requires a GCP service account JSON key
- Committing the service account JSON key to the repository
- Granting the Release Manager role only in GCP without also granting it in Play Console — both are required
- Running `eas submit` from a directory that does not contain `eas.json`

## Example usage

> Expo app builds via EAS successfully. Need to submit the AAB to Google Play internal testing. No service account set up yet.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
