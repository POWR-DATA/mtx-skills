# Example Output — Web Print PDF

## 1. Print CSS block

```css
@media print {
  /* preserve colour */
  .header-band, .card-badge {
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* running footer on every page */
  .report-footer { position: fixed; bottom: 0; left: 0; right: 0; }
  .report-body   { padding-bottom: 24mm; }   /* = footer height */

  /* equal-height photo/text columns */
  .two-col { display: grid; grid-template-columns: 1fr 1fr; align-items: stretch; }
  .two-col .photo-wrap { height: 100%; overflow: hidden; }  /* crop without object-fit */
  .two-col .photo-wrap img { width: 100%; height: 100%; }

  /* pagination */
  .detail-section { break-before: page; page-break-before: always; }
  .summary-card   { break-inside: avoid; page-break-inside: avoid; }
}
```

## 2. Structural changes

- Wrapped the header photo in `<div class="photo-wrap">` (fixed height + `overflow: hidden`) instead of `object-fit: cover`.
- No other markup changes — the two-column and card structures already existed.

## 3. Pagination map

- **Page 1:** header band + summary section (cards kept intact via `break-inside: avoid`)
- **Forced break:** `.detail-section` starts page 2 (`break-before: page`)
- **Page 2:** detail content
- Footer repeats on both pages; `padding-bottom` reserves its space

## 4. Verification notes

- Ctrl+P → Save as PDF: exactly two pages, no stray blank page
- Header photo cropped to the banner; coloured header band and badges retain colour
- Footer present on both pages; no card split across the break
- Photo and text columns render equal height
