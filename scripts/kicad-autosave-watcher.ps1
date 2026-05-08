# KiCad Auto-Save Watcher
# Sendet alle N Sekunden Ctrl+S an offene KiCad PCB- und Schematic-Editor-Fenster.
# Erkennt ALLE Top-Level-Fenster via EnumWindows (KiCad 10 hat mehrere Fenster im selben Prozess).
# Optional: startet KiCad mit dem Projekt automatisch.
# Stoppen mit Ctrl+C oder das PowerShell-Fenster schliessen.
#
# Usage:
#   .\kicad-autosave-watcher.ps1                       # Default: alle 300s, oeffnet KiCad mit Projekt
#   .\kicad-autosave-watcher.ps1 -IntervalSec 120      # alle 120s
#   .\kicad-autosave-watcher.ps1 -NoLaunch             # KiCad NICHT automatisch starten
#   .\kicad-autosave-watcher.ps1 -DryRun               # nur loggen, nicht senden
#   .\kicad-autosave-watcher.ps1 -Verbose              # alle gefundenen Fenster auflisten

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
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class Win32 {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll", SetLastError=true)] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();

    public static List<KeyValuePair<IntPtr,string>> GetAllWindows() {
        var list = new List<KeyValuePair<IntPtr,string>>();
        EnumWindows((h, l) => {
            if (!IsWindowVisible(h)) return true;
            int len = GetWindowTextLength(h);
            if (len == 0) return true;
            var sb = new StringBuilder(len + 1);
            GetWindowText(h, sb, sb.Capacity);
            list.Add(new KeyValuePair<IntPtr,string>(h, sb.ToString()));
            return true;
        }, IntPtr.Zero);
        return list;
    }
}
"@

function Write-Log($msg) {
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts] $msg"
}

function Force-Foreground($hwnd) {
    $fg = [Win32]::GetForegroundWindow()
    $fgThread = 0; $myThread = [Win32]::GetCurrentThreadId()
    [void][Win32]::GetWindowThreadProcessId($fg, [ref]$fgThread)
    [void][Win32]::AttachThreadInput($fgThread, $myThread, $true)
    if ([Win32]::IsIconic($hwnd)) { [void][Win32]::ShowWindow($hwnd, 9) }  # SW_RESTORE
    [void][Win32]::SetForegroundWindow($hwnd)
    [void][Win32]::AttachThreadInput($fgThread, $myThread, $false)
}

# Pattern: erkennt PCB Editor und Schematic Editor in DE und EN.
# Beispiele:
#   "Amiga-HID_rev1.0 - PCB Editor"
#   "Amiga-HID_rev1.0 - Schaltplan-Editor"
# Project Manager wird absichtlich NICHT erfasst (nichts zu speichern).
$titlePattern = '(PCB[ -]?Editor|Schematic[ -]?Editor|Schaltplan[ -]?Editor|Leiterplatten[ -]?Editor)'

Write-Log "KiCad Auto-Save Watcher gestartet (Interval: $IntervalSec s, DryRun: $DryRun)"
Write-Log "Stoppen mit Ctrl+C"

while ($true) {
    try {
        $allWindows = [Win32]::GetAllWindows()
        $hits = @($allWindows | Where-Object { $_.Value -match $titlePattern })

        if ($VerbosePreference -eq 'Continue') {
            Write-Log "Top-Level-Fenster ($($allWindows.Count)):"
            foreach ($w in $allWindows) { Write-Host "    [$($w.Key)] $($w.Value)" }
        }

        if ($hits.Count -eq 0) {
            Write-Log "Keine KiCad-Editor-Fenster offen. (Tipp: -Verbose zeigt alle Titel)"
        } else {
            $origFg = [Win32]::GetForegroundWindow()
            foreach ($w in $hits) {
                $hwnd  = $w.Key
                $title = $w.Value
                $procId = 0
                [void][Win32]::GetWindowThreadProcessId($hwnd, [ref]$procId)
                Write-Log "Save -> '$title' (PID $procId)"
                if (-not $DryRun) {
                    Force-Foreground $hwnd
                    Start-Sleep -Milliseconds 250
                    [System.Windows.Forms.SendKeys]::SendWait('^s')
                    Start-Sleep -Milliseconds 350
                }
            }
            if ($origFg -ne [IntPtr]::Zero) { Force-Foreground $origFg }
        }
    } catch {
        Write-Log "FEHLER: $_"
    }
    Start-Sleep -Seconds $IntervalSec
}
