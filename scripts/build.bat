@echo off
setlocal
echo ==========================================
echo  Building OriginalRPG Standalone Windows .exe
echo ==========================================

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo [SUCCESS] Game built and updated!
pause
