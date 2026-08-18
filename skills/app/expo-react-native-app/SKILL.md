---
name: expo-react-native-app
description: Build cross-platform React Native apps with Expo — correct setup patterns, cross-platform gotchas, and hard-won lessons from native and web targets
author: PowerData
version: 1.5.0
license: MIT
---

# Expo React Native App

## Purpose

Guide the setup and development of a cross-platform React Native app using Expo, covering icon and font configuration, Metro bundler behaviour, web-platform API access, and UI component gotchas that only surface on specific targets or themes.

## When to use

When starting a new Expo project or debugging a problem that appears only on a specific platform (web, dark theme, after a package install). Apply at project setup time to avoid the class of silent failures that only surface on device or in the browser target.

## Inputs expected

- Expo SDK version and target platforms (native, web, or both)
- Icon set or UI library in use (e.g. `@expo/vector-icons`, custom assets)
- External API endpoints the app will call
- Known errors or unexpected rendering behaviour

---

## Guiding principles

- **Vector icon fonts must be explicitly preloaded.** `@expo/vector-icons` (Ionicons and others) renders blank boxes unless `useFonts(Iconset.font)` is called in the root layout and rendering is gated behind `fontsLoaded`. This is required even when the package is already installed — installation does not trigger font registration.
- **Clear Metro cache after every package install.** After `npx expo install <package>`, run `npm start -- --clear` or `npx expo start --clear`. A plain restart leaves stale module resolution and causes icons or modules to fail silently until the cache is cleared.
- **Proxy all external API calls — never branch by platform for CORS.** External REST API calls that work on native are silently blocked by CORS on Expo web. The fix is a proxy (e.g. a Supabase Edge Function) so both native and web use the same code path. A web-only fetch branch doubles the maintenance surface and will diverge.
- **Emoji ignores colour styling in TextInput rows.** Emoji characters inside `TextInput` rows are invisible on dark backgrounds because emoji rendering ignores the `color` style prop. Use a short text label (`SHOW`/`HIDE`) with an explicit `color` instead. Merge the label button into a shared bordered container using `flexDirection: 'row'` to avoid an unwanted internal dividing line.
- **Test on both native and web targets before considering a screen complete.** Behaviour differences between native and web (CORS, emoji rendering, font loading) only surface when the target is exercised — do not rely on native-only testing.
- **Expo Go is no longer available for SDK 56+ — use EAS development builds.** Expo Go was removed from the App Store for SDK 56 (confirmed May 2026). The correct local testing approach for iOS is an EAS development build with `expo-dev-client`, including when developing on Windows against a physical device.
- **The iOS `icon` field in `app.config.js` must point to a real PNG.** The Expo default template may leave a placeholder (e.g. `./assets/expo.icon`) that is not a valid image. Replace it with a real PNG path (e.g. `./assets/images/icon.png`) before building, or the iOS build fails.
- **Use a `Modal`-based dropdown when a list sits inside nested ScrollViews on Android.** A `ScrollView` inside an absolutely-positioned `View` that is itself inside a parent `ScrollView` cannot receive scroll touches — the parent clips touch events regardless of `nestedScrollEnabled`. The reliable fix: `measureInWindow` on the trigger ref to get screen coordinates, then render the list in a `Modal` positioned at those coordinates, placing it entirely outside the ScrollView hierarchy.
- **iOS `Modal` components ignore the app-level orientation lock.** Expo's `orientation: 'portrait'` config does not propagate to modals. Each `Modal` must explicitly declare `supportedOrientations={['portrait']}` or it rotates when the device is held sideways or in Stage Manager on iPad.
- **On Windows, the Android emulator lives at `C:\Users\<username>\Android\sdk\emulator\emulator.exe`** — not `%LOCALAPPDATA%\Android\Sdk\emulator`. Multiple `expo start` invocations accumulate Metro instances across ports 8081, 8083, 8085…; kill all processes on ports 8081–8090 before starting a new Metro instance, then run `adb reverse tcp:8081 tcp:8081` so the emulator can reach Metro on the host.
- **Expo/React Native and Flet/Flutter are entirely separate stacks — no patterns transfer between them.** Expo uses TypeScript → React Native → native platform UI (UIKit on iOS, Jetpack Compose on Android). Flet uses Python → Flutter (Dart) → canvas-based rendering. No runtime is shared; packages, debugging approaches, and build tooling are completely different.
- **Choose Expo over Flet for production mobile unless Python familiarity is the only constraint.** Expo's hot reload dev cycle, EAS build/signing/OTA tooling, native push notification support, and ecosystem size substantially outweigh Flet's sole advantage of Python. If the team is comfortable with TypeScript, choose Expo.
- **Expo only exposes `EXPO_PUBLIC_*` env vars to client code.** `app.config.js` `extra` must read the prefixed names (e.g. `process.env.EXPO_PUBLIC_SUPABASE_URL`), and CI workflows must inject under those names too. Reading the unprefixed `SUPABASE_URL` yields empty values and a runtime "supabaseUrl is required" crash.
- **`app.config.js` `extra` constants are Metro-cached.** After editing `app.config.js`, the old values persist until you restart with `npx expo start --clear`. A stale-config error that won't go away is usually this, not a code bug.
- **Consolidate per-app placeholders into one `template.config.json` + a generator script.** The generator stamps `app.config.js` / `package.json` / `eas.json` / the CI workflow and regenerates a single `src/constants/AppConfig.ts` the screens import — killing hardcoded URL/name sprawl and making a new app one edit plus one command.
- **Push notifications require a development build, not Expo Go.** Expo push was removed from Expo Go in SDK 53 (deprecated in 52) and only works in a dev build (`expo-dev-client`). The iOS Simulator cannot receive push (physical device required); EAS provisions the APNs/FCM credentials.
- **Native in-app review is a silent no-op on sideloaded/dev builds.** `expo-store-review` (Play In-App Review / `SKStoreReviewController`) only renders on store-distributed installs (Android: any Play track, Internal testing is enough; iOS: TestFlight/App Store). On a dev APK `requestReview()` does nothing — that is correct, not a bug. Verify it as a launch-time test on a real store track; never add a dev-only fallback to force it.
- **Lazy-load optional native modules with a synchronous `require()`.** Importing an optional native module (e.g. `expo-store-review`) at the top level crashes any dev build whose native binary predates the JS module ("Cannot find native module"); `await import()` then trips a Metro async-require bug ("Requiring unknown module N"). Use a synchronous `require()` inside the function (with an eslint-disable for `no-require-imports`) to keep graceful degradation.
- **Reach Metro from a physical Android device over USB with `adb reverse`.** Run `adb reverse tcp:8081 tcp:8081`, start with plain `npx expo start --dev-client` (default 0.0.0.0 binding), and in the dev launcher enter `http://localhost:8081`. Do not pass `--localhost` — it binds Metro to IPv6 `::1` only, breaking the IPv4 adb-reverse tunnel ("unexpected end of stream" / UNAUTHORIZED).
- **On Windows under OneDrive, mark `node_modules` "Always keep on this device".** OneDrive's on-demand placeholder files make Metro bundling fail with `readlink EINVAL` until the files are materialised locally.
- **Scope App Links / Universal Links to the landing path only (`/<slug>`, `/<slug>/`), never `/<slug>/*`.** Broadening the pattern hijacks web-only auth pages (e.g. `/<slug>/reset-password`, `/<slug>/confirm-email`) into the app and breaks them — those must complete in the browser. Links also stay inert until `assetlinks.json` (Android, signing SHA-256) / AASA (iOS, Apple Team ID) are deployed to `/.well-known/` and the app is rebuilt.
- **`Alert.alert` is a silent no-op on react-native-web.** Message-type errors never appear on the web target — provide a cross-platform toast (a root-mounted host plus a plain `showToast` function) for one-way messages, and keep native `Alert` only for interactive prompts (action sheets, camera-permission dialogs).
- **Create `Animated.Value`s with a lazy `useState`, not `useRef(...).current`.** `useRef(new Animated.Value(0)).current` trips the newer `react-hooks/refs` lint rule ("cannot access refs during render") — use `useState(() => new Animated.Value(0))` for a value that is stable across renders without reading `.current` during render.
- **Resolve the current user via `getSession()`, not `getUser()`, in write paths.** supabase-js `getUser()` makes a network round-trip and returns null when offline (surfacing a misleading "not signed in"); `getSession()` reads the persisted local session and is offline-safe, so an offline action fails as a network error, not a false sign-out.
- **Supabase and fetch errors are frequently plain objects, not `Error` instances.** `e instanceof Error` misses their `.message` — extract `.message` from any object shape and map network strings ("failed to fetch", "network request failed") to a friendly line, so raw errors and the backend URL never reach users.
- **Make the server authoritative about onboarding.** Return an explicit `needs_onboarding` flag rather than inferring it client-side from a missing profile row — the client guess also fires on a transient read failure and wrongly bounces an onboarded user to the wizard. Self-heal the onboarding page too (redirect an already-onboarded user away) so a stale tab can't strand them there.
- **Persist the pending-confirmation email for an email-confirmation sign-up gate** (email only, never the password) so closing and reopening the app mid-wait restores the "confirm your email" state instead of a blank login with full re-entry.
- **A coloured badge inside a web form field is the browser's native autofill or a password-manager extension, not your code.** `autocomplete` attributes (`given-name`/`family-name`/`tel`/`email`, and `off` on unique/credential fields) steer the browser's native autofill but cannot suppress a third-party extension (e.g. LastPass); confirm by loading the page in a private window.
- **The red bottom-left error popup on the Expo web target is Expo's dev-only notification.** The dismissable lightning-bolt popup for a runtime or network error does not ship to production — don't mistake it for your own in-app toast or UI.
- **Run the project's own `lint` script, not `npx eslint` directly.** A JS/TS project may lint with oxlint rather than eslint; invoking eslint applies a different (often stricter) ruleset and reports "errors" the project never gates on.
- **View a private Supabase Storage file with a signed URL + `WebBrowser.openBrowserAsync`.** Create a short-lived signed URL and open it with `expo-web-browser` (usually already installed) rather than adding `expo-file-system` or a download step; open plain links with `Linking.openURL`.
- **Render tappable links inside message text with nested `<Text onPress>`.** Split the string on a URL regex and return the URL segments as nested `<Text onPress={() => Linking.openURL(url)}>` within the parent `<Text>` — RN honours press handlers on nested Text runs, so you get inline links with no rich-text library.
- **When the website's URL path differs from the Expo `slug`, use a separate web-path value.** The slug is a technical id tied to the EAS project — don't derive web URLs or App-Link paths from it. Introduce `webSlug` / `extra.webPath` for the web path and keep the slug for builds/credentials; `+native-intent.tsx` should strip `extra.webPath`, not `Constants.expoConfig.slug`, so the landing link resolves to the app root even when slug ≠ URL segment.

