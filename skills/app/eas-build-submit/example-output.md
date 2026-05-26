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
6. Add `google-service-account.json` to `.gitignore` immediately

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

## Checklist

- [ ] Service account JSON key downloaded from GCP
- [ ] Service account email granted Release Manager in Play Console → Users and permissions
- [ ] `google-service-account.json` in project root and added to `.gitignore`
- [ ] `eas.json` submit profile configured with `serviceAccountKeyPath` and `track: internal`
- [ ] `eas submit` completed — build visible in Play Console → Testing → Internal testing
