import 'dart:ffi';
import 'dart:io' as io;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import 'package:win32_registry/win32_registry.dart' as reg;
import '../utils/error_handler.dart';

// ==================== Top-level FFI typedefs ====================

typedef ChangeServiceConfigWNative = Int32 Function(
  IntPtr hService,
  Uint32 dwServiceType,
  Uint32 dwStartType,
  Uint32 dwErrorControl,
  Pointer<Utf16> lpBinaryPathName,
  Pointer<Utf16> lpLoadOrderGroup,
  Pointer<Uint32> lpdwTagId,
  Pointer<Utf16> lpDependencies,
  Pointer<Utf16> lpServiceStartName,
  Pointer<Utf16> lpPassword,
  Pointer<Utf16> lpDisplayName,
);
typedef ChangeServiceConfigWDart = int Function(
  int hService,
  int dwServiceType,
  int dwStartType,
  int dwErrorControl,
  Pointer<Utf16> lpBinaryPathName,
  Pointer<Utf16> lpLoadOrderGroup,
  Pointer<Uint32> lpdwTagId,
  Pointer<Utf16> lpDependencies,
  Pointer<Utf16> lpServiceStartName,
  Pointer<Utf16> lpPassword,
  Pointer<Utf16> lpDisplayName,
);

typedef SHEmptyRecycleBinWNative = Int32 Function(
  IntPtr hwnd,
  Pointer<Utf16> pszRootPath,
  Uint32 dwFlags,
);
typedef SHEmptyRecycleBinWDart = int Function(
  int hwnd,
  Pointer<Utf16> pszRootPath,
  int dwFlags,
);

// ==================== Top-level constants (also used by SystemService) ====================

const int sherbNoConfirmation = 0x00000001;
const int sherbNoProgressUi = 0x00000002;
const int sherbNoSound = 0x00000004;

const int serviceChangeConfigFfi = 0x0002; // SERVICE_CHANGE_CONFIG
const int serviceNoChangeFfi = 0xFFFFFFFF; // no change
const int serviceDisabledFfi = 0x00000004; // Disabled
const int serviceAutoStartFfi = 0x00000002; // Automatic
const int serviceDemandStartFfi = 0x00000003; // Manual (Demand)

// ==================== WindowsNative helper class ====================

class WindowsNative {
  WindowsNative._();

  // Dynamic libraries
  static final DynamicLibrary _advapi32 = DynamicLibrary.open('advapi32.dll');
  static final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');

  // Resolved functions
  static final ChangeServiceConfigWDart _changeServiceConfigW =
      _advapi32.lookupFunction<ChangeServiceConfigWNative, ChangeServiceConfigWDart>('ChangeServiceConfigW');

  static final SHEmptyRecycleBinWDart _shEmptyRecycleBinW =
      _shell32.lookupFunction<SHEmptyRecycleBinWNative, SHEmptyRecycleBinWDart>('SHEmptyRecycleBinW');

  // -------------------- Service helpers --------------------

  static int _openScManager() {
    // Use minimal rights to allow non-admin checks to succeed.
    var scm = win32.OpenSCManager(nullptr, nullptr, win32.SC_MANAGER_CONNECT);
    if (scm == 0) {
      // Fallback (may require admin); keep best-effort.
      scm = win32.OpenSCManager(nullptr, nullptr, win32.SC_MANAGER_ALL_ACCESS);
    }
    return scm;
  }

  static int _openService(int hScm, String serviceName, int access) {
    final namePtr = serviceName.toNativeUtf16();
    final hSvc = win32.OpenService(hScm, namePtr, access);
    calloc.free(namePtr);
    return hSvc;
  }

  static void _closeHandle(int h) {
    if (h != 0) {
      win32.CloseServiceHandle(h);
    }
  }

