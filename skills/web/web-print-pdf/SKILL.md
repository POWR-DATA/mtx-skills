---
name: web-print-pdf
description: Produce reliable print and PDF output from an HTML page with print-specific CSS — pagination, image cropping, equal columns, running footers, and colour
author: PowerData
version: 1.2.0
license: MIT
---

# Web Print PDF

## Purpose

Turn an HTML page into clean, predictable print/PDF output using `@media print` CSS — controlling pagination, image cropping, column heights, running footers, and background colour so the printed result matches the design instead of the browser's default reflow.

## When to use

When a web page must also produce a polished PDF or printout (invoices, reports, certificates, one/two-page summaries) via the browser's print engine (Ctrl+P → Save as PDF). Apply when print output crops wrongly, spills onto blank pages, drops background colours, breaks awkwardly across pages, or inherits mobile-responsive reordering that should never reach paper. This covers the print-CSS layer, not server-side PDF generation.

## Inputs expected

- The HTML page (or component) to be printed
- The target page count / layout (e.g. single page, fixed two-page)
- Which elements must keep background colour or images in print
- Any header/footer that should repeat on every printed page
- Any responsive (mobile) reordering the page does on screen that must not leak into print

---

## Guiding principles

- **`object-fit: cover` is unreliable in Chrome's print engine — crop with a wrapper instead.** In print, `object-fit: cover` on an `<img>` is often ignored and the full image renders at natural size. Wrap the image in a `<div>` with a fixed height and `overflow: hidden`, and let the container clip it — overflow clipping is handled by the layout engine and works consistently in print.
- **Match adjacent column heights with grid stretch, not pixel guessing.** To make a photo column fill the height of the neighbouring text column, apply `align-items: stretch` to the grid container in `@media print` and `height: 100%` to the photo wrapper so it fills the stretched grid item. This removes all manual print-height tweaking.
- **A `position: fixed` element in `@media print` becomes a running footer on *every* page.** `position: fixed; bottom: 0; left: 0; right: 0` repeats at the bottom of every printed page (and prevents a footer overflowing onto a blank final page). Add `padding-bottom` to the main content equal to the footer height so content never prints underneath it.
- **Force page breaks explicitly, and protect elements from splitting.** `break-before: page` (with the legacy `page-break-before: always`) on a section forces a clean break before it — the basis of reliable fixed-page layouts. Pair with `break-inside: avoid` (and `page-break-inside: avoid`) on cards/entries so they don't split across pages.
- **Background colours, gradients, and dot patterns are stripped in print unless forced.** Browsers drop backgrounds in print mode by default. Add `-webkit-print-color-adjust: exact; print-color-adjust: exact` to any element whose background colour or image must appear in the PDF.
- **Always include both the modern and legacy break properties.** Print CSS support is uneven across engines; write `break-inside`/`break-before` *and* their `page-break-*` equivalents together so the layout holds in Chrome, Firefox, and Safari print.
- **Reorder content across CSS grid cells on mobile with `display: contents`, not duplicated markup.** Set the grid's column wrappers to `display: contents` (flattening their children into the grid's flow), then apply flex `order` to those now-direct children. One copy of the markup serves screen, mobile, and print.
- **Scope every mobile/responsive reorder rule to `@media screen and (max-width: N)` so it can never reach print** — print media never matches a `screen` query. Add explicit `@media print` resets (`order: 0`, `display: block`, re-assert the grid, hide any new interactive buttons) as belt-and-suspenders against browsers leaking screen rules.
- **CSS cannot target "the bottom of the last printed page" — pin it with flex.** Make the main container a flex column with `min-height: calc(N * <printable page height> - K)` and give the element `margin-top: auto`. K absorbs the space lost at page breaks and must be tuned by rendering: too small and the document gains an extra page, too large and the element floats mid-page. Re-tune K whenever content changes the page count or break positions. See *Last-page pin* in [`reference.md`](reference.md).
- **Print CSS that strips a link's colour and underline does not stop it being clickable.** Chromium's print-to-PDF keeps anchors live, so styling links as plain text for print costs you nothing — and wrapping a print-only logo or QR image in an anchor makes that image a clickable link in the PDF too.
- **Generate and verify PDFs headlessly, not by eye.** Render with `--headless=new --disable-gpu --no-pdf-header-footer --run-all-compositor-stages-before-draw --virtual-time-budget=8000 --print-to-pdf=<out>`, then check page count and rasterise pages programmatically (pymupdf) rather than trusting a visual preview. Every layout change that could move a page break needs a re-render and a page-count check.

## Process

1. **Add a dedicated `@media print` block** — do not rely on screen CSS for print; screen layout reflows unpredictably on paper.
2. **Fix image cropping** — replace `object-fit` cropping with fixed-height `overflow: hidden` wrappers.
3. **Equalise columns** — set `align-items: stretch` on print grids and `height: 100%` on the elements that must fill.
4. **Set pagination** — add `break-before: page` where pages must split and `break-inside: avoid` on atomic blocks.
5. **Add running header/footer** — `position: fixed` in `@media print`, with matching `padding` on the content.
6. **Preserve colour** — add `print-color-adjust: exact` to elements whose backgrounds must survive.
7. **Isolate screen-only rules** — scope responsive reorders (`display: contents` + `order`) to `@media screen and (max-width: N)`, then add `@media print` resets (`order: 0`, `display: block`, grid re-asserted, screen-only buttons hidden).
8. **Verify in the print dialog** — Ctrl+P → Save as PDF, checking every page boundary, crop, and background.
8. **Render headlessly and verify** — produce the PDF with the headless flags above, assert the page count, and rasterise the pages to confirm breaks and pinned elements landed where intended.

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
- [ ] Responsive reorder rules scoped to `@media screen and (...)`, with `@media print` resets (`order: 0`, `display: block`, grid re-asserted, screen-only buttons hidden)
- [ ] Output verified in Ctrl+P → Save as PDF, every page checked
- [ ] Any bottom-of-last-page element pinned with the flex + `min-height: calc(...)` + `margin-top: auto` pattern, with K re-tuned after content changes
- [ ] Page count and rendered pages verified programmatically after every layout change, not from a preview

## Avoid

- Relying on `object-fit: cover` for print image cropping — Chrome ignores it; use a clipping wrapper
- Pixel-guessing column heights — use grid `align-items: stretch` instead
- Using `position: fixed` for a footer without adding content `padding-bottom` — content prints underneath it
- Writing only modern `break-*` (or only legacy `page-break-*`) properties — include both for cross-browser print
- Expecting background colours to print by default — they are stripped without `print-color-adjust: exact`
- Judging print output from the screen view — always verify in the actual print/PDF dialog
- Putting mobile reorder rules in a bare `@media (max-width: N)` query — it also matches print; write `@media screen and (max-width: N)` and add print resets
- Duplicating markup to reorder columns on mobile — use `display: contents` on the wrappers plus `order` on the children
- Trying to target the last printed page with CSS selectors — pin the element with the flex/min-height pattern instead
- Removing link styling for print out of fear of losing clickability — Chromium keeps anchors live in the PDF
- Signing off a PDF from a visual preview — assert the page count and rasterise the pages

## Example usage

> "This HTML report needs to export as a clean two-page PDF via Ctrl+P. Right now the photo crops wrong, the coloured header prints white, the footer only shows on page one, and cards split across the page break. Give me the `@media print` CSS to fix it."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
