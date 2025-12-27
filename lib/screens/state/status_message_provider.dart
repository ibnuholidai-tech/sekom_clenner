import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status message shown in the bottom status bar of MainScreen.
final statusMessageProvider = StateProvider<String>(
  (ref) => 'Siap untuk membersihkan browser dan folder sistem',
);