  /// Sets service Startup type using ChangeServiceConfigW.
  static bool setServiceStartupType(String serviceName, int startType) {
    int hScm = 0;
    int hSvc = 0;
    try {
      hScm = _openScManager();
      if (hScm == 0) return false;

      hSvc = _openService(hScm, serviceName, serviceChangeConfigFfi);
      if (hSvc == 0) return false;

      final result = _changeServiceConfigW(
        hSvc,
        serviceNoChangeFfi, // dwServiceType
        startType, // dwStartType
        serviceNoChangeFfi, // dwErrorControl
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
      );
      return result != 0;
    } catch (e, st) {
      GlobalErrorHandler.logError('ChangeServiceConfig failed for service: $serviceName', e, st);
      return false;
    } finally {
      _closeHandle(hSvc);
      _closeHandle(hScm);
    }
  }

  /// Returns service start type via registry (HKLM\SYSTEM\CurrentControlSet\Services\<name>\Start).
  /// 2=Automatic, 3=Manual, 4=Disabled. Returns null on failure.
  static int? getServiceStartType(String serviceName) {
    try {
      final key = reg.Registry.openPath(
        reg.RegistryHive.localMachine,
        path: r'SYSTEM\CurrentControlSet\Services\' + serviceName,
        desiredAccessRights: reg.AccessRights.readOnly,
      );
      final v = key.getValue('Start');
      key.close();
      if (v != null && v.data is int) {
        return v.data as int;
      }
    } catch (e, st) {
      GlobalErrorHandler.logDebug('Failed to get service start type for: $serviceName, error: $e');
    }
    return null;
  }

  /// Checks if a service is currently running.
  static bool isServiceRunning(String serviceName) {
    int hScm = 0;
    int hSvc = 0;
    try {
      hScm = _openScManager();
      if (hScm == 0) return false;

      hSvc = _openService(
        hScm,
        serviceName,
        win32.SERVICE_QUERY_STATUS, // query-only to work without admin
      );
      if (hSvc == 0) return false;

      final status = calloc<win32.SERVICE_STATUS>();
      final ok = win32.QueryServiceStatus(hSvc, status) != 0;
      final running = ok && status.ref.dwCurrentState == win32.SERVICE_RUNNING;
      calloc.free(status);
      return running;
    } catch (e, st) {
      GlobalErrorHandler.logDebug('isServiceRunning failed for: $serviceName, error: $e');
      return false;
    } finally {
      _closeHandle(hSvc);
      _closeHandle(hScm);
    }
  }

  /// Tries to start a service and waits a bit for running state.
  static bool startService(String serviceName, {Duration timeout = const Duration(seconds: 8)}) {
    int hScm = 0;
    int hSvc = 0;
    try {
      hScm = _openScManager();
      if (hScm == 0) return false;

      hSvc = _openService(hScm, serviceName, win32.SERVICE_START | win32.SERVICE_QUERY_STATUS);
      if (hSvc == 0) return false;

      // StartService
      final okStart = win32.StartService(hSvc, 0, nullptr) != 0 || win32.GetLastError() == win32.ERROR_SERVICE_ALREADY_RUNNING;
      if (!okStart) return false;

      // Wait for running
      final end = DateTime.now().add(timeout);
      final status = calloc<win32.SERVICE_STATUS>();
      while (DateTime.now().isBefore(end)) {
        final ok = win32.QueryServiceStatus(hSvc, status) != 0;
        if (ok && status.ref.dwCurrentState == win32.SERVICE_RUNNING) {
          calloc.free(status);
          return true;
        }
        io.sleep(const Duration(milliseconds: 300));
      }
      calloc.free(status);
      return false;
    } catch (e, st) {
      GlobalErrorHandler.logError('StartService failed for: $serviceName', e, st);
      return false;
    } finally {
      _closeHandle(hSvc);
      _closeHandle(hScm);
    }
  }

