# Erstellt eine Desktop-Verknuepfung "KiCad mit AutoSave" und legt sie auch in den Startmenue-Ordner.
# Anschliessend muss die Verknuepfung manuell per Rechtsklick "An Taskleiste anheften" angeheftet werden
# (Windows 11 erlaubt das Pinnen per Script nicht mehr).

$proj    = "C:\Scripts\RP2040\amigahid-pico"
$cmd     = "$proj\scripts\start-kicad-with-watcher.cmd"
$icon    = "C:\Program Files\KiCad\10.0\bin\kicad.exe,0"
$lnkName = "KiCad mit AutoSave.lnk"

if (-not (Test-Path $cmd)) { Write-Error "Launcher nicht gefunden: $cmd"; exit 1 }

$shell = New-Object -ComObject WScript.Shell

function New-Link($targetDir) {
    $path = Join-Path $targetDir $lnkName
    $sc = $shell.CreateShortcut($path)
    $sc.TargetPath       = $cmd
    $sc.WorkingDirectory = $proj
    $sc.IconLocation     = $icon
    $sc.Description      = "Startet KiCad 10 mit Auto-Save Watcher (alle 5 Min Ctrl+S)"
    $sc.WindowStyle      = 1
    $sc.Save()
    "Verknuepfung erstellt: $path"
}

# Desktop
New-Link ([Environment]::GetFolderPath('Desktop'))

# Startmenue (Programs)
$startMenu = Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs"
New-Link $startMenu

Write-Host ""
Write-Host "=========================================================="
Write-Host " So heftest du die Verknuepfung an die Taskleiste:"
Write-Host " 1. Auf dem Desktop die Datei 'KiCad mit AutoSave' suchen"
Write-Host " 2. Rechtsklick -> 'Weitere Optionen anzeigen'"
Write-Host " 3. -> 'An Taskleiste anheften'"
Write-Host "=========================================================="
