#!/usr/bin/env powershell

$ErrorActionPreference = "Stop"

$commandsDir = "$env:USERPROFILE\.claude\commands"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFile = Join-Path $repoDir "commands\mtx.md"

New-Item -ItemType Directory -Force $commandsDir | Out-Null

try {
    # Try to create symlink (requires Dev Mode or admin on Windows)
    $linkPath = Join-Path $commandsDir "mtx.md"
    if (Test-Path $linkPath) {
        Remove-Item $linkPath -Force
    }
    New-Item -ItemType SymbolicLink -Path $linkPath -Value $sourceFile | Out-Null
    Write-Host "[OK] /mtx installed (symlinked) and ready" -ForegroundColor Green
    Write-Host "  Updates to commands/mtx.md will be available automatically after git pull"
} catch {
    # Fall back to copy if symlink fails
    Copy-Item $sourceFile "$commandsDir\mtx.md" -Force
    Write-Host "[OK] /mtx installed (copied) and ready" -ForegroundColor Green
    Write-Host "  Tip: run .\install.ps1 again after git pull to get the latest version"
}
