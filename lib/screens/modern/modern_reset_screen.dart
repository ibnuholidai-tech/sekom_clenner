import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/system_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
import '../../widgets/modern/modern_pill.dart';
import '../state/status_message_provider.dart';

/// Modern Reset screen — central place for "destructive but useful" actions.
class ModernResetScreen extends ConsumerStatefulWidget {
  const ModernResetScreen({super.key});

  @override
  ConsumerState<ModernResetScreen> createState() => _ModernResetScreenState();
}

class _ModernResetScreenState extends ConsumerState<ModernResetScreen> {
  bool _busy = false;

  void _setStatus(String s) =>
      ref.read(statusMessageProvider.notifier).state = s;

  Future<void> _confirmedRun(
    String title,
    String message,
    Future<bool> Function() action,
  ) async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    _setStatus('Menjalankan: $title...');
    try {
      final res = await action();
      _setStatus(res ? '$title selesai.' : '$title gagal.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? '$title selesai.' : '$title gagal.')),
      );
    } catch (e) {
      _setStatus('$title error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 14),
          _browsersCard(),
          const SizedBox(height: 14),
          _systemCleanupCard(),
          const SizedBox(height: 14),
          _windowsResetCard(),
        ],
      ),
    );
  }

  Widget _header() {
    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.pillRed,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.refresh, color: AppTheme.pillRedText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset & Restore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kembalikan komponen ke kondisi default',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _browsersCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.travel_explore,
            iconColor: AppTheme.pillBlueText,
            iconBackground: AppTheme.pillBlue,
            title: 'Reset Browser',
            subtitle: 'Hapus profil & data browser sepenuhnya',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.public,
                label: 'Reset Chrome',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                onTap: () => _confirmedRun(
                  'Reset Chrome',
                  'Tindakan ini akan menutup Chrome dan menghapus profil pengguna Chrome. Lanjutkan?',
                  () => SystemService.cleanBrowsers(
                    chrome: true,
                    resetBrowser: true,
                  ).then((_) => true),
                ),
              ),
              ModernActionPill(
                icon: Icons.web,
                label: 'Reset Edge',
                tint: AppTheme.pillTeal,
                tintText: AppTheme.pillTealText,
                onTap: () => _confirmedRun(
                  'Reset Edge',
                  'Tindakan ini akan menutup Edge dan menghapus profil pengguna Edge. Lanjutkan?',
                  () => SystemService.cleanBrowsers(
                    edge: true,
                    resetBrowser: true,
                  ).then((_) => true),
                ),
              ),
              ModernActionPill(
                icon: Icons.local_fire_department,
                label: 'Reset Firefox',
                tint: AppTheme.pillAmber,
                tintText: AppTheme.pillAmberText,
                onTap: () => _confirmedRun(
                  'Reset Firefox',
                  'Tindakan ini akan menutup Firefox dan menghapus profil pengguna Firefox. Lanjutkan?',
                  () => SystemService.cleanBrowsers(
                    firefox: true,
                    resetBrowser: true,
                  ).then((_) => true),
                ),
              ),
              ModernActionPill(
                icon: Icons.cleaning_services,
                label: 'Bersihkan Semua',
                tint: AppTheme.pillRed,
                tintText: AppTheme.pillRedText,
                onTap: () => _confirmedRun(
                  'Reset Semua Browser',
                  'Tindakan ini akan menghapus profil Chrome, Edge, dan Firefox. Lanjutkan?',
                  () => SystemService.cleanBrowsers(
                    chrome: true,
                    edge: true,
                    firefox: true,
                    resetBrowser: true,
                  ).then((_) => true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _systemCleanupCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.delete_sweep,
            iconColor: AppTheme.pillPurpleText,
            iconBackground: AppTheme.pillPurple,
            title: 'Pembersihan Sistem',
            subtitle: 'Recent files, recycle bin, dan disk cleanup',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.history_toggle_off,
                label: 'Hapus Recent',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                onTap: () => _confirmedRun(
                  'Hapus Recent Files',
                  'Tindakan ini akan menghapus daftar file yang baru saja dibuka. Lanjutkan?',
                  () => SystemService.clearRecentFiles(),
                ),
              ),
              ModernActionPill(
                icon: Icons.delete_outline,
                label: 'Kosongkan Bin',
                tint: AppTheme.pillRed,
                tintText: AppTheme.pillRedText,
                onTap: () => _confirmedRun(
                  'Kosongkan Recycle Bin',
                  'Tindakan ini akan mengosongkan Recycle Bin secara permanen. Lanjutkan?',
                  () => SystemService.clearRecycleBin(),
                ),
              ),
              ModernActionPill(
                icon: Icons.cleaning_services,
                label: 'Disk Cleanup',
                tint: AppTheme.pillTeal,
                tintText: AppTheme.pillTealText,
                onTap: () => _confirmedRun(
                  'Buka Disk Cleanup',
                  'Tindakan ini akan membuka aplikasi Disk Cleanup. Lanjutkan?',
                  () => SystemService.openDiskCleanup(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowsResetCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.settings_backup_restore,
            iconColor: AppTheme.pillAmberText,
            iconBackground: AppTheme.pillAmber,
            title: 'Pengaturan Windows',
            subtitle: 'Reset jaringan, recovery, dan reset PC',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.network_check,
                label: 'Reset Network',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                onTap: () => _confirmedRun(
                  'Buka Reset Network',
                  'Tindakan ini akan membuka pengaturan reset jaringan Windows. Lanjutkan?',
                  () => SystemService.openSettingsUri(
                    'ms-settings:network-status',
                  ),
                ),
              ),
              ModernActionPill(
                icon: Icons.system_update,
                label: 'Recovery',
                tint: AppTheme.pillPurple,
                tintText: AppTheme.pillPurpleText,
                onTap: () => _confirmedRun(
                  'Buka Recovery',
                  'Tindakan ini akan membuka pengaturan Recovery Windows. Lanjutkan?',
                  () => SystemService.openSettingsUri('ms-settings:recovery'),
                ),
              ),
              ModernActionPill(
                icon: Icons.refresh,
                label: 'Reset This PC',
                tint: AppTheme.pillRed,
                tintText: AppTheme.pillRedText,
                onTap: () => _confirmedRun(
                  'Reset This PC',
                  'Tindakan ini akan membuka panel Reset This PC. Pastikan Anda sudah backup data penting. Lanjutkan?',
                  () =>
                      SystemService.openSettingsUri('ms-settings:recovery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
