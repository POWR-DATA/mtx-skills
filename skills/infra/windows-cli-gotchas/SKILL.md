---
name: windows-cli-gotchas
description: Run native CLIs reliably from PowerShell 5.1 and Git Bash on Windows — quoting, encoding, JSON payloads, stderr and exit codes, MSYS path mangling, and which shell to use for which tool
author: PowerData
version: 1.4.0
license: MIT
---

# Windows CLI Gotchas

## Purpose

Keep agent- and script-driven work on Windows from failing on shell mechanics rather than the task: the PowerShell 5.1 quoting, encoding and output rules, how to hand JSON and paths to native executables, MSYS path rewriting in Git Bash, which tools live in which shell, how to judge whether a native command actually succeeded, and how to run long-lived processes, secrets, Office COM and headless browser probes without leaks or hangs.

## When to use

Any time `az`, `gh`, `git`, `supabase`, `curl.exe`, `python`, `msedge`, or `npx` is being invoked from Windows PowerShell 5.1, the Git Bash tool or a Node script — especially by an AI agent — and a command "fails" with a parse error, a mangled path, corrupted characters, a NativeCommandError, or an exit code that contradicts the output. Apply before writing the command, and again when diagnosing one.

## Inputs expected

- Which shell is running the command (Windows PowerShell 5.1, PowerShell 7, Git Bash)
- The native tool and the argument that is misbehaving (path, JSON body, quoted string, redirect)
- The observed error text or exit code, and whether the output was piped or redirected

---

## Guiding principles

**Shell choice and paths**

- **Split tools by shell.** git and gh are often absent from PowerShell's PATH while the supabase CLI and node run fine there; use PowerShell for supabase/node/npx/az and Bash (with `-C "C:/..."`) for git. Run browser executables that take Windows file paths (headless Edge/Chrome print-to-PDF or `--screenshot`) from PowerShell — from Git Bash, MSYS rewrites the path arguments and the browser silently produces nothing.
- **Git Bash rewrites any argument that begins with `/`, not just paths.** A `/c/Users/...` path handed to `python3` became `C:/Program Files/Git/c/Users/...`, and `gh issue comment --body "/publish 2"` posted `C:/Program Files/Git/publish 2`. Pass Windows-style `C:/Users/...` paths to non-MSYS executables (`git -C "C:/repo"`, `gh ... --body-file "C:/..."`), and prefix the command with `MSYS_NO_PATHCONV=1` whenever an argument is legitimately a slash-command or URL path.
- **Never hand 8.3 short paths to a native executable, compare them, or build URLs from them.** Temp paths can come back in short form (`C:\Users\<USER>~1\...` — exactly what `$env:TEMP` returns): `az` broke on a short file argument, headless Edge `--screenshot` fails with "cannot find the path specified" when the output path uses the short user folder, a comparison with the long form of the same path fails, and the `~` is URL-encoded when the path is turned into a file URL. Resolve to the long form first with `(Get-Item $p).FullName`.
- **Use forward slashes or raw strings for every Windows path inside Python.** In a non-raw string `\U` raises a unicode-escape error (even inside a triple-quoted block of prose) and `\a` becomes a bell character, so `...website\assets` silently became `...websitessets` with no error. This applies to paths written *into* generated files as well as paths in the script.

**Quoting and strings**

