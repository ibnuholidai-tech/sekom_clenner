import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service for local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  static Future<void> init() async {
    // For Windows, we don't need special initialization
    // The plugin will handle it automatically
    try {
      await _notifications.initialize(
        const InitializationSettings(),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
    } catch (e) {
      print('Notification init error: $e');
    }
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  /// Show cleaning complete notification
  static Future<void> showCleaningComplete({
    required int filesDeleted,
    required String spaceFreed,
  }) async {
    try {
      await _notifications.show(
        0,
        '🧹 Cleaning Complete!',
        'Deleted $filesDeleted files • Freed $spaceFreed',
        const NotificationDetails(),
        payload: 'cleaning_complete',
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Show scan complete notification
  static Future<void> showScanComplete({
    required int filesFound,
    required String totalSize,
  }) async {
    try {
      await _notifications.show(
        1,
        '🔍 Scan Complete!',
        'Found $filesFound items • Total size: $totalSize',
        const NotificationDetails(),
        payload: 'scan_complete',
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }

  /// Show generic notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      print('Notification error: $e');
    }
  }
}
