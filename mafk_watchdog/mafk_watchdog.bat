@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo  RADMIR CRMP mafk watchdog
echo  (AutoLogin AutoRestart + crash recovery)
echo  Close this window to STOP the watchdog.
echo ============================================
echo.
echo Lag in this window: watchdog.log
echo Flag file : C:\Games\RADMIR Games\RADMIR CRMP\mafk_on.flag
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0mafk_watchdog.ps1"

echo.
echo Watchdog stopped. Press any key to close...
pause >nul
