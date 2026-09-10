#!/usr/bin/env powershell

$ErrorActionPreference = "Stop"

$commandsDir = "$env:USERPROFILE\.claude\commands"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $repoDir "commands"
$sourceFile = Join-Path $sourceDir "mtx.md"

function Test-IsReparsePoint($path) {
    if (-not (Test-Path $path)) { return $false }
    return [bool]((Get-Item $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Resolve-Full($path) {
    $r = Resolve-Path $path -ErrorAction SilentlyContinue
    if ($r) { return $r.Path.TrimEnd('\') }
    return $null
}

# Handle an existing link FIRST. Never use Remove-Item -Recurse on a junction:
# it can delete the contents of the TARGET (this repo), not just the link.
if (Test-IsReparsePoint $commandsDir) {
    $target = (Get-Item $commandsDir -Force).Target
    if ($target -and ((Resolve-Full $target) -eq (Resolve-Full $sourceDir))) {
        Write-Host "[OK] /mtx already linked to this repo - nothing to do" -ForegroundColor Green
        Write-Host "  $commandsDir -> $sourceDir"
        return
    }
    [System.IO.Directory]::Delete($commandsDir, $false)   # removes the link only
}

$linked = $false

# 1. Symlink the file - cleanest, but needs Developer Mode or an elevated shell.
try {
    New-Item -ItemType Directory -Force $commandsDir | Out-Null
    $linkPath = Join-Path $commandsDir "mtx.md"
    if (Test-Path $linkPath) { Remove-Item $linkPath -Force }
    New-Item -ItemType SymbolicLink -Path $linkPath -Value $sourceFile -ErrorAction Stop | Out-Null
    $linked = $true
    Write-Host "[OK] /mtx installed (symlinked) and ready" -ForegroundColor Green
    Write-Host "  Updates to commands/mtx.md will be available automatically after git pull"
} catch {
    # 2. Junction the directory - works WITHOUT admin, and survives git replacing
    #    the file on pull (a hard link would not). Only when the destination holds
    #    nothing but our own mtx.md, so other slash commands are never discarded.
    $existing = @(Get-ChildItem $commandsDir -Force -ErrorAction SilentlyContinue)
    $onlyOurs = ($existing.Count -eq 0) -or
                (($existing.Count -eq 1) -and ($existing[0].Name -eq "mtx.md") -and -not $existing[0].PSIsContainer)
    if ($onlyOurs) {
        try {
            Remove-Item $commandsDir -Recurse -Force -Confirm:$false   # a real directory here, not a link
            New-Item -ItemType Junction -Path $commandsDir -Target $sourceDir -ErrorAction Stop | Out-Null
            $linked = $true
            Write-Host "[OK] /mtx installed (junction) and ready" -ForegroundColor Green
            Write-Host "  Updates to commands/mtx.md will be available automatically after git pull"
            Write-Host "  Note: $commandsDir now points at this repo - moving or deleting the repo removes /mtx"
        } catch {
            New-Item -ItemType Directory -Force $commandsDir | Out-Null
        }
    }
}

# 3. Copy - always works, but goes stale until the next install.
if (-not $linked) {
    New-Item -ItemType Directory -Force $commandsDir | Out-Null
    Copy-Item $sourceFile "$commandsDir\mtx.md" -Force
    Write-Host "[OK] /mtx installed (copied) and ready" -ForegroundColor Green
    Write-Host "  Tip: run .\install.ps1 again after git pull to get the latest version"
    Write-Host "  A copy drifts silently - if /mtx behaves unexpectedly, check it matches contribute/commands/mtx.md"
}
