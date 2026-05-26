---
name: expo-react-native-app
description: Build cross-platform React Native apps with Expo — correct setup patterns, cross-platform gotchas, and hard-won lessons from native and web targets
author: PowerData
version: 1.0.0
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

## Process

1. **Set up font preloading in the root layout.** For every icon set in use, call `useFonts(Iconset.font)` at the root layout level. Gate the return of any component tree behind `if (!fontsLoaded) return null`. Do not render icon-dependent components before `fontsLoaded` is true.
2. **Install packages via `npx expo install`.** This selects the SDK-compatible version. After every install, restart with `--clear` to flush Metro's module cache.
3. **Route all external API calls through a proxy.** Create a Supabase Edge Function (or equivalent server-side proxy) that forwards requests to the external API. Call the proxy from both native and web — do not use `Platform.OS` branching for fetch logic.
4. **Audit interactive UI for dark-theme compatibility.** Check any component that uses emoji, icon characters, or colour-reliant elements against a dark background. Replace emoji with text labels or `@expo/vector-icons` components that respect the `color` prop.
5. **Smoke test on web target.** Run `npx expo start --web` and exercise all screens. CORS errors and font failures that pass on native will surface here.

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

## Avoid

- Assuming vector icons work without `useFonts` — they will render as blank boxes
- Restarting Metro without `--clear` after package installs — stale cache causes silent module failures
- Adding a web-only fetch branch for CORS — use a proxy that works on both targets
- Using emoji in TextInput interactive elements — emoji ignores `color` and disappears on dark backgrounds
- Testing only on the native simulator — web-specific failures (CORS, font loading) only surface in the browser target

## Example usage

> Starting a new Expo app — icons blank on first run, API calls working on iOS but failing on web, password toggle invisible in dark mode

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
