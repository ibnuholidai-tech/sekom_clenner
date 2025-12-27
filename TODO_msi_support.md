# Task: Add .msi support to Application Manager "Tambah Shortcut"

Status: Completed

Goals:
- Allow users to add and run .msi installers in addition to .exe in the Application Manager.

Steps:
1) Update UI/validation in lib/screens/application_screen.dart
   - Change labels and helper texts from .exe to .exe/.msi
   - Validation: accept .exe or .msi extensions for add/edit dialogs
   - File picker: allow ['exe', 'msi'] and update dialog title
   - Update confirmation note text to mention .exe/.msi

2) Update execution logic in lib/services/application_service.dart
   - simulateInstallation(): if file ends with .msi, launch with:
     cmd /c start "" msiexec /i "path"
   - Keep .exe launching with:
     cmd /c start "" "path"
   - Adjust comments to reflect .exe or .msi

3) Update empty-state hint in lib/widgets/installable_apps_section.dart
   - Change hint text to “.exe atau .msi”

Testing checklist:
- Add shortcut with .exe (passes validation, saved portable path, runs)
- Add shortcut with .msi (passes validation, saved portable path, runs via msiexec)
- Edit existing shortcut to .msi path (validation and save)
- Run multiple selected shortcuts (.exe and .msi mixed)
- Persistence: application_lists.json updated and reloaded correctly
