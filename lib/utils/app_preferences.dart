import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _keyPrefix = 'installer_path_';

  /// Save installer path for a specific app
  static Future<void> saveInstallerPath(String appId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$appId', path);
  }

  /// Get installer path for a specific app
  static Future<String?> getInstallerPath(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$appId');
  }

  /// Remove installer path for a specific app
  static Future<void> removeInstallerPath(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$appId');
  }

  /// Clear all installer paths
  static Future<void> clearAllInstallerPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  /// Save app required status
  static Future<void> saveAppRequiredStatus(
    String appId,
    bool isRequired,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_required_$appId', isRequired);
  }

  /// Get app required status (default: true)
  static Future<bool> getAppRequiredStatus(String appId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('app_required_$appId') ?? true;
  }
}
