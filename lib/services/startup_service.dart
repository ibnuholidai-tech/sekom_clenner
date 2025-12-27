import 'dart:io';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service untuk auto-startup Windows
class StartupService {
  bool _isInitialized = false;

  /// Initialize startup service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
      );

      _isInitialized = true;
    } catch (e) {
      print('Error initializing startup service: $e');
    }
  }

  /// Enable auto-startup
  Future<bool> enable() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await launchAtStartup.enable();
      return true;
    } catch (e) {
      print('Error enabling auto-startup: $e');
      return false;
    }
  }

  /// Disable auto-startup
  Future<bool> disable() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await launchAtStartup.disable();
      return true;
    } catch (e) {
      print('Error disabling auto-startup: $e');
      return false;
    }
  }

  /// Check if auto-startup is enabled
  Future<bool> isEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      print('Error checking auto-startup status: $e');
      return false;
    }
  }

  /// Toggle auto-startup
  Future<bool> toggle() async {
    final isCurrentlyEnabled = await isEnabled();

    if (isCurrentlyEnabled) {
      return await disable();
    } else {
      return await enable();
    }
  }
}
