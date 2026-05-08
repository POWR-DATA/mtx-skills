# Example Output

## Confirmed source

Using `app_logo_master.png` — 2048x2048px RGBA with transparent background. Confirmed clean transparency (corner pixels alpha=0). Proceeding with this as the master for all exports.

---

## Planned outputs

**Large/detail assets** (exported directly from master):
- `logo_2048.png` — 2048x2048, transparent PNG
- `logo_1024.png` — 1024x1024, transparent PNG
- `logo_512.png` — 512x512, transparent PNG
- `logo_192.png` — 192x192, transparent PNG (Android/PWA launcher)
- `logo_120.png` — 120x120, transparent PNG (login hero/compact brand)

**Micro assets** (simplified central mark):
- `microicon.svg` — scalable SVG micro icon
- `microicon_32.png` — 32x32, transparent PNG
- `microicon_28.png` — 28x28, transparent PNG (Flet AppBar target)
- `favicon_32.png` — 32x32, transparent PNG

---

## Generated files

**Large/detail assets:**
- [Download logo_2048.png — 2048x2048 transparent PNG](sandbox:/mnt/data/logo_2048.png)
- [Download logo_1024.png — 1024x1024 transparent PNG](sandbox:/mnt/data/logo_1024.png)
- [Download logo_512.png — 512x512 transparent PNG](sandbox:/mnt/data/logo_512.png)
- [Download logo_192.png — 192x192 transparent PNG](sandbox:/mnt/data/logo_192.png)
- [Download logo_120.png — 120x120 transparent PNG](sandbox:/mnt/data/logo_120.png)

**Micro assets:**
- [Download microicon.svg — scalable SVG](sandbox:/mnt/data/microicon.svg)
- [Download microicon_32.png — 32x32 transparent PNG](sandbox:/mnt/data/microicon_32.png)
- [Download microicon_28.png — 28x28 transparent PNG](sandbox:/mnt/data/microicon_28.png)
- [Download favicon_32.png — 32x32 transparent PNG](sandbox:/mnt/data/favicon_32.png)

---

## Notes

- All PNGs exported using `PIL.Image.LANCZOS` resampling. Corner pixel alpha confirmed at 0 for all files.
- The micro icon uses the central mark only — fine detail from the full logo removed for readability at 28px.
- The SVG is a true vector redraw of the simplified mark, not a PNG embedded in an SVG wrapper.
- The 16x16 favicon was skipped at this stage — the 32x32 favicon is the practical minimum for modern browsers.

---

## Next recommended step

Place `logo_1024.png` in your project `assets/` folder as the Flet app icon source. For Android launcher icons, use `logo_192.png` or pass `logo_1024.png` to `flet build apk` — Flet generates the required launcher sizes automatically from the master icon.
