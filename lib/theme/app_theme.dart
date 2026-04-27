import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens for the modern Sekom Cleaner UI.
///
/// Inspired by a soft, glassmorphic-light look:
/// - Light blue page background.
/// - White/translucent rounded cards.
/// - Pastel pill buttons (blue, green, purple, pink, teal).
/// - Solid blue primary action.
class AppTheme {
  AppTheme._();

  // ---- Brand colors ----
  static const Color primary = Color(0xFF2F80F2); // brand blue
  static const Color primaryDark = Color(0xFF1F66D6);
  static const Color accent = Color(0xFF54A0FF);

  // ---- Surfaces ----
  static const Color pageBackground = Color(0xFFEAF1FB); // very light blue
  static const Color sidebar = Color(0xFFEFF5FC);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE3ECF6);

  // ---- Status / accent colors ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---- Pill / pastel surfaces ----
  static const Color pillBlue = Color(0xFFE6EFFC);
  static const Color pillBlueText = Color(0xFF1F66D6);
  static const Color pillGreen = Color(0xFFE3F4E5);
  static const Color pillGreenText = Color(0xFF1B7A3B);
  static const Color pillPurple = Color(0xFFEFE9FB);
  static const Color pillPurpleText = Color(0xFF6D49C1);
  static const Color pillPink = Color(0xFFFCE7EE);
  static const Color pillPinkText = Color(0xFFB8336A);
  static const Color pillTeal = Color(0xFFE0F4F1);
  static const Color pillTealText = Color(0xFF0E7C6C);
  static const Color pillAmber = Color(0xFFFCEFD9);
  static const Color pillAmberText = Color(0xFFB7791F);
  static const Color pillRed = Color(0xFFFCE6E6);
  static const Color pillRedText = Color(0xFFB91C1C);

  // ---- Typography ----
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF94A3B8);

  static double get cardRadius => 14.0;
  static double get pillRadius => 999.0;

  static BorderRadius get cardShape => BorderRadius.circular(cardRadius);
  static BorderRadius get pillShape => BorderRadius.circular(pillRadius);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData buildLightTheme() => _build(Brightness.light);
  static ThemeData buildDarkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppColors.dark : AppColors.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: palette.cardBackground,
      ),
      scaffoldBackgroundColor: palette.pageBackground,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[palette],
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
            titleSmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            bodyLarge: TextStyle(fontSize: 14, color: palette.textPrimary),
            bodyMedium: TextStyle(fontSize: 13, color: palette.textPrimary),
            bodySmall: TextStyle(fontSize: 12, color: palette.textSecondary),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(fontFamily: base.textTheme.bodyMedium?.fontFamily),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.cardBackground,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardShape,
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: palette.cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: IconThemeData(size: 20, color: palette.textPrimary),
      dividerTheme: DividerThemeData(
        color: palette.cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
