<#
.SYNOPSIS
    Holt Updates vom Original-Repository und erstellt einen Test-Branch

.DESCRIPTION
    Fetcht die neuesten Änderungen von borb/amigahid-pico und erstellt/aktualisiert
    den 'upstream-test' Branch zum Testen bevor du in main mergst.

.EXAMPLE
    .\scripts\sync-upstream.ps1
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "`n=== Sync Upstream ===" -ForegroundColor Cyan

# Prüfen ob upstream remote existiert
$upstreamExists = git remote | Where-Object { $_ -eq "upstream" }
if (-not $upstreamExists) {
    Write-Host "Upstream remote nicht gefunden. Füge hinzu..." -ForegroundColor Yellow
    git remote add upstream https://github.com/borb/amigahid-pico.git
    Write-Host "Upstream remote hinzugefügt." -ForegroundColor Green
}

# Prüfen ob es uncommitted changes gibt
$status = git status --porcelain
if ($status) {
    Write-Host "`nWARNUNG: Du hast uncommitted Änderungen!" -ForegroundColor Red
    Write-Host $status
    $response = Read-Host "`nMöchtest du sie stashen? (j/n)"
    if ($response -eq "j") {
        git stash push -m "Auto-stash before upstream sync"
        Write-Host "Änderungen gestashed." -ForegroundColor Green
    } else {
        Write-Host "Abbruch. Bitte committe oder stashe deine Änderungen zuerst." -ForegroundColor Yellow
        exit 1
    }
}

# Upstream fetchen
Write-Host "`nHole neueste Änderungen von upstream..." -ForegroundColor Gray
git fetch upstream

# Submodules auch fetchen
Write-Host "Aktualisiere Submodule-Referenzen..." -ForegroundColor Gray
git fetch upstream --recurse-submodules=on-demand

# Prüfen ob upstream-test Branch existiert
$testBranchExists = git branch --list "upstream-test"

if ($testBranchExists) {
    Write-Host "`nWechsle zu 'upstream-test' Branch..." -ForegroundColor Gray
    git checkout upstream-test
    
    # Reset auf upstream/main
    Write-Host "Setze 'upstream-test' auf upstream/main zurück..." -ForegroundColor Gray
    git reset --hard upstream/main
} else {
    Write-Host "`nErstelle 'upstream-test' Branch von upstream/main..." -ForegroundColor Gray
    git checkout -b upstream-test upstream/main
}

# Submodules aktualisieren
Write-Host "`nAktualisiere Submodules..." -ForegroundColor Gray
git submodule update --init --recursive

Write-Host "`n=== Sync abgeschlossen ===" -ForegroundColor Green
Write-Host ""
Write-Host "Du bist jetzt auf dem 'upstream-test' Branch mit dem neuesten Code von borb."
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Baue das Projekt:  cmd /c build-pico2.cmd"
Write-Host "  2. Teste auf deiner Hardware"
Write-Host "  3. Wenn alles funktioniert:  .\scripts\merge-upstream.ps1"
Write-Host "  4. Zurück zu main ohne merge:  git checkout main"
Write-Host ""
