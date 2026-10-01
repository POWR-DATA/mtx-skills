# Example Input

## Context

A two-person consultancy runs a daily LLM pipeline that publishes one health-topic card to social media each weekday. It drafts with an Opus-class model, fact-checks with a web-search tool call, screens for sensitive content, renders a branded image card with Pillow, and posts via a scheduled job. Nobody reviews a run unless it fails.

## Input provided

**Stages:** topic pick → draft (LLM) → fact-check (LLM + web search) → risk screen (keyword floor) → render card (Pillow) → publish. All automated; drafts persist as JSON in `drafts/`.

**Problems from the last two weeks:**

1. A post about a conference in San Diego was held by the risk screen as a "death story"
2. A rendered card showed `Glp-1` instead of `GLP-1`
3. Loading `drafts/` started crashing — one file has a `summary` field longer than its limit, written by the fact-check stage
4. Every image for the last ten days is some shade of brown; the brief says "warm golden-hour cinematic" and the renderer darkens the lower 70% for text contrast
5. Budget tracker says about $6 of credit left; the provider console says $1.93

**Brand constraints:** palette is teal/coral; acronyms that must survive casing include GLP-1, COVID-19, BMI, HbA1c; never auto-publish anything about a named individual's death.

**Ask:** make the pipeline trustworthy enough to keep running unattended.