## Process

1. **Set up font preloading in the root layout.** For every icon set in use, call `useFonts(Iconset.font)` at the root layout level. Gate the return of any component tree behind `if (!fontsLoaded) return null`. Do not render icon-dependent components before `fontsLoaded` is true.
2. **Install packages via `npx expo install`.** This selects the SDK-compatible version. After every install, restart with `--clear` to flush Metro's module cache.
3. **Route all external API calls through a proxy.** Create a Supabase Edge Function (or equivalent server-side proxy) that forwards requests to the external API. Call the proxy from both native and web — do not use `Platform.OS` branching for fetch logic.
4. **Audit interactive UI for dark-theme compatibility.** Check any component that uses emoji, icon characters, or colour-reliant elements against a dark background. Replace emoji with text labels or `@expo/vector-icons` components that respect the `color` prop.
5. **Smoke test on web target.** Run `npx expo start --web` and exercise all screens. CORS errors, font failures, and silent `Alert.alert` no-ops that pass on native will surface here.
6. **Harden auth/session paths.** `getSession()` for the current user in writes, object-shape error extraction with friendly network messages, server-driven `needs_onboarding`, persisted pending-confirmation email.
7. **Lint with the project's script** (`npm run lint`), not `npx eslint`.

## Output format

1. **Setup checklist** — font preloading wired, Metro cache strategy confirmed, proxy endpoint identified
2. **Screen-by-screen notes** — any platform-specific issues found and how they were resolved
3. **Remaining work** — items that need device testing beyond what the web target covers

