---
name: eas-build-submit
description: Build and submit Expo apps to Google Play and the App Store using EAS — credential setup, eas.json configuration, CI/CD integration, and the EAS CLI submission workflow
author: PowerData
version: 1.2.0
license: MIT
---

# EAS Build and Submit

## Purpose

Guide the configuration and execution of Expo Application Services (EAS) Build and Submit for both Google Play and the App Store — covering credential setup (GCP service account for Android, App Store Connect API key for iOS), `eas.json` submit profile configuration, EAS environment variables, CI/CD integration via GitHub Actions, and the EAS CLI submission workflow.

## When to use

After an Expo React Native app builds successfully via EAS Build. Apply when setting up Google Play or App Store submission for the first time, integrating EAS into a GitHub Actions pipeline, or diagnosing credential, environment, or build-reuse errors during build or submission. Use alongside `expo-react-native-app` for app development setup, `google-play-listing` for Play Console listing content, and `app-store-listing` for App Store Connect listing content.

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
- **Check existing GitHub Secrets before creating a new Expo access token.** `EXPO_TOKEN` may already exist in the repo from a prior setup run. Expo access tokens are only shown once at creation — if the value is lost, delete the token in the Expo dashboard and create a new one with a descriptive name (e.g. `<ProjectName>_GH_Actions_CI`).
- **iOS `eas submit --non-interactive` requires a pre-registered App Store Connect API key.** Without it the command fails with "App Store Connect API Keys cannot be set up in --non-interactive mode". Create the key in App Store Connect → Users and Access → Integrations (request access first; approved by email), then run `eas credentials --platform ios` and select the API key option. EAS stores the key on its servers; the p8 file can then be discarded.
- **GitHub Actions secrets cannot reach EAS cloud builds.** GitHub secrets exist only on the runner, not on EAS servers where `app.config.js` is evaluated. Values needed at build time must be stored as EAS environment variables (`eas env:create --environment production`) and linked via `environment: "production"` in the eas.json build profile. Reserve GitHub secrets for `EXPO_TOKEN` and deployment credentials only — never for app config values.
- **Do not double-specify the environment.** Passing `--environment production` on the `eas build` CLI *and* declaring `environment: "production"` in the eas.json build profile causes an immediate failure (exit 1, ~1s). Remove the CLI flag and rely solely on the eas.json profile field.
- **`expo/expo-github-action@8.2.1` is hardcoded to Node 20.** No Node 24 version existed as of May 2026. Add `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION: true` at the job level (not just the build step env) in every workflow that uses the action. Node 20 is not removed from runners until September 2026.
- **`npm ci` fails in CI when `package.json` and `package-lock.json` are out of sync.** This happens when packages are added or removed locally without running `npm install` before committing. Run `npm install` locally and commit the updated lock file.
- **When a build succeeds but the deploy fails, re-deploy — don't rebuild.** For a build-number conflict or network error after a successful build, trigger `deploy-only` mode passing the EAS `build_id` from the successful build. This skips the 20–25 minute build and goes straight to submission — critical for iterating on submit failures.
- **EAS caches the native build layer.** When only JavaScript changes (no native package added or removed), subsequent builds reuse the cached native output and only re-bundle JS, cutting build time from ~25 min to ~6–7 min. Adding or removing a native package invalidates the cache and forces a full rebuild.
- **EAS free plan is 15 Android + 15 iOS builds/month** (not 30 as older docs state). The Starter plan ($19/month) provides $45 in build credits — enough for active CI/CD. Cancel once the pipeline is stable to avoid ongoing cost.

## Process

1. **Create the service account.** In Play Console → Setup → API access, link or create a GCP project. Click Create new service account → follow the GCP console link → create the account → download the JSON key → save as `google-service-account.json` in the project root.
2. **Grant the Play Console role.** In Play Console → Users and permissions → Invite new users, enter the service account email and grant Release Manager under Account permissions.
3. **Gitignore the key file.** Add `google-service-account.json` to `.gitignore` immediately. Never commit it.
4. **Configure the `eas.json` submit profile.** Add a `submit` section with `serviceAccountKeyPath` and `track` set for the target Play Console track.
5. **For iOS, register an App Store Connect API key.** Create the key in App Store Connect → Users and Access → Integrations, then run `eas credentials --platform ios` and select the API key option so EAS can submit non-interactively.
6. **Store build-time config as EAS environment variables.** Use `eas env:create --environment production` for any value `app.config.js` needs at build time — GitHub secrets do not reach EAS servers. Link the environment via `environment: "production"` in the eas.json build profile (do not also pass `--environment` on the CLI).
7. **Build via EAS.** Run `eas build --platform android|ios --profile <profile>` or reuse an existing build ID.
8. **Submit.** Run `eas submit --platform android|ios --profile <profile>`. Pass `--id <build-id>` to target a specific build. If a build succeeded but the deploy failed, re-run in deploy-only mode with the existing `build_id` rather than rebuilding.

## Output format

1. **Credential setup summary** — service account created, JSON key downloaded, Play Console role assigned
2. **`eas.json` submit profile** — the relevant JSON block configured for the target track
3. **Submission result** — build submitted, track confirmed, any errors surfaced with resolution

## Quality checklist

- [ ] GCP service account JSON key downloaded from Play Console → Setup → API access
- [ ] Service account email granted Release Manager in Play Console → Users and permissions
- [ ] `google-service-account.json` added to `.gitignore` — not committed
- [ ] `serviceAccountKeyPath` and `track` set in `eas.json` submit profile
- [ ] `eas submit --platform android|ios` completes and build appears in the target store track
- [ ] For iOS: App Store Connect API key registered with EAS via `eas credentials --platform ios`
- [ ] Build-time config stored as EAS environment variables — not GitHub secrets
- [ ] No double-specification of `--environment` flag and eas.json `environment` field
- [ ] `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION: true` set at job level if using `expo/expo-github-action`
- [ ] `package-lock.json` committed and in sync before relying on `npm ci`

## Avoid

- Using a personal Google account credential for `eas submit` — it requires a GCP service account JSON key
- Committing the service account JSON key to the repository
- Granting the Release Manager role only in GCP without also granting it in Play Console — both are required
- Running `eas submit` from a directory that does not contain `eas.json`
- Creating a new Expo access token without first checking whether `EXPO_TOKEN` already exists in GitHub Secrets — tokens are only shown once at creation; if lost, delete and recreate with a descriptive name
- Storing app config values (e.g. Supabase URL/anon key) as GitHub secrets and expecting them at EAS build time — they never reach EAS servers; use EAS environment variables
- Passing `--environment` on the CLI while also setting `environment` in eas.json — the double-specification fails immediately
- Rebuilding from scratch when a build succeeded but only the deploy failed — re-run deploy-only with the existing `build_id`
- Running `eas submit --non-interactive` for iOS without a pre-registered App Store Connect API key — it cannot prompt for one in non-interactive mode

## Example usage

> Expo app builds via EAS successfully. Need to submit the AAB to Google Play internal testing. No service account set up yet.

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
