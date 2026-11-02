# Expo React Native App — Reference Excerpts

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Deep-link opening on a map screen

A shared link must open what it names regardless of the viewport, and the on-mount default fly must stand down when the screen was opened explicitly.

```tsx
const { lat, lng, item } = useLocalSearchParams<{ lat?: string; lng?: string; item?: string }>();
// Explicit opening: coordinates, an item id, or a fly token left by a list tap
const openingFlyDone = useRef(Boolean((lat && lng) || item || hasPendingFlyToken()));

// Load the linked item by id — never resolve it from items loaded for the current viewport
useEffect(() => {
  if (!item) return;
  supabase.rpc('<item>_by_id', { p_id: item }).then(({ data }) => {
    if (!data) return;
    upsertItems([data]);        // into the local item store
    setSelectedItem(data);      // card state independent of the viewport
    flyTo(data.lat, data.lng);
  });
}, [item]);

// On-mount default: only when nothing explicit asked for a position
useEffect(() => {
  if (openingFlyDone.current) return;
  openingFlyDone.current = true;
  flyToDefaultAreaOrDeviceLocation();
}, []);
```

## Sign-out cleanup

On web, device storage is `localStorage` shared by every account that signs in on that browser.

```ts
const itemCacheKey = (userId: string) => `item-cache:${userId}`; // holds isMine / myVote
const PER_USER_KEYS = ['unlocks', 'signup-default-area', 'session-id'];

export async function signOut() {
  const userId = (await supabase.auth.getSession()).data.session?.user.id;
  await supabase.auth.signOut();
  await AsyncStorage.multiRemove([...PER_USER_KEYS, ...(userId ? [itemCacheKey(userId)] : [])]);
}
```

## Production web export gate

`EXPO_PUBLIC_*` values are inlined when the bundle is exported, so the env files present at export time decide which backend production talks to.

```bash
# Production export: only .env.production may supply EXPO_PUBLIC_* values (no dev-pointing .env in play)
npx expo export --platform web
# Gate: refuse to deploy if the dev backend host was inlined
if grep -rq "<dev-project-ref>" dist/; then echo "dev backend in production bundle"; exit 1; fi
```

## Release-proof switches

For a switch that must hold on binaries that may never update (e.g. a seasonal freeze on writes).

```ts
const FREEZE_FROM = new Date('<yyyy-mm-dd>T00:00:00Z'); // built-in calendar fallback

async function writesFrozen(): Promise<boolean> {
  try {
    const value = await fetchServerFlag('writes_frozen');   // 1. fresh server read
    await cache.set('writes_frozen', value);
    return value;
  } catch {
    const cached = await cache.get('writes_frozen');        // 2. last good cache
    if (cached !== undefined) return cached;
    return Date.now() >= FREEZE_FROM.getTime();              // 3. built-in date
  }
}
// The server refuses the write during the freeze whatever the client resolved.
```
