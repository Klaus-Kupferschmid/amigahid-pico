<#
.SYNOPSIS
    Zeigt den Status zwischen deinem Fork und dem Original-Repository (borb/amigahid-pico)

.DESCRIPTION
    Prüft wie viele Commits du hinter dem Original-Repository bist und zeigt
    die neuesten Änderungen von borb an.

.EXAMPLE
    .\scripts\status-upstream.ps1
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "`n=== Upstream Status Check ===" -ForegroundColor Cyan

# Prüfen ob upstream remote existiert
$upstreamExists = git remote | Where-Object { $_ -eq "upstream" }
if (-not $upstreamExists) {
    Write-Host "Upstream remote nicht gefunden. Füge hinzu..." -ForegroundColor Yellow
    git remote add upstream https://github.com/borb/amigahid-pico.git
    Write-Host "Upstream remote hinzugefügt: https://github.com/borb/amigahid-pico.git" -ForegroundColor Green
}

# Upstream fetchen (ohne merge)
Write-Host "`nHole neueste Informationen von upstream..." -ForegroundColor Gray
git fetch upstream --quiet

# Aktuellen Branch ermitteln
$currentBranch = git branch --show-current

# Commits zählen die wir hinter upstream sind
$behindCount = git rev-list --count HEAD..upstream/main 2>$null
$aheadCount = git rev-list --count upstream/main..HEAD 2>$null

Write-Host "`n--- Dein Status ---" -ForegroundColor Yellow
Write-Host "Aktueller Branch: $currentBranch"
Write-Host "Commits hinter upstream/main: " -NoNewline
if ($behindCount -gt 0) {
    Write-Host "$behindCount" -ForegroundColor Red
} else {
    Write-Host "$behindCount" -ForegroundColor Green
}
Write-Host "Commits vor upstream/main: $aheadCount (deine eigenen Änderungen)"

# Zeige die neuesten Commits von upstream die wir noch nicht haben
if ($behindCount -gt 0) {
    Write-Host "`n--- Neue Commits von borb/amigahid-pico ---" -ForegroundColor Yellow
    git log HEAD..upstream/main --oneline --no-merges | Select-Object -First 10
    
    if ($behindCount -gt 10) {
        Write-Host "... und $($behindCount - 10) weitere Commits" -ForegroundColor Gray
    }
    
    Write-Host "`n→ Führe '.\scripts\sync-upstream.ps1' aus um Updates zu testen" -ForegroundColor Cyan
} else {
    Write-Host "`n✓ Du bist auf dem neuesten Stand mit upstream!" -ForegroundColor Green
}

Write-Host ""
