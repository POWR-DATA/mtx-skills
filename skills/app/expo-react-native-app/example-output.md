# Example Output — Expo React Native App

## Setup checklist

| Item | Action |
|---|---|
| Font preloading | Add to root layout — required before any icons render |
| Metro cache | Clear now, then after every future package install |
| API proxy | Create server-side proxy for external REST calls |
| Dark-theme UI | Replace 👁 emoji with text label |

---

## Fix 1 — Blank vector icons

`@expo/vector-icons` requires explicit font preloading — the package being installed is not enough.

In the root layout (`app/_layout.tsx`):

```tsx
import { useFonts } from 'expo-font';
import { Ionicons } from '@expo/vector-icons';

export default function RootLayout() {
  const [fontsLoaded] = useFonts(Ionicons.font);
  if (!fontsLoaded) return null;
  return <Stack />;
}
```

If multiple icon families are used (MaterialIcons, FontAwesome), add all of them in a single `useFonts` call. Every icon-dependent component must only render after `fontsLoaded` is true.

---

## Fix 2 — Crash after package install

A plain `npm start` does not flush Metro's module cache. After every `npx expo install`, restart with:

```
npx expo start --clear
```

Standard workflow: install → `--clear` restart → verify. Never skip the flag after a new install.

---

## Fix 3 — CORS blocking API calls on web

External REST calls work on native but are blocked by the browser's CORS policy on Expo web. The correct fix is a server-side proxy — not a `Platform.OS === 'web'` branch.

Create a Supabase Edge Function:

```ts
// supabase/functions/shifts-proxy/index.ts
Deno.serve(async (req) => {
  const { date } = await req.json();
  const response = await fetch(`https://api.example.com/shifts?date=${date}`, {
    headers: { Authorization: `Bearer ${Deno.env.get('API_KEY')}` },
  });
  const data = await response.json();
  return Response.json(data);
});
```

Call it identically from native and web:

```ts
const { data, error } = await supabase.functions.invoke('shifts-proxy', {
  body: { date: selectedDate },
});
```

---

## Fix 4 — Password toggle invisible on dark theme

Emoji characters ignore `color` styling and disappear on dark backgrounds. Replace with a text label in a shared container:

```tsx
<View style={{ flexDirection: 'row', borderWidth: 1, borderColor: theme.border, borderRadius: 8 }}>
  <TextInput
    style={{ flex: 1, paddingHorizontal: 12, color: theme.text }}
    secureTextEntry={!showPassword}
    value={password}
    onChangeText={setPassword}
  />
  <Pressable
    onPress={() => setShowPassword(p => !p)}
    style={{ justifyContent: 'center', paddingHorizontal: 12 }}
  >
    <Text style={{ color: theme.text, fontSize: 13 }}>
      {showPassword ? 'HIDE' : 'SHOW'}
    </Text>
  </Pressable>
</View>
```

The shared bordered container with `flexDirection: 'row'` prevents an internal dividing line between the input and the button.

---

## Fix 5 — Errors invisible on web, false "signed out" offline

- `Alert.alert` calls for one-way errors replaced with a root-mounted toast host + `showToast()`; native `Alert` kept for the camera-permission prompt.
- Write paths now call `supabase.auth.getSession()` (offline-safe) instead of `getUser()`; failures surface as a network toast, not a sign-out.
- Error helper extracts `.message` from any object shape and maps "failed to fetch" / "network request failed" to "You're offline — try again shortly".
- Onboarding redirect now keys off the server's `needs_onboarding` flag; the onboarding screen redirects already-onboarded users away.

## Remaining work

- Smoke test all icon-dependent screens on `npx expo start --web` after font preloading is added
- Verify the shifts proxy handles API error responses and surfaces them to the client
- Confirm dark-theme appearance on a physical Android device