- **`"$f:"` throws "Variable reference is not valid".** Inside a double-quoted PowerShell string the colon is parsed as a scope qualifier; write `"${f}:"`.
- **Backslash does not escape anything in PowerShell.** Writing `\"` inside a command string is a parser error ("Missing expression", "Unexpected token") — a habit imported from bash. Use single-quoted strings, here-strings, or doubled quotes (`""`) for literal quotes.
- **PowerShell 5.1 strips embedded double quotes from arguments passed to native executables.** Inline JSON for `curl.exe -d` had a word parsed as a command, `az` KQL queries and ETags arrived without their quotes, and `gh ... --jq '"\(.state) \(.x)"'` reached gh as `\(.state) ...` so jq failed with "unexpected token". Put anything carrying quotes in a UTF-8 no-BOM file — `git commit -F <file>`, `gh ... --body-file <file>`, `curl.exe -d @file`, REST calls with the JSON body read from a file — and shape `gh` output with `--json <fields>` piped to `ConvertFrom-Json` instead of jq string literals or `\(...)` interpolation.
- **Write commit messages to a file, never inline.** A multi-line here-string containing double quotes passed to `git commit -m` is re-split by native argument quoting, so words land as pathspecs and the commit fails. Write the message with `[IO.File]::WriteAllText(path, text, (New-Object Text.UTF8Encoding $false))` and use `git commit -F <file>` — `Set-Content -Encoding utf8` prepends a BOM that `git commit -F` keeps as an invisible character at the start of the subject. Check a suspicious subject with `git log -1 --format=%s | Format-Hex`.
- **`az` is a `.cmd` wrapper.** Node cannot spawn `az` directly on Windows — use `shell: true` or call `az.cmd`. And `&` inside a `--uri` query string is a command separator, producing `'$top' is not recognized as an internal or external command`; pass query parameters with `az rest --url-parameters` instead of building them into the URL.
- **Build edit lists as typed objects, not array literals.** An array-literal `.Replace` chain silently no-ops through operator precedence, and nested arrays such as `@( ,@('a','b'), ,@('c','d') )` passed to a function flatten — `$pr[1]` came back null, and a helper that wrote the file after every attempt silently rewrote it unchanged. Chain literal `.Replace` calls for a few fixed edits; for a list use a `[System.Collections.Generic.List[object]]` of `[pscustomobject]@{Old=...;New=...}`, check every `Old` matches exactly once before writing anything, then write once and verify with `git diff`. See *Edit list as typed objects* in `reference.md`.

**Encoding**

- **Always read-modify-write text with explicit UTF-8.** In PowerShell 5.1 `Get-Content -Raw` reads UTF-8 files as ANSI, so writing back with `Set-Content -Encoding utf8` double-encodes every non-ASCII character (an em dash becomes `â€”`, © becomes `Â©`) and a naive em-dash check then reports zero. Use `[System.IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)` and `WriteAllText($p,$c,(New-Object Text.UTF8Encoding($false)))`. See *UTF-8 read-modify-write* in [`reference.md`](reference.md).
- **`[Text.Encoding]::Latin1` does not exist in PowerShell 5.1** — use `[Text.Encoding]::GetEncoding(28591)`.
- **Match the file's existing newline style.** Inserting a line built with `` "`r`n" `` into a file that otherwise uses LF leaves a single CRLF line, which later surfaces as an unexplained whitespace-only diff on a line nobody meant to touch. Detect the file's style and reuse it; confirm an odd diff line is only line endings with `git diff -w`.

**Output, exit codes and verification**

- **In Windows PowerShell 5.1, do not redirect native stderr with `2>&1`.** It becomes NativeCommandError/RemoteException noise and a failing exit even when the command succeeded (`az containerapp env create` spinner lines, supabase CLI warnings, `curl` exit 60 for TLS); confirm state by reading the JSON or a follow-up `show` rather than trusting `$?`.
- **A wrapper script with strict error handling can abort after the real work succeeded.** Tools that write progress notices to stderr (`eas`, `az`) make PowerShell report failure, so the wrapper stopped and skipped its own verification step. Check the actual outcome (the published update, the deployed resource) before retrying.
- **Print with `Write-Host` inside PowerShell functions.** Anything emitted with `Write-Output` becomes part of the function's return value, so `$fails = Test-Routes ...` captured the printed report *plus* the count, the `-eq 0` check on that array evaluated false, and a passing test gate reported failure with nothing printed. Return results through a `$script:` variable.
- **`$home` is a read-only automatic variable, and `R` is a built-in alias.** Assigning to `$home` throws, and every later check against it silently reads the wrong value, producing false negatives; a helper function named `R` never runs because the alias wins. Pick other names (`$landing`, `$body`).
- **`Measure-Object -Line` skips blank lines**, so it undercounts text files. Count lines with `[IO.File]::ReadAllLines(path).Length`.
- **`Select-Object -First N` stops the upstream command early.** Piping a long-running deploy watch into it ended the watch; never cap the output of a command that has to run to completion.
- **A pipe reports the last command's exit status.** Piping a test run into `tail` reported `tail`'s status, so a failing suite looked green and red tests were pushed twice. Redirect to a file and chain (`pytest -q > log && tail log`), or enable `set -o pipefail`.
- **A trailing `bash: line N: /c/Users/.../claude-XXXX-cwd: No such file or directory` with exit code 1 is harmless.** An agent running native commands through Git Bash often sees it even when the command succeeded — it is a working-directory-cleanup artefact; judge success by the command's real stdout.
- **Write long or multi-part Bash commands to a script file and run the file.** Commands embedding large heredocs or several scripts failed with "unexpected EOF while looking for matching quote" or ENAMETOOLONG; a file was reliable every time.
- **Observed with the Claude Code guardrail:** a whole command is blocked as a "system path" removal when `Remove-Item` appears alongside a string that looks like a root path (`/delete-account` inside a commit message, or a `cmd /c` call), and nothing in it runs. Keep `Remove-Item` out of commands carrying such strings, and one `Remove-Item` per command — chained calls are also blocked.

