## Secret Remediation Plan

1. **Containment (already started)**
- Confirm credential rotation is complete.
- Revoke old token/secret everywhere it was used.

2. **Build replacement map**
- Create mappings in `replacements.txt`:

```text
literal:old-secret-value==>REDACTED_SECRET
literal:old-token-value==>REDACTED_TOKEN
```

3. **Write file as BOM-free UTF-8 (Windows PowerShell)**

```powershell
$path = "replacements.txt"
$content = @"
literal:old-secret-value==>REDACTED_SECRET
literal:old-token-value==>REDACTED_TOKEN
"@
[System.IO.File]::WriteAllText($path, $content.Trim(), [System.Text.UTF8Encoding]::new($false))
```

4. **Rewrite history**

```bash
git filter-repo --replace-text replacements.txt --force
```

5. **Verify no leaked values remain**

```bash
git log -p --all -- "*.env" | rg "old-secret-value|old-token-value"
git grep -n "old-secret-value\|old-token-value" $(git rev-list --all)
```

6. **Push rewritten history and coordinate recovery**

```bash
git push origin --force --all
git push origin --force --tags
```

- Tell collaborators to re-clone or hard reset to rewritten refs.
- Pause merges until all active contributors have moved to the rewritten history.

## Why this works

- Credential risk is reduced immediately by rotation.
- `git filter-repo` replaces historical occurrences deterministically.
- BOM-free UTF-8 avoids hidden-byte mismatches on Windows that cause silent no-op replacements.
- Force-push plus team reset prevents old history from being reintroduced.

## Follow-up hardening

- Add secret scanning in pre-commit and CI.
- Expand `.gitignore` for local env/config artifacts.
- Add a brief incident log entry with timeline and prevention changes.
