import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../testing_screen.dart';

/// Modern shell that hosts the existing TestingScreen.
class ModernTestingScreen extends StatelessWidget {
  const ModernTestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.pageBackground,
      child: const TestingScreen(),
    );
  }
}
