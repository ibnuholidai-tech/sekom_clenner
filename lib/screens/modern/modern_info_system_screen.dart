import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/system_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
import '../../widgets/modern/modern_pill.dart';
import '../state/status_message_provider.dart';

/// Modern Info System — shows OS / CPU / RAM / disk / network details.
class ModernInfoSystemScreen extends ConsumerStatefulWidget {
  const ModernInfoSystemScreen({super.key});

  @override
  ConsumerState<ModernInfoSystemScreen> createState() =>
      _ModernInfoSystemScreenState();
}

class _ModernInfoSystemScreenState
    extends ConsumerState<ModernInfoSystemScreen> {
  bool _loading = true;
  Map<String, dynamic> _ram = {};
  List<Map<String, dynamic>> _disks = [];
  String _osVersion = '';
  String _hostName = '';
  String _userName = '';
  String _ipAddresses = '';
  bool _elevated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    ref.read(statusMessageProvider.notifier).state = 'Mengumpulkan info sistem...';
    try {
      final ramF = SystemService.getRamInfo()
          .catchError((_) => <String, dynamic>{});
      final disksF = SystemService.getPhysicalDiskInfo()
          .catchError((_) => <Map<String, dynamic>>[]);
      final elevatedF =
          SystemService.isElevated().catchError((_) => false);

      final results = await Future.wait<dynamic>([ramF, disksF, elevatedF]);

      final addresses = <String>[];
      try {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.any,
        );
        for (final i in interfaces) {
          for (final a in i.addresses) {
            addresses.add('${i.name}: ${a.address}');
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _ram = results[0] as Map<String, dynamic>;
        _disks = results[1] as List<Map<String, dynamic>>;
        _elevated = results[2] as bool;
        _osVersion = Platform.operatingSystemVersion;
        _hostName = Platform.localHostname;
        _userName = Platform.environment['USERNAME'] ??
            Platform.environment['USER'] ??
            '';
        _ipAddresses = addresses.join('\n');
        _loading = false;
      });
      ref.read(statusMessageProvider.notifier).state = 'Info sistem siap.';
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ref.read(statusMessageProvider.notifier).state = 'Error: $e';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(size < 10 ? 2 : 1)} ${units[unit]}';
  }

  Widget _kv(String k, String v, {IconData? icon}) {
    final palette = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.surfaceMutedBorder),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon ?? Icons.info_outline,
              size: 16,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  v.isEmpty ? '—' : v,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: v));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disalin ke clipboard')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ],
      ),
    );
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _systemCard(),
            const SizedBox(height: 14),
            _hardwareCard(),
            const SizedBox(height: 14),
            _networkCard(),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    final palette = context.appColors;
    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.dns_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Info System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detail OS, hardware, dan jaringan',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _systemCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.computer,
            title: 'Sistem Operasi',
            subtitle: 'Identitas mesin dan akun',
          ),
          const SizedBox(height: 8),
          _kv(
            'Operating System',
            '${Platform.operatingSystem.toUpperCase()} ${_osVersion.isEmpty ? "" : "• $_osVersion"}',
            icon: Icons.desktop_windows_outlined,
          ),
          _kv(
            'Hostname',
            _hostName,
            icon: Icons.dns_outlined,
          ),
          _kv(
            'User',
            _userName,
            icon: Icons.person_outline,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                ModernBadge.tone(
                  tone: _elevated ? PillTone.success : PillTone.warning,
                  text: _elevated ? 'Administrator' : 'Standard User',
                  icon: _elevated ? Icons.admin_panel_settings : Icons.lock_open,
                ),
                const SizedBox(width: 8),
                if (!_elevated)
                  TextButton(
                    onPressed: () => SystemService.relaunchAsAdmin(),
                    child: const Text('Jalankan sebagai Admin'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hardwareCard() {
    final palette = context.appColors;
    final ramTotal =
        ((_ram['totalMemoryBytes'] as num?)?.toInt() ?? 0);
    final ramFree = ((_ram['availableMemoryBytes'] as num?)?.toInt() ?? 0);
    final used = ramTotal - ramFree;
    final usedPct =
        ramTotal > 0 ? (used / ramTotal).clamp(0.0, 1.0) : 0.0;
    final barColor = usedPct > 0.85
        ? AppTheme.danger
        : (usedPct > 0.6 ? AppTheme.warning : AppTheme.primary);
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.memory,
            title: 'Hardware',
            subtitle: 'Memori dan disk fisik',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.surfaceMutedBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory, size: 16, color: palette.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'RAM',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatBytes(used)} / ${_formatBytes(ramTotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: usedPct,
                    minHeight: 8,
                    backgroundColor: palette.cardBorder,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_disks.isEmpty)
            Text(
              'Tidak ada info disk fisik.',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final d in _disks)
                  _diskTile(d),
              ],
            ),
        ],
      ),
    );
  }

  Widget _diskTile(Map<String, dynamic> disk) {
    final palette = context.appColors;
    final name =
        (disk['model'] ?? disk['friendlyName'] ?? 'Disk').toString();
    final type = (disk['mediaType'] ?? disk['type'] ?? '').toString();
    final size = (disk['sizeFormatted'] ??
            disk['size']?.toString() ??
            disk['capacity']?.toString() ??
            '')
        .toString();
    final health = (disk['healthStatus'] ?? '').toString();
    final ok = health.toLowerCase().contains('ok') ||
        health.toLowerCase().contains('healthy') ||
        health.isEmpty;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.surfaceMutedBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.album, size: 16, color: palette.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              ModernBadge.tone(
                tone: ok ? PillTone.success : PillTone.warning,
                text: ok ? 'OK' : 'Periksa',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tipe: ${type.isEmpty ? "-" : type} • $size',
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _networkCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.network_wifi,
            title: 'Jaringan',
            subtitle: 'Antarmuka dan alamat IP',
          ),
          const SizedBox(height: 8),
          _kv(
            'IP Addresses',
            _ipAddresses,
            icon: Icons.lan_outlined,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.network_check,
                label: 'Network Settings',
                onTap: () => SystemService.openNetworkConnections(),
              ),
              ModernActionPill(
                icon: Icons.shield_outlined,
                label: 'Firewall',
                onTap: () => SystemService.openFirewall(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
