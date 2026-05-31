# Example Input — App Store Listing

> My iOS app is built and the binary is uploaded to App Store Connect via EAS. I need to get it review-ready and out to my internal testers, and I keep hitting blockers.

**App details:**
- App name: `TrackMyPlants`
- Bundle ID: `com.myorg.trackmyplants`
- Platform: iOS (Expo / React Native, built with EAS)
- Backend: Supabase (email/password auth, user profile and activity tables)
- Privacy policy: `https://www.example.com/privacy` (live)

**What I need help with:**
- Screenshots: which device sizes are required and the exact pixel dimensions
- App Privacy: what to declare for a Supabase-auth app
- TestFlight: getting the build to my two internal testers
- The "Add for Review" button is greyed out and I can't tell why
- A previous `eas submit` failed and now re-submitting says "build number already used"

**Constraints:**
- No physical iPhone or iPad on hand — need to produce screenshots from a desktop browser
- Want automated submission from CI, so the App Store Connect API key needs setting up
