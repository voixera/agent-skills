@echo off
REM Agent Skills launcher (CMD). Thin wrapper only: all logic lives in
REM install.ps1 so there is a single implementation to audit.
REM
REM Usage: install.cmd <command> [options]
REM Run "install.cmd help" for the command reference.

setlocal
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%install.ps1"

if not exist "%PS_SCRIPT%" (
    echo [error] Cannot find install.ps1 next to this launcher.
    exit /b 1
)

REM Prefer Windows PowerShell 5.1 (present on all supported Windows versions).
REM Fall back to pwsh (PowerShell 7+) if powershell.exe is unavailable.
where powershell.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

echo [error] Neither powershell.exe nor pwsh.exe was found on PATH.
exit /b 1
