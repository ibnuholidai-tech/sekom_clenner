import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A rounded "pill" tile with leading icon, label, and an optional checkmark
/// at the right edge — used for browser/folder selection in the screenshot.
class ModernSelectablePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final Color tint;
  final Color tintText;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  const ModernSelectablePill({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.tintText,
    required this.selected,
    required this.onTap,
    this.trailingText,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = disabled ? Colors.grey.shade100 : tint;
    final fg = disabled ? Colors.grey.shade500 : tintText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bg.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: fg),
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
                    color: fg.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              _CheckBubble(selected: selected, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  final bool selected;
  final Color color;
  const _CheckBubble({required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.white,
        border: Border.all(
          color: selected ? color : const Color(0xFFCBD5E1),
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

/// Compact action button styled like a soft pill (pastel background + icon + label).
class ModernActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final Color tintText;
  final VoidCallback? onTap;
  final bool dense;

  const ModernActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.tintText,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
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
            color: disabled ? Colors.grey.shade100 : tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: dense ? 14 : 16,
                color: disabled ? Colors.grey.shade500 : tintText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: dense ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey.shade500 : tintText,
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
class ModernBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const ModernBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
