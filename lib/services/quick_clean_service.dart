import '../state/cleaning_preset_provider.dart';
import 'cleaning_history_service.dart';
import 'notification_service.dart';
import 'system_service.dart';

/// One-shot cleaning runner used by the system-tray "Quick Clean" entry.
///
/// Reads the user's saved [CleaningPreset], applies its [CleaningSelection],
/// runs the matching [SystemService] cleaning calls, persists the result to
/// [CleaningHistoryService], and shows a desktop notification when done.
class QuickCleanService {
  QuickCleanService._();
  static final QuickCleanService instance = QuickCleanService._();

  bool _running = false;
  bool get isRunning => _running;

  Future<void> run({required CleaningPreset preset}) async {
    if (_running) return;
    _running = true;
    final start = DateTime.now();
    final selection = CleaningSelection.forPreset(preset);
    final actions = <String>[];
    var detectedSize = 0;

    Future<T?> safe<T>(Future<T> Function() fn) async {
      try {
        return await fn();
      } catch (_) {
        return null;
      }
    }

    try {
      final tasks = <Future<dynamic>>[];

      final anyBrowser =
          selection.chrome ||
          selection.edge ||
          selection.firefox ||
          selection.brave;
      if (anyBrowser) {
        actions.add('Browser');
        tasks.add(
          safe(
            () => SystemService.cleanBrowsers(
              chrome: selection.chrome,
              edge: selection.edge,
              firefox: selection.firefox,
              resetBrowser: selection.resetBrowser,
            ),
          ),
        );
      }

      final anyFolder = selection.folders.values.any((v) => v);
      if (anyFolder) {
        actions.add('Folder pengguna');
        tasks.add(
          safe(
            () => SystemService.cleanSystemFolders(
              documents: selection.folders['Documents'] ?? false,
              downloads: selection.folders['Downloads'] ?? false,
              music: selection.folders['Music'] ?? false,
              pictures: selection.folders['Pictures'] ?? false,
              videos: selection.folders['Videos'] ?? false,
              objects3d: selection.folders['3D Objects'] ?? false,
            ),
          ),
        );
      }

      if (selection.clearRecent) {
        actions.add('Recent');
        tasks.add(safe(() => SystemService.clearRecentFiles()));
      }
      if (selection.clearRecycleBin) {
        actions.add('Recycle Bin');
        tasks.add(safe(() => SystemService.clearRecycleBin()));
      }

      try {
        final folders = await SystemService.getFolderSizesUltraFast(
          timeout: const Duration(seconds: 4),
        );
        for (final f in folders) {
          if (selection.folders[f.name] ?? false) {
            detectedSize += f.sizeBytes;
          }
        }
      } catch (_) {}

      await Future.wait(tasks);
    } finally {
      final duration = DateTime.now().difference(start);
      await CleaningHistoryService.instance.append(
        CleaningRecord(
          timestamp: start,
          duration: duration,
          detectedSizeBytes: detectedSize,
          items: actions,
          preset: preset.name,
          note: 'quick-clean',
        ),
      );
      try {
        await NotificationService.showCleaningComplete(
          filesDeleted: 0,
          spaceFreed: _formatBytes(detectedSize),
        );
      } catch (_) {}
      _running = false;
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var s = bytes.toDouble();
    var u = 0;
    while (s >= 1024 && u < units.length - 1) {
      s /= 1024;
      u++;
    }
    return '${s.toStringAsFixed(s < 10 ? 2 : 1)} ${units[u]}';
  }
}
