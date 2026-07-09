# Example Input — Web Print PDF

> This HTML report needs to export as a clean two-page PDF via Ctrl+P → Save as PDF. It looks right on screen but prints badly.

**The page:**
- A single-page HTML report with a coloured header band, a two-column body (photo + text), a grid of summary cards, and a footer with contact details
- Styled with a normal screen stylesheet; no print styles yet
- Target: a fixed **two-page** PDF (summary on page 1, detail on page 2)

**What's going wrong in print:**
- The header photo is meant to be cropped to a banner, but the full image prints at natural size (screen uses `object-fit: cover`)
- The coloured header band and card badges print white — the background colour is dropped
- The footer only appears at the bottom of page 1, not page 2
- Summary cards split across the page break, with half a card at the bottom of a page
- The photo column and text column are different heights on paper

**What I need:**
- The `@media print` CSS (and any wrapper markup) to fix all of the above
- A reliable forced break between the summary and detail sections
