# Web Print PDF — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Last-page pin

Pins a print-only element to the bottom of the final page. `K` absorbs space lost at page breaks and is tuned by rendering — too small adds a page, too large floats the element mid-page.

```css
@media print {
  main.profile-page { display: flex; flex-direction: column; box-sizing: border-box;
                      min-height: calc(3 * 273mm - 58mm); } /* A4 minus 12mm margins; K=58mm for this layout */
  .qr-tail-wrap { margin-top: auto; }
}
```

## Headless render and verification

```bash
msedge --headless=new --disable-gpu --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw --virtual-time-budget=8000 \
  --print-to-pdf="<out.pdf>" "<url-or-file>"
```

```python
import fitz                                  # pymupdf
doc = fitz.open("<out.pdf>")
assert doc.page_count == 3, doc.page_count   # fail the build on an unexpected extra page
doc[doc.page_count - 1].get_pixmap(dpi=120).save("last-page.png")   # eyeball the pinned element
```
