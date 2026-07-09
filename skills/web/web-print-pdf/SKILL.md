---
name: web-print-pdf
description: Produce reliable print and PDF output from an HTML page with print-specific CSS — pagination, image cropping, equal columns, running footers, and colour
author: PowerData
version: 1.0.0
license: MIT
---

# Web Print PDF

## Purpose

Turn an HTML page into clean, predictable print/PDF output using `@media print` CSS — controlling pagination, image cropping, column heights, running footers, and background colour so the printed result matches the design instead of the browser's default reflow.

## When to use

When a web page must also produce a polished PDF or printout (invoices, reports, certificates, one/two-page summaries) via the browser's print engine (Ctrl+P → Save as PDF). Apply when print output crops wrongly, spills onto blank pages, drops background colours, or breaks awkwardly across pages. This covers the print-CSS layer, not server-side PDF generation.

## Inputs expected

- The HTML page (or component) to be printed
- The target page count / layout (e.g. single page, fixed two-page)
- Which elements must keep background colour or images in print
- Any header/footer that should repeat on every printed page

---

## Guiding principles

- **`object-fit: cover` is unreliable in Chrome's print engine — crop with a wrapper instead.** In print, `object-fit: cover` on an `<img>` is often ignored and the full image renders at natural size. Wrap the image in a `<div>` with a fixed height and `overflow: hidden`, and let the container clip it — overflow clipping is handled by the layout engine and works consistently in print.
- **Match adjacent column heights with grid stretch, not pixel guessing.** To make a photo column fill the height of the neighbouring text column, apply `align-items: stretch` to the grid container in `@media print` and `height: 100%` to the photo wrapper so it fills the stretched grid item. This removes all manual print-height tweaking.
- **A `position: fixed` element in `@media print` becomes a running footer on *every* page.** `position: fixed; bottom: 0; left: 0; right: 0` repeats at the bottom of every printed page (and prevents a footer overflowing onto a blank final page). Add `padding-bottom` to the main content equal to the footer height so content never prints underneath it.
- **Force page breaks explicitly, and protect elements from splitting.** `break-before: page` (with the legacy `page-break-before: always`) on a section forces a clean break before it — the basis of reliable fixed-page layouts. Pair with `break-inside: avoid` (and `page-break-inside: avoid`) on cards/entries so they don't split across pages.
- **Background colours, gradients, and dot patterns are stripped in print unless forced.** Browsers drop backgrounds in print mode by default. Add `-webkit-print-color-adjust: exact; print-color-adjust: exact` to any element whose background colour or image must appear in the PDF.
- **Always include both the modern and legacy break properties.** Print CSS support is uneven across engines; write `break-inside`/`break-before` *and* their `page-break-*` equivalents together so the layout holds in Chrome, Firefox, and Safari print.

## Process

1. **Add a dedicated `@media print` block** — do not rely on screen CSS for print; screen layout reflows unpredictably on paper.
2. **Fix image cropping** — replace `object-fit` cropping with fixed-height `overflow: hidden` wrappers.
3. **Equalise columns** — set `align-items: stretch` on print grids and `height: 100%` on the elements that must fill.
4. **Set pagination** — add `break-before: page` where pages must split and `break-inside: avoid` on atomic blocks.
5. **Add running header/footer** — `position: fixed` in `@media print`, with matching `padding` on the content.
6. **Preserve colour** — add `print-color-adjust: exact` to elements whose backgrounds must survive.
7. **Verify in the print dialog** — Ctrl+P → Save as PDF, checking every page boundary, crop, and background.

## Output format

1. **Print CSS block** — the complete `@media print` rules
2. **Structural changes** — any wrapper `<div>`s added for cropping or column stretch
3. **Pagination map** — where breaks are forced and which blocks are kept intact
4. **Verification notes** — confirmed page count, crops, footer repetition, and colour retention in the PDF

## Quality checklist

- [ ] All print styling lives in a dedicated `@media print` block
- [ ] Image cropping uses fixed-height `overflow: hidden` wrappers, not `object-fit`
- [ ] Equal-height columns use grid `align-items: stretch` + `height: 100%`
- [ ] Forced breaks use both `break-before: page` and `page-break-before: always`
- [ ] Atomic blocks use both `break-inside: avoid` and `page-break-inside: avoid`
- [ ] Running footers use `position: fixed` with matching content `padding-bottom`
- [ ] Colour-critical elements set `-webkit-print-color-adjust: exact; print-color-adjust: exact`
- [ ] Output verified in Ctrl+P → Save as PDF, every page checked

## Avoid

- Relying on `object-fit: cover` for print image cropping — Chrome ignores it; use a clipping wrapper
- Pixel-guessing column heights — use grid `align-items: stretch` instead
- Using `position: fixed` for a footer without adding content `padding-bottom` — content prints underneath it
- Writing only modern `break-*` (or only legacy `page-break-*`) properties — include both for cross-browser print
- Expecting background colours to print by default — they are stripped without `print-color-adjust: exact`
- Judging print output from the screen view — always verify in the actual print/PDF dialog

## Example usage

> "This HTML report needs to export as a clean two-page PDF via Ctrl+P. Right now the photo crops wrong, the coloured header prints white, the footer only shows on page one, and cards split across the page break. Give me the `@media print` CSS to fix it."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
