@echo off
:: Batch script to pause Windows Update until 2077
:: Run as administrator

echo Setting Windows Update pause until 2077...

:: Buat file PowerShell sementara
echo $endDate = Get-Date -Year 2077 -Month 12 -Day 31 > "%TEMP%\pause_update_2077.ps1"
echo New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Force ^| Out-Null >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "AllowMUUpdateService" -Value 0 -Type DWord -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesEndTime" -Value $endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseQualityUpdatesEndTime" -Value $endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force >> "%TEMP%\pause_update_2077.ps1"
echo Write-Host "Windows Update paused until 2077" >> "%TEMP%\pause_update_2077.ps1"

:: Jalankan script PowerShell dengan hak admin
powershell -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%TEMP%\pause_update_2077.ps1\"' -Verb RunAs"

echo Done.
