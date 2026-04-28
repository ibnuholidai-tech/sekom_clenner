import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/cleaning_history_service.dart';
import '../../state/cleaning_history_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class CleaningHistoryDialog extends ConsumerWidget {
  const CleaningHistoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CleaningHistoryDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(cleaningHistoryProvider);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 540),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Riwayat Pembersihan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${records.length} entri',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: records.isEmpty
                    ? const _EmptyState()
                    : _HistoryList(records: records),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: records.isEmpty
                        ? null
                        : () => _exportCsv(context, records),
                    icon: const Icon(Icons.file_download, size: 16),
                    label: const Text('Ekspor CSV'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: records.isEmpty
                        ? null
                        : () async {
                            final ok = await _confirmClear(context);
                            if (ok != true) return;
                            await ref
                                .read(cleaningHistoryProvider.notifier)
                                .clear();
                          },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus semua'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus riwayat?'),
        content: const Text(
          'Semua entri riwayat pembersihan akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<CleaningRecord> records,
  ) async {
    try {
      final csv = CleaningHistoryService.instance.toCsv(records);
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(dir.path, 'cleaning_history_$stamp.csv'));
      await file.writeAsString(csv, flush: true);
      await Clipboard.setData(ClipboardData(text: file.path));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disimpan: ${file.path} (path disalin ke clipboard)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ekspor: $e')));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.surfaceMutedBorder),
            ),
            child: Icon(
              Icons.cleaning_services_outlined,
              size: 28,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Setiap pembersihan yang berhasil akan tercatat di sini.',
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<CleaningRecord> records;
  const _HistoryList({required this.records});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var s = bytes.toDouble();
    var u = 0;
    while (s >= 1024 && u < units.length - 1) {
      s /= 1024;
      u++;
    }
    return '${s.toStringAsFixed(s < 10 ? 2 : 1)} ${units[u]}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final fmt = DateFormat('dd MMM yyyy • HH:mm');
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: palette.cardBorder),
      itemBuilder: (ctx, i) {
        final r = records[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt.format(r.timestamp),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Preset: ${r.preset} • '
                      'Durasi ${r.duration.inSeconds}s • '
                      'Terdeteksi ${_formatBytes(r.detectedSizeBytes)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (r.items.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: r.items
                            .map(
                              (it) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: palette.surfaceMutedBorder,
                                  ),
                                ),
                                child: Text(
                                  it,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