## Quality checklist

- [ ] `useFonts(Iconset.font)` called for every icon set in the root layout
- [ ] Rendering gated on `fontsLoaded` before any icon-dependent component renders
- [ ] Metro restarted with `--clear` after every new package install
- [ ] All external API calls routed through a proxy — no `Platform.OS` branching for fetch
- [ ] Interactive TextInput components use text labels, not emoji, for dark-theme compatibility
- [ ] Web target tested with `npx expo start --web`
- [ ] iOS `icon` in `app.config.js` points to a real PNG, not a template placeholder
- [ ] iOS testing uses an EAS development build (`expo-dev-client`), not Expo Go, on SDK 56+
- [ ] Portrait-locked iOS modals declare `supportedOrientations={['portrait']}`
- [ ] Nested-ScrollView dropdowns on Android use a `Modal` rather than an inner ScrollView
- [ ] Client env vars use the `EXPO_PUBLIC_*` prefix in `app.config.js` `extra` and in CI
- [ ] Push notifications, in-app review, and other store-only features tested on a real store track — not a dev build
- [ ] Optional native modules lazy-loaded via synchronous `require()`, not top-level or `await import()`
- [ ] App Links / Universal Links scoped to the landing path only, with `assetlinks.json`/AASA deployed
- [ ] One-way messages use a cross-platform toast; native `Alert` reserved for interactive prompts
- [ ] Write paths resolve the user via `getSession()`; errors extracted by shape, network strings mapped to friendly text
- [ ] Onboarding driven by a server `needs_onboarding` flag; onboarding page self-heals; pending-confirmation email persisted (never the password)
- [ ] `Animated.Value` created via lazy `useState`; project `lint` script used

