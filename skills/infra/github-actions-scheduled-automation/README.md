# GitHub Actions Scheduled Automation

Run time-sensitive scheduled work on GitHub Actions — external dispatch when cron slips, idempotency guards for every trigger, per-job secret validation, and safe issue-comment chatops.

## What this skill does

GitHub's `schedule` trigger is best-effort: slots get skipped and runs arrive late, while dispatched runs start within seconds. This skill covers compensating with an external dispatcher, then the consequences of making a workflow dispatchable — every trigger now does real work, so guards and idempotency have to cover all of them, not just the cron. It also covers scoping secrets per job and driving a workflow from issue comments without a stray sentence firing a command.

## When to use it

- A scheduled workflow misses slots or runs hours late, and the timing matters
- A manual or test dispatch re-ran paid work or overwrote the day's state
- A job fails demanding a credential it never uses
- You want to approve or control runs from issue comments
- The workflow commits state back to the repo and your pushes keep conflicting

## Example use cases

- Move a daily generation job onto an external dispatcher with a single-repo fine-grained PAT
- Add an "already done today" guard that applies to manual dispatches as well as cron
- Split a shared startup validator so publish jobs stop requiring the LLM key
- Gate an approval command on open-issue state, author association and an exact short match

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — dispatches API call and PAT scope, guard YAML, per-job secret validation, comment gating |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt. Provide the workflow's triggers, what each run costs or overwrites, and where state lives, then work through the structured output. Load `reference.md` for the dispatch call and the guard snippets.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
