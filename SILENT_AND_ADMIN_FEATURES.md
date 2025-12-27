# Silent Mode & Run as Administrator - Enhanced Features

## Overview
Fitur Silent Install dan Run as Administrator telah disempurnakan dengan implementasi yang lebih robust, lengkap, dan user-friendly.

## Fitur Utama

### 1. **Run as Administrator** (Elevated Execution)
Menjalankan aplikasi dengan hak akses administrator (UAC elevation).

#### Cara Kerja:
- **Windows**: Menggunakan PowerShell `Start-Process -Verb RunAs` untuk elevation
- **Linux/Unix**: Menggunakan `sudo`
- Support untuk berbagai tipe file: `.exe`, `.msi`, `.bat`, `.cmd`, `.ps1`, dll

#### Implementasi:
```dart
if (app.runAsAdmin) {
  // Windows: Elevation via PowerShell
  String psCommand = '''
    Start-Process -FilePath 'program.exe' -Verb RunAs -Wait
  ''';
  
  // Unix: Elevation via sudo
  await Process.run('sudo', ['program', 'arg1', 'arg2']);
}
```

### 2. **Silent Install** (Background Installation)
Instalasi aplikasi di background tanpa tampilan UI interaktif.

#### Dukungan File Type:

| Type | Silent Flags | Behavior |
|------|-------------|----------|
| **MSI** | `/quiet /qn /norestart REBOOT=ReallySuppress` | Instalasi tanpa UI, no restart |
| **EXE** | `/S /silent /quiet /qn ALLUSERS=1` | Instalasi background, all users |
| **BAT/CMD** | `/C` | Batch execution normal |
| **PS1** | `-NoProfile -ExecutionPolicy Bypass` | PowerShell hidden window |

#### Implementasi:
```dart
if (app.silentInstall) {
  switch (fileExtension) {
    case 'msi':
      arguments = ['/i', filePath, '/quiet', '/qn', '/norestart'];
      break;
    case 'exe':
      arguments = ['/S', '/silent', '/quiet', '/qn', 'ALLUSERS=1'];
      break;
  }
}
```

### 3. **Kombinasi Mode (Admin + Silent)**
Support penuh untuk menjalankan instalasi secara bersamaan dengan elevation dan silent mode.

#### Workflow:
1. Generate PowerShell script dengan settings silent
2. Execute script dengan elevation (`-Verb RunAs`)
3. Process berjalan di background dengan hak admin
4. Cleanup temporary files setelah selesai

### 4. **User Interface Enhancements**

#### Badges di Shortcut List:
- **ADMIN** (Orange): Aplikasi akan dijalankan dengan hak administrator
- **SILENT** (Purple): Aplikasi akan diinstall/dijalankan di background

#### Edit Dialog:
- Checkbox `Run as Administrator`: Enable/disable elevation
- Checkbox `Silent Install`: Enable/disable background mode
- Real-time preview di confirmation dialog

#### Installation Progress:
- Status menampilkan mode (silent/admin) untuk setiap aplikasi
- Progress bar dengan detail aplikasi yang sedang diinstall
- Summary hasil instalasi

## Method Reference

### `_installSingleApp(InstallableApplication app)`
Instalasi satu aplikasi dengan dukungan penuh silent + admin mode.

**Parameters:**
- `app.filePath`: Path ke file installer
- `app.fileType`: Tipe file (exe, msi, bat, cmd, ps1, dll)
- `app.silentInstall`: Enable silent mode
- `app.runAsAdmin`: Enable admin elevation
- `app.installArgs`: Custom arguments

**Exit Codes Accepted:**
- `0`: Success
- `3010`: Reboot required
- `1602`: User cancelled

### `_runSingleApp(InstallableApplication app)`
Menjalankan aplikasi (shortcut) dengan dukungan silent + admin mode.

**Behavior:**
- Non-admin: Direct execution atau `Process.start` dengan `detached` mode untuk silent
- Admin: PowerShell elevation via `Start-Process -Verb RunAs`
- Silent: `-WindowStyle Hidden` untuk PowerShell atau `ProcessStartMode.detached` untuk direct run

## Technical Details

### File Type Detection
Automatic detection dari file extension jika `fileType` tidak diset:
```dart
String fileExt = app.fileType.isNotEmpty 
    ? app.fileType.toLowerCase() 
    : file.path.split('.').last.toLowerCase();
```

### Temporary Script Handling
Untuk elevated execution yang kompleks, script PowerShell dibuat di `%TEMP%`:
```dart
final tempDir = Directory.systemTemp;
final scriptFile = File('${tempDir.path}\\script_${timestamp}.ps1');
await scriptFile.writeAsString(psCommand);
// Execute & cleanup after 2 seconds
```

### Error Handling
- Comprehensive error reporting dengan exit codes
- Stderr capture untuk troubleshooting
- User-friendly error dialogs

## Usage Examples

### Example 1: Silent MSI Install with Admin Rights
```dart
InstallableApplication app = InstallableApplication(
  id: 'office2024',
  name: 'Microsoft Office 2024',
  description: 'Instalasi Office 2024 background tanpa UI',
  filePath: 'C:\\Installers\\office_2024.msi',
  fileType: 'msi',
  runAsAdmin: true,          // ← Elevation
  silentInstall: true,       // ← Silent mode
  installArgs: ['ALLUSERS=1'],
);
```

### Example 2: EXE Run as Admin (Normal UI)
```dart
InstallableApplication app = InstallableApplication(
  id: 'notepad++',
  name: 'Notepad++',
  description: 'Text Editor',
  filePath: 'C:\\Program Files\\Notepad++\\notepad++.exe',
  fileType: 'exe',
  runAsAdmin: true,          // ← Elevation only
  silentInstall: false,      // ← Normal UI
);
```

### Example 3: PowerShell Script Silent (Background)
```dart
InstallableApplication app = InstallableApplication(
  id: 'cleanup_script',
  name: 'System Cleanup',
  description: 'Background cleanup script',
  filePath: 'C:\\Scripts\\cleanup.ps1',
  fileType: 'ps1',
  runAsAdmin: false,         // ← No elevation
  silentInstall: true,       // ← Background
);
```

## Troubleshooting

### Issue: "Access Denied" on MSI Installation
**Solution:** Enable `Run as Administrator` checkbox for MSI files

### Issue: Installation Hangs
**Solution:** 
1. Enable `Silent Install` to skip UI interaction
2. Check MSI log: `msiexec.exe /i installer.msi /l*v logfile.txt`

### Issue: Script Doesn't Execute
**Solution:** 
1. Verify PowerShell execution policy: `Get-ExecutionPolicy`
2. Use `-ExecutionPolicy Bypass` flag (already included)
3. Check temp folder permissions

## Storage Location & Portability
- All settings disimpan dengan portable path (`<exeDir>/data`)
- Silent/Admin preferences persist across sessions
- Data accessible di flashdisk/removable drives

## Future Enhancements
- [ ] Progress callback untuk real-time UI updates
- [ ] Installation rollback on error
- [ ] Custom installer parameters wizard
- [ ] Installation scheduling (batch mode)
- [ ] Hardware detection for system requirements
