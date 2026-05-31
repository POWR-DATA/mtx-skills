# Example Output — Expo iOS Deployment

## 1. Prerequisite check

- EAS CLI: logged in ✓
- `expo-dev-client`: not detected → install first

```bash
npx expo install expo-dev-client
```

> Windows is fine — EAS builds run in the cloud, so no Mac is required for the build itself.

## 2. Credential summary

```bash
eas credentials
```

- Distribution certificate: generated and stored by EAS ✓
- Provisioning profile: generated and stored by EAS ✓
- No manual work in the Apple Developer portal required

## 3. Device registration

```bash
eas device:create
```

- Chose the **Website** option → opened the generated URL on the iPhone
- Device UDID captured and added to the provisioning profile ✓

> Ad hoc distribution only installs on devices registered this way. Register the device **before** building.

## 4. Build result

```bash
eas build --platform ios --profile development
```

- Development build produced in EAS cloud
- Installed on the registered iPhone and launches with the dev client ✓

## 5. eas.json iOS config

Recorded ahead of production submission:

```json
{
  "submit": {
    "production": {
      "ios": {
        "appleTeamId": "<your-team-id>",
        "ascAppId": "<ascAppId>"
      }
    }
  }
}
```

- **Apple Team ID** — from the Apple Developer Portal header (Certificates, Identifiers & Profiles)
- **`ascAppId`** — the numeric App ID from App Store Connect, recorded after creating the app

> With these set, `eas submit --platform ios` is ready to run when you move to production (see `eas-build-submit`).
