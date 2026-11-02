# Example Output

## 1. Tile source decision

| Item | Before | After |
|---|---|---|
| Provider | Free dark raster basemap | OpenFreeMap vector tiles |
| Key required server-side | Yes (placeholder tiles without it) | No |
| Commercial use on free terms | Excluded | Allowed |

## 2. Style definition

An in-house dark style lives next to the renderer: background, water, major roads and a reduced label set. The glow overlay colours are defined in the same file so one change updates both.

## 3. Coverage method

1. From centre, zoom and the 1200x630 frame, compute the frame's pixel bounds in world pixel space.
2. Divide by 256 and take `floor(min)` to `floor(max)` on each axis.
3. Fetch every tile in that inclusive range (the right-edge strip came from the fixed 3x3 grid stopping one column short).

## 4. Cache key scheme

`<entity-id>-<view-hash>-v2.png`. The version moved from implicit v1 to `v2` with the new tile source and style; it is bumped on every future rendering change. Old objects are left in place and simply no longer requested.

## 5. Verification

| Check | Result |
|---|---|
| Card at a central position, zoom 12 | Styled vector map, no placeholder |
| Card where the frame crosses a tile boundary on the right | No blank strip |
| Card for an entity rendered before the change | New key, new colours served |
