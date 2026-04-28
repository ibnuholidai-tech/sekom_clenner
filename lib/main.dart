import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/modern_main_screen.dart';
import 'services/notification_service.dart';
import 'services/quick_clean_service.dart';
import 'services/system_service.dart';
import 'services/system_tray_service.dart';
import 'state/cleaning_preset_provider.dart';
import 'state/theme_provider.dart';
import 'config/build_flags.dart';
import 'utils/error_handler.dart';
import 'config/service_locator.dart';
import 'config/sentry_config.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SentryConfig.initialize();
      await setupServiceLocator();
      // Initialize global error handling
      GlobalErrorHandler.init();
      // Local notifications (best-effort).
      try {
        await NotificationService.init();
      } catch (_) {}

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
      });
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
        ProviderScope(child: ErrorBoundary(child: const SekomCleanerApp())),
      );
    },
    (error, stack) {
      GlobalErrorHandler.report(error, stack);
    },
  );
}

class SekomCleanerApp extends ConsumerStatefulWidget {
  const SekomCleanerApp({super.key});

  @override
  ConsumerState<SekomCleanerApp> createState() => _SekomCleanerAppState();
}

class _SekomCleanerAppState extends ConsumerState<SekomCleanerApp> {
  final SystemTrayService _tray = SystemTrayService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTray());
  }

  Future<void> _initTray() async {
    if (!Platform.isWindows) return; // tray plugin is Windows-only here
    try {
      await _tray.initialize(
        appName: 'Sekom Cleaner',
        iconPath: SystemTrayHelper.getWindowsIconPath(),
        onShow: () async {
          try {
            await windowManager.show();
            await windowManager.focus();
          } catch (_) {}
        },
        onQuickClean: () async {
          if (!mounted) return;
          final preset = ref.read(cleaningPresetProvider);
          await QuickCleanService.instance.run(preset: preset);
        },
        onExit: () async {
          await _tray.destroy();
          exit(0);
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _tray.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: GlobalErrorHandler.navigatorKey,
      title: 'Sekom Cleaner',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      home: const ModernMainScreen(),
    );
  }
}
