import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// A flat, soft-shadow card used everywhere in the modern UI.
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? radius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.radius,
    this.shadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.cardRadius;
    final palette = context.appColors;
    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );

    Widget body = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? palette.cardBackground,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: borderColor ?? palette.cardBorder),
        boxShadow: shadow ?? AppTheme.cardShadow,
      ),
      child: inner,
    );

    if (onTap != null) {
      body = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(r),
          child: body,
        ),
      );
    }

    return body;
  }
}

/// Card section header with a circular tinted icon and optional trailing widget.
class ModernSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ModernSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBackground,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primary;
    final bg = iconBackground ?? color.withValues(alpha: 0.12);
    final palette = context.appColors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 11, color: palette.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
