import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

/// Persisted theme-mode notifier.
///
/// Defaults to system. User can switch to light or dark from the sidebar
/// toggle and the preference is restored across launches.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  static const String _key = 'theme_mode';
  final SharedPreferences? _prefs;

  static ThemeMode _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(_key);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs?.setString(_key, _serialize(mode));
  }

  /// Cycle: system → light → dark → system.
  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await set(next);
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefsAsync.asData?.value);
});
