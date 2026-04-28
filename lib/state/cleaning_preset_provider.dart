import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

/// Predefined cleaning intensities the user can apply with a single click.
enum CleaningPreset {
  light,
  standard,
  deep,
  custom;

  String get label {
    switch (this) {
      case CleaningPreset.light:
        return 'Ringan';
      case CleaningPreset.standard:
        return 'Standar';
      case CleaningPreset.deep:
        return 'Dalam';
      case CleaningPreset.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case CleaningPreset.light:
        return 'Cache browser & temp file saja';
      case CleaningPreset.standard:
        return 'Browser + Recent + Recycle Bin';
      case CleaningPreset.deep:
        return 'Semua + reset browser + folder pengguna';
      case CleaningPreset.custom:
        return 'Pengaturan manual';
    }
  }
}

/// Concrete selection that a preset translates into.
///
/// `null` for booleans means "do not change current selection" (only used
/// for [CleaningPreset.custom]).
class CleaningSelection {
  final bool chrome;
  final bool edge;
  final bool firefox;
  final bool brave;
  final bool resetBrowser;
  final Map<String, bool> folders;
  final bool clearRecent;
  final bool clearRecycleBin;

  const CleaningSelection({
    required this.chrome,
    required this.edge,
    required this.firefox,
    required this.brave,
    required this.resetBrowser,
    required this.folders,
    required this.clearRecent,
    required this.clearRecycleBin,
  });

  static CleaningSelection forPreset(CleaningPreset preset) {
    switch (preset) {
      case CleaningPreset.light:
        return const CleaningSelection(
          chrome: true,
          edge: true,
          firefox: false,
          brave: false,
          resetBrowser: false,
          folders: {
            'Downloads': false,
            'Documents': false,
            'Pictures': false,
            'Music': false,
            'Videos': false,
            '3D Objects': false,
          },
          clearRecent: false,
          clearRecycleBin: false,
        );
      case CleaningPreset.standard:
        return const CleaningSelection(
          chrome: true,
          edge: true,
          firefox: true,
          brave: false,
          resetBrowser: false,
          folders: {
            'Downloads': false,
            'Documents': false,
            'Pictures': false,
            'Music': false,
            'Videos': false,
            '3D Objects': false,
          },
          clearRecent: true,
          clearRecycleBin: true,
        );
      case CleaningPreset.deep:
        return const CleaningSelection(
          chrome: true,
          edge: true,
          firefox: true,
          brave: true,
          resetBrowser: true,
          folders: {
            'Downloads': true,
            'Documents': false,
            'Pictures': false,
            'Music': false,
            'Videos': false,
            '3D Objects': true,
          },
          clearRecent: true,
          clearRecycleBin: true,
        );
      case CleaningPreset.custom:
        return const CleaningSelection(
          chrome: true,
          edge: true,
          firefox: true,
          brave: false,
          resetBrowser: true,
          folders: {
            'Downloads': false,
            'Documents': false,
            'Pictures': false,
            'Music': false,
            'Videos': false,
            '3D Objects': false,
          },
          clearRecent: false,
          clearRecycleBin: false,
        );
    }
  }
}

class CleaningPresetNotifier extends StateNotifier<CleaningPreset> {
  CleaningPresetNotifier(this._prefs) : super(_load(_prefs));

  static const String _key = 'cleaning_preset';
  final SharedPreferences? _prefs;

  static CleaningPreset _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(_key);
    return CleaningPreset.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => CleaningPreset.standard,
    );
  }

  Future<void> set(CleaningPreset preset) async {
    state = preset;
    await _prefs?.setString(_key, preset.name);
  }
}

final cleaningPresetProvider =
    StateNotifierProvider<CleaningPresetNotifier, CleaningPreset>((ref) {
      final prefsAsync = ref.watch(sharedPreferencesProvider);
      return CleaningPresetNotifier(prefsAsync.asData?.value);
    });
