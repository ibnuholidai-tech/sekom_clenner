# Sekom Clenner - Elevation Error Solutions

## Quick Fix for "The requested operation requires elevation"

### Immediate Solutions

#### 1. Run as Administrator (Fastest)
```batch
# Right-click method
Right-click sekom_clenner.exe → "Run as administrator" → Click "Yes"

# Command line method
runas /user:Administrator "D:\Program Files\sekom_clenner\build\windows\x64\runner\Debug\sekom_clenner.exe"
```

#### 2. Use Launcher Script
```batch
# Run the provided launcher
cd D:\Program Files\sekom_clenner
scripts\elevate_launcher.bat
```

#### 3. Move to User Directory
```batch
# Copy to user directory (limited features)
xcopy "D:\Program Files\sekom_clenner" "C:\Users\%USERNAME%\sekom_clenner\" /E /I
cd "C:\Users\%USERNAME%\sekom_clenner"
build\windows\x64\runner\Debug\sekom_clenner.exe
```

### Why This Happens

**Location**: Your app is in `Program Files` which requires admin rights
**Manifest**: Configured for `requireAdministrator` level
**UAC**: Windows User Account Control blocks elevation

### Permanent Solutions

#### Option A: Keep Current Setup (Recommended)
- **Keep admin requirement** for full functionality
- **Use launcher scripts** for easy elevation
- **Add to antivirus whitelist**

#### Option B: Change Manifest (Advanced)
- Modify `windows/runner/runner.exe.manifest`
- Change `requireAdministrator` to `asInvoker`
- **Warning**: Some features may not work

#### Option C: Install to User Directory
- Move entire application to user-accessible location
- **Limitation**: Reduced system cleaning capabilities

### Troubleshooting Commands

```batch
# Check current elevation status
powershell -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)"

# Test UAC settings
powershell -Command "Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA"

# Check file permissions
icacls "D:\Program Files\sekom_clenner\build\windows\x64\runner\Debug\sekom_clenner.exe"
```

### Security Notes

✅ **Safe**: Application requires admin for legitimate system cleaning
✅ **Signed**: Check digital signature before running
✅ **Transparent**: All operations are logged and reversible

### Support

If issues persist:
1. Check Windows Event Viewer
2. Run Windows System File Checker: `sfc /scannow`
3. Contact support with error codes
