@echo off
title Sekom Clenner - Elevation Check

echo Checking elevation status...
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [✓] Running as Administrator
    echo [✓] Ready to use Sekom Clenner
) else (
    echo [✗] NOT running as Administrator
    echo.
    echo To fix this:
    echo 1. Right-click on sekom_clenner.exe
    echo 2. Select "Run as administrator"
    echo 3. Click "Yes" when prompted
    echo.
    echo Or use: scripts\elevate_launcher.bat
)

echo.
pause
