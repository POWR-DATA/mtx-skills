# Windows CLI Gotchas

Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, JSON payloads, stderr and exit codes, MSYS path mangling, and which shell to use for which tool.

## What this skill does

Collects the shell-mechanics rules that make `az`, `gh`, `git`, `supabase`, `curl.exe`, `python` and `npx` behave on Windows, especially when an AI agent is driving them: PowerShell 5.1's colon-in-string and `2>&1` traps, handing JSON to `curl.exe` via a file, Git Bash rewriting `/c/Users/...` paths for non-MSYS executables, splitting tools by shell, and reading real success from output rather than misleading exit codes.

## When to use it

- A native command "fails" in PowerShell 5.1 with NativeCommandError but clearly did its job
- `curl.exe -d '{...}'` reports a JSON word as an unrecognised command
- A path handed to python/git/gh from the Bash tool comes back as `C:/Program Files/Git/c/...`
- git or gh is missing from PowerShell's PATH while supabase/node work fine
- An agent sees a trailing `claude-XXXX-cwd: No such file or directory` and exit 1

## Example use cases

- Rewrite a Supabase REST insert test so `curl.exe` sends the JSON body from a file
- Diagnose `az containerapp env create` "failing" under `2>&1` when the environment exists
- Wait for a deploy with `gh run list --commit <full-sha>` and `gh run watch --exit-status` before curling a new file
- Choose the right shell for each tool in a mixed PowerShell/Git Bash agent session

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy `SKILL.md` into your AI tool as an instruction or system prompt when working on Windows. Provide the shell, the tool and the failing command, and apply the corrected form plus the success check it recommends.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
