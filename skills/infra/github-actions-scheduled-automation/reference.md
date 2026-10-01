# GitHub Actions Scheduled Automation — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## External dispatch

Point an external scheduler (cron-job.org works and is free) at the workflow's dispatches endpoint. Expect `204 No Content`.

```text
POST https://api.github.com/repos/<owner>/<repo>/actions/workflows/<workflow>.yml/dispatches
Accept: application/vnd.github+json
Authorization: Bearer <fine-grained-pat>
X-GitHub-Api-Version: 2022-11-28
Content-Type: application/json

{"ref":"main"}
```

| Response | Meaning |
|---|---|
| 204 | accepted, run queued |
| 401 | bad or expired token |
| 404 | token cannot see the repo (wrong scope) |
| 422 | bad body — usually a missing or wrong `ref` |

PAT scope: fine-grained, **this repository only**, Actions read and write. Nothing else.

## Guard every trigger, not just schedule

```yaml
on:
  schedule:    [{ cron: "0 20 * * *" }]     # backup only
  workflow_dispatch:
    inputs:
      force: { description: "Re-run even if today is done", type: boolean, default: false }

jobs:
  discover:
    steps:
      - id: guard
        run: |
          if [ -f state/$(date -u +%F).json ] && [ "${{ inputs.force }}" != "true" ]; then
            echo "done=true" >> "$GITHUB_OUTPUT"      # applies to EVERY trigger
          fi
      - if: steps.guard.outputs.done != 'true'
        run: python discover.py                       # the step that costs money
```

## Per-job secret validation

```python
def build_context(*, needs_llm: bool = False):
    require("SUPABASE_URL")
    if needs_llm:                      # publish jobs never call the LLM; don't demand its key
        require("LLM_API_KEY")
```

## Comment command gating

```yaml
if: >
  github.event.issue.state == 'open' &&
  contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)
```

```python
CMD = re.compile(r"^(approve|reject)\s+pick\s+(\d+)$", re.I)
body = comment.strip()
if len(body) > 40 or not CMD.match(body):
    sys.exit(0)        # "closing — see Issue #8" must not parse as "approve pick 8"
```

## Pushing around the bot's own state commits

```bash
git pull --rebase origin main    # the workflow commits state with GITHUB_TOKEN between your pushes
git push
```
