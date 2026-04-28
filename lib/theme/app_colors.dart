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

  /// Subtle filled surface used for inactive pills, chips, and tonal
  /// containers (one step darker than [cardBackground]).
  final Color surfaceMuted;
  final Color surfaceMutedBorder;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const AppColors({
    required this.pageBackground,
    required this.sidebar,
    required this.cardBackground,
    required this.cardBorder,
    required this.surfaceMuted,
    required this.surfaceMutedBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  static const AppColors light = AppColors(
    pageBackground: Color(0xFFF7F8FA),
    sidebar: Color(0xFFFFFFFF),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E7EB),
    surfaceMuted: Color(0xFFF3F4F6),
    surfaceMutedBorder: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
  );

  static const AppColors dark = AppColors(
    pageBackground: Color(0xFF0B1220),
    sidebar: Color(0xFF111827),
    cardBackground: Color(0xFF161E2D),
    cardBorder: Color(0xFF243042),
    surfaceMuted: Color(0xFF1E2738),
    surfaceMutedBorder: Color(0xFF2A3548),
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
    Color? surfaceMuted,
    Color? surfaceMutedBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppColors(
      pageBackground: pageBackground ?? this.pageBackground,
      sidebar: sidebar ?? this.sidebar,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceMutedBorder: surfaceMutedBorder ?? this.surfaceMutedBorder,
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
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceMutedBorder:
          Color.lerp(surfaceMutedBorder, other.surfaceMutedBorder, t)!,
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
