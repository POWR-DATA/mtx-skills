# Demo Seed Data

Build demo and screenshot data that is safe to publish and repeatable to rebuild — reserved fictitious identifiers, curated content encoded in the seed, recency-aware ordering, and the expected noise after a reseed.

## What this skill does

Covers both halves of demo data: making it safe to publish, and making it reproducible. Safety means identifiers from ranges reserved for fiction rather than numbers that merely look fake, and names checked against the public registers. Reproducibility means the exact content a screenshot was composed around lives in `seed()` and `teardown()`, so a reset rebuilds the same world rather than destroying months of hand-built state.

## When to use it

- Preparing store screenshots or a product walkthrough video
- A demo environment is about to be rebuilt and nobody can reproduce what was there
- Demo data contains invented phone numbers, ABNs or registration numbers
- New showcase content has pushed the curated items out of a recency-sorted list
- A reseed produces refresh-token errors and it is unclear whether something broke

## Example use cases

- Replace invented contact details with ACMA-reserved numbers and a checksum-failing ABN
- Move hand-built screenshot content into a repeatable `seed()` before a store submission
- Pin curated entries as the newest records so later demo data cannot bury them
- Explain the post-reseed `Invalid Refresh Token` error as expected rather than a defect

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the screens to capture, the data model behind them and the jurisdiction the demo data must be safe in, then work through the structured output. Pairs with [Screen Recording Web Guides](../../web/screen-recording-web-guides/) when the output is a video, and with the store-listing skills when it is screenshots.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
