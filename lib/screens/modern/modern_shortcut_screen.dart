import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../uninstaller_screen.dart';

/// Modern shell that hosts the existing UninstallerScreen (system shortcuts).
class ModernShortcutScreen extends StatelessWidget {
  const ModernShortcutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.pageBackground,
      child: const UninstallerScreen(),
    );
  }
}
