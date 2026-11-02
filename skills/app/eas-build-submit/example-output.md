# Example Output — EAS Build and Submit

## Credential setup summary

EAS Submit for Google Play requires a GCP service account JSON key — not a personal Google account. The account must be granted Release Manager in Play Console (not just in GCP).

---

## Step 1 — Create the service account

In Google Play Console → Setup → API access:

1. Link or create a Google Cloud project
2. Click **Create new service account** → follow the GCP console link
3. In GCP: create the account with a descriptive name (e.g. `eas-submit`)
4. Go to GCP → IAM → Service Accounts → your account → Keys → Add key → JSON → download
5. Save the file as `google-service-account.json` in the project root
6. Add `google-service-account.json` to `.gitignore` immediately and confirm with `git check-ignore google-service-account.json`

---

## Step 2 — Grant the role in Play Console

In Play Console → Users and permissions → Invite new users:

1. Enter the service account email (visible in the GCP service accounts list)
2. Under **Account permissions**, grant **Release manager**
3. Click **Invite user**

This step is required even if GCP roles are already assigned. Both GCP service account creation and Play Console role assignment must be completed.

---

## Step 3 — Configure eas.json

```json
{
  "cli": {
    "version": ">= 10.0.0"
  },
  "build": {
    "production": {
      "android": {
        "buildType": "app-bundle"
      }
    }
  },
  "submit": {
    "production": {
      "android": {
        "serviceAccountKeyPath": "./google-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

To target production later, add a separate `production` submit profile with `"track": "production"`.

---

## Step 4 — Submit

```bash
# Submit the most recent build interactively
eas submit --platform android --profile production

# Or target a specific build by ID
eas submit --platform android --profile production --id <build-id>
```

EAS will confirm the build being submitted and the target track before proceeding.

---

## Step 5 — iOS auto-submit to TestFlight (optional)

```json
"submit": {
  "production": {
    "ios": {
      "ascAppId": "<asc-app-id>",
      "appleTeamId": "<team-id>",
      "ascApiKeyPath": "./AuthKey_<key-id>.p8",
      "ascApiKeyId": "<key-id>",
      "ascApiKeyIssuerId": "<issuer-id>"
    }
  }
}
```

`EAS_SKIP_AUTO_FINGERPRINT=1 eas build --profile production --platform ios --auto-submit --no-wait` — build number auto-increments; TestFlight processing adds ~10–30 min. Fetch the IPA from **Application Archive URL** (Build Artifacts URL reads `null`).

---

## Step 6 — Publish OTA updates to production

A bare `eas update --channel production` does not set `APP_VARIANT`, so `app.config.js` would resolve the development variant and ship its name, scheme and backend URL to production phones. Publish only through the wrapper (see *Production OTA publish* in `reference.md`):

1. Confirm the channel from the `production` build profile in `eas.json`
2. Run the wrapper — it refuses a dirty tree, sets `APP_VARIANT=production` and passes `--environment production`
3. Read the manifest back for iOS and Android and confirm name, scheme, `appEnv`, bundle id and backend URL are the production values

In CI, the production publish workflow runs on `workflow_dispatch` only, behind a `production` GitHub environment with required reviewers.

## Checklist

- [ ] Service account JSON key downloaded from GCP
- [ ] Service account email granted Release Manager in Play Console → Users and permissions
- [ ] `google-service-account.json` in project root, added to `.gitignore` and confirmed with `git check-ignore`
- [ ] `eas.json` submit profile configured with `serviceAccountKeyPath` and `track: internal`
- [ ] `eas submit` completed — build visible in Play Console → Testing → Internal testing
- [ ] Production OTA published via the wrapper and its manifest read back for both platforms
