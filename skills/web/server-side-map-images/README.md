# Server-Side Map Images

Render static map images on the server for share cards, emails and previews, covering tile provider licensing, in-house styling, complete tile coverage of the view, and cache keys that survive write-once storage.

## What this skill does

Many products need a map as a plain image rather than an interactive widget. This skill covers the parts that go wrong around the drawing itself: choosing a tile source that genuinely allows server-side and commercial use without a key, owning the style, computing every tile the frame touches so no edge renders blank, and versioning the cache key so a storage bucket that never overwrites objects cannot keep serving old images.

## When to use it

- Generating social share cards, email headers, PDF exports or thumbnails that include a map
- Production map images show "API KEY REQUIRED" or other placeholder tiles
- A blank strip appears along one edge of some rendered images
- A styling fix is deployed but the old images keep appearing

## Example use cases

- Move a server-side renderer from a key-gated free basemap to OpenFreeMap vector tiles with an in-house dark style
- Replace a fixed 3x3 tile fetch with a bounds-based tile range calculation
- Introduce a `-v<n>` rendering version into the image cache key of a storage bucket

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide where the image is rendered and cached, the view and output size, the current tile provider and the style wanted, then follow the structured output. Always finish by inspecting live images from the deployed environment.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
