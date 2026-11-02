# Example Input — Expo React Native App

Building ShiftTrack, a cross-platform Expo app targeting iOS, Android, and web.

Current issues:
- Using `@expo/vector-icons` (Ionicons) — icons render as blank boxes on first run. Package is installed via `npx expo install`.
- Just added `react-native-async-storage` via `npx expo install` — app crashes on plain `npm start`.
- Shift data is fetched from an external REST API. Works on iOS simulator, fails silently on `npx expo start --web`.
- Password field has a 👁 button to toggle visibility — visible on light theme, invisible on dark theme.
- A shared `/shift/<id>` link opens the schedule map but never shows the shift card, and the map then jumps back to the default area.
- After signing out and in as a colleague on the same browser, the previous user's shifts still show as "mine".

What needs fixing and in what order?
