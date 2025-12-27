@echo off
:: Sekom Clenner Elevation Launcher
:: This script helps launch the application with proper elevation handling

title Sekom Clenner - Administrator Required

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running with administrator privileges...
    goto :launch
)

:: Not running as admin - provide guidance
echo.
echo ================================================
echo SEKOM CLENNER - ADMINISTRATOR REQUIRED
echo ================================================
echo.
echo This application requires administrator privileges
echo to perform system cleaning and optimization tasks.
echo.
echo Please:
echo 1. Right-click on sekom_clenner.exe
echo 2. Select "Run as administrator"
echo 3. Click "Yes" when prompted by UAC
echo.
echo Alternatively, you can:
echo - Move the application to a non-restricted folder
echo - Use this launcher script as administrator
echo.

:: Try to elevate automatically
echo Attempting automatic elevation...
powershell -Command "Start-Process '%~dp0build\windows\x64\runner\Debug\sekom_clenner.exe' -Verb RunAs"
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Failed to elevate automatically.
    echo Please manually run as administrator.
)
goto :end

:launch
:: Launch the application
echo Launching Sekom Clenner...
start "" "%~dp0build\windows\x64\runner\Debug\sekom_clenner.exe"

:end
echo.
pause
