import 'package:process_run/shell.dart';

/// Windows Update service management via registry
class WindowsUpdateService {
  static final Shell _shell = Shell();

  /// Pause Windows Update via registry sampai tahun 2077
  static Future<bool> pauseWindowsUpdate() async {
    try {
      final script = '''
        # Pause Windows Update via registry sampai tahun 2077
        \$ErrorActionPreference = "SilentlyContinue"
        
        # Set registry keys untuk pause sampai 2077
        \$endDate = Get-Date -Year 2077 -Month 12 -Day 31
        
        # Windows Update pause settings
        New-Item -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseUpdatesExpiryTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "AllowMUUpdateService" -Value 0 -Type DWord -Force
        
        # Feature updates pause
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseFeatureUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseFeatureUpdatesEndTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        
        # Quality updates pause sampai 2077
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseQualityUpdatesStartTime" -Value (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseQualityUpdatesEndTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force
        
        # Additional registry keys untuk kontrol Windows Update
        New-Item -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate" -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force
        
        # Disable automatic updates via registry
        New-Item -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU" -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
        
        Write-Host "Windows Update paused via registry sampai tahun 2077"
        exit 0
      ''';

      final result = await _shell.run('powershell -NoProfile -Command "$script"');
      return result.first.exitCode == 0;
    } catch (e) {
      print('Registry pause error: $e');
      return false;
    }
  }

  /// Resume Windows Update via registry
  static Future<bool> resumeWindowsUpdate() async {
    try {
      final script = '''
        # Resume Windows Update via registry
        \$ErrorActionPreference = "SilentlyContinue"
        
        # Clear semua pause settings
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseUpdatesStartTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseFeatureUpdatesEndTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "PauseQualityUpdatesEndTime" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings" -Name "AllowMUUpdateService" -ErrorAction SilentlyContinue
        
        # Clear policy settings
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate" -Name "SetDisableUXWUAccess" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
        
        Write-Host "Windows Update resumed via registry"
        exit 0
      ''';
      
      final result = await _shell.run('powershell -NoProfile -Command "$script"');
      return result.first.exitCode == 0;
    } catch (e) {
      print('Registry resume error: $e');
      return false;
    }
  }

  /// Check if Windows Update is paused via registry
  static Future<bool> isWindowsUpdatePaused() async {
    try {
      final script = '''
        try {
          # Check registry pause settings
          \$regPath = "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings"
          if (Test-Path \$regPath) {
            \$pauseTime = Get-ItemProperty -Path \$regPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
            if (\$pauseTime -and \$pauseTime.PauseUpdatesExpiryTime) {
              \$endTime = [DateTime]::Parse(\$pauseTime.PauseUpdatesExpiryTime)
              if (\$endTime -gt (Get-Date)) {
                exit 0
              }
            }
          }
          
          # Check policy settings
          \$policyPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
          if (Test-Path \$policyPath) {
            \$noAutoUpdate = Get-ItemProperty -Path \$policyPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
            if (\$noAutoUpdate -and \$noAutoUpdate.NoAutoUpdate -eq 1) {
              exit 0
            }
          }
          
          exit 1
        } catch {
          exit 1
        }
      ''';
      
      final result = await _shell.run('powershell -NoProfile -Command "$script"');
      return result.first.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
