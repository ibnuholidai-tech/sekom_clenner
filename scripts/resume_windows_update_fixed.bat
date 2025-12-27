@echo off
:: Batch script to resume Windows Update
:: Run as administrator

echo Resuming Windows Update...

:: Buat file PowerShell sementara
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesStartTime" -ErrorAction SilentlyContinue > "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "AllowMUUpdateService" -ErrorAction SilentlyContinue >> "%TEMP%\resume_update.ps1"
echo Write-Host "Windows Update resumed" >> "%TEMP%\resume_update.ps1"

:: Jalankan script PowerShell dengan hak admin
powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%TEMP%\resume_update.ps1\"' -Verb RunAs"

echo Done.
