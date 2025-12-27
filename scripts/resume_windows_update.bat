@echo off
:: Batch script to resume Windows Update
:: Run as administrator

echo Resuming Windows Update...

powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseUpdatesStartTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseUpdatesExpiryTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseFeatureUpdatesStartTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseFeatureUpdatesEndTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseQualityUpdatesStartTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"PauseQualityUpdatesEndTime\\\" -ErrorAction SilentlyContinue; Remove-ItemProperty -Path \\\"HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings\\\" -Name \\\"AllowMUUpdateService\\\" -ErrorAction SilentlyContinue; Write-Host \\\"Windows Update resumed\\\"\"' -Verb RunAs"

echo Done.
