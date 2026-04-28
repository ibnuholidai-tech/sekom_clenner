import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens for the modern Sekom Cleaner UI.
///
/// Minimalist look:
/// - Off-white page background (see [AppColors]).
/// - White cards with a thin slate border.
/// - Pills that are neutral when inactive, primary blue when active.
/// - Single solid blue primary action.
/// - Semantic accents (success / warning / danger) reserved strictly for
///   state badges (defender status, recycle bin, etc.).
class AppTheme {
  AppTheme._();

  // ---- Brand colors ----
  static const Color primary = Color(0xFF2F80F2); // brand blue
  static const Color primaryDark = Color(0xFF1F66D6);
  static const Color accent = Color(0xFF54A0FF);

  /// Subtle primary tint for selected-state backgrounds (12% of [primary]).
  static const Color primarySurface = Color(0x1F2F80F2);

  // ---- Surfaces (legacy static fallbacks; prefer context.appColors) ----
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE5E7EB);

  // ---- Status / accent colors ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---- Semantic pill surfaces (kept for status badges only) ----
  /// Light-blue tint used as the "primary" pill when a single accent is
  /// the only color in a layout. All call sites that previously used
  /// [pillBlue] keep working with this value.
  static const Color pillBlue = Color(0xFFEAF2FE);
  static const Color pillBlueText = Color(0xFF1F66D6);
  static const Color pillGreen = Color(0xFFE5F5EA);
  static const Color pillGreenText = Color(0xFF15803D);
  static const Color pillAmber = Color(0xFFFEF3C7);
  static const Color pillAmberText = Color(0xFFB45309);
  static const Color pillRed = Color(0xFFFEE2E2);
  static const Color pillRedText = Color(0xFFB91C1C);

  /// Deprecated pastel aliases — kept so legacy call sites compile while
  /// the UI is being simplified. They all collapse to the neutral surface
  /// and will be removed once every screen migrates.
  @Deprecated('Use AppColors.surfaceMuted via context.appColors')
  static const Color pillPurple = Color(0xFFF3F4F6);
  @Deprecated('Use AppColors.textSecondary via context.appColors')
  static const Color pillPurpleText = Color(0xFF4B5563);
  @Deprecated('Use AppColors.surfaceMuted via context.appColors')
  static const Color pillPink = Color(0xFFF3F4F6);
  @Deprecated('Use AppColors.textSecondary via context.appColors')
  static const Color pillPinkText = Color(0xFF4B5563);
  @Deprecated('Use AppColors.surfaceMuted via context.appColors')
  static const Color pillTeal = Color(0xFFF3F4F6);
  @Deprecated('Use AppColors.textSecondary via context.appColors')
  static const Color pillTealText = Color(0xFF4B5563);

  // ---- Typography ----
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

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
