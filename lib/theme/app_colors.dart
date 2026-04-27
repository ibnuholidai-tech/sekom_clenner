import 'package:flutter/material.dart';

/// Theme-aware color palette for surfaces, sidebar, and text.
///
/// Light/dark variants are registered as ThemeExtensions on the
/// MaterialApp themes so widgets can read either palette via
/// `Theme.of(context).extension<AppColors>()` (or the
/// `context.appColors` getter below).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color pageBackground;
  final Color sidebar;
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppColors({
    required this.pageBackground,
    required this.sidebar,
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const AppColors light = AppColors(
    pageBackground: Color(0xFFEAF1FB),
    sidebar: Color(0xFFEFF5FC),
    cardBackground: Colors.white,
    cardBorder: Color(0xFFE3ECF6),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF94A3B8),
  );

  static const AppColors dark = AppColors(
    pageBackground: Color(0xFF0B1220),
    sidebar: Color(0xFF111827),
    cardBackground: Color(0xFF1A2434),
    cardBorder: Color(0xFF253142),
    textPrimary: Color(0xFFE5E7EB),
    textSecondary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
  );

  @override
  AppColors copyWith({
    Color? pageBackground,
    Color? sidebar,
    Color? cardBackground,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppColors(
      pageBackground: pageBackground ?? this.pageBackground,
      sidebar: sidebar ?? this.sidebar,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension AppColorsBuildContext on BuildContext {
  /// Convenient theme-aware color accessor: `context.appColors.pageBackground`.
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