**Processes, secrets and automation**

- **Start long-lived processes fully detached, with their own hidden console.** A server process started from a shell died with `0xC0000142` when that console went away; launch it so it owns its console (e.g. `Start-Process <exe> -WindowStyle Hidden`) rather than as a child of the session's shell.
- **Read secrets into environment variables at a masked prompt, inside `try/finally`.** A secret typed on a command line lands in history. Prompt with `Read-Host -AsSecureString`, run the work in `try`, and remove the variables in `finally` so they cannot leak into later commands in the same window. See *Read a secret into an environment variable* in `reference.md`.
- **An Office COM save can fail silently.** Saving a Word document through COM does nothing while the user has that file open, and can leave a hidden `WINWORD` process running. Check the file's timestamp and size after saving, and end any orphaned Word process.
- **Bound headless browser probes of a live single-page app.** Headless Edge `--virtual-time-budget=N --dump-dom` never returned on an SPA that keeps connections open, and `--screenshot` of it came back blank. Run such probes with `Start-Process` using an isolated `--user-data-dir`, wait with `WaitForExit(<timeout>)` and stop only that process, and report a blank render as "cannot verify", not as a failure.

**HTTP checks**

- **`Invoke-WebRequest -MaximumRedirection 0` throws on a 3xx in PowerShell 5.1** ("Operation is not valid due to the current state of the object") instead of returning the response. Catch the exception and read the status from it, or check redirect chains with `curl.exe -s -o NUL -w "%{http_code} %{redirect_url}"`.
- **A page served without a charset is decoded as Latin-1 and looks like mojibake that is not there.** Azure Static Web Apps serves HTML as `text/html` with no charset, so `Invoke-WebRequest` reports corrupted characters on a perfectly good deploy. Read raw bytes before concluding anything: `[Text.Encoding]::UTF8.GetString((New-Object Net.WebClient).DownloadData($u))`.
- **Verify a deploy with the full SHA.** `gh run list --commit <full-sha> --json databaseId --jq ".[0].databaseId"` (a short SHA returns nothing), then `gh run watch <id> --exit-status` before curling — new files 404 until the workflow completes. If a watch runs long, poll `gh run list --json headSha,status,conclusion` instead (`gh run watch` once hung past ten minutes; see `static-website-hosting`).

## Process

1. **Pick the shell for the tool** — PowerShell for supabase/node/npx/az and any browser executable; Git Bash for git (with `-C "C:/..."`); gh in whichever has it on PATH.
2. **Write paths Windows-style and long-form** — never MSYS `/c/...` to a native exe, never 8.3 short paths, forward slashes or raw strings in Python; add `MSYS_NO_PATHCONV=1` when an argument really does start with `/`.
3. **Quote deliberately** — `"${var}:"`; no backslash escapes; anything carrying embedded double quotes (messages, JSON, KQL, ETags) in files, not inline; `--json` + `ConvertFrom-Json` rather than `--jq`; `--url-parameters` rather than `&` in an `az` URI; edit lists as typed objects, validated before a single write.
4. **Handle text as UTF-8 explicitly** — `ReadAllText`/`WriteAllText` with no BOM, `GetEncoding(28591)` for Latin-1, and reuse the file's newline style.
5. **Never `2>&1` a native command in 5.1**, never trust a piped exit status, never cap a long-running command with `Select-Object -First`, use `Write-Host` inside functions, and count lines with `ReadAllLines`.
6. **Judge success by output** — ignore the `claude-XXXX-cwd` trailer; read raw bytes before believing mojibake; confirm state with a `show`/`list`, including before retrying a wrapper that stopped on stderr.
7. **Put anything long in a file** — scripts, commit messages, JSON bodies — and run or reference the file.
8. **Contain processes and secrets** — start servers detached with their own hidden console; read secrets at a masked prompt and remove them in `finally`; bound headless probes with a timeout and an isolated profile; check COM saves by timestamp and size.

