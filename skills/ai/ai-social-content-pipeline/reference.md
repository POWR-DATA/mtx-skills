# AI Social Content Pipeline — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## Re-validate after a programmatic edit

`model_copy(update=...)` skips validation, so a too-long field is written and every later load raises.

```python
# wrong: writes past the field's own limit
draft = draft.model_copy(update={"summary": checked})

# right: round-trips through validation
draft = Draft.model_validate(draft.model_dump() | {"summary": checked})
```

```python
def load_drafts(folder):
    for f in sorted(folder.glob("*.json")):
        try:
            yield Draft.model_validate_json(f.read_text(encoding="utf-8"))
        except ValidationError as e:
            log.warning("skipping %s: %s", f.name, e)      # one bad file must not stop the run
```

## Whole-word stems with inflections

```python
STEMS = {"die": r"(?:s|d)?", "kill": r"(?:s|ed|ing)?", "minor": r"s?"}
PATTERN = re.compile(r"\b(" + "|".join(f"{s}{suf}" for s, suf in STEMS.items()) + r")\b", re.I)
# \bdie matches "San Diego"; \b(?:die|dies|died)\b does not
```

## Acronym-aware Title Case

```python
ACRONYMS = {"GLP-1", "COVID-19", "HbA1c", "BMI"}

def title_case(text):
    out = []
    for tok in text.split():
        if tok in ACRONYMS or (tok.isupper() and any(c.isdigit() for c in tok)):
            out.append(tok)                 # whole hyphenated token, checked before any casing
        else:
            out.append(tok.capitalize())
    return " ".join(out)
```

## Gradient fill from glyph ink bounds

```python
x0, y0, x1, y1 = font.getbbox(word)          # ink bounds, not the line-height box
card.paste(gradient.crop((0, 0, x1 - x0, y1 - y0)), (x + x0, y + y0), mask=word_mask)
# using the line box here clips descenders — "Group" loses its "p"
```

## Booking spend so a crash still counts

```python
cost = 0.0
try:
    resp = client.messages.create(...)
    cost = estimate_cost(resp.usage)
finally:
    ledger.record(run_id, cost)              # a crashed run books what it spent
```
