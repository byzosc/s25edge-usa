@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\03-recover-5g-after-update.ps1" -AssumeYes
echo.
pause
