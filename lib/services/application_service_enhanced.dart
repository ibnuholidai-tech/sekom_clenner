import 'dart:io';
import 'dart:convert';
import 'package:process_run/shell.dart';
import 'package:path_provider/path_provider.dart';
import '../models/application_models_enhanced.dart';

class ApplicationServiceEnhanced {
  static final Shell _shell = Shell();

  // Default applications to check
  static List<Map<String, String>> get defaultApplications => [
    {
      'name': 'Microsoft Office',
      'registryPath': 'HKLM\\SOFTWARE\\Microsoft\\Office',
      'alternativePath': 'HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Office',
    },
  ];

  // Predefined installable applications
  static List<InstallableApplication> get predefinedApplications => [
    // Microsoft Office Versions
    InstallableApplication(
      id: 'office2021',
      name: 'Microsoft Office 2021',
      description: 'Office 2021 (Rilis: Oktober 2021)',
      downloadUrl: '',
      installerName: 'Office2021Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2019',
      name: 'Microsoft Office 2019',
      description: 'Office 2019 (Rilis: September 2018)',
      downloadUrl: '',
      installerName: 'Office2019Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2016',
      name: 'Microsoft Office 2016',
      description: 'Office 2016 (Rilis: September 2015)',
      downloadUrl: '',
      installerName: 'Office2016Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2013',
      name: 'Microsoft Office 2013',
      description: 'Office 2013 (Rilis: Januari 2013)',
      downloadUrl: '',
      installerName: 'Office2013Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2010',
      name: 'Microsoft Office 2010',
      description: 'Office 2010 (Rilis: Juni 2010)',
      downloadUrl: '',
      installerName: 'Office2010Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2007',
      name: 'Microsoft Office 2007',
      description: 'Office 2007 (Rilis: Januari 2007)',
      downloadUrl: '',
      installerName: 'Office2007Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2003',
      name: 'Microsoft Office 2003',
      description: 'Office 2003 (Rilis: Oktober 2003)',
      downloadUrl: '',
      installerName: 'Office2003Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office2000',
      name: 'Microsoft Office 2000',
      description: 'Office 2000 (Rilis: Juni 1999)',
      downloadUrl: '',
      installerName: 'Office2000Setup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'office365',
      name: 'Microsoft Office 365',
      description: 'Suite aplikasi produktivitas Microsoft',
      downloadUrl: 'https://www.office.com/',
      installerName: 'OfficeSetup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'firefox',
      name: 'Mozilla Firefox',
      description: 'Browser web yang cepat dan aman',
      downloadUrl: 'https://www.mozilla.org/firefox/',
      installerName: 'Firefox Installer.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'chrome',
      name: 'Google Chrome',
      description: 'Browser web dari Google',
      downloadUrl: 'https://www.google.com/chrome/',
      installerName: 'ChromeSetup.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'winrar',
      name: 'WinRAR',
      description: 'Aplikasi kompresi dan ekstraksi file',
      downloadUrl: 'https://www.win-rar.com/',
      installerName: 'winrar-x64.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'rustdesk',
      name: 'RustDesk',
      description: 'Aplikasi remote desktop open source',
      downloadUrl: 'https://rustdesk.com/',
      installerName: 'rustdesk.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'directx',
      name: 'DirectX Runtime',
      description: 'Runtime library untuk gaming dan multimedia',
      downloadUrl: 'https://www.microsoft.com/en-us/download/details.aspx?id=35',
      installerName: 'directx_Jun2010_redist.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'vlc',
      name: 'VLC Media Player',
      description: 'Pemutar media yang mendukung berbagai format',
      downloadUrl: 'https://www.videolan.org/vlc/',
      installerName: 'vlc-installer.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: '7zip',
      name: '7-Zip',
      description: 'Aplikasi kompresi file gratis',
      downloadUrl: 'https://www.7-zip.org/',
      installerName: '7z-installer.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'notepadpp',
      name: 'Notepad++',
      description: 'Editor teks dan kode yang powerful',
      downloadUrl: 'https://notepad-plus-plus.org/',
      installerName: 'npp-installer.exe',
      filePath: '',
    ),
    InstallableApplication(
      id: 'teamviewer',
      name: 'TeamViewer',
      description: 'Aplikasi remote access dan support',
      downloadUrl: 'https://www.teamviewer.com/',
      installerName: 'TeamViewer_Setup.exe',
      filePath: '',
    ),
  ];

