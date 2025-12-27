import 'package:logger/logger.dart';

/// Global logger instance for the application
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Number of method calls to be displayed
    errorMethodCount: 5, // Number of method calls if stacktrace is provided
    lineLength: 80, // Width of the output
    colors: true, // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
    printTime: true, // Should each log print contain a timestamp
  ),
);

/// Simple logger for production
final productionLogger = Logger(
  printer: SimplePrinter(colors: false, printTime: true),
);