  /// Tries to stop a service and waits a bit for stopped state.
  static bool stopService(String serviceName, {Duration timeout = const Duration(seconds: 10)}) {
    int hScm = 0;
    int hSvc = 0;
    try {
      hScm = _openScManager();
      if (hScm == 0) return false;

      hSvc = _openService(
        hScm,
        serviceName,
        win32.SERVICE_STOP | win32.SERVICE_QUERY_STATUS,
      );
      if (hSvc == 0) return false;

      final status = calloc<win32.SERVICE_STATUS>();
      // ControlService with SERVICE_CONTROL_STOP
      win32.ControlService(hSvc, win32.SERVICE_CONTROL_STOP, status);
      calloc.free(status);

      // Wait for stopped
      final end = DateTime.now().add(timeout);
      final status2 = calloc<win32.SERVICE_STATUS>();
      while (DateTime.now().isBefore(end)) {
        final ok = win32.QueryServiceStatus(hSvc, status2) != 0;
        if (ok && status2.ref.dwCurrentState == win32.SERVICE_STOPPED) {
          calloc.free(status2);
          return true;
        }
        io.sleep(const Duration(milliseconds: 300));
      }
      calloc.free(status2);
      return false;
    } catch (e, st) {
      GlobalErrorHandler.logError('StopService failed for: $serviceName', e, st);
      return false;
    } finally{
      _closeHandle(hSvc);
      _closeHandle(hScm);
    }
  }

