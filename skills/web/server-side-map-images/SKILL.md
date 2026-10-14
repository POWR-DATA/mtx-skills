---
name: server-side-map-images
description: Render static map images on the server for share cards, emails and previews, covering tile provider licensing, in-house styling, complete tile coverage of the view, and cache keys that survive write-once storage
author: PowerData
version: 1.0.0
license: MIT
---

# Server-Side Map Images

## Purpose

Produce static map images on the server (in a function, worker or build step) that are legal to use commercially, render without blank areas, and refresh when the rendering changes. The traps are not in drawing the map but around it: a basemap provider whose free terms or key requirements break server-side use, tile maths that leaves a strip of the frame uncovered, and a storage-backed cache that keeps serving the old image forever.

## When to use

When an app or site needs a map as a plain image rather than an interactive map: social share cards, email headers, PDF exports, list thumbnails or link previews. Also when an existing renderer shows placeholder tiles, a blank band at one edge, or an image that never changes after a styling fix.

## Inputs expected

Partial inputs are fine.

- Where the image is rendered (edge function, serverless worker, build script) and where it is stored or cached
- The view: centre and zoom, or bounds, plus output width and height in pixels
- The basemap provider currently used (if any) and whether the product is commercial
- The visual style wanted (dark, light, brand colours) and any overlays (markers, routes, glow)

---

## Guiding principles

- **Check the basemap's terms and key requirements for server-side use before writing code.** Some popular free basemaps return "API KEY REQUIRED" placeholder tiles when fetched from a server, and their free terms exclude commercial use. A renderer built on them works in a local test and then fails, or breaches terms, in production.
- **Prefer an open vector tile source that allows server-side use without a key.** OpenFreeMap vector tiles need no API key and permit server-side fetching. Style them in-house (colours, label density, which layers draw) rather than depending on a provider's hosted raster style, so the look is owned and stable.
- **Fetch every tile that touches the view, not the tile under the centre plus a guess.** Convert the view bounds (centre, zoom and output size) to tile coordinates, take the floor of the minimum and the floor of the maximum on each axis, and fetch the full inclusive range. A frame that extends past the fetched tiles renders as a blank strip along that edge.
- **Version the cache key whenever rendering changes.** Storage buckets used as image caches commonly never overwrite an existing object at the same key (or sit behind a CDN that will not revalidate). Include a rendering version suffix in the key and bump it with every style or logic change, so new requests miss the old objects instead of serving stale images indefinitely.
- **Verify against the live output, not the code path.** Fetch a rendered image from the deployed environment and look at it: placeholder text, blank strips and old styling are all visual faults that unit tests do not catch.

## Process

1. **Confirm the tile source** — read the provider's terms for server-side and commercial use and whether a key is required. Switch to OpenFreeMap vector tiles (or another source that permits it) if not.
2. **Define the style in-house** — background, water, roads, labels and any overlay colours, kept in the repository alongside the renderer.
3. **Compute tile coverage** — from centre, zoom and output size, derive the pixel bounds, convert to the inclusive tile range on both axes, and fetch every tile in it.
4. **Render and crop** — composite the tiles, apply the style and overlays, then crop to the exact output frame.
5. **Cache with a versioned key** — e.g. `<entity-id>-<view-hash>-v<n>.png`; bump `<n>` whenever rendering changes.
6. **Verify live** — request images at several zooms and positions (including near tile boundaries) from the deployed environment and inspect them.

## Output format

1. **Tile source decision** — provider, key requirement, server-side and commercial terms
2. **Style definition** — where it lives and what it controls
3. **Coverage method** — the bounds-to-tile-range calculation used
4. **Cache key scheme** — format and the current rendering version
5. **Verification** — images checked live, at which views, and what was seen

## Quality checklist

- [ ] Basemap terms allow server-side and commercial use; no key-required placeholder tiles
- [ ] Style defined in-house, not borrowed from a provider's hosted style
- [ ] Every tile intersecting the view is fetched; no blank strip at any edge or zoom
- [ ] Cache key includes a rendering version that is bumped on every rendering change
- [ ] Live images inspected from the deployed environment after each change

## Avoid

- Building on a basemap whose free terms exclude commercial use, or that needs a key the server does not send
- Fetching a fixed grid of tiles around the centre instead of computing coverage from the frame
- Fixing a rendering bug and expecting cached images to update in a bucket that never overwrites objects
- Declaring a fix done from logs or tests without looking at a live image

## Example usage

> "Our share cards render a dark map server-side. In production the tiles say API KEY REQUIRED, some images have an empty band down the right side, and after we changed the colours the old images are still being served. Fix the renderer properly."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
