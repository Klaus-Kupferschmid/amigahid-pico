@echo off
REM Startet KiCad mit Auto-Save Watcher (alle 5 Min)
REM Wird von der Taskleisten-Verknuepfung aufgerufen
cd /d "%~dp0\.."
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0kicad-autosave-watcher.ps1"