  // Check installed applications using Control Panel method (faster)
  static Future<List<InstalledApplication>> checkInstalledApplications() async {
    List<InstalledApplication> installedApps = [];

    // Get installed programs from Control Panel
    Map<String, Map<String, String>> installedPrograms = await _getInstalledProgramsFromControlPanel();

    for (Map<String, String> app in defaultApplications) {
      try {
        InstalledApplication installedApp = await _checkApplicationFromControlPanel(
          app['name']!,
          installedPrograms,
        );
        
        // CRITICAL: Filter Office if no executable exists
        // Office is in defaultApplications, so we need to filter it here
        if (app['name']!.toLowerCase().contains('office')) {
          if (installedApp.isInstalled) {
            // Verify Office executable actually exists
            bool hasOfficeExe = await _hasOfficeExecutable();
            if (!hasOfficeExe) {
              installedApp = InstalledApplication(
                name: app['name']!,
                version: 'Tidak terdeteksi',
                isInstalled: false,
                status: 'Tidak terinstal atau tidak terdeteksi',
                registryPath: '',
              );
            }
          }
        }
        
        installedApps.add(installedApp);
      } catch (e) {
        installedApps.add(InstalledApplication(
          name: app['name']!,
          version: 'Error checking',
          isInstalled: false,
          status: 'Error: ${e.toString()}',
          registryPath: '',
        ));
      }
    }

    // Merge custom default apps added by user (persisted)
    try {
      List<String> customNames = await loadDefaultAppChecks();
      final lowerExisting = installedApps.map((e) => e.name.toLowerCase()).toSet();
      for (final cname in customNames) {
        if (cname.trim().isEmpty) continue;
        if (lowerExisting.contains(cname.toLowerCase())) continue;
        try {
          final customApp = await _checkApplicationFromControlPanel(cname, installedPrograms);
          installedApps.add(customApp);
        } catch (e) {
          installedApps.add(InstalledApplication(
            name: cname,
            version: 'Tidak terdeteksi',
            isInstalled: false,
            status: 'Tidak terinstal atau tidak terdeteksi',
            registryPath: 'Control Panel',
          ));
        }
      }
    } catch (_) {}

    return installedApps;
  }
  
  // Check if Office executable exists
  static Future<bool> _hasOfficeExecutable() async {
    final officePaths = [
      'C:\\Program Files\\Microsoft Office\\root\\Office16\\WINWORD.EXE',
      'C:\\Program Files (x86)\\Microsoft Office\\root\\Office16\\WINWORD.EXE',
      'C:\\Program Files\\Microsoft Office\\Office16\\WINWORD.EXE',
      'C:\\Program Files (x86)\\Microsoft Office\\Office16\\WINWORD.EXE',
      'C:\\Program Files\\Microsoft Office\\Office15\\WINWORD.EXE',
      'C:\\Program Files (x86)\\Microsoft Office\\Office15\\WINWORD.EXE',
    ];
    
    for (final path in officePaths) {
      if (await File(path).exists()) {
        return true;
      }
    }
    return false;
  }

