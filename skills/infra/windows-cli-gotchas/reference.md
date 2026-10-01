# Windows CLI Gotchas — Reference

Load-on-demand excerpts for [`SKILL.md`](SKILL.md). Illustrative — load-bearing lines only; replace `<...>` placeholders.

---

## UTF-8 read-modify-write (PowerShell 5.1)

`Get-Content -Raw` reads UTF-8 as ANSI and `Set-Content -Encoding utf8` writes a BOM, so the naive round trip double-encodes every non-ASCII character.

```powershell
$utf8NoBom = New-Object Text.UTF8Encoding($false)
$c = [System.IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
$c = $c -replace '<old>', '<new>'
[System.IO.File]::WriteAllText($p, $c, $utf8NoBom)
```

## Commit message via file

```powershell
[System.IO.File]::WriteAllText($msgPath, $message, (New-Object Text.UTF8Encoding $false))
git commit -F $msgPath
git log -1 --format=%s | Format-Hex        # first bytes should not be EF BB BF
```

## Reading a live page's real bytes

A response with no charset is decoded as Latin-1 and shows mojibake that is not in the file.

```powershell
$html = [Text.Encoding]::UTF8.GetString((New-Object Net.WebClient).DownloadData($url))
```

## Redirect check without Invoke-WebRequest

```powershell
curl.exe -s -o NUL -w "%{http_code} %{redirect_url}`n" $url
# or, if using Invoke-WebRequest, catch the 3xx it throws on:
try { Invoke-WebRequest $url -MaximumRedirection 0 -ErrorAction Stop }
catch { $_.Exception.Response.StatusCode.value__; $_.Exception.Response.Headers['Location'] }
```

## gh output without --jq

```powershell
$id = (gh run list --commit (git rev-parse HEAD) --json databaseId | ConvertFrom-Json)[0].databaseId
gh run watch $id --exit-status
```

## az query parameters

```powershell
# & in a --uri is a cmd command separator; pass parameters separately
az rest --method get --url "https://<host>/api/items" --url-parameters '$top=50' 'filter=active'
```

## Returning a value from a PowerShell function

```powershell
function Test-Routes {
    Write-Host "checking..."          # Write-Output would become part of the return value
    $script:failCount = 0
    # ...
}
Test-Routes; if ($script:failCount -eq 0) { "PASS" }
```

## MSYS escape hatch

```bash
MSYS_NO_PATHCONV=1 gh issue comment 7 --body "/publish 2"    # without it: C:/Program Files/Git/publish 2
```
