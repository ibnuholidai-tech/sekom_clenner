import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../battery_screen.dart';

/// Modern shell that hosts the existing BatteryScreen on the new background.
class ModernBatteryScreen extends StatelessWidget {
  const ModernBatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.pageBackground,
      child: const BatteryScreen(),
    );
  }
}
