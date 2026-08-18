# Web Print PDF

Produce reliable print and PDF output from an HTML page with print-specific CSS.

## What this skill does

Guides the `@media print` CSS needed to turn a web page into clean PDF/print output — controlling pagination, image cropping, equal column heights, running footers, and background colour. It focuses on the print-engine quirks (ignored `object-fit`, stripped backgrounds, footers repeating or not) that make browser print output diverge from the on-screen design.

## When to use it

- A web page must also export as a polished PDF via Ctrl+P → Save as PDF
- Print output crops images wrongly or drops background colours
- Content spills onto a blank final page, or cards split across page breaks
- A header/footer must repeat on every printed page
- A mobile-responsive reorder (photo-first on phones) must not leak into the printed page

## Example use cases

- Export an HTML report as a fixed two-page PDF
- Crop photos reliably in print without `object-fit`
- Add a running footer that appears on every page
- Keep coloured headers and badges visible in the printed output

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Load `SKILL.md` into your AI tool along with the HTML page and your target layout (page count, which elements keep colour, any repeating footer).

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
