<#
.SYNOPSIS
    Merged getestete upstream Updates in deinen main Branch

.DESCRIPTION
    Merged den 'upstream-test' Branch (mit borb's Updates) in deinen 'main' Branch
    nachdem du erfolgreich getestet hast.

.EXAMPLE
    .\scripts\merge-upstream.ps1
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "`n=== Merge Upstream to Main ===" -ForegroundColor Cyan

# Prüfen ob upstream-test Branch existiert
$testBranchExists = git branch --list "upstream-test"
if (-not $testBranchExists) {
    Write-Host "ERROR: 'upstream-test' Branch existiert nicht!" -ForegroundColor Red
    Write-Host "Führe zuerst '.\scripts\sync-upstream.ps1' aus." -ForegroundColor Yellow
    exit 1
}

# Aktuellen Branch ermitteln
$currentBranch = git branch --show-current

# Prüfen ob es uncommitted changes gibt
$status = git status --porcelain
if ($status) {
    Write-Host "`nWARNUNG: Du hast uncommitted Änderungen!" -ForegroundColor Red
    Write-Host $status
    Write-Host "Bitte committe oder stashe deine Änderungen zuerst." -ForegroundColor Yellow
    exit 1
}

# Bestätigung anfordern
Write-Host "`nDiese Aktion merged upstream Updates in deinen 'main' Branch." -ForegroundColor Yellow
Write-Host "Stelle sicher, dass du auf 'upstream-test' getestet hast!"
Write-Host ""
$response = Read-Host "Fortfahren? (j/n)"
if ($response -ne "j") {
    Write-Host "Abgebrochen." -ForegroundColor Yellow
    exit 0
}

# Zu main wechseln
Write-Host "`nWechsle zu 'main' Branch..." -ForegroundColor Gray
git checkout main

# Merge durchführen
Write-Host "Merge 'upstream-test' in 'main'..." -ForegroundColor Gray
$mergeResult = git merge upstream-test --no-edit 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nMERGE KONFLIKT!" -ForegroundColor Red
    Write-Host $mergeResult
    Write-Host ""
    Write-Host "Optionen:" -ForegroundColor Yellow
    Write-Host "  1. Konflikte manuell lösen, dann: git add . && git commit"
    Write-Host "  2. Merge abbrechen: git merge --abort"
    Write-Host ""
    exit 1
}

# Submodules aktualisieren nach Merge
Write-Host "Aktualisiere Submodules..." -ForegroundColor Gray
git submodule update --init --recursive

Write-Host "`n=== Merge erfolgreich! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Nächste Schritte:" -ForegroundColor Yellow
Write-Host "  1. Baue nochmal:  cmd /c build-pico2.cmd"
Write-Host "  2. Kurzer Smoke-Test"
Write-Host "  3. Push zu deinem Fork:  git push origin main"
Write-Host ""

# Optional: upstream-test Branch löschen?
$deleteResponse = Read-Host "Möchtest du den 'upstream-test' Branch löschen? (j/n)"
if ($deleteResponse -eq "j") {
    git branch -d upstream-test
    Write-Host "'upstream-test' Branch gelöscht." -ForegroundColor Green
}

Write-Host ""
