# KiCad Auto-Save Watcher
# Sendet alle N Sekunden Ctrl+S an offene KiCad PCB- und Schematic-Editor-Fenster.
# Optional: startet KiCad mit dem Projekt automatisch.
# Stoppen mit Ctrl+C oder das PowerShell-Fenster schliessen.
#
# Usage:
#   .\kicad-autosave-watcher.ps1                       # Default: alle 300s, oeffnet KiCad mit Projekt
#   .\kicad-autosave-watcher.ps1 -IntervalSec 120      # alle 120s
#   .\kicad-autosave-watcher.ps1 -NoLaunch             # KiCad NICHT automatisch starten
#   .\kicad-autosave-watcher.ps1 -DryRun               # nur loggen, nicht senden

[CmdletBinding()]
param(
    [int]$IntervalSec = 300,
    [string]$KiCadExe = "C:\Program Files\KiCad\10.0\bin\kicad.exe",
    [string]$ProjectFile = "C:\Scripts\RP2040\amigahid-pico\kicad\Amiga-HID_rev1.0\Amiga-HID_rev1.0.kicad_pro",
    [switch]$NoLaunch,
    [switch]$DryRun
)

# --- Optional: KiCad starten ---
if (-not $NoLaunch -and -not $DryRun) {
    $running = Get-Process -Name "kicad" -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "KiCad laeuft bereits (PID $($running.Id)) - kein Neustart."
    } elseif (Test-Path $KiCadExe) {
        if (Test-Path $ProjectFile) {
            Write-Host "Starte KiCad: $KiCadExe `"$ProjectFile`""
            Start-Process -FilePath $KiCadExe -ArgumentList "`"$ProjectFile`""
        } else {
            Write-Host "Starte KiCad (Projekt nicht gefunden: $ProjectFile)"
            Start-Process -FilePath $KiCadExe
        }
        Start-Sleep -Seconds 5
    } else {
        Write-Warning "KiCad nicht gefunden: $KiCadExe"
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
}
"@

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts] $msg"
}

function Force-Foreground($hwnd) {
    # Workaround fuer SetForegroundWindow Restriction
    $fg = [Win32]::GetForegroundWindow()
    $fgThread = 0; $myThread = [Win32]::GetCurrentThreadId()
    [void][Win32]::GetWindowThreadProcessId($fg, [ref]$fgThread)
    [void][Win32]::AttachThreadInput($fgThread, $myThread, $true)
    if ([Win32]::IsIconic($hwnd)) { [void][Win32]::ShowWindow($hwnd, 9) }  # SW_RESTORE
    [void][Win32]::SetForegroundWindow($hwnd)
    [void][Win32]::AttachThreadInput($fgThread, $myThread, $false)
}

Write-Log "KiCad Auto-Save Watcher gestartet (Interval: $IntervalSec s, DryRun: $DryRun)"
Write-Log "Stoppen mit Ctrl+C"

while ($true) {
    try {
        $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $_.MainWindowTitle -and (
                $_.MainWindowTitle -match 'PCB Editor' -or
                $_.MainWindowTitle -match 'Schematic Editor' -or
                $_.MainWindowTitle -match 'Symbol Editor' -or
                $_.MainWindowTitle -match 'Footprint Editor'
            ) -and $_.ProcessName -match 'kicad|pcbnew|eeschema'
        }

        if (-not $procs) {
            Write-Log "Keine KiCad-Editor-Fenster offen."
        } else {
            $origFg = [Win32]::GetForegroundWindow()
            foreach ($p in $procs) {
                $title = $p.MainWindowTitle
                Write-Log "Save -> '$title' (PID $($p.Id))"
                if (-not $DryRun) {
                    Force-Foreground $p.MainWindowHandle
                    Start-Sleep -Milliseconds 200
                    [System.Windows.Forms.SendKeys]::SendWait('^s')
                    Start-Sleep -Milliseconds 300
                }
            }
            # Fokus zurueck (best effort)
            if ($origFg -ne [IntPtr]::Zero) {
                Force-Foreground $origFg
            }
        }
    } catch {
        Write-Log "FEHLER: $_"
    }
    Start-Sleep -Seconds $IntervalSec
}
