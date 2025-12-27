# Sekom Clenner - Elevation Guide

## Why Administrator Privileges Are Required

Sekom Clenner performs deep system cleaning and optimization tasks that require administrator access:

### System-Level Operations
- **Registry Cleaning**: Removes invalid registry entries and optimizes registry hives
- **Service Management**: Controls Windows services (Windows Update, Windows Search, etc.)
- **File System Operations**: Accesses protected system folders and files
- **Windows Defender**: Updates antivirus signatures and manages security settings
- **Driver Management**: Scans and updates system drivers
- **Activation Tools**: Manages Windows and Office activation status

### Protected System Areas
- `C:\Windows\System32` - System files and drivers
- `C:\Program Files` - Protected application directories
- Windows Registry hives (`HKEY_LOCAL_MACHINE`, `HKEY_CLASSES_ROOT`)
- System services and processes
- Windows Update components

## Elevation Error Solutions

### Option 1: Run as Administrator (Recommended)
1. **Right-click** on `sekom_clenner.exe`
2. Select **"Run as administrator"**
3. Click **"Yes"** when UAC prompt appears

### Option 2: Use the Launcher Script
1. Navigate to the `scripts` folder
2. Right-click on `elevate_launcher.bat`
3. Select **"Run as administrator"**
4. Follow the on-screen instructions

### Option 3: Move to User Directory
If you cannot get administrator access:
1. Copy the entire application folder to your user directory
2. Example: `C:\Users\YourUsername\sekom_clenner`
3. Run from there (some features may be limited)

### Option 4: Disable UAC (Not Recommended)
⚠️ **Warning**: This reduces system security
1. Open Control Panel → User Accounts
2. Click "Change User Account Control settings"
3. Move slider to "Never notify"
4. Restart computer

## Troubleshooting Elevation Issues

### Error: "The requested operation requires elevation"
**Cause**: Application is in a protected directory (Program Files)
**Solution**: Move to user directory or run as administrator

### Error: "Access is denied"
**Cause**: Insufficient permissions for system operations
**Solution**: Ensure you're running as administrator

### UAC Prompt Not Appearing
**Cause**: UAC might be disabled or corrupted
**Solution**: 
1. Check UAC settings in Control Panel
2. Run `sfc /scannow` in elevated Command Prompt
3. Restart Windows

### Antivirus Blocking Elevation
**Cause**: Security software preventing privilege escalation
**Solution**:
1. Temporarily disable antivirus
2. Add application to antivirus whitelist
3. Check Windows Defender exclusions

## Advanced Solutions

### PowerShell Elevation
```powershell
# Run in PowerShell as Administrator
Start-Process "D:\Program Files\sekom_clenner\build\windows\x64\runner\Debug\sekom_clenner.exe" -Verb RunAs
```

### Task Scheduler Method
1. Open Task Scheduler as Administrator
2. Create new task with highest privileges
3. Set trigger to run on demand
4. Set action to launch sekom_clenner.exe

### Compatibility Mode
1. Right-click sekom_clenner.exe → Properties
2. Go to Compatibility tab
3. Check "Run this program as an administrator"
4. Apply and OK

## Security Considerations

### Why We Need Admin Access
- **System Integrity**: Proper cleaning requires access to all system areas
- **Registry Protection**: Safe registry modification needs admin rights
- **Service Control**: Managing Windows services requires elevated privileges
- **File Protection**: Accessing protected system files for cleaning

### Safety Measures
- **Backup First**: Always backup registry before cleaning
- **System Restore**: Create restore points before major operations
- **Gradual Cleaning**: Start with less aggressive cleaning options
- **Monitor Changes**: Check what changes are being made

## Alternative Approaches

### Limited User Mode
If you cannot get administrator access:
- Use only basic cleaning features
- Focus on user-profile cleaning (Downloads, Documents, etc.)
- Use browser cleaning features
- Manual registry cleaning with regedit (requires admin anyway)

### Portable Mode
Consider creating a portable version:
1. Extract to USB drive
2. Run from there with limited features
3. Use only non-administrative cleaning options

## Getting Help

If elevation issues persist:
1. Check Windows Event Viewer for detailed error messages
2. Run `eventvwr.msc` and look for Application errors
3. Contact support with specific error codes
4. Consider using alternative cleaning tools for non-admin scenarios

## Command Line Options

### Silent Elevation
```batch
# Run with automatic elevation
powershell -Command "Start-Process 'sekom_clenner.exe' -Verb RunAs -ArgumentList '/silent'"
```

### Debug Mode
```batch
# Run with debug logging
sekom_clenner.exe --debug --log-level=verbose
```

Remember: Administrator privileges are required for comprehensive system cleaning. The application is designed to safely manage elevated operations while protecting your system integrity.
