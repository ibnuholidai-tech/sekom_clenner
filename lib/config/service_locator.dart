import 'package:get_it/get_it.dart';
import 'package:sekom_clenner/services/system_service.dart';

/// Service Locator untuk Dependency Injection
/// Menggunakan Get It untuk clean architecture
final getIt = GetIt.instance;

/// Setup semua services yang dibutuhkan aplikasi
Future<void> setupServiceLocator() async {
  // Register services sebagai singleton
  getIt.registerLazySingleton<SystemService>(() => SystemService());
}

/// Helper untuk mendapatkan service
T locate<T extends Object>() => getIt<T>();

/// Example usage:
/// final systemService = locate<SystemService>();
