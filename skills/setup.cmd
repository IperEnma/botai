@echo off
REM Windows launcher (PowerShell does not run setup.sh)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
exit /b %ERRORLEVEL%