## Avoid

- Assuming vector icons work without `useFonts` — they will render as blank boxes
- Restarting Metro without `--clear` after package installs — stale cache causes silent module failures
- Adding a web-only fetch branch for CORS — use a proxy that works on both targets
- Using emoji in TextInput interactive elements — emoji ignores `color` and disappears on dark backgrounds
- Testing only on the native simulator — web-specific failures (CORS, font loading) only surface in the browser target
- Applying Flet/Flutter patterns, packages, or mental models to Expo development — they are entirely separate stacks with no shared runtime
- Relying on Expo Go for SDK 56+ iOS testing — it is no longer available; use an EAS development build with `expo-dev-client`
- Leaving the Expo template's placeholder icon path in `app.config.js` — point the iOS `icon` field at a real PNG before building
- Nesting a scrollable list inside an absolutely-positioned `View` within a parent `ScrollView` on Android — touch events are clipped; render the list in a `Modal` instead
- Omitting `supportedOrientations={['portrait']}` on iOS modals when the app is portrait-locked — modals rotate independently of the app config
- Reading unprefixed env vars (`SUPABASE_URL`) in client code — only `EXPO_PUBLIC_*` names reach the client; the rest are empty at runtime
- Top-level importing an optional native module — it crashes dev builds whose native binary predates it; lazy-load with `require()`
- Broadening App Links to `/<slug>/*` — it hijacks web-only auth pages into the app; scope to the landing path only
- Passing `--localhost` to `expo start` for USB device debugging — it binds IPv6-only and breaks the adb-reverse tunnel
- Using `Alert.alert` for error messages — it is a silent no-op on web; use a toast
- Calling `getUser()` in write paths — offline it returns null and reads as "signed out"; use `getSession()`
- Testing errors with `instanceof Error` — Supabase/fetch errors are often plain objects; read `.message` by shape
- Inferring onboarding state client-side from a missing profile row — a transient read failure bounces onboarded users to the wizard
- Chasing a coloured autofill badge as a styling bug — it is the browser or a password-manager extension; check in a private window
- Mistaking Expo's dev-only red error popup on web for your own toast — it never ships
- Running `npx eslint` on an oxlint project — wrong ruleset, phantom errors

## Example usage

> Starting a new Expo app — icons blank on first run, API calls working on iOS but failing on web, password toggle invisible in dark mode

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
