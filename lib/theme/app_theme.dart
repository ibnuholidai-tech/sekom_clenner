import 'package:flutter/material.dart';

/// Design tokens for the modern Sekom Cleaner UI.
///
/// Surfaces & text colors are theme-aware: read from [brightness] which is
/// updated by the root widget on every rebuild from `Theme.of(context).brightness`.
/// Brand & pill colors stay constant — they are pastel-on-tinted bubbles that
/// look fine on both light and dark surrounding surfaces.
class AppTheme {
  AppTheme._();

  /// Active brightness driving the surface/text getters.
  ///
  /// Updated by [SekomCleanerApp]'s `MaterialApp.builder` so every rebuild
  /// resolves the correct palette before children read their colors.
  static Brightness brightness = Brightness.light;

  static bool get _isDark => brightness == Brightness.dark;

  // ---- Brand colors (constant across themes) ----
  static const Color primary = Color(0xFF2F80F2); // brand blue
  static const Color primaryDark = Color(0xFF1F66D6);
  static const Color accent = Color(0xFF54A0FF);

  // ---- Status / accent colors ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ---- Pill / pastel surfaces (constant across themes) ----
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

  // ---- Surfaces (theme-aware) ----
  static const Color _pageBackgroundLight = Color(0xFFEAF1FB);
  static const Color _pageBackgroundDark = Color(0xFF0B1220);
  static Color get pageBackground =>
      _isDark ? _pageBackgroundDark : _pageBackgroundLight;

  static const Color _sidebarLight = Color(0xFFEFF5FC);
  static const Color _sidebarDark = Color(0xFF111827);
  static Color get sidebar => _isDark ? _sidebarDark : _sidebarLight;

  static const Color _cardBackgroundLight = Colors.white;
  static const Color _cardBackgroundDark = Color(0xFF161E2E);
  static Color get cardBackground =>
      _isDark ? _cardBackgroundDark : _cardBackgroundLight;

  static const Color _cardBorderLight = Color(0xFFE3ECF6);
  static const Color _cardBorderDark = Color(0xFF1F2937);
  static Color get cardBorder =>
      _isDark ? _cardBorderDark : _cardBorderLight;

  /// Backing color for the title bar / window chrome surface.
  static Color get titleBar =>
      _isDark ? const Color(0xFF0E1626) : const Color(0xFFF4F8FD);

  /// Translucent acrylic tint applied to the host window via flutter_acrylic.
  static Color get acrylicTint => _isDark
      ? const Color(0xCC0B1220)
      : const Color(0xCCEAF1FB);

  // ---- Typography (theme-aware) ----
  static const Color _textPrimaryLight = Color(0xFF0F172A);
  static const Color _textPrimaryDark = Color(0xFFE5E7EB);
  static Color get textPrimary =>
      _isDark ? _textPrimaryDark : _textPrimaryLight;

  static const Color _textSecondaryLight = Color(0xFF6B7280);
  static const Color _textSecondaryDark = Color(0xFF9CA3AF);
  static Color get textSecondary =>
      _isDark ? _textSecondaryDark : _textSecondaryLight;

  static const Color _textMutedLight = Color(0xFF94A3B8);
  static const Color _textMutedDark = Color(0xFF6B7280);
  static Color get textMuted => _isDark ? _textMutedDark : _textMutedLight;

  // ---- Shape tokens ----
  static double get cardRadius => 14.0;
  static double get pillRadius => 999.0;

  static BorderRadius get cardShape => BorderRadius.circular(cardRadius);
  static BorderRadius get pillShape => BorderRadius.circular(pillRadius);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.30)
              : const Color(0xFF0F172A).withValues(alpha: 0.04),
          blurRadius: _isDark ? 18 : 12,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData buildLightTheme() => _buildTheme(Brightness.light);
  static ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness b) {
    final isDark = b == Brightness.dark;
    final cardColor = isDark ? _cardBackgroundDark : _cardBackgroundLight;
    final borderColor = isDark ? _cardBorderDark : _cardBorderLight;
    final pageColor = isDark ? _pageBackgroundDark : _pageBackgroundLight;
    final primaryText = isDark ? _textPrimaryDark : _textPrimaryLight;
    final secondaryText = isDark ? _textSecondaryDark : _textSecondaryLight;

    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: b,
        primary: primary,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: pageColor,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            titleSmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
            bodyLarge: TextStyle(fontSize: 14, color: primaryText),
            bodyMedium: TextStyle(fontSize: 13, color: primaryText),
            bodySmall: TextStyle(fontSize: 12, color: secondaryText),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(fontFamily: base.textTheme.bodyMedium?.fontFamily),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: cardShape,
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconTheme: IconThemeData(size: 20, color: primaryText),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
