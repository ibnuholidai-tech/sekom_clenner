import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Custom window title bar drawn inside the Flutter view (no native frame).
///
/// Provides:
/// - A drag area that fills the available width (so the user can move the window).
/// - A small brand mark + app title on the left.
/// - A trailing slot for theme toggle / extra controls.
/// - Min / Max-Restore / Close buttons sized like Windows 11.
class WindowTitleBar extends StatelessWidget {
  final Widget? trailing;

  const WindowTitleBar({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.titleBar,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          _BrandMark(),
          const SizedBox(width: 10),
          Expanded(
            child: MoveWindow(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sekom Cleaner',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 6),
          ],
          const _WindowButtons(),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.tune_rounded, size: 13, color: Colors.white),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.textSecondary;
    final hoverBg = AppTheme.cardBorder;
    return Row(
      children: [
        _WinButton(
          icon: Icons.minimize,
          tooltip: 'Minimize',
          iconColor: iconColor,
          hoverColor: hoverBg,
          onPressed: () => appWindow.minimize(),
        ),
        _WinButton(
          icon: Icons.crop_square,
          tooltip: 'Maximize',
          iconColor: iconColor,
          hoverColor: hoverBg,
          onPressed: () => appWindow.maximizeOrRestore(),
        ),
        _WinButton(
          icon: Icons.close,
          tooltip: 'Close',
          iconColor: iconColor,
          hoverColor: const Color(0xFFE81123),
          hoverIconColor: Colors.white,
          onPressed: () => appWindow.close(),
        ),
      ],
    );
  }
}

class _WinButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color iconColor;
  final Color hoverColor;
  final Color? hoverIconColor;
  final VoidCallback onPressed;

  const _WinButton({
    required this.icon,
    required this.tooltip,
    required this.iconColor,
    required this.hoverColor,
    this.hoverIconColor,
    required this.onPressed,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = _hover
        ? (widget.hoverIconColor ?? widget.iconColor)
        : widget.iconColor;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
            height: 40,
            color: _hover ? widget.hoverColor : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