## Output format

1. **Command as written** — shell, path style, quoting, encoding
2. **Why it failed** — the specific rule it tripped
3. **Corrected command** — and how success is confirmed (output/JSON/`show`, not `$?`)

## Quality checklist

- [ ] Right shell for the tool; browser executables run from PowerShell; git called with `-C "C:/..."` from Bash
- [ ] No MSYS `/c/...` paths and no 8.3 short paths given to native executables, compared, or turned into file URLs; `MSYS_NO_PATHCONV=1` where an argument starts with `/`
- [ ] Python paths use forward slashes or raw strings, including paths written into generated files
- [ ] Commit messages, JSON bodies and anything else with embedded double quotes written to files (UTF-8, no BOM) and passed with `-F` / `@file` / `--body-file`
- [ ] `gh` output shaped with `--json` + `ConvertFrom-Json`, not `--jq`; `az` query strings passed with `--url-parameters`; Node calls `az` with `shell: true` or as `az.cmd`
- [ ] Multi-edit scripts use a typed edit list, every `Old` matched exactly once before a single write
- [ ] Text read and written with explicit UTF-8; file newline style preserved
- [ ] No `2>&1` on native commands; no piped exit status trusted; no long-running command piped into `Select-Object -First`; `Write-Host` used inside functions
- [ ] Line counts from `[IO.File]::ReadAllLines(path).Length`; no helper named after a built-in alias such as `R`
- [ ] Real outcome checked before retrying a wrapper that aborted on stderr
- [ ] Long-lived processes started detached; secrets read at a masked prompt into env vars and removed in `finally`
- [ ] COM saves checked by timestamp and size; headless probes bounded by a timeout, a blank render reported as "cannot verify"
- [ ] Live-page checks read raw bytes; redirects checked with `curl.exe -w` or a caught exception
- [ ] Deploy verification uses the full SHA + `gh run watch --exit-status`

## Avoid

- Writing `"$f:"`, `\"`, or inline JSON, commit messages, KQL queries or ETags in a PowerShell command
- MSYS `/c/...` paths, 8.3 short paths (to native exes, in comparisons or file URLs), or unescaped `\U`/`\a` Windows paths in Python
- Nested array literals as edit lists, or a helper that rewrites the file after every attempted edit
- `Set-Content -Encoding utf8` for a round-trip edit, or `Get-Content -Raw` on a UTF-8 file
- `2>&1` on `az`/`supabase`/`curl` in PowerShell 5.1 and then trusting `$?`, or re-running a wrapper that stopped on stderr notices without checking what it already did
- Piping a test or build command into `tail`/`head` and reading the pipeline's exit status, or a long-running watch into `Select-Object -First`
- `Write-Output` inside a function whose return value is captured, assigning to `$home`, or naming a function `R`
- `Measure-Object -Line` for line counts — it skips blank lines
- Typing a secret on a command line, or leaving it in an environment variable after the script ends
- Starting a server as a child of a console that will close; trusting a COM save while the user has the file open; waiting on an unbounded headless probe of a live SPA
- `--jq` expressions containing string literals from PowerShell; short SHAs with `gh run list --commit`
- Concluding a deploy corrupted characters from an `Invoke-WebRequest` body without checking raw bytes
- Treating the trailing `claude-XXXX-cwd … No such file or directory` / exit 1 as a real failure
- Chained `Remove-Item` calls, or `Remove-Item` in a command that also carries a leading-slash string

## Example usage

> "From PowerShell, `curl.exe -d '{\"campaign\":\"spring\"}'` says 'spring is not recognized as a command', my `git commit -F` subject line has an invisible character at the front, and the live page looks full of `â€”` after a deploy that the workflow says succeeded. In the Bash tool, `python3 /c/Users/me/script.py` can't find the file. Fix my commands."

---

_Source: This skill is sourced from the [Matrix Skills](https://github.com/POWR-DATA/mtx-skills) library. Learn more at the [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills)._
