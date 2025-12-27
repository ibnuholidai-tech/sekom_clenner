import 'package:intl/intl.dart';

/// Utility class for formatting file sizes and numbers
class FormatUtils {
  /// Format bytes to human-readable string (B, KB, MB, GB, TB)
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (i * 10));

    final formatter = NumberFormat.decimalPatternDigits(
      decimalDigits: decimals,
    );

    return '${formatter.format(value)} ${suffixes[i]}';
  }

  /// Format number with thousand separators
  static String formatNumber(num number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

  /// Format percentage
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format GB with one decimal
  static String formatGB(double gb) {
    return '${gb.toStringAsFixed(1)} GB';
  }
}
