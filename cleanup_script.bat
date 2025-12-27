@echo off
echo Cleaning up unused keyboard test files...

:: Delete unused keyboard test files
del /q "lib\screens\keyboard_test_isolated_screen.dart" 2>nul
del /q "lib\screens\keyboard_test_screen_final.dart" 2>nul
del /q "lib\screens\testing_screen_final_complete.dart" 2>nul
del /q "lib\screens\testing_screen_final_fixed.dart" 2>nul
del /q "lib\screens\testing_screen_final.dart" 2>nul
del /q "lib\screens\testing_screen_fix.dart" 2>nul
del /q "lib\screens\testing_screen_perfect.dart" 2>nul
del /q "lib\screens\testing_screen_repaired.dart" 2>nul
del /q "lib\screens\testing_screen_stable.dart" 2>nul

del /q "lib\widgets\keyboard_test_dialog_page.dart" 2>nul
del /q "lib\widgets\keyboard_test_dialog_stable.dart" 2>nul
del /q "lib\widgets\keyboard_test_direct.dart" 2>nul
del /q "lib\widgets\keyboard_test_final_complete.dart" 2>nul
del /q "lib\widgets\keyboard_test_final.dart" 2>nul
del /q "lib\widgets\keyboard_test_fix.dart" 2>nul
del /q "lib\widgets\keyboard_test_isolated.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_complete.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_enhanced.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_final_focus.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_fixed.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_ghost.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_native.dart" 2>nul
del /q "lib\widgets\keyboard_test_offline_rapih_complete.dart" 2>nul
del /q "lib\widgets\keyboard_test_page.dart" 2>nul
del /q "lib\widgets\keyboard_test_stable.dart" 2>nul
del /q "lib\widgets\keyboard_test_web_offline.dart" 2>nul

echo Cleanup completed!
echo.
echo Now update the main.dart file to use the ModernAppScreen instead of EnhancedApplicationScreen.
echo.
echo In main.dart, replace:
echo import 'screens/enhanced_application_screen.dart';
echo with:
echo import 'screens/modern_app_screen.dart';
echo.
echo And in the TabBarView, replace:
echo EnhancedApplicationScreen(),
echo with:
echo ModernAppScreen(),
echo.
pause
