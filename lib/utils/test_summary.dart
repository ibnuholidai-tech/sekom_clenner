import 'package:shared_preferences/shared_preferences.dart';

class TestSummary {
  static const _kSound = 'summary_sound';
  static const _kSoundTime = 'summary_sound_time';
  static const _kNetwork = 'summary_network';
  static const _kNetworkTime = 'summary_network_time';
  static const _kCpu = 'summary_cpu';
  static const _kCpuTime = 'summary_cpu_time';

  static Future<void> saveSound({
    required String channel,
    required double volume,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text =
          'Sound $channel @ ${volume < 0 ? 'N/A' : '${(volume * 100).toInt()}%'}';
      await prefs.setString(_kSound, text);
      await prefs.setString(
        _kSoundTime,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<void> saveNetwork({
    required double downloadMbps,
    required double uploadMbps,
    required int pingMs,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text =
          'Net D:${downloadMbps.toStringAsFixed(1)} Mbps U:${uploadMbps.toStringAsFixed(1)} Mbps Ping:${pingMs} ms';
      await prefs.setString(_kNetwork, text);
      await prefs.setString(
        _kNetworkTime,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<void> saveCpu({required int seconds}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = 'CPU ran ${seconds}s';
      await prefs.setString(_kCpu, text);
      await prefs.setString(
        _kCpuTime,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  static Future<List<String>> loadLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lines = <String>[];

      final sound = prefs.getString(_kSound);
      if (sound != null && sound.isNotEmpty) {
        lines.add(sound);
      }

      final net = prefs.getString(_kNetwork);
      if (net != null && net.isNotEmpty) {
        lines.add(net);
      }

      final cpu = prefs.getString(_kCpu);
      if (cpu != null && cpu.isNotEmpty) {
        lines.add(cpu);
      }

      return lines;
    } catch (_) {
      return <String>[];
    }
  }

  static Future<String> buildSummaryText() async {
    final lines = await loadLines();
    if (lines.isEmpty) {
      return 'Belum ada hasil tes.';
    }
    return lines.join('\n');
  }
}
