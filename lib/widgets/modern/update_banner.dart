import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/update_checker_service.dart';
import '../../state/update_status_provider.dart';
import '../../theme/app_theme.dart';

/// Slim banner that surfaces a newer GitHub release.
///
/// Shows nothing while loading, on error, or when the local build is up
/// to date — by design it is invisible 99% of the time.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(updateStatusProvider);
    final info = asyncInfo.asData?.value;
    if (info == null || !info.isUpdateAvailable) {
      return const SizedBox.shrink();
    }
    return _UpdateBannerView(info: info);
  }
}

class _UpdateBannerView extends StatefulWidget {
  final AppUpdateInfo info;
  const _UpdateBannerView({required this.info});

  @override
  State<_UpdateBannerView> createState() => _UpdateBannerViewState();
}

class _UpdateBannerViewState extends State<_UpdateBannerView> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.pillAmber,
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder),
          bottom: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update_alt,
            size: 18,
            color: AppTheme.pillAmberText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Versi baru tersedia: ${widget.info.latestVersion} '
              '(saat ini ${widget.info.currentVersion})',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.pillAmberText,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () => _open(widget.info.htmlUrl),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('Buka', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.pillAmberText,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close, size: 14),
            color: AppTheme.pillAmberText,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', '', url], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [url]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [url]);
      }
    } catch (_) {
      // Best-effort: ignore failures opening the browser.
    }
  }
}
