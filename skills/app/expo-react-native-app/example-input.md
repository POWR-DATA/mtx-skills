# Example Input — Expo React Native App

Building ShiftTrack, a cross-platform Expo app targeting iOS, Android, and web.

Current issues:
- Using `@expo/vector-icons` (Ionicons) — icons render as blank boxes on first run. Package is installed via `npx expo install`.
- Just added `react-native-async-storage` via `npx expo install` — app crashes on plain `npm start`.
- Shift data is fetched from an external REST API. Works on iOS simulator, fails silently on `npx expo start --web`.
- Password field has a 👁 button to toggle visibility — visible on light theme, invisible on dark theme.

What needs fixing and in what order?
