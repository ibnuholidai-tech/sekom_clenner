import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:logger/logger.dart';

/// Configuration untuk Sentry error monitoring
class SentryConfig {
  // TODO: Replace dengan DSN dari sentry.io atau set lewat --dart-define SENTRY_DSN
  static const String dsn = 'YOUR_SENTRY_DSN_HERE';

  static const String environment = 'production'; // atau 'development'
  static const String release = '1.0.0'; // sesuaikan dengan versi app

  static String _resolveDsn() {
    const envDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    if (envDsn.isNotEmpty) return envDsn;
    return dsn;
  }

  /// Initialize Sentry
  static Future<void> initialize() async {
    final dsnValue = _resolveDsn();
    if (dsnValue.isEmpty || dsnValue == 'YOUR_SENTRY_DSN_HERE') {
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsnValue;
      options.environment = environment;
      options.release = release;

      // Set sample rate
      options.tracesSampleRate =
          1.0; // 100% untuk development, kurangi di production

      // Enable auto session tracking
      options.enableAutoSessionTracking = true;

      // Attach screenshots on errors
      options.attachScreenshot = true;

      // Attach view hierarchy
      options.attachViewHierarchy = true;
    });
  }

  /// Capture exception
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
  }) async {
    if (!Sentry.isEnabled) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Capture message
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!Sentry.isEnabled) return;
    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) {
          extra.forEach((key, value) {
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// Set user context
  static void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(id: id, email: email, username: username, data: extra),
      );
    });
  }

  /// Clear user context
  static void clearUser() {
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Add breadcrumb
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  /// Set tag
  static void setTag(String key, String value) {
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Set context
  static void setContext(String key, Map<String, dynamic> context) {
    Sentry.configureScope((scope) {
      scope.setContexts(key, context);
    });
  }
}

/// Logger configuration
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Also send to Sentry
    if (error != null) {
      SentryConfig.captureException(
        error,
        stackTrace: stackTrace,
        hint: message,
      );
    }
  }

  /// Log fatal message
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Also send to Sentry
    if (error != null) {
      SentryConfig.captureException(
        error,
        stackTrace: stackTrace,
        hint: message,
      );
    }
  }
}

/// Error handler widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorDetails!.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Capture errors
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      setState(() {
        _errorDetails = details;
      });

      // Send to Sentry
      SentryConfig.captureException(
        details.exception,
        stackTrace: details.stack,
        hint: details.summary.toString(),
      );
    };
  }
}

/// Example usage:
/// 
/// // In main.dart:
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize Sentry
///   await SentryConfig.initialize();
///   
///   runApp(
///     ErrorBoundary(
///       child: MyApp(),
///     ),
///   );
/// }
/// 
/// // Log errors:
/// AppLogger.error('Something went wrong', error, stackTrace);
/// 
/// // Capture exception:
/// SentryConfig.captureException(error, stackTrace: stackTrace);
