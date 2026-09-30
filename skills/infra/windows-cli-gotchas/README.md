# Windows CLI Gotchas

Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, encoding, JSON payloads, stderr and exit codes, MSYS path mangling, and which shell to use for which tool.

## What this skill does

Collects the shell-mechanics rules that make `az`, `gh`, `git`, `supabase`, `curl.exe`, `python`, headless browsers and `npx` behave on Windows, especially when an AI agent is driving them: PowerShell 5.1's quoting, UTF-8 and output-capture traps, handing JSON and commit messages to native tools via files, Git Bash rewriting any argument that starts with `/`, splitting tools by shell, and reading real success from output rather than misleading exit codes or false mojibake.

## When to use it

- A native command "fails" in PowerShell 5.1 with NativeCommandError but clearly did its job
- `curl.exe -d '{...}'` reports a JSON word as an unrecognised command
- A path handed to python/git/gh from the Bash tool comes back as `C:/Program Files/Git/c/...`
- git or gh is missing from PowerShell's PATH while supabase/node work fine
- An agent sees a trailing `claude-XXXX-cwd: No such file or directory` and exit 1
- A round-trip edit turns em dashes into `â€”`, or a live page looks corrupted after a clean deploy
- A PowerShell function's return value contains its printed output, or a piped test run reports the wrong exit status

## Example use cases

- Rewrite a Supabase REST insert test so `curl.exe` sends the JSON body from a file
- Diagnose `az containerapp env create` "failing" under `2>&1` when the environment exists
- Wait for a deploy with `gh run list --commit <full-sha>` and `gh run watch --exit-status` before curling a new file
- Choose the right shell for each tool in a mixed PowerShell/Git Bash agent session
- Fix a commit subject that carries an invisible BOM character from `Set-Content -Encoding utf8`

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |
| `reference.md` | Load-on-demand excerpts — UTF-8 round trip, commit message via file, raw-byte page reads, redirect checks, gh/az invocation |

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
