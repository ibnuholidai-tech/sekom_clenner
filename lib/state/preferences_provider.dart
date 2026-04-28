import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Async provider exposing the shared SharedPreferences instance.
///
/// Notifiers that persist user preferences (theme mode, cleaning preset,
/// language, etc.) read this via `ref.read(sharedPreferencesProvider.future)`.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);
