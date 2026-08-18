# Expo React Native App

Build cross-platform React Native apps with Expo — correct setup patterns, cross-platform gotchas, and hard-won lessons from native and web targets

## What this skill does

Guides the setup and debugging of Expo React Native apps, focusing on the class of silent failures that only appear on specific platforms: blank icons without font preloading, Metro bundler cache issues after package installs, CORS blocks on Expo web, and colour-invisible UI elements in dark mode.

## When to use it

- Setting up vector icons (`@expo/vector-icons`) in a new Expo project
- Debugging a newly installed package that fails to resolve after a plain Metro restart
- Getting external API calls to work on both native and Expo web targets
- Auditing interactive UI components for dark-theme rendering issues

## Example use cases

- Make error toasts, offline sign-in checks, and onboarding routing behave the same on native and web
- Ionicons rendering blank boxes despite the package being installed — fixed by adding `useFonts(Ionicons.font)` to the root layout
- New package install causes a crash until `npx expo start --clear` is run
- External API calls work on iOS but fail with CORS on Expo web — resolved by proxying through a Supabase Edge Function
- Password toggle button (👁) disappearing on dark backgrounds — replaced with a `SHOW`/`HIDE` text label

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into Claude Code at the start of a new Expo project or when a platform-specific rendering issue appears. Use alongside `supabase-edge-functions` when edge function proxying is involved.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
