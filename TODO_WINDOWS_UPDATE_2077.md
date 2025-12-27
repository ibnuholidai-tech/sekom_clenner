Title: Standardize Windows Update Pause to 2077

Goal:
Ensure all Windows Update service implementations set Windows Update pause registry keys to year 2077 and clear them correctly on resume, matching the Registry screenshot:
HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings

Keys to set when pausing:
- PauseUpdatesStartTime = (Get-Date) in ISO 8601 UTC "yyyy-MM-ddTHH:mm:ssZ"
- PauseUpdatesExpiryTime = 2077-12-31T..Z
- PauseFeatureUpdatesStartTime = (Get-Date)
- PauseFeatureUpdatesEndTime = 2077-12-31T..Z
- PauseQualityUpdatesStartTime = (Get-Date)
- PauseQualityUpdatesEndTime = 2077-12-31T..Z
- AllowMUUpdateService (DWORD) = 0  [as per screenshot]

Keys to remove when resuming:
- PauseUpdatesStartTime
- PauseUpdatesExpiryTime
- PauseFeatureUpdatesStartTime
- PauseFeatureUpdatesEndTime
- PauseQualityUpdatesStartTime
- PauseQualityUpdatesEndTime
- AllowMUUpdateService

Implementation Steps:
1) lib/services/windows_update_service.dart
   - Add PauseUpdatesStartTime and AllowMUUpdateService=0 in pause script.
   - Remove PauseUpdatesStartTime and AllowMUUpdateService in resume script.

2) lib/services/windows_update_service_registry.dart
   - Change end date from (Get-Date).AddDays(365) to 2077-12-31.
   - Add PauseUpdatesStartTime and AllowMUUpdateService=0.
   - Update resume to remove all keys including PauseUpdatesStartTime and AllowMUUpdateService.

3) lib/services/windows_update_service_simple.dart
   - Update _simpleRegistryPause() to set all six keys to 2077 + AllowMUUpdateService=0.
   - Update _clearRegistry() to remove all six keys + AllowMUUpdateService.

4) lib/services/windows_update_service_complete.dart
   - Set all six keys to 2077 + AllowMUUpdateService=0 in pause.
   - Remove them in resume.

5) lib/services/windows_update_service_final.dart
   - In _forcePause(), set all six keys to 2077 + AllowMUUpdateService=0.
   - In _forceResume(), remove all keys including PauseUpdatesStartTime + AllowMUUpdateService.

6) lib/services/windows_update_service_forced.dart
   - In _forcePauseViaRegistry(), change all AddDays(365) to fixed 2077-12-31 and add PauseUpdatesStartTime for both HKCU and HKLM; also set AllowMUUpdateService=0 (HKLM).
   - In _forceResumeViaRegistry(), remove PauseUpdatesStartTime and AllowMUUpdateService in addition to existing removes.

7) lib/services/windows_update_service_fixed.dart
   - In _forcePause(), set all six keys to 2077 + AllowMUUpdateService=0 (currently only ExpiryTime for 1 year).
   - In _forceResume(), remove all keys including PauseUpdatesStartTime + AllowMUUpdateService.

Validation:
- Leave isWindowsUpdatePaused() checks as-is (ExpiryTime > Get-Date) across services.
- Comments and user-visible messages should reflect “2077” instead of “1 year”.

Progress Tracking:
- [ ] Step 1: Update windows_update_service.dart
- [ ] Step 2: Update windows_update_service_registry.dart
- [ ] Step 3: Update windows_update_service_simple.dart
- [ ] Step 4: Update windows_update_service_complete.dart
- [ ] Step 5: Update windows_update_service_final.dart
- [ ] Step 6: Update windows_update_service_forced.dart
- [ ] Step 7: Update windows_update_service_fixed.dart
