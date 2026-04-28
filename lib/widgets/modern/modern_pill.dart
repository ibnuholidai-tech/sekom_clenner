import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Visual tone applied to pill / badge surfaces.
///
/// Used for status indicators only (success / warning / danger) — most
/// pills should leave this at [PillTone.neutral].
enum PillTone { neutral, primary, success, warning, danger }

class _ToneStyle {
  final Color background;
  final Color foreground;
  final Color border;
  const _ToneStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });
}

_ToneStyle _resolveTone(BuildContext context, PillTone tone) {
  final palette = context.appColors;
  switch (tone) {
    case PillTone.neutral:
      return _ToneStyle(
        background: palette.surfaceMuted,
        foreground: palette.textPrimary,
        border: palette.surfaceMutedBorder,
      );
    case PillTone.primary:
      return _ToneStyle(
        background: AppTheme.primary.withValues(alpha: 0.14),
        foreground: AppTheme.primaryDark,
        border: AppTheme.primary.withValues(alpha: 0.40),
      );
    case PillTone.success:
      return _ToneStyle(
        background: AppTheme.success.withValues(alpha: 0.14),
        foreground: AppTheme.pillGreenText,
        border: AppTheme.success.withValues(alpha: 0.40),
      );
    case PillTone.warning:
      return _ToneStyle(
        background: AppTheme.warning.withValues(alpha: 0.18),
        foreground: AppTheme.pillAmberText,
        border: AppTheme.warning.withValues(alpha: 0.40),
      );
    case PillTone.danger:
      return _ToneStyle(
        background: AppTheme.danger.withValues(alpha: 0.14),
        foreground: AppTheme.pillRedText,
        border: AppTheme.danger.withValues(alpha: 0.40),
      );
  }
}

/// A rounded "pill" tile with a leading icon, label, and an optional
/// checkmark on the right edge — used for browser/folder selection.
///
/// Visuals are derived purely from [selected] state and the ambient
/// theme: unselected pills use a neutral surface, selected pills use
/// the brand primary tint. The [tint] / [tintText] parameters are kept
/// for source-compat with older call sites but are ignored.
class ModernSelectablePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  /// Deprecated. Pill colors are now derived from [selected] state.
  final Color? tint;

  /// Deprecated. Pill colors are now derived from [selected] state.
  final Color? tintText;

  const ModernSelectablePill({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingText,
    this.disabled = false,
    this.tint,
    this.tintText,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final Color bg;
    final Color fg;
    final Color borderColor;
    final Color iconBubbleBg;
    final Color iconColor;

    if (disabled) {
      bg = palette.surfaceMuted;
      fg = palette.textMuted;
      borderColor = palette.surfaceMutedBorder;
      iconBubbleBg = palette.surfaceMuted;
      iconColor = palette.textMuted;
    } else if (selected) {
      bg = AppTheme.primary.withValues(alpha: 0.10);
      fg = AppTheme.primaryDark;
      borderColor = AppTheme.primary.withValues(alpha: 0.32);
      iconBubbleBg = AppTheme.primary;
      iconColor = Colors.white;
    } else {
      bg = palette.cardBackground;
      fg = palette.textPrimary;
      borderColor = palette.cardBorder;
      iconBubbleBg = palette.surfaceMuted;
      iconColor = palette.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBubbleBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              _CheckBubble(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  final bool selected;
  const _CheckBubble({required this.selected});

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppTheme.primary : palette.cardBackground,
        border: Border.all(
          color: selected ? AppTheme.primary : palette.cardBorder,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

/// Compact action button styled like a soft pill (neutral surface +
/// icon + label). The [tint] / [tintText] parameters are kept for
/// source-compat but are ignored — set [tone] for semantic variants.
class ModernActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dense;
  final PillTone tone;

  /// Deprecated. Use [tone] for semantic variants.
  final Color? tint;

  /// Deprecated. Use [tone] for semantic variants.
  final Color? tintText;

  const ModernActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.dense = false,
    this.tone = PillTone.neutral,
    this.tint,
    this.tintText,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final disabled = onTap == null;
    final style = _resolveTone(context, tone);
    final Color bg;
    final Color fg;
    final Color borderColor;
    if (disabled) {
      bg = palette.surfaceMuted;
      fg = palette.textMuted;
      borderColor = palette.surfaceMutedBorder;
    } else if (tone == PillTone.neutral) {
      bg = palette.cardBackground;
      fg = palette.textPrimary;
      borderColor = palette.cardBorder;
    } else {
      bg = style.background;
      fg = style.foreground;
      borderColor = style.border;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 14,
            vertical: dense ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: dense ? 14 : 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small status badge (e.g. "Activated", "RAM terlalu tinggi").
///
/// Prefer the [ModernBadge.tone] constructor for semantic variants
/// (success / warning / danger / primary / neutral). The legacy
/// `background` / `foreground` constructor remains for cases that need
/// a custom palette.
class ModernBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final PillTone? tone;
  final Color? background;
  final Color? foreground;

  const ModernBadge({
    super.key,
    required this.text,
    this.icon,
    this.tone,
    this.background,
    this.foreground,
  }) : assert(
          tone != null || (background != null && foreground != null),
          'Either tone or both background and foreground must be provided',
        );

  const ModernBadge.tone({
    super.key,
    required this.text,
    required PillTone this.tone,
    this.icon,
  })  : background = null,
        foreground = null;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (tone != null) {
      final s = _resolveTone(context, tone!);
      bg = s.background;
      fg = s.foreground;
    } else {
      bg = background!;
      fg = foreground!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
