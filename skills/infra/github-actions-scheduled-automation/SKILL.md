---
name: github-actions-scheduled-automation
description: Run time-sensitive scheduled work on GitHub Actions — external dispatch when cron slips, idempotency guards for every trigger, per-job secret validation, and safe issue-comment chatops
author: PowerData
version: 1.0.0
license: MIT
---

# GitHub Actions Scheduled Automation

## Purpose

Make a scheduled GitHub Actions workflow actually run when it is supposed to, and make every run safe to repeat — covering the external dispatcher that compensates for best-effort cron, the guards that stop a stray dispatch doing paid work twice, per-job secret validation, and the rules for driving a workflow from issue comments without a stray sentence triggering it.

## When to use

When a workflow does work that matters at a particular time — a daily generation or discovery step, a publish slot, a billing or reporting job — and especially when it costs money or overwrites state. Apply when scheduled runs are arriving late or not at all, when a manual test re-ran real work, or before wiring any comment-driven control channel.

## Inputs expected

Partial inputs are fine — infer the rest from the workflow file.

- The workflow's triggers and what each run actually does (and what it costs)
- Which steps are safe to repeat and which overwrite state
- Where run state is stored (repo file, artifact, external store) and who writes it
- Whether a human control channel is wanted, and who should be allowed to use it

---

## Guiding principles

- **GitHub's `schedule` trigger is best-effort — do not build a time-sensitive job on it alone.** On one day every discovery and publish slot was skipped and the only scheduled run arrived two hours late, while `workflow_dispatch` and `issue_comment` runs started within seconds. Call the workflow's dispatches API from an external scheduler (cron-job.org works and is free) with a fine-grained PAT scoped to the single repo with Actions read/write, and keep the repo crons only as a backup. See *External dispatch* in [`reference.md`](reference.md).
- **Once anything can dispatch the workflow, every run does real work.** A test dispatch re-ran a paid daily discovery and overwrote that day's state. Put the "already done today" guard in the workflow for **all** triggers, not only `schedule`, with an explicit `force` input to override it deliberately — and make publish jobs idempotent so an extra slot is harmless rather than duplicated.
- **Validate only the secrets a job actually uses.** A scheduled publish job that never calls the LLM still failed because the shared context builder insisted on the LLM API key, which that job's `env` did not pass. Either give every job the secrets the shared startup code checks, or make startup validate per job — the second is usually right, because it keeps unrelated credentials out of jobs that do not need them.
- **Gate comment-driven workflows on issue state and author.** Require `github.event.issue.state == 'open'` and check the author association before acting on anything.
- **Parse only short replies as commands.** A closing note that mentioned "Issue #8" was parsed as "approve pick 8" and acted on. Treat a comment as a command only when it is short and matches the command grammar exactly; ignore anything longer.
- **Expect to rebase around the bot's own commits.** State written back by the workflow with `GITHUB_TOKEN` lands between local pushes, so always `git pull --rebase` before pushing, and expect JSON state files to conflict — keep them small and machine-written so the conflict is trivial to resolve.

## Process

1. **Classify the work** — what must happen on time, what costs money, what overwrites state.
2. **Keep the repo cron as a backup**, then add an external scheduler calling the dispatches API with a fine-grained, single-repo PAT.
3. **Write the idempotency guard** against the stored state, applying to every trigger, with a `force` input for deliberate re-runs.
4. **Make publish steps idempotent** so a duplicate slot is a no-op rather than a double post.
5. **Scope secrets per job** — pass only what the job uses, and make shared startup validate only that.
6. **If adding chatops**, gate on open-issue state plus author association, and accept only short, exactly-matching commands.
7. **Handle bot state commits** — `git pull --rebase` before every push; keep the state file minimal.
8. **Verify the dispatch path end to end** — expect `204 No Content`, and confirm the guard blocks a second same-day run.

## Output format

1. **Trigger plan** — repo cron (backup), external dispatcher, manual and comment triggers
2. **Dispatch setup** — API call, PAT scope, scheduler configuration
3. **Guard logic** — state checked, which triggers it applies to, how `force` overrides it
4. **Secret matrix** — which job gets which secret, and what startup validates
5. **Chatops rules** — allowed authors, issue state, command grammar, rejected examples
6. **Verification** — dispatch returns 204, duplicate run blocked, publish step proven idempotent

## Quality checklist

- [ ] Time-sensitive runs driven by an external dispatcher, with repo cron retained as backup
- [ ] PAT is fine-grained, scoped to one repo, Actions read/write only
- [ ] "Already done" guard applies to every trigger, not just `schedule`, with an explicit `force` input
- [ ] Publish steps idempotent — a repeat slot does not double-post
- [ ] Each job receives only the secrets it uses; shared startup validates per job
- [ ] Comment commands require an open issue, an allowed author association, and an exact short match
- [ ] `git pull --rebase` before pushing, given the workflow writes state commits itself

## Avoid

- Relying on `schedule` alone for anything time-sensitive — slots are skipped and runs arrive late
- Guarding only the `schedule` trigger, so a manual or external dispatch re-does paid work
- A broad-scoped or classic PAT for the dispatch call — scope it to the one repo
- Shared startup code that demands every credential regardless of the job
- Treating any comment containing a number as a command — a closing note triggered an approval
- Acting on comments from a closed issue or an unverified author
- Pushing without rebasing when the workflow commits state with `GITHUB_TOKEN`

## Example usage

> "Our daily content workflow missed every slot yesterday and the one run that fired was two hours late. When I hit the test button this morning it re-ran the paid discovery step and overwrote today's picks. A publish job also failed asking for an LLM key it never uses, and a comment where I wrote 'closing — see Issue #8' approved pick 8. Make this reliable."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
