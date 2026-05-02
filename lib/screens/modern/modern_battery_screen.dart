import 'package:flutter/material.dart';

import '../battery_screen.dart';
import '../../theme/app_theme.dart';

/// Modern shell that hosts the existing BatteryScreen on the new background.
class ModernBatteryScreen extends StatelessWidget {
  const ModernBatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pageBackground,
      child: const BatteryScreen(),
    );
  }
}
