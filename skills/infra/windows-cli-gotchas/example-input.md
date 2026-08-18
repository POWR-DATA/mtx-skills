# Example Input

## Context

An AI agent is helping a consultant deploy a small Azure Container App and test a Supabase REST endpoint from a Windows 11 laptop. The agent has two shells: Windows PowerShell 5.1 and a Git Bash tool. Several commands are "failing" in ways that do not match what actually happened.

## Input provided

**Shells:** Windows PowerShell 5.1 (primary), Git Bash tool

**Failing commands and what was seen:**

1. PowerShell — `curl.exe -X POST https://<ref>.supabase.co/rest/v1/interest_signups -d '{"campaign":"spring","email":"a@example.com"}' -H "apikey: <anon>"` → `spring : The term 'spring' is not recognized as the name of a cmdlet`
2. PowerShell — `az containerapp env create -n cae-go -g rg-go -l australiaeast 2>&1` → red NativeCommandError lines, `$?` is `False`, yet `az containerapp env show` returns the environment
3. PowerShell — `Write-Host "$f:"` in a loop over files → `Variable reference is not valid. ':' was not followed by a valid variable name character`
4. Bash tool — `python3 /c/Users/<user>/repo/scripts/build_links.py` → `can't open file 'C:/Program Files/Git/c/Users/<user>/repo/scripts/build_links.py'`
5. Bash tool — `git status` succeeds but the output ends with `bash: line 1: /c/Users/<user>/AppData/Local/Temp/claude-1a2b-cwd: No such file or directory` and exit code 1
6. PowerShell — `gh run list --json headSha,databaseId --jq ".[] | \(.headSha[0:7])"` → `.headSha : The term '.headSha' is not recognized`; the agent needs the run id for the commit it just pushed so it can `gh run watch` before curling a new file

**Ask:** corrected commands and a rule for each so the agent stops tripping on them.
