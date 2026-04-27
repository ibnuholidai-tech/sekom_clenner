import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../uninstaller_screen.dart';

/// Modern shell that hosts the existing UninstallerScreen (system shortcuts).
class ModernShortcutScreen extends StatelessWidget {
  const ModernShortcutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pageBackground,
      child: const UninstallerScreen(),
    );
  }
}
