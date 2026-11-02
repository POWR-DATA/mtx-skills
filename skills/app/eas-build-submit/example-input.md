# Example Input — EAS Build and Submit

ShiftTrack Expo app — EAS Build is configured and producing a signed AAB. Ready to submit to Google Play internal testing.

Current state:
- `eas build --platform android --profile production` completes successfully, signed AAB produced
- No Google Service Account set up yet — unclear what credential type EAS Submit needs
- Play Console developer account exists, app created, but API access not yet configured
- Submission target: internal testing track
- After launch we want to ship JS-only fixes with `eas update` to the production channel; `app.config.js` switches name, scheme and backend URL on `APP_VARIANT`

What credential setup is needed, how is `eas.json` configured for submission, and how do we publish updates safely?
