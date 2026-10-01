# AI Social Content Pipeline

Build an automated LLM pipeline that drafts, fact-checks and renders social posts — validation on every edit, defensible risk classification, correct typography and acronyms, image briefs that do not come out brown, and spend tracking that matches the provider.

## What this skill does

Covers the failure modes that make an unattended content pipeline quietly wrong rather than obviously broken: drafts edited around their own validation, a risk classifier that flags place names, Title Case that mangles acronyms like GLP-1, image briefs that produce uniformly brown cards, and an in-code spend estimate that drifts three times optimistic because crashed runs book nothing.

## When to use it

- An LLM generates content that publishes with little or no human review
- The pipeline moves from on-demand to scheduled, so nobody sees each run
- A risk or safety classifier is holding posts that are obviously harmless
- Rendered cards show wrong casing, clipped descenders, or all look the same
- The budget tracker and the provider console disagree

## Example use cases

- Add re-validation after a fact-check stage edits a draft past its length limit
- Replace prefix keyword matching with whole-word stems and a false-positive test file
- Fix a Title Case helper that lowercases `GLP-1`, `COVID-19` and `5G`
- Rewrite image briefs for named colours and concrete objects, and darken only the text panel

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — re-validation, stem regex, acronym-aware casing, glyph-bounds gradient, cost booking |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Describe the pipeline stages, the model and the brand constraints, then work through the structured output. Load `reference.md` for the concrete regex, casing and Pillow snippets.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
