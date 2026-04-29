# Flash amigahid-pico to Pico 2 via BOOTSEL mode
# Usage: .\flash-uf2.ps1
# NOTE: Hold BOOTSEL button on Pico 2 and connect USB to enter BOOTSEL mode

$uf2Path = "$PSScriptRoot\build_pico2\src\amigahid-pico.uf2"

if (-not (Test-Path $uf2Path)) {
    Write-Host "ERROR: UF2 file not found at $uf2Path" -ForegroundColor Red
    Write-Host "Run 'cmd /c build-pico2.cmd' first to build the firmware."
    exit 1
}

# Find the Pico in BOOTSEL mode (appears as RP2350 or RPI-RP2 drive)
$drive = Get-Volume | Where-Object { $_.FileSystemLabel -eq 'RP2350' -or $_.FileSystemLabel -eq 'RPI-RP2' } | Select-Object -First 1

if ($drive) {
    $destPath = "$($drive.DriveLetter):\"
    Write-Host "Found Pico at drive $($drive.DriveLetter):" -ForegroundColor Green
    Write-Host "Copying $uf2Path to $destPath..."
    Copy-Item $uf2Path -Destination $destPath
    Write-Host "Done! Pico will restart automatically." -ForegroundColor Green
} else {
    Write-Host "ERROR: Pico not found in BOOTSEL mode." -ForegroundColor Red
    Write-Host ""
    Write-Host "To enter BOOTSEL mode:" -ForegroundColor Yellow
    Write-Host "1. Hold the BOOTSEL button on the Pico 2"
    Write-Host "2. Connect USB cable (or press Reset while holding BOOTSEL)"
    Write-Host "3. Release BOOTSEL button"
    Write-Host "4. A new drive (RP2350 or RPI-RP2) should appear"
    Write-Host "5. Run this script again"
    exit 1
}
