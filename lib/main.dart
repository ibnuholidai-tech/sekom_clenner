import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_screen.dart';
import 'services/system_service.dart';
import 'config/build_flags.dart';
import 'utils/error_handler.dart';
import 'config/service_locator.dart';
import 'config/sentry_config.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SentryConfig.initialize();
    await setupServiceLocator();
    // Initialize global error handling
    GlobalErrorHandler.init();

    // Configure window size and properties
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Sekom Cleaner',
      minimumSize: Size(800, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    }
    );
    // Prefer Administrator in release builds (double‑click).
    // In debug builds, jangan relaunch otomatis agar sesi debug tidak terputus.
    final elevated = await SystemService.isElevated();
    if (!elevated && kReleaseMode && kAutoElevate) {
      final ok = await SystemService.relaunchAsAdmin();
      if (ok) {
        // Tutup instance non‑elevated agar tidak ada dua instance berjalan
        exit(0);
      }
      // Jika gagal (user cancel UAC), lanjutkan non‑elevated.
      // Fitur yang butuh admin akan menampilkan prompt di dalam aplikasi.
    }
    runApp(
      ProviderScope(
        child: ErrorBoundary(
          child: const SekomCleanerApp(),
        ),
      ),
    );
  }, (error, stack) {
    GlobalErrorHandler.report(error, stack);
  });
}

class SekomCleanerApp extends StatelessWidget {
  const SekomCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalErrorHandler.navigatorKey,
      title: 'Sekom Cleaner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Reduce overall font size and padding to make UI more compact
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 14),
          bodyMedium: TextStyle(fontSize: 13),
          bodySmall: TextStyle(fontSize: 12),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 2,
          shadowColor: Colors.black26,
          toolbarHeight: 48, // Reduce app bar height
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: TextStyle(fontSize: 13), // Smaller tab text
          unselectedLabelStyle: TextStyle(fontSize: 13),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(4), // Reduce card margins
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Smaller buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontSize: 13), // Smaller button text
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        iconTheme: IconThemeData(
          size: 20, // Smaller icons
        ),
        visualDensity: VisualDensity.compact, // Make everything more compact
      ),
      home: const MainScreen(),
    );
  }
}
