@echo off
:: Batch script to check if Windows Update is paused
:: Run as administrator

echo Checking Windows Update pause status...

:: Pendekatan yang lebih sederhana: cek registry langsung untuk menentukan status
powershell -Command "if (Test-Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings') { $pauseTime = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' -Name 'PauseUpdatesExpiryTime' -ErrorAction SilentlyContinue; if ($pauseTime -and $pauseTime.PauseUpdatesExpiryTime) { $endTime = [DateTime]::Parse($pauseTime.PauseUpdatesExpiryTime); if ($endTime -gt (Get-Date)) { exit 0 } } } exit 1"

if %ERRORLEVEL% EQU 0 (
  echo Windows Update is PAUSED
  exit /b 0
) else (
  echo Windows Update is ACTIVE
  exit /b 1
)
