---
name: windows-cli-gotchas
description: Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, JSON payloads, stderr and exit codes, MSYS path mangling, and which shell to use for which tool
author: PowerData
version: 1.1.0
license: MIT
---

# Windows CLI Gotchas

## Purpose

Keep agent- and script-driven work on Windows from failing on shell mechanics rather than the task: the PowerShell 5.1 quoting and stderr rules, how to hand JSON to `curl.exe`, MSYS path rewriting in Git Bash, which tools live in which shell, and how to judge whether a native command actually succeeded.

## When to use

Any time `az`, `gh`, `git`, `supabase`, `curl.exe`, `python`, or `npx` is being invoked from Windows PowerShell 5.1 or the Git Bash tool — especially by an AI agent — and a command "fails" with a parse error, a mangled path, a NativeCommandError, or an exit code that contradicts the output. Apply before writing the command, and again when diagnosing one.

## Inputs expected

- Which shell is running the command (Windows PowerShell 5.1, PowerShell 7, Git Bash)
- The native tool and the argument that is misbehaving (path, JSON body, quoted string, redirect)
- The observed error text or exit code

---

## Guiding principles

- **`"$f:"` throws "Variable reference is not valid".** Inside a double-quoted PowerShell string the colon is parsed as a scope qualifier; write `"${f}:"`.
- **Do not pass JSON inline to `curl.exe -d` from PowerShell.** The quotes get mangled (a word inside the JSON was parsed as a command); write the payload to a UTF-8 no-BOM file and pass `-d @file`.
- **In Windows PowerShell 5.1, do not redirect native stderr with `2>&1`.** It becomes NativeCommandError/RemoteException noise and a failing exit even when the command succeeded (`az containerapp env create` spinner lines, supabase CLI warnings, `curl` exit 60 for TLS); confirm state by reading the JSON or a follow-up `show` rather than trusting `$?`.
- **Git Bash on Windows rewrites `/c/Users/...` paths for non-MSYS executables.** A `/c/Users/...` path handed to `python3` was rewritten to `C:/Program Files/Git/c/Users/...`; native exes (git, gh, supabase) invoked from Git Bash mangle MSYS-style paths the same way — pass Windows-style `C:/Users/...` paths instead, e.g. `git -C "C:/repo"` and `gh ... --body-file "C:/..."`.
- **Split tools by shell.** git and gh are often absent from PowerShell's PATH while the supabase CLI and node run fine there; use PowerShell for supabase/node/npx and Bash (with `-C "C:/..."`) for git.
- **`gh run list --jq` with `\(.headSha[0:7])` inside a PowerShell double-quoted string is parsed as a command.** Use `gh run list --commit <full-sha> --json databaseId --jq ".[0].databaseId"` (a short SHA returned nothing; the full SHA from `git rev-parse HEAD` worked), then `gh run watch <id> --exit-status` before curling, because new files 404 until the deploy workflow completes.
- **Do not hand 8.3 short paths to `az`.** Passing a short path (e.g. `C:\Users\<USER>~1\...`) as a file argument to `az` appeared to break the command; resolve to the long form first with `(Get-Item $p).FullName`.
- **Three more PowerShell traps seen in agent sessions:** chained `Remove-Item` calls were blocked by safety hooks (split them into separate commands); an array-literal `.Replace` chain silently no-op'd through operator precedence (use literal chained `.Replace` calls and check `git diff`); embedded double quotes in commit messages broke native argument parsing (use single-quoted here-strings for messages).
- **A trailing `bash: line N: /c/Users/.../claude-XXXX-cwd: No such file or directory` with exit code 1 is harmless.** An agent running native commands through Git Bash on Windows often sees it even when the command succeeded — it is a working-directory-cleanup artefact; judge success by the command's real stdout, not that trailing exit status.

## Process

1. **Pick the shell for the tool** — PowerShell for supabase/node/npx/az; Git Bash for git (with `-C "C:/..."`); gh in whichever has it on PATH.
2. **Write paths Windows-style** (`C:/Users/...`) for anything that is not an MSYS tool, and long-form (`(Get-Item $p).FullName`) — never 8.3 short paths — for `az`.
3. **Quote deliberately** — `"${var}:"` for colon-adjacent variables; no `\(...)` jq inside PowerShell double quotes; single-quoted here-strings for commit messages with embedded double quotes; literal chained `.Replace` calls, not array literals; one `Remove-Item` per command.
4. **Move JSON bodies to files** (UTF-8, no BOM) and pass `-d @file` / `--body-file`.
5. **Never `2>&1` a native command in PowerShell 5.1** — read its JSON or run a `show`/`list` afterwards to confirm state.
6. **Judge success by output** — ignore the `claude-XXXX-cwd` trailer; use full SHAs with `gh run list --commit`; `gh run watch --exit-status` before testing deployed files.

## Output format

1. **Command as written** — shell, working path style, quoting
2. **Why it failed** — the specific rule it tripped
3. **Corrected command** — and how success is confirmed (output/JSON/`show`, not `$?`)

## Quality checklist

- [ ] Right shell for the tool; git called with `-C "C:/..."` from Bash
- [ ] No `/c/Users/...` paths given to non-MSYS executables
- [ ] No inline JSON to `curl.exe`; payload in a UTF-8 no-BOM file
- [ ] No `2>&1` on native commands in PowerShell 5.1; state confirmed via output or `show`
- [ ] Colon-adjacent variables written `${var}`
- [ ] Deploy verification uses the full SHA + `gh run watch --exit-status`
- [ ] `claude-XXXX-cwd` trailer not mistaken for failure
- [ ] `az` file arguments are long-form paths; commit messages use single-quoted here-strings; `.Replace` edits verified with `git diff`

## Avoid

- Writing `"$f:"` in a PowerShell double-quoted string
- Inline JSON in `curl.exe -d` from PowerShell
- `2>&1` on `az`/`supabase`/`curl` in PowerShell 5.1 and then trusting `$?`
- MSYS `/c/...` paths to python, git, gh or supabase from Git Bash
- Short SHAs with `gh run list --commit`, or `\(...)` jq inside PowerShell double quotes
- Treating the trailing `claude-XXXX-cwd … No such file or directory` / exit 1 as a real failure
- 8.3 short paths as `az` file arguments; array-literal `.Replace` chains; chained `Remove-Item` in one command; double quotes inside a native commit-message argument

## Example usage

> "From PowerShell, `curl.exe -d '{\"campaign\":\"spring\"}'` says 'spring is not recognized as a command', `az containerapp env create 2>&1` reports errors even though the environment exists, and in the Bash tool `python3 /c/Users/me/script.py` can't find the file. Fix my commands."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
