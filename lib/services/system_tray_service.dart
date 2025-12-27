import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Service untuk system tray integration
class SystemTrayService {
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();

  bool _isInitialized = false;

  /// Initialize system tray
  Future<void> initialize({
    required String appName,
    required String iconPath,
    required VoidCallback onShow,
    required VoidCallback onExit,
  }) async {
    if (_isInitialized) return;

    try {
      // Set icon
      await _systemTray.initSystemTray(title: appName, iconPath: iconPath);

      // Create menu
      await _menu.buildFrom([
        MenuItemLabel(
          label: 'Show $appName',
          onClicked: (menuItem) => onShow(),
        ),
        MenuSeparator(),
        MenuItemLabel(label: 'Exit', onClicked: (menuItem) => onExit()),
      ]);

      // Set menu
      await _systemTray.setContextMenu(_menu);

      // Set tooltip
      await _systemTray.setToolTip(appName);

      // Handle click
      _systemTray.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          onShow();
        } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing system tray: $e');
    }
  }

  /// Update tooltip
  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;
    await _systemTray.setToolTip(tooltip);
  }

  /// Update icon
  Future<void> updateIcon(String iconPath) async {
    if (!_isInitialized) return;
    await _systemTray.setImage(iconPath);
  }

  /// Show notification balloon (Windows only)
  Future<void> showNotification({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;
    // Note: System tray notifications are platform-specific
    // This is a placeholder for future implementation
  }

  /// Destroy system tray
  Future<void> destroy() async {
    if (!_isInitialized) return;
    await _systemTray.destroy();
    _isInitialized = false;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Helper untuk membuat icon path
class SystemTrayHelper {
  /// Get icon path untuk Windows
  static String getWindowsIconPath() {
    // Icon harus berada di folder assets
    // Untuk Windows, gunakan .ico file
    return path.join(Directory.current.path, 'assets', 'app_icon.ico');
  }

  /// Get icon path untuk development
  static String getDevIconPath() {
    // Untuk development, bisa menggunakan PNG
    return path.join(Directory.current.path, 'assets', 'app_icon.png');
  }
}