  // Get installed programs via Registry (fast and safe; avoids Win32_Product)
  static Future<Map<String, Map<String, String>>> _getInstalledProgramsFromControlPanel() async {
    Map<String, Map<String, String>> programs = {};

    try {
      // Query uninstall keys from HKLM (x64 + WOW6432Node) and HKCU using a temporary PowerShell script to avoid quoting issues.
      final String psScript = r'''
$paths = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
);
$apps = foreach ($p in $paths) {
  try { Get-ItemProperty -Path $p -ErrorAction SilentlyContinue | Select-Object DisplayName, DisplayVersion } catch {}
};
$apps | Where-Object { $_ -and $_.DisplayName -and $_.DisplayName.Trim() -ne '' } |
  Select-Object @{Name='Name';Expression={$_.DisplayName}}, @{Name='Version';Expression={$_.DisplayVersion}} |
  ConvertTo-Json -Compress
''';
      final String scriptPath = '${Directory.systemTemp.path}\\sekom_proglist.ps1';
      final String outPath = '${Directory.systemTemp.path}\\sekom_proglist.json';
      await File(scriptPath).writeAsString(psScript);
      try { await File(outPath).delete(); } catch (_) {}
      await _shell.run('cmd /c powershell -NoProfile -ExecutionPolicy Bypass -File "$scriptPath" > "$outPath"').timeout(Duration(seconds: 15));
      String output = '';
      try {
        output = await File(outPath).readAsString();
      } catch (_) {}

      if (output.isNotEmpty && !output.toLowerCase().contains('error')) {
        try {
          final decoded = jsonDecode(output);
          if (decoded is List) {
            for (final item in decoded) {
              final name = (item['Name'] ?? '').toString();
              final version = (item['Version'] ?? '').toString();
              if (name.isNotEmpty) {
                programs[name.toLowerCase()] = {
                  'name': name,
                  'version': version.isNotEmpty ? version : 'Terdeteksi',
                };
              }
            }
          } else if (decoded is Map) {
            final name = (decoded['Name'] ?? '').toString();
            final version = (decoded['Version'] ?? '').toString();
            if (name.isNotEmpty) {
              programs[name.toLowerCase()] = {
                'name': name,
                'version': version.isNotEmpty ? version : 'Terdeteksi',
              };
            }
          }
        } catch (e) {
          print('Failed to parse registry JSON: $e');
        }
      }
    } catch (e) {
      print('Error getting programs from registry: $e');
    }

    // Fallback: Check common installation paths (very fast)
    await _checkCommonPaths(programs);

    return programs;
  }

  // Check common installation paths for faster detection
  static Future<void> _checkCommonPaths(Map<String, Map<String, String>> programs) async {
    Map<String, List<String>> commonPaths = {
      'Microsoft Office': [
        'C:\\Program Files\\Microsoft Office',
        'C:\\Program Files (x86)\\Microsoft Office',
      ],
      'Google Chrome': [
        'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
        'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
      ],
      'Mozilla Firefox': [
        'C:\\Program Files\\Mozilla Firefox\\firefox.exe',
        'C:\\Program Files (x86)\\Mozilla Firefox\\firefox.exe',
      ],
      'Microsoft Edge': [
        'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
        'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
      ],
      'WinRAR': [
        'C:\\Program Files\\WinRAR\\WinRAR.exe',
        'C:\\Program Files (x86)\\WinRAR\\WinRAR.exe',
      ],
      'RustDesk': [
        'C:\\Program Files\\RustDesk\\rustdesk.exe',
        'C:\\Program Files (x86)\\RustDesk\\rustdesk.exe',
      ],
    };

    for (String appName in commonPaths.keys) {
      String lowerName = appName.toLowerCase();
      if (!programs.containsKey(lowerName)) {
        for (String path in commonPaths[appName]!) {
          if (await File(path).exists()) {
            try {
              // Try to get version from file
              var result = await _shell.run('powershell "(Get-ItemProperty \'$path\').VersionInfo.FileVersion"').timeout(Duration(seconds: 2));
              String version = result.first.stdout.toString().trim();
              
              programs[lowerName] = {
                'name': appName,
                'version': version.isNotEmpty ? version : 'Terdeteksi',
              };
              break;
            } catch (e) {
              programs[lowerName] = {
                'name': appName,
                'version': 'Terdeteksi',
              };
              break;
            }
          }
        }
      }
    }

    // DirectX is always present on modern Windows
    programs['directx'] = {
      'name': 'DirectX',
      'version': '9.0c atau lebih tinggi',
    };
  }

  // Check single application from Control Panel data
  static Future<InstalledApplication> _checkApplicationFromControlPanel(
    String appName,
    Map<String, Map<String, String>> installedPrograms,
  ) async {
    // Search for the application in installed programs
    String searchKey = appName.toLowerCase();
    
    // Try exact match first
    if (installedPrograms.containsKey(searchKey)) {
      Map<String, String> appInfo = installedPrograms[searchKey]!;
      return InstalledApplication(
        name: appName,
        version: appInfo['version'] ?? 'Terdeteksi',
        isInstalled: true,
        status: 'Terinstal (Versi: ${appInfo['version'] ?? 'Terdeteksi'})',
        registryPath: 'Control Panel',
      );
    }

    // Try partial match
    for (String key in installedPrograms.keys) {
      if (key.contains(searchKey.split(' ')[0]) || searchKey.contains(key.split(' ')[0])) {
        Map<String, String> appInfo = installedPrograms[key]!;
        return InstalledApplication(
          name: appName,
          version: appInfo['version'] ?? 'Terdeteksi',
          isInstalled: true,
          status: 'Terinstal (Versi: ${appInfo['version'] ?? 'Terdeteksi'})',
          registryPath: 'Control Panel',
        );
      }
    }

    // Special cases
    if (appName == 'Microsoft Edge') {
      // Edge is built into Windows 10/11
      return InstalledApplication(
        name: appName,
        version: 'Built-in',
        isInstalled: true,
        status: 'Terinstal (Built-in Windows)',
        registryPath: 'System',
      );
    }

    return InstalledApplication(
      name: appName,
      version: 'Tidak terdeteksi',
      isInstalled: false,
      status: 'Tidak terinstal atau tidak terdeteksi',
      registryPath: '',
    );
  }

