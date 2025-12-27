@echo off
:: Batch script to check if Windows Update is paused
:: Run as administrator

echo Checking Windows Update pause status...

:: Create temporary PowerShell script
echo try { > "%TEMP%\check_update_paused.ps1"
echo   # Check registry pause settings >> "%TEMP%\check_update_paused.ps1"
echo   $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" >> "%TEMP%\check_update_paused.ps1"
echo   if (Test-Path $regPath) { >> "%TEMP%\check_update_paused.ps1"
echo     $pauseTime = Get-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue >> "%TEMP%\check_update_paused.ps1"
echo     if ($pauseTime -and $pauseTime.PauseUpdatesExpiryTime) { >> "%TEMP%\check_update_paused.ps1"
echo       $endTime = [DateTime]::Parse($pauseTime.PauseUpdatesExpiryTime) >> "%TEMP%\check_update_paused.ps1"
echo       if ($endTime -gt (Get-Date)) { >> "%TEMP%\check_update_paused.ps1"
echo         Write-Output "PAUSED" >> "%TEMP%\check_update_paused.ps1"
echo         exit 0 >> "%TEMP%\check_update_paused.ps1"
echo       } >> "%TEMP%\check_update_paused.ps1"
echo     } >> "%TEMP%\check_update_paused.ps1"
echo   } >> "%TEMP%\check_update_paused.ps1"
echo   # Check policy settings >> "%TEMP%\check_update_paused.ps1"
echo   $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" >> "%TEMP%\check_update_paused.ps1"
echo   if (Test-Path $policyPath) { >> "%TEMP%\check_update_paused.ps1"
echo     $noAutoUpdate = Get-ItemProperty -Path $policyPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue >> "%TEMP%\check_update_paused.ps1"
echo     if ($noAutoUpdate -and $noAutoUpdate.NoAutoUpdate -eq 1) { >> "%TEMP%\check_update_paused.ps1"
echo       Write-Output "PAUSED" >> "%TEMP%\check_update_paused.ps1"
echo       exit 0 >> "%TEMP%\check_update_paused.ps1"
echo     } >> "%TEMP%\check_update_paused.ps1"
echo   } >> "%TEMP%\check_update_paused.ps1"
echo   Write-Output "ACTIVE" >> "%TEMP%\check_update_paused.ps1"
echo   exit 1 >> "%TEMP%\check_update_paused.ps1"
echo } catch { >> "%TEMP%\check_update_paused.ps1"
echo   Write-Output "ERROR: $_" >> "%TEMP%\check_update_paused.ps1"
echo   exit 1 >> "%TEMP%\check_update_paused.ps1"
echo } >> "%TEMP%\check_update_paused.ps1"

:: Run PowerShell script with admin rights and capture output
powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%TEMP%\check_update_paused.ps1\" > \"%TEMP%\check_update_status.txt\"' -Verb RunAs -Wait"

:: Check the result file
if exist "%TEMP%\check_update_status.txt" (
  type "%TEMP%\check_update_status.txt"
  findstr /C:"PAUSED" "%TEMP%\check_update_status.txt" >nul
  if %ERRORLEVEL% EQU 0 (
    exit /b 0
  ) else (
    exit /b 1
  )
) else (
  echo ERROR: Failed to read output file
  exit /b 1
)
