import 'dart:io';
import 'dart:async';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/modern_main_screen.dart';
import 'services/system_service.dart';
import 'config/build_flags.dart';
import 'utils/error_handler.dart';
import 'config/service_locator.dart';
import 'config/sentry_config.dart';
import 'state/theme_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SentryConfig.initialize();
    await setupServiceLocator();
    // Initialize global error handling
    GlobalErrorHandler.init();

    // Initialize the acrylic / mica window effect on supported desktop hosts.
    // Failures (e.g. running on a non-Windows host) are non-fatal — the app
    // still renders against the regular Flutter background.
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
      try {
        await acrylic.Window.initialize();
        await acrylic.Window.setEffect(
          effect: Platform.isWindows
              ? acrylic.WindowEffect.acrylic
              : acrylic.WindowEffect.solid,
          color: AppTheme.acrylicTint,
        );
      } catch (e, st) {
        GlobalErrorHandler.report(e, st);
      }
    }

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

    // Configure the bitsdojo borderless window on Windows / Linux / macOS
    // builds. On unsupported platforms (web, mobile) this is a no-op.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      doWhenWindowReady(() {
        const initial = Size(1200, 760);
        appWindow.minSize = const Size(900, 640);
        appWindow.size = initial;
        appWindow.alignment = Alignment.center;
        appWindow.title = 'Sekom Cleaner';
        appWindow.show();
      });
    }
  }, (error, stack) {
    GlobalErrorHandler.report(error, stack);
  });
}

class SekomCleanerApp extends ConsumerWidget {
  const SekomCleanerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      navigatorKey: GlobalErrorHandler.navigatorKey,
      title: 'Sekom Cleaner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      themeMode: themeMode,
      builder: (context, child) {
        // Sync the static AppTheme.brightness flag with the resolved
        // ThemeData so all `AppTheme.*` getters return the right palette
        // for the current frame.
        AppTheme.brightness = Theme.of(context).brightness;
        return child ?? const SizedBox.shrink();
      },
      home: const ModernMainScreen(),
    );
  }
}
