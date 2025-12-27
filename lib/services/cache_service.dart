// import 'package:hive_flutter/hive_flutter.dart';

// /// Cache service using Hive for fast local storage
// class CacheService {
//   static const String _scanResultsBox = 'scan_results';
//   static const String _appSettingsBox = 'app_settings';

//   /// Initialize Hive
//   static Future<void> init() async {
//     await Hive.initFlutter();
//     await Hive.openBox(_scanResultsBox);
//     await Hive.openBox(_appSettingsBox);
//   }

//   /// Save scan results
//   static Future<void> saveScanResults(Map<String, dynamic> results) async {
//     final box = Hive.box(_scanResultsBox);
//     await box.put('last_scan', results);
//     await box.put('last_scan_time', DateTime.now().toIso8601String());
//   }

//   /// Get cached scan results
//   static Map<String, dynamic>? getCachedScanResults() {
//     final box = Hive.box(_scanResultsBox);
//     return box.get('last_scan') as Map<String, dynamic>?;
//   }

//   /// Get last scan time
//   static DateTime? getLastScanTime() {
//     final box = Hive.box(_scanResultsBox);
//     final timeStr = box.get('last_scan_time') as String?;
//     return timeStr != null ? DateTime.parse(timeStr) : null;
//   }

//   /// Check if cache is fresh (less than 1 hour old)
//   static bool isCacheFresh() {
//     final lastScan = getLastScanTime();
//     if (lastScan == null) return false;
//     return DateTime.now().difference(lastScan).inHours < 1;
//   }

//   /// Save app setting
//   static Future<void> saveSetting(String key, dynamic value) async {
//     final box = Hive.box(_appSettingsBox);
//     await box.put(key, value);
//   }

//   /// Get app setting
//   static T? getSetting<T>(String key) {
//     final box = Hive.box(_appSettingsBox);
//     return box.get(key) as T?;
//   }

//   /// Clear all cache
//   static Future<void> clearCache() async {
//     final scanBox = Hive.box(_scanResultsBox);
//     await scanBox.clear();
//   }

//   /// Close all boxes
//   static Future<void> close() async {
//     await Hive.close();
//   }
// }
