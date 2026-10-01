# Example Input

## Context

A content pipeline lives entirely in one GitHub repository. A `discover` job picks and drafts the day's item at 06:00 UTC (it calls a paid LLM API), and two `publish` jobs post at 09:00 and 17:00 UTC. State for each day is committed back to the repo as `state/<date>.json` by the workflow itself using `GITHUB_TOKEN`. Approvals happen by commenting on a tracking issue.

## Input provided

**Workflow triggers today:** `schedule` only (three cron entries), plus `workflow_dispatch` with no inputs.

**What went wrong this week:**

1. Tuesday: all three scheduled slots were skipped entirely. Wednesday's 06:00 run started at 08:05.
2. Clicking "Run workflow" to test re-ran `discover`, which called the paid API again and overwrote Wednesday's already-approved pick.
3. The 17:00 publish job failed at startup with `LLM_API_KEY is required` — it only reads state and posts, and never calls the model. The shared `build_context()` demands every key.
4. A comment reading "closing this off — details in Issue #8" was parsed as `approve pick 8` and published the wrong item.
5. Local pushes to `main` keep rejecting because the workflow has committed `state/*.json` in between.

**Constraints:** the repo is private; the team wants approvals to stay in issue comments; budget for external tooling is effectively zero.

**Ask:** make the timing dependable and stop a stray trigger from doing real work twice.
