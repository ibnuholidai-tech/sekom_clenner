import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Single cleaning run captured for the History view.
class CleaningRecord {
  final DateTime timestamp;
  final Duration duration;
  final int detectedSizeBytes;
  final List<String> items;
  final String preset;
  final String? note;

  const CleaningRecord({
    required this.timestamp,
    required this.duration,
    required this.detectedSizeBytes,
    required this.items,
    required this.preset,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'durationMs': duration.inMilliseconds,
    'detectedSizeBytes': detectedSizeBytes,
    'items': items,
    'preset': preset,
    if (note != null) 'note': note,
  };

  factory CleaningRecord.fromJson(Map<String, dynamic> json) => CleaningRecord(
    timestamp: DateTime.tryParse(json['ts'] as String? ?? '') ?? DateTime.now(),
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    detectedSizeBytes: json['detectedSizeBytes'] as int? ?? 0,
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(),
    preset: json['preset'] as String? ?? 'custom',
    note: json['note'] as String?,
  );
}

/// JSON-backed cleaning history. Stored at:
///   `<appSupport>/cleaning_history.json`
///
/// The most recent 200 records are kept; older records are dropped.
class CleaningHistoryService {
  CleaningHistoryService._();
  static final CleaningHistoryService instance = CleaningHistoryService._();

  static const String _fileName = 'cleaning_history.json';
  static const int _maxRecords = 200;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, _fileName));
  }

  Future<List<CleaningRecord>> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const [];
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return const [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(CleaningRecord.fromJson)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(CleaningRecord record) async {
    try {
      final current = List<CleaningRecord>.from(await load());
      current.insert(0, record);
      final trimmed = current.take(_maxRecords).toList();
      final f = await _file();
      await f.writeAsString(
        jsonEncode(trimmed.map((r) => r.toJson()).toList()),
        flush: true,
      );
    } catch (_) {
      // Swallow: history is best-effort.
    }
  }

  Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// CSV serialization for export.
  String toCsv(List<CleaningRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln(
      'timestamp,duration_seconds,detected_size_bytes,preset,items',
    );
    for (final r in records) {
      final items = r.items.join('|').replaceAll(',', ' ');
      buffer.writeln(
        '${r.timestamp.toIso8601String()},'
        '${r.duration.inSeconds},'
        '${r.detectedSizeBytes},'
        '${r.preset},'
        '"$items"',
      );
    }
    return buffer.toString();
  }
}
