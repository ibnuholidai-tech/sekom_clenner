Sekom Cleaner - Windows Release Checklist

Goal
Produce a Windows release that minimizes antivirus/SmartScreen false positives without removing any feature.

1) Build Configuration
- Manifest privilege:
  - Confirm windows/runner/runner.exe.manifest uses:
    <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
- Auto-elevate mode:
  - Default: disabled to reduce heuristic flags.
  - To enable auto-elevate on specific builds (without code change):
    flutter build windows --release --dart-define=AUTO_ELEVATE=true
  - File: lib/config/build_flags.dart contains kAutoElevate.

2) Clean Build
- Flutter Windows Release:
  flutter build windows --release
- Ensure build artifacts exist:
  - build/windows/x64/runner/Release/sekom_clenner.exe
  - build/windows/x64/runner/Release/flutter_windows.dll, data/, flutter_assets/, etc.

3) Optional Code Signing (Recommended)
- Sign App Binaries (before building installer):
  - sekom_clenner.exe
  - native/publish/SekomHelper.exe
- Use signtool (Windows SDK) with SHA256 and timestamp:
  signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f "C:\path\to\cert.pfx" /p "PASSWORD" "path\to\binary.exe"
- Verify:
  signtool verify /pa /v "path\to\binary.exe"
- See docs/INSTALLER_SIGNING.md for full guidance.

4) Installer Build (Inno Setup)
- Input script: scripts/installer/sekom_clenner.iss
- Notes:
  - Excludes PDB and map files already configured.
  - PrivilegesRequired=admin (installing into Program Files).
  - Optional: uncomment and configure SignTool in .iss to sign installer and uninstaller.
- Build:
  - Use Inno Setup GUI or ISCC to produce:
    dist/installer/sekom_cleanner-<version>.exe

5) Post-Build Verification
- Run on a clean Windows VM:
  - Launch app normally (non-admin). Features that require admin must prompt UAC when used.
  - Verify critical features:
    - System Cleaner: Recent files, Jump lists, Office MRU (HKCU), Start/Photos unpin.
    - Application Manager/Uninstaller.
    - Windows Update/Defender checks and actions.
    - Activation buttons still present; user confirmation dialog should show command text.
- Check binary metadata:
  - Right-click -> Properties -> Details:
    - Company: Sekom
    - Product Name: Sekom Cleaner
    - File Description: Sekom Cleaner
  - Origin/Pubisher matches your certificate (if signed).

6) Antivirus & SmartScreen
- Local scan with Windows Defender:
  - Right-click binaries and installer -> Scan with Microsoft Defender.
- Optional: Upload hashes to VirusTotal to check detections.
- Distribute through trusted channels to build SmartScreen reputation.

7) Distribution Package
- Include:
  - Installer: dist/installer/sekom_cleanner-<version>.exe
  - Release notes/changelog.
  - Known requirements:
    - WebView2 Runtime (usually present on Win10/11).
    - If SekomHelper.exe is not self-contained, ensure .NET 7 Desktop Runtime is available or rebuild helper as self-contained.
- Do NOT include:
  - *.pdb files
  - Debug artifacts
  - Internal logs

8) Troubleshooting
- If SmartScreen warns:
  - Ensure all binaries + installer are consistently signed.
  - EV certs improve reputation faster than OV.
  - Give some time for reputation to build across installs/downloads.
- If AV flags persist:
  - Confirm asInvoker manifest is used.
  - Ensure auto-elevate is disabled except when you explicitly enable it via dart-define.
  - Keep PowerShell-heavy operations behind explicit user actions with clear UI confirmations.

9) Command Examples
- Default release build (no auto-elevate):
  flutter build windows --release
- Release build that auto-elevates on start (optional/internal builds):
  flutter build windows --release --dart-define=AUTO_ELEVATE=true

10) Change Log
- Update app version in scripts/installer/sekom_clenner.iss (#define MyAppVersion).
- Update Runner.rc version via FLUTTER_VERSION (from Flutter) or keep synced manually if needed.
