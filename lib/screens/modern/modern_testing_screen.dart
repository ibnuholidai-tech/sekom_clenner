import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../testing_screen.dart';

/// Modern shell that hosts the existing TestingScreen.
class ModernTestingScreen extends StatelessWidget {
  const ModernTestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pageBackground,
      child: const TestingScreen(),
    );
  }
}