  /// Pause Windows Update for 10 years using multiple methods for maximum effectiveness
  static bool pauseWindowsUpdateFor10Years() {
    try {
      // Use PowerShell to pause Windows Update for 10 years using multiple approaches
      final result = io.Process.runSync(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '''
          try {
            # Check if running as admin
            if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
              Write-Error "Administrator privileges required"
              exit 1
            }
            
            # Set Windows Update pause until year 2077
            \$startDate = Get-Date
            \$endDate = Get-Date -Year 2077 -Month 12 -Day 31
            
            Write-Output "Starting Windows Update pause process..."
            
            # Method 1: Stop Windows Update services
            Write-Output "Stopping Windows Update services..."
            Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
            Stop-Service -Name "UsoSvc" -Force -ErrorAction SilentlyContinue
            Stop-Service -Name "BITS" -Force -ErrorAction SilentlyContinue
            
            # Method 2: Disable Windows Update services
            Write-Output "Disabling Windows Update services..."
            Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Disabled -ErrorAction SilentlyContinue
            
            # Method 3: Registry settings for Windows Update pause
            Write-Output "Setting registry pause settings..."
            \$regPath = "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings"
            if (-not (Test-Path \$regPath)) {
              New-Item -Path \$regPath -Force | Out-Null
            }
            
            # Set pause settings until 2077
            Set-ItemProperty -Path \$regPath -Name "PauseFeatureUpdatesStartTime" -Value \$startDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "PauseFeatureUpdatesEndTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "PauseQualityUpdatesStartTime" -Value \$startDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "PauseQualityUpdatesEndTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "PauseUpdatesExpiryTime" -Value \$endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "PauseUpdatesStartTime" -Value \$startDate.ToString("yyyy-MM-ddTHH:mm:ssZ") -Type String -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$regPath -Name "AllowMUUpdateService" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Method 4: Group Policy settings
            Write-Output "Setting group policy restrictions..."
            \$policyPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate"
            if (-not (Test-Path \$policyPath)) {
              New-Item -Path \$policyPath -Force | Out-Null
            }
            
            # Configure Windows Update to not connect to Windows Update servers
            Set-ItemProperty -Path \$policyPath -Name "DoNotConnectToWindowsUpdateInternetLocations" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$policyPath -Name "DisableWindowsUpdateAccess" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$policyPath -Name "SetUpdateNotificationLevel" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path \$policyPath -Name "UpdateNotificationLevel" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Method 5: Disable Windows Update through Windows Settings
            Write-Output "Configuring Windows Update settings..."
            \$auPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
            if (-not (Test-Path \$auPath)) {
              New-Item -Path \$auPath -Force | Out-Null
            }
            Set-ItemProperty -Path \$auPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            
            # Method 6: Block Windows Update URLs in hosts file
            Write-Output "Blocking Windows Update URLs..."
            \$hostsContent = Get-Content "C:\\Windows\\System32\\drivers\\etc\\hosts" -ErrorAction SilentlyContinue
            \$updateUrls = @(
              "0.0.0.0 fe2.update.microsoft.com",
              "0.0.0.0 fe3.update.microsoft.com", 
              "0.0.0.0 fe4.update.microsoft.com",
              "0.0.0.0 fe5.update.microsoft.com",
              "0.0.0.0 fe6.update.microsoft.com",
              "0.0.0.0 download.windowsupdate.com",
              "0.0.0.0 update.microsoft.com",
              "0.0.0.0 windowsupdate.microsoft.com"
            )
            
            \$newHostsContent = \$hostsContent + \$updateUrls | Select-Object -Unique
            \$newHostsContent | Set-Content "C:\\Windows\\System32\\drivers\\etc\\hosts" -ErrorAction SilentlyContinue
            
            Write-Output "Windows Update successfully paused for 10 years using multiple methods"
            exit 0
          } catch {
            Write-Error "Failed to pause Windows Update: \$_"
            exit 1
          }
          '''
        ],
        runInShell: true,
      );
      
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Resume Windows Update by clearing all pause settings and re-enabling services
  static bool resumeWindowsUpdate() {
    try {
      // Use PowerShell to clear Windows Update pause settings and re-enable services
      final result = io.Process.runSync(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '''
          try {
            # Check if running as admin
            if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
              Write-Error "Administrator privileges required"
              exit 1
            }
            
            Write-Output "Starting Windows Update resume process..."
            
            # Method 1: Re-enable Windows Update services
            Write-Output "Re-enabling Windows Update services..."
            Set-Service -Name "wuauserv" -StartupType Automatic -ErrorAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Automatic -ErrorAction SilentlyContinue
            Set-Service -Name "BITS" -StartupType Automatic -ErrorAction SilentlyContinue
            
            # Method 2: Start Windows Update services
            Write-Output "Starting Windows Update services..."
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            Start-Service -Name "UsoSvc" -ErrorAction SilentlyContinue
            Start-Service -Name "BITS" -ErrorAction SilentlyContinue
            
            # Method 3: Clear Windows Update pause settings
            Write-Output "Clearing registry pause settings..."
            \$regPath = "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings"
            \$policyPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate"
            \$auPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU"
            
            if (Test-Path \$regPath) {
              Remove-ItemProperty -Path \$regPath -Name "PauseFeatureUpdatesStartTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "PauseFeatureUpdatesEndTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "PauseQualityUpdatesStartTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "PauseQualityUpdatesEndTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "PauseUpdatesStartTime" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$regPath -Name "AllowMUUpdateService" -ErrorAction SilentlyContinue
            }
            
            if (Test-Path \$policyPath) {
              Remove-ItemProperty -Path \$policyPath -Name "DoNotConnectToWindowsUpdateInternetLocations" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$policyPath -Name "DisableWindowsUpdateAccess" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$policyPath -Name "SetUpdateNotificationLevel" -ErrorAction SilentlyContinue
              Remove-ItemProperty -Path \$policyPath -Name "UpdateNotificationLevel" -ErrorAction SilentlyContinue
            }
            
            if (Test-Path \$auPath) {
              Remove-ItemProperty -Path \$auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
            }
            
            # Method 4: Clear blocked URLs from hosts file
            Write-Output "Clearing blocked URLs from hosts file..."
            \$hostsFile = "C:\\Windows\\System32\\drivers\\etc\\hosts"
            if (Test-Path \$hostsFile) {
              \$hostsContent = Get-Content \$hostsFile -ErrorAction SilentlyContinue
              \$filteredContent = \$hostsContent | Where-Object {
                \$_ -notmatch "fe2.update.microsoft.com" -and
                \$_ -notmatch "fe3.update.microsoft.com" -and
                \$_ -notmatch "fe4.update.microsoft.com" -and
                \$_ -notmatch "fe5.update.microsoft.com" -and
                \$_ -notmatch "fe6.update.microsoft.com" -and
                \$_ -notmatch "download.windowsupdate.com" -and
                \$_ -notmatch "update.microsoft.com" -and
                \$_ -notmatch "windowsupdate.microsoft.com"
              }
              \$filteredContent | Set-Content \$hostsFile -ErrorAction SilentlyContinue
            }
            
            Write-Output "Windows Update successfully resumed"
            exit 0
          } catch {
            Write-Error "Failed to resume Windows Update: \$_"
            exit 1
          }
          '''
        ],
        runInShell: true,
      );
      
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if Windows Update is paused by checking multiple indicators
  static bool isWindowsUpdatePaused() {
    try {
      // Check multiple indicators for Windows Update pause status
      final result = io.Process.runSync(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          '''
          try {
            # Check 1: Registry pause settings
            \$regPath = "HKLM:\\SOFTWARE\\Microsoft\\WindowsUpdate\\UX\\Settings"
            if (Test-Path \$regPath) {
              \$pauseEndTime = Get-ItemProperty -Path \$regPath -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
              if (\$pauseEndTime -and \$pauseEndTime.PauseUpdatesExpiryTime) {
                \$endTime = [DateTime]::Parse(\$pauseEndTime.PauseUpdatesExpiryTime)
                if (\$endTime -gt (Get-Date)) {
                  exit 0  # Paused by registry
                }
              }
            }
            
            # Check 2: Service status
            \$wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            \$usoService = Get-Service -Name "UsoSvc" -ErrorAction SilentlyContinue
            
            if (\$wuService -and \$wuService.StartType -eq "Disabled") {
              exit 0  # Paused by disabled service
            }
            if (\$usoService -and \$usoService.StartType -eq "Disabled") {
              exit 0  # Paused by disabled service
            }
            
            # Check 3: Group Policy settings
            \$policyPath = "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsUpdate"
            if (Test-Path \$policyPath) {
              \$disableAccess = Get-ItemProperty -Path \$policyPath -Name "DisableWindowsUpdateAccess" -ErrorAction SilentlyContinue
              if (\$disableAccess -and \$disableAccess.DisableWindowsUpdateAccess -eq 1) {
                exit 0  # Paused by group policy
              }
            }
            
            exit 1  # Not paused
          } catch {
            exit 1  # Error, assume not paused
          }
          '''
        ],
        runInShell: true,
      );
      
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // -------------------- Windows Defender helpers --------------------

  /// Returns Defender signature version as string (best-effort, may return empty on failure).
  static String? getDefenderSignatureVersion() {
    // HKLM\SOFTWARE\Microsoft\Windows Defender\Signature Updates
    const path = r'SOFTWARE\Microsoft\Windows Defender\Signature Updates';
    try {
      final key = reg.Registry.openPath(
        reg.RegistryHive.localMachine,
        path: path,
        desiredAccessRights: reg.AccessRights.readOnly,
      );
      // Try "AVSignatureVersion", fallback to "EngineVersion"
      final v1 = key.getValue('AVSignatureVersion');
      final v2 = key.getValue('EngineVersion');
      key.close();
      if (v1 != null && v1.data is String) return (v1.data as String).trim();
      if (v2 != null && v2.data is String) return (v2.data as String).trim();
    } catch (e, st) {
      GlobalErrorHandler.logDebug('Failed to get Defender signature version: $e');
    }
    return null;
  }

  // -------------------- Windows Update helpers --------------------

  /// Get last successful Windows Update time (string). Tries multiple registry paths.
  static String? getWindowsUpdateLastSuccessTime() {
    // Try several well-known locations (varies by Windows build)
    final candidates = <Map<String, String>>[
      {
        'path': r'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install',
        'value': 'LastSuccessTime',
      },
      {
        'path': r'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect',
        'value': 'LastSuccessTime',
      },
      {
        'path': r'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install',
        'value': 'LastSuccessStartTime',
      },
      {
        'path': r'SOFTWARE\Microsoft\WindowsUpdate\UX\Settings',
        'value': 'LastScanTime',
      },
    ];

    for (final item in candidates) {
      try {
        final key = reg.Registry.openPath(
          reg.RegistryHive.localMachine,
          path: item['path']!,
          desiredAccessRights: reg.AccessRights.readOnly,
        );
        final v = key.getValue(item['value']!);
        key.close();
        if (v != null && v.data is String) {
          final s = (v.data as String).trim();
          if (s.isNotEmpty) return s;
        }
      } catch (_) {
        // try next
      }
    }
    return null;
  }

  // -------------------- Genuine / Activation lightweight probe --------------------

  /// Returns a lightweight "genuine state": 1 if looks activated/genuine, 0 otherwise.
  /// Best-effort using SoftwareProtectionPlatform registry.
  static int getWindowsGenuineState() {
    // HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform
    const path = r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform';
    try {
      final key = reg.Registry.openPath(
        reg.RegistryHive.localMachine,
        path: path,
        desiredAccessRights: reg.AccessRights.readOnly,
      );
      final v = key.getValue('WindowsStatus'); // non-documented; best-effort
      key.close();
      if (v != null && v.data is int) {
        final n = v.data as int;
        return n == 1 ? 1 : 0;
      }
    } catch (_) {}
    // Fallback (return 0 to avoid false-positive "Activated" when registry read fails)
    return 0;
  }

  // -------------------- Registry helpers --------------------

  static bool regDeleteTreeHKLM(String subKey) {
    try {
      final subKeyPtr = subKey.toNativeUtf16();
      final result = win32.RegDeleteTree(win32.HKEY_LOCAL_MACHINE, subKeyPtr);
      calloc.free(subKeyPtr);
      return result == win32.ERROR_SUCCESS || result == win32.ERROR_FILE_NOT_FOUND;
    } catch (e, st) {
      GlobalErrorHandler.logDebug('regDeleteTreeHKLM failed for: $subKey, error: $e');
      return false;
    }
  }

  static bool regDeleteTreeHKCU(String subKey) {
    try {
      final subKeyPtr = subKey.toNativeUtf16();
      final result = win32.RegDeleteTree(win32.HKEY_CURRENT_USER, subKeyPtr);
      calloc.free(subKeyPtr);
      return result == win32.ERROR_SUCCESS || result == win32.ERROR_FILE_NOT_FOUND;
    } catch (e, st) {
      GlobalErrorHandler.logDebug('regDeleteTreeHKCU failed for: $subKey, error: $e');
      return false;
    }
  }

  static bool regDeleteValueHKCU(String path, String valueName) {
    try {
      final pathPtr = path.toNativeUtf16();
      final phKey = calloc<IntPtr>();
      final open = win32.RegOpenKeyEx(
        win32.HKEY_CURRENT_USER,
        pathPtr,
        0,
        win32.KEY_SET_VALUE,
        phKey,
      );
      calloc.free(pathPtr);
      if (open != win32.ERROR_SUCCESS) {
        calloc.free(phKey);
        // Consider "not found" as success
        return open == win32.ERROR_FILE_NOT_FOUND;
      }
      final valuePtr = valueName.toNativeUtf16();
      final del = win32.RegDeleteValue(phKey.value, valuePtr);
      calloc.free(valuePtr);
      win32.RegCloseKey(phKey.value);
      calloc.free(phKey);
      return del == win32.ERROR_SUCCESS || del == win32.ERROR_FILE_NOT_FOUND;
    } catch (e, st) {
      GlobalErrorHandler.logDebug('regDeleteValueHKCU failed for: $path\\$valueName, error: $e');
      return false;
    }
  }

  // -------------------- Process helpers --------------------

  /// Kill a process by image name using taskkill. Returns true if a kill was attempted successfully.
  static bool killProcessByName(String exeName) {
    try {
      final res = io.Process.runSync(
        'taskkill',
        ['/f', '/im', exeName],
        runInShell: true,
      );
      if (res.exitCode == 0) return true;
      final out = (res.stdout ?? '').toString().toLowerCase();
      final err = (res.stderr ?? '').toString().toLowerCase();
      // Treat "no instance" (process not running) as non-fatal
      if (out.contains('no instance') || err.contains('no instance')) {
        return false;
      }
      return res.exitCode == 0;
    } catch (e, st) {
      GlobalErrorHandler.logDebug('killProcessByName failed for: $exeName, error: $e');
      return false;
    }
  }

  /// Lightweight process presence check (no admin required).
  /// Returns true if tasklist finds the given image name.
  static bool isProcessRunning(String imageName) {
    try {
      final res = io.Process.runSync(
        'tasklist',
        ['/FI', 'IMAGENAME eq $imageName'],
        runInShell: true,
      );
      final out = (res.stdout ?? '').toString().toLowerCase();
      return res.exitCode == 0 && out.contains(imageName.toLowerCase());
    } catch (e, st) {
      GlobalErrorHandler.logDebug('isProcessRunning failed for: $imageName, error: $e');
      return false;
    }
  }

  static bool killProcessesByNames(List<String> names) {
    bool any = false;
    for (final n in names) {
      any = killProcessByName(n) || any;
    }
    return any;
  }

  // Launch a process elevated (UAC) using ShellExecuteW "runas".
  // Returns true if the UAC prompt was successfully invoked (return code > 32).
  static bool launchElevated(String exePath, List<String> arguments, String workingDir) {
    try {
      String buildArgs(List<String> args) {
        return args.map((a) {
          // Quote each arg if it contains spaces or special chars
          final needsQuote = a.contains(' ') || a.contains('"');
          var v = a.replaceAll('"', r'\"');
          return needsQuote ? '"$v"' : v;
        }).join(' ');
      }

      final opPtr = 'runas'.toNativeUtf16();
      final filePtr = exePath.toNativeUtf16();
      final params = buildArgs(arguments);
      final paramsPtr = params.toNativeUtf16();
      final dirPtr = workingDir.toNativeUtf16();

      final res = win32.ShellExecute(0, opPtr, filePtr, paramsPtr, dirPtr, win32.SW_SHOWNORMAL);

      calloc.free(opPtr);
      calloc.free(filePtr);
      calloc.free(paramsPtr);
      calloc.free(dirPtr);

      return res > 32;
    } catch (e, st) {
      GlobalErrorHandler.logError('launchElevated failed for: $exePath', e, st);
      return false;
    }
  }

  // Alternate elevation strategy: elevate cmd.exe and let it start our exe.
  // This helps on some environments where ShellExecute on the target exe is blocked.
  static bool launchElevatedViaCmd(String exePath, List<String> arguments, String workingDir) {
    try {
      String quote(String s) => '"${s.replaceAll('"', r'\"')}"';
      final exeQ = quote(exePath);
      final argsQ = arguments.map(quote).join(' ');
      final cmdLine = '/c start "" $exeQ $argsQ';

      final opPtr = 'runas'.toNativeUtf16();
      final filePtr = 'cmd.exe'.toNativeUtf16();
      final paramsPtr = cmdLine.toNativeUtf16();
      final dirPtr = workingDir.toNativeUtf16();

      final res = win32.ShellExecute(0, opPtr, filePtr, paramsPtr, dirPtr, win32.SW_SHOWNORMAL);

      calloc.free(opPtr);
      calloc.free(filePtr);
      calloc.free(paramsPtr);
      calloc.free(dirPtr);

      return res > 32;
    } catch (e, st) {
      GlobalErrorHandler.logError('launchElevatedViaCmd failed for: $exePath', e, st);
      return false;
    }
  }

  /// Clear recycle bin using SHEmptyRecycleBinW FFI
  static bool clearRecycleBin() {
    try {
      final rootPtr = ''.toNativeUtf16();
      final result = _shEmptyRecycleBinW(0, rootPtr, sherbNoConfirmation | sherbNoProgressUi | sherbNoSound);
      calloc.free(rootPtr);
      return result == win32.S_OK;
    } catch (e, st) {
      GlobalErrorHandler.logError('clearRecycleBin failed', e, st);
      return false;
    }
  }

  /// Disable Windows Update services using FFI
  static bool disableWindowsUpdateServices() {
    try {
      return setServiceStartupType('wuauserv', serviceDisabledFfi) &&
             setServiceStartupType('UsoSvc', serviceDisabledFfi);
    } catch (e, st) {
      GlobalErrorHandler.logError('disableWindowsUpdateServices failed', e, st);
      return false;
    }
  }

  /// Enable Windows Update services using FFI
  static bool enableWindowsUpdateServices() {
    try {
      return setServiceStartupType('wuauserv', serviceAutoStartFfi) &&
             setServiceStartupType('UsoSvc', serviceAutoStartFfi);
    } catch (e, st) {
      GlobalErrorHandler.logError('enableWindowsUpdateServices failed', e, st);
      return false;
    }
  }

  /// Check if Windows Update services are disabled
  static bool isWindowsUpdateDisabled() {
    try {
      final wuType = getServiceStartType('wuauserv');
      final usoType = getServiceStartType('UsoSvc');
      
      return (wuType == serviceDisabledFfi) || (usoType == serviceDisabledFfi);
    } catch (_) {
      return false;
    }
  }
}
