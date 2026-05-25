# Example Input — Flet Store Submission

The app (TrackMyPlants) builds successfully in CI — APK and IPA artifacts are uploading to GitHub Actions. I want to submit it to both Google Play and the App Store.

Current state:
- `flet build apk` works; the APK installs and runs on a physical Android device
- `flet build ipa` produces an xcarchive; the IPA sideloads via AltStore but crashes on launch
- `pyproject.toml` has `name = "TrackMyPlants"` and `bundle_id = "com.powrdata.trackmyplants"` in `[tool.flet.app]`
- No signing keys set up yet
- No Google Play or Apple Developer account yet
- We are an Australian company (PTY LTD), so we need organisation accounts on both platforms
- Privacy policy is live at `https://www.example.com/privacy`
- We have a rough app description but haven't formatted it for store listings yet

What do I need to do to get this submitted to both stores?
