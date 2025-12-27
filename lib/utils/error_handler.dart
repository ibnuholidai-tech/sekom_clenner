import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sekom_clenner/config/sentry_config.dart';

/// Global error handler for centralized error reporting and user notifications
class GlobalErrorHandler {
  GlobalErrorHandler._();

  // Expose a global navigator key to show SnackBars/Dialogs outside widget context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static bool _initialized = false;
  
  // Error deduplication: track recently shown errors to avoid spam
  static final Set<String> _recentErrors = {};
  static DateTime? _lastErrorClearTime;
  static const _errorDeduplicationWindow = Duration(seconds: 5);

  static void init() {
    if (_initialized) return;
    _initialized = true;

    // Catch framework-level Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Keep default behavior in debug for visibility
      FlutterError.presentError(details);
      // Report through our handler
      report(details.exception, details.stack);
    };

    // Catch uncaught async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      report(error, stack);
      // Return true to signal we've handled the error
      return true;
    };
  }

  // Centralized error reporting
  static void report(Object error, [StackTrace? stack]) {
    try {
      final msg = error.toString();
      debugPrint('[GlobalErrorHandler] $msg');
      if (stack != null) {
        debugPrint('[GlobalErrorHandler] Stack: $stack');
      }

      try {
        unawaited(
          SentryConfig.captureException(error, stackTrace: stack),
        );
      } catch (_) {}

      // Show a non-intrusive SnackBar in release/profile; verbose in debug.
      _showErrorSnack(kDebugMode
          ? 'Error: $msg'
          : 'Terjadi kesalahan tak terduga. Beberapa fitur mungkin tidak berjalan.');

    } catch (_) {
      // Swallow secondary failures from reporter
    }
  }

  /// Log debug messages (only in debug mode)
  static void logDebug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[Debug] ';
      debugPrint('$prefix$message');
    }
  }

  /// Log errors without showing UI notifications (for diagnostic purposes)
  static void logError(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('[ERROR] Exception: $error');
    }
    if (stack != null) {
      debugPrint('[ERROR] Stack: $stack');
    }
  }

  /// Show info message to user
  static void showInfo(String message, {Duration? duration}) {
    _showSnack(message, Colors.blueGrey, duration: duration);
  }

  /// Show warning message to user
  static void showWarning(String message, {Duration? duration}) {
    _showSnack(message, Colors.orange, duration: duration);
  }

  /// Show error message to user
  static void showError(String message, {Duration? duration}) {
    if (_shouldShowError(message)) {
      _showSnack(message, Colors.red, duration: duration);
      _trackError(message);
    }
  }

  /// Show success message to user
  static void showSuccess(String message, {Duration? duration}) {
    _showSnack(message, Colors.green, duration: duration);
  }

  /// Show error dialog for critical errors that require user attention
  static Future<void> showErrorDialog(String title, String message, {String? details}) async {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) {
        // Fallback to snackbar if context not available
        showError(message);
        return;
      }

      await showDialog(
        context: ctx,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Detail Teknis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback to snackbar if dialog fails
      logError('Failed to show error dialog', e);
      showError(message);
    }
  }

  /// Show error dialog with retry option
  static Future<bool?> showErrorWithRetry(String message, {String? title}) async {
    try {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) {
        showError(message);
        return false;
      }

      return await showDialog<bool>(
        context: ctx,
        builder: (context) => AlertDialog(
          title: Text(title ?? 'Terjadi Kesalahan'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    } catch (e) {
      logError('Failed to show error with retry dialog', e);
      return false;
    }
  }

  // Internal implementation

  static void _showErrorSnack(String message) {
    if (_shouldShowError(message)) {
      _showSnack(message, Colors.redAccent);
      _trackError(message);
    }
  }

  static void _showSnack(String message, Color color, {Duration? duration}) {
    try {
      final ctx = navigatorKey.currentState?.overlay?.context;
      if (ctx == null) return;
      ScaffoldMessenger.of(ctx)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            duration: duration ?? const Duration(seconds: 3),
          ),
        );
    } catch (e) {
      // Log but don't show UI errors from messenger to avoid infinite loop
      logDebug('Failed to show snackbar: $e');
    }
  }

  // Error deduplication helpers

  static bool _shouldShowError(String message) {
    _clearOldErrors();
    // Normalize message for comparison (case-insensitive, trimmed)
    final normalizedMsg = message.trim().toLowerCase();
    return !_recentErrors.contains(normalizedMsg);
  }

  static void _trackError(String message) {
    final normalizedMsg = message.trim().toLowerCase();
    _recentErrors.add(normalizedMsg);
  }

  static void _clearOldErrors() {
    final now = DateTime.now();
    if (_lastErrorClearTime == null || 
        now.difference(_lastErrorClearTime!) > _errorDeduplicationWindow) {
      _recentErrors.clear();
      _lastErrorClearTime = now;
    }
  }
}
