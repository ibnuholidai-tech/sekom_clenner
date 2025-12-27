Installer and Binary Code Signing Guide (Windows)

Goal
Improve SmartScreen/AV reputation and reduce false positives by code signing:
- App binary: sekom_clenner.exe
- Native helper: SekomHelper.exe
- Installer (Inno Setup) and Uninstaller

Prerequisites
- A valid code signing certificate (OV or EV) issued to your organization:
  - PFX file (certificate + private key), e.g., C:\certs\sekom-codesign.pfx
  - Certificate password
- Windows 10/11 with Windows SDK installed (signtool.exe available)
  - Typical path: "C:\Program Files (x86)\Windows Kits\10\bin\<version>\x64\signtool.exe"
- Built binaries:
  - Flutter: build\windows\x64\runner\Release\sekom_clenner.exe
  - Helper: native\publish\SekomHelper.exe
  - Inno Setup output: dist\installer\sekom_cleanner-<version>.exe

Timestamp servers (choose one)
- DigiCert: http://timestamp.digicert.com
- GlobalSign: http://timestamp.globalsign.com/?signature=sha2
Use SHA256 digest for file and timestamp: /fd SHA256 /td SHA256

1) Sign App Binaries (EXE)
Sign sekom_clenner.exe and SekomHelper.exe after building, before creating the installer.

Example command using PFX:
"C:\Path\To\signtool.exe" sign ^
  /fd SHA256 ^
  /tr http://timestamp.digicert.com ^
  /td SHA256 ^
  /f "C:\certs\sekom-codesign.pfx" ^
  /p "YOUR_PFX_PASSWORD" ^
  "D:\Program Files\sekom_clenner\build\windows\x64\runner\Release\sekom_clenner.exe"

Repeat for SekomHelper.exe:
"C:\Path\To\signtool.exe" sign ^
  /fd SHA256 ^
  /tr http://timestamp.digicert.com ^
  /td SHA256 ^
  /f "C:\certs\sekom-codesign.pfx" ^
  /p "YOUR_PFX_PASSWORD" ^
  "D:\Program Files\sekom_clenner\native\publish\SekomHelper.exe"

Alternative using certificate subject (/n):
"C:\Path\To\signtool.exe" sign ^
  /fd SHA256 ^
  /tr http://timestamp.digicert.com ^
  /td SHA256 ^
  /n "Sekom" ^
  "path\to\binary.exe"

Verify signature:
"C:\Path\To\signtool.exe" verify /pa /v "path\to\binary.exe"

2) Build and Sign the Installer (Inno Setup)
First, compile the installer normally using ISCC or the GUI:
- Input script: scripts\installer\sekom_clenner.iss
- Output: dist\installer\sekom_cleanner-<version>.exe

Option A: Post-build external signing
"C:\Path\To\signtool.exe" sign ^
  /fd SHA256 ^
  /tr http://timestamp.digicert.com ^
  /td SHA256 ^
  /f "C:\certs\sekom-codesign.pfx" ^
  /p "YOUR_PFX_PASSWORD" ^
  "D:\Program Files\sekom_clenner\dist\installer\sekom_cleanner-1.0.1.exe"

Option B: Enable signing inside .iss
Open scripts\installer\sekom_clenner.iss and uncomment/adapt the SignTool lines:
; SignTool=62
; SignTool=cmd /c "signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /f ""C:\certs\sekom-codesign.pfx"" /p ""YOUR_PFX_PASSWORD"" $f"
; SignedUninstaller=yes
; SignToolRetryCount=3
; SignToolRetryDelay=2000
; SignToolMinimumFileSize=8192

Notes:
- If using subject name instead of PFX: replace /f ... /p ... with /n "Sekom"
- Keep the timestamp server; without it, signatures can become invalid after cert expiry.
- The Uninstaller will be signed if SignedUninstaller=yes is set.

3) Best Practices
- Use consistent Publisher metadata:
  - windows\runner\Runner.rc updated to CompanyName=Sekom, ProductName=Sekom Cleaner
- Keep the app manifest at asInvoker and elevate only when required (reduces false positives).
- Exclude PDB and map files from installer to reduce noise:
  - Already configured in scripts\installer\sekom_clenner.iss Excludes: "*.pdb;*.map"
- After signing, scan artifacts with Windows Defender and optionally submit to VirusTotal.
- Distribute via trusted channels, and maintain versioning and changelogs.

4) CI/CD Integration (Optional)
- Add a signing step in your pipeline:
  - Build -> Sign binaries -> Build installer -> Sign installer -> Publish
- Store PFX securely (e.g., GitHub Actions secrets + secure download at runtime).
- Never commit certificates or passwords to the repository.

5) Troubleshooting
- "No certificates were found that met all the given criteria":
  - Ensure correct /f or /n parameter; confirm cert is installed or PFX path is correct.
- "The specified timestamp server either could not be reached or returned an invalid response":
  - Try another timestamp server URL or check network/firewall.
- SmartScreen still warns:
  - It can take time to build reputation, especially with OV certs; EV certs help reduce warnings faster.
  - Ensure every release is consistently signed (binaries + installer).
