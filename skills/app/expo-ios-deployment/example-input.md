# Example Input — Expo iOS Deployment

> I need to test my Expo app on my iPhone. I'm on SDK 56 so Expo Go doesn't work anymore, and I develop on Windows.

**Project details:**
- Framework: Expo / React Native, SDK 56
- Bundle ID: `com.myorg.trackmyplants`
- EAS CLI: installed and logged in
- Apple Developer Program: active membership

**Environment:**
- Development machine: Windows 11
- Test device: iPhone, plugged in via USB
- No Mac available

**What I need:**
- An iOS build I can actually install and run on the iPhone
- EAS to handle the certificates — I don't want to manage them in the Apple portal
- `eas.json` set up so I can submit to the App Store later without reconfiguring

**Known unknowns:**
- I haven't registered the device with EAS yet
- I'm not sure whether `expo-dev-client` is installed
- I have the app created in App Store Connect but haven't recorded the numeric App ID
