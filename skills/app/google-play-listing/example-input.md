# Example Input — Google Play Listing

The app (TrackMyPlants) builds successfully in CI — signed AAB artifacts are produced on manual trigger. I want to submit it to Google Play.

Current state:
- Signed AAB builds via CI on `workflow_dispatch` and uploads as a GitHub Actions artifact
- App package name: `com.myorg.trackmyplants`
- No Google Play Developer account yet — we are an Australian company (PTY LTD), publishing under the company name
- No keystore set up yet — AAB is currently unsigned
- Privacy policy is live at `https://www.example.com/privacy`
- App description drafted but not formatted for store listing yet
- The app requires login to access all functionality

What do I need to do to get this submitted to Google Play and available for internal testers?