  // Application list management
  static Future<void> saveApplicationList(ApplicationList appList) async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      final file = File('${directory.path}/application_lists_enhanced.json');
      
      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      List<ApplicationList> existingLists = await loadApplicationLists();
      
      // Update existing list or add new one
      int existingIndex = existingLists.indexWhere((list) => list.name == appList.name);
      if (existingIndex != -1) {
        existingLists[existingIndex] = appList.copyWith(updatedAt: DateTime.now());
      } else {
        existingLists.add(appList);
      }
      
      String jsonString = jsonEncode(existingLists.map((list) => list.toMap()).toList());
      await file.writeAsString(jsonString);
      
      print('Successfully saved application list to: ${file.path}');
      print('Data saved: ${existingLists.length} lists, current list has ${appList.applications.length} apps');
    } catch (e) {
      print('Error saving application list: $e');
      throw Exception('Failed to save application list: $e');
    }
  }

  static Future<List<ApplicationList>> loadApplicationLists() async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      final file = File('${directory.path}/application_lists_enhanced.json');
      await _tryMigratePortableFile('application_lists_enhanced.json');
      
      print('Loading application lists from: ${file.path}');
      
      if (await file.exists()) {
        String jsonString = await file.readAsString();
        print('File content length: ${jsonString.length}');
        
        if (jsonString.isNotEmpty) {
          List<dynamic> jsonList = jsonDecode(jsonString);
          List<ApplicationList> result = jsonList.map((json) => ApplicationList.fromMap(json)).toList();
          print('Successfully loaded ${result.length} application lists');
          return result;
        }
      } else {
        print('Application lists file does not exist yet');
      }
    } catch (e) {
      print('Error loading application lists: $e');
    }
    
    return [];
  }

  // Helper method to get application documents directory with USB portability support
  static Future<Directory> _getApplicationDocumentsDirectory() async {
    // PRIORITY 1: Portable folder next to the executable: <exeDir>/data
    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final appDir = Directory('${exeDir.path}${Platform.pathSeparator}data');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } catch (e) {
      print('Portable dir (exeDir/data) not available: $e');
    }

    // PRIORITY 2: User Documents/AppData locations (non-portable)
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/SekomCleaner');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } catch (e) {
      print('Failed to get application documents directory: $e');

      try {
        final directory = await getApplicationSupportDirectory();
        final appDir = Directory('${directory.path}/SekomCleaner');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        return appDir;
      } catch (e2) {
        print('Failed to get application support directory: $e2');

        try {
          final directory = await getTemporaryDirectory();
          final appDir = Directory('${directory.path}/SekomCleaner');
          if (!await appDir.exists()) {
            await appDir.create(recursive: true);
          }
          return appDir;
        } catch (e3) {
          print('Failed to get temporary directory: $e3');

          // FINAL FALLBACK: current directory (best effort)
          try {
            final appDir = Directory('${Directory.current.path}/data');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            print('Using current directory fallback: ${appDir.path}');
            return appDir;
          } catch (_) {
            // As a last resort, return current directory itself
            return Directory.current;
          }
        }
      }
    }
  }

  // Attempt to migrate existing data file from old locations to the new portable folder.
  static Future<void> _tryMigratePortableFile(String filename) async {
    try {
      final targetDir = await _getApplicationDocumentsDirectory();
      final targetFile = File('${targetDir.path}/$filename');
      if (await targetFile.exists()) return;

      final candidates = <Directory>[];
      try {
        final d1 = await getApplicationDocumentsDirectory();
        candidates.add(Directory('${d1.path}/SekomCleaner'));
      } catch (_) {}
      try {
        final d2 = await getApplicationSupportDirectory();
        candidates.add(Directory('${d2.path}/SekomCleaner'));
      } catch (_) {}
      try {
        final d3 = await getTemporaryDirectory();
        candidates.add(Directory('${d3.path}/SekomCleaner'));
      } catch (_) {}

      for (final dir in candidates) {
        final src = File('${dir.path}/$filename');
        if (await src.exists()) {
          try {
            await targetDir.create(recursive: true);
            await src.copy(targetFile.path);
            print('Migrated $filename to portable folder: ${targetFile.path}');
            break;
          } catch (e) {
            // ignore copy errors
          }
        }
      }
    } catch (_) {
      // ignore migration errors
    }
  }

  static Future<ApplicationList> loadDefaultApplicationList() async {
    return ApplicationList(
      applications: predefinedApplications,
      name: 'Default Applications',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Execute shortcut applications with enhanced features
  static Future<Map<String, dynamic>> simulateInstallation(List<InstallableApplication> selectedApps) async {
    List<String> successfulRuns = [];
    List<String> failedRuns = [];
    
    for (InstallableApplication app in selectedApps) {
      if (app.isSelected) {
        try {
          String filePath = app.downloadUrl; // Path to installer
          
          if (filePath.isNotEmpty && await File(filePath).exists()) {
            // Try to run the installer
            try {
              final lower = filePath.toLowerCase();
              String command = '';
              
              // Determine how to run the file based on its type and options
              if (app.runAsAdmin) {
                // Run as administrator
                if (lower.endsWith('.msi') && app.silentInstall) {
                  // Silent MSI installation as admin
                  List<String> args = ['msiexec', '/i', '"$filePath"'];
                  if (app.installArgs.isNotEmpty) {
                    args.addAll(app.installArgs);
                  } else if (app.silentInstall) {
                    args.add('/qn');
                  }
                  command = 'powershell -Command "Start-Process -FilePath \\"${args[0]}\\" -ArgumentList \\"${args.sublist(1).join(' ')}\\" -Verb RunAs"';
                } else if (lower.endsWith('.exe') && app.silentInstall) {
                  // Silent EXE installation as admin
                  List<String> args = ['"$filePath"'];
                  if (app.installArgs.isNotEmpty) {
                    args.addAll(app.installArgs.map((arg) => '"$arg"'));
                  }
                  command = 'powershell -Command "Start-Process -FilePath ${args[0]} -ArgumentList \\"${args.sublist(1).join(' ')}\\" -Verb RunAs"';
                } else if (lower.endsWith('.bat') || lower.endsWith('.cmd')) {
                  // Batch file as admin
                  command = 'powershell -Command "Start-Process -FilePath \\"cmd.exe\\" -ArgumentList \\"/c \\"\\"$filePath\\"\\"${app.installArgs.isNotEmpty ? ' ${app.installArgs.join(' ')}' : ''}\\" -Verb RunAs"';
                } else if (lower.endsWith('.ps1')) {
                  // PowerShell script as admin
                  command = 'powershell -Command "Start-Process -FilePath \\"powershell.exe\\" -ArgumentList \\"-ExecutionPolicy Bypass -File \\"\\"$filePath\\"\\"${app.installArgs.isNotEmpty ? ' ${app.installArgs.join(' ')}' : ''}\\" -Verb RunAs"';
                } else {
                  // Generic file as admin
                  command = 'powershell -Command "Start-Process -FilePath \\"$filePath\\" -Verb RunAs"';
                }
              } else {
                // Run normally (not as admin)
                if (lower.endsWith('.msi')) {
                  // MSI installation
                  List<String> args = ['msiexec', '/i', '"$filePath"'];
                  if (app.installArgs.isNotEmpty) {
                    args.addAll(app.installArgs);
                  } else if (app.silentInstall) {
                    args.add('/qn');
                  }
                  command = 'cmd /c ${args.join(' ')}';
                } else if (lower.endsWith('.exe')) {
                  // EXE installation
                  List<String> args = ['"$filePath"'];
                  if (app.installArgs.isNotEmpty) {
                    args.addAll(app.installArgs.map((arg) => '"$arg"'));
                  }
                  command = 'cmd /c start "" ${args.join(' ')}';
                } else if (lower.endsWith('.bat') || lower.endsWith('.cmd')) {
                  // Batch file
                  command = 'cmd /c "$filePath"${app.installArgs.isNotEmpty ? ' ${app.installArgs.join(' ')}' : ''}';
                } else if (lower.endsWith('.ps1')) {
                  // PowerShell script
                  command = 'powershell -ExecutionPolicy Bypass -File "$filePath"${app.installArgs.isNotEmpty ? ' ${app.installArgs.join(' ')}' : ''}';
                } else {
                  // Generic file
                  command = 'cmd /c start "" "$filePath"';
                }
              }
              
              await _shell.run(command);
              successfulRuns.add(app.name);
            } catch (e) {
              failedRuns.add('${app.name} (Error: ${e.toString()})');
            }
          } else {
            failedRuns.add('${app.name} (File tidak ditemukan: $filePath)');
          }
        } catch (e) {
          failedRuns.add('${app.name} (Error: ${e.toString()})');
        }
      }
    }
    
    return {
      'successful': successfulRuns,
      'failed': failedRuns,
      'total': selectedApps.where((app) => app.isSelected).length,
    };
  }

  // Helper method to convert absolute path to relative path for USB portability
  // Make path relative to the executable directory so it travels with the USB.
  static String makePathPortable(String absolutePath) {
    try {
      // Base directory is the executable location (portable-friendly)
      String baseDir;
      try {
        baseDir = File(Platform.resolvedExecutable).parent.path;
      } catch (_) {
        baseDir = Directory.current.path;
      }

      final absNorm = absolutePath.replaceAll('/', '\\');
      final baseNorm = baseDir.replaceAll('/', '\\');

      // Only make relative if file resides under the base directory
      if (absNorm.toLowerCase().startsWith(baseNorm.toLowerCase())) {
        final relative = '.${absNorm.substring(baseNorm.length)}';
        return relative;
      }

      // If not under base dir (e.g., different drive or external path), keep absolute
      return absolutePath;
    } catch (e) {
      return absolutePath;
    }
  }

  // Helper method to resolve portable path back to absolute
  // Resolve path relative to the executable directory (portable-friendly).
  static String resolvePortablePath(String portablePath) {
    try {
      if (portablePath.startsWith('.')) {
        String baseDir;
        try {
          baseDir = File(Platform.resolvedExecutable).parent.path;
        } catch (_) {
          baseDir = Directory.current.path;
        }
        return portablePath.replaceFirst('.', baseDir);
      }

      // Already absolute path
      return portablePath;
    } catch (e) {
      return portablePath;
    }
  }

  // ===== Default app checks persistence =====
  static Future<void> saveDefaultAppChecks(List<String> names) async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      final file = File('${directory.path}/default_app_checks.json');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final uniq = names.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      await file.writeAsString(jsonEncode(uniq));
      print('Saved ${uniq.length} default app checks to: ${file.path}');
    } catch (e) {
      print('Error saving default app checks: $e');
    }
  }

  static Future<List<String>> loadDefaultAppChecks() async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      final file = File('${directory.path}/default_app_checks.json');
      await _tryMigratePortableFile('default_app_checks.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        }
      }
    } catch (e) {
      print('Error loading default app checks: $e');
    }
    return <String>[];
  }

  // ===== Installed programs listing (names only) =====
  static Future<List<String>> listInstalledProgramNames() async {
    final map = await _getInstalledProgramsFromControlPanel();
    final names = map.values
        .map((m) => (m['name'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }
  
  // Get file type from file path
  static String getFileTypeFromPath(String path) {
    if (path.isEmpty) return '';
    
    final lower = path.toLowerCase();
    if (lower.endsWith('.exe')) return 'exe';
    if (lower.endsWith('.msi')) return 'msi';
    if (lower.endsWith('.bat')) return 'bat';
    if (lower.endsWith('.cmd')) return 'cmd';
    if (lower.endsWith('.ps1')) return 'ps1';
    if (lower.endsWith('.vbs')) return 'vbs';
    if (lower.endsWith('.js')) return 'js';
    if (lower.endsWith('.jar')) return 'jar';
    if (lower.endsWith('.py')) return 'py';
    if (lower.endsWith('.sh')) return 'sh';
    
    // Extract extension
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1 && lastDot < path.length - 1) {
      return path.substring(lastDot + 1);
    }
    
    return '';
  }
}
