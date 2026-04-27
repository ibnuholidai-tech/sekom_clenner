import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../state/theme_provider.dart';
import '../../state/update_status_provider.dart';
import '../../theme/app_theme.dart';

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final asyncUpdate = ref.watch(updateStatusProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Pengaturan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Theme mode
              const _SectionLabel('Tampilan'),
              const SizedBox(height: 6),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Sistem'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Terang'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Gelap'),
                  ),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),

              const SizedBox(height: 18),

              // Crash reporting
              const _SectionLabel('Laporan kesalahan'),
              const SizedBox(height: 6),
              _StatusRow(
                icon: Icons.bug_report_outlined,
                title: 'Sentry',
                subtitle: Sentry.isEnabled
                    ? 'Aktif — error otomatis dikirim ke Sentry'
                    : 'Nonaktif — pasang DSN saat build dengan '
                          '--dart-define=SENTRY_DSN=https://... untuk mengaktifkan',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Sentry.isEnabled
                        ? AppTheme.pillGreen
                        : AppTheme.pillAmber,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    Sentry.isEnabled ? 'AKTIF' : 'NONAKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Sentry.isEnabled
                          ? AppTheme.pillGreenText
                          : AppTheme.pillAmberText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Update status
              const _SectionLabel('Pembaruan aplikasi'),
              const SizedBox(height: 6),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (ctx, snap) {
                  final cur = snap.data?.version ?? '?';
                  final info = asyncUpdate.asData?.value;
                  String subtitle;
                  if (asyncUpdate.isLoading) {
                    subtitle = 'Memeriksa rilis terbaru...';
                  } else if (info == null) {
                    subtitle = 'Versi saat ini: $cur';
                  } else if (info.isUpdateAvailable) {
                    subtitle =
                        'Versi baru ${info.latestVersion} tersedia '
                        '(saat ini $cur)';
                  } else {
                    subtitle = 'Sudah versi terbaru ($cur)';
                  }
                  return _StatusRow(
                    icon: Icons.system_update_alt,
                    title: 'GitHub Releases',
                    subtitle: subtitle,
                    trailing: TextButton(
                      onPressed: () => ref.invalidate(updateStatusProvider),
                      child: const Text('Refresh'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.pillBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
