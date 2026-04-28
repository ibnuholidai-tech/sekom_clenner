import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/system_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
import '../../widgets/modern/modern_pill.dart';
import '../state/status_message_provider.dart';

/// Modern Optimization screen — actionable performance & maintenance tasks.
class ModernOptimizationScreen extends ConsumerStatefulWidget {
  const ModernOptimizationScreen({super.key});

  @override
  ConsumerState<ModernOptimizationScreen> createState() =>
      _ModernOptimizationScreenState();
}

class _ModernOptimizationScreenState
    extends ConsumerState<ModernOptimizationScreen> {
  bool _busy = false;

  void _setStatus(String s) =>
      ref.read(statusMessageProvider.notifier).state = s;

  Future<void> _run(String label, Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    _setStatus('Menjalankan: $label...');
    try {
      final ok = await action();
      _setStatus(ok ? '$label berhasil.' : '$label gagal.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '$label berhasil.' : '$label gagal.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      _setStatus('$label error: $e');
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
          _buildHeader(),
          const SizedBox(height: 14),
          _buildPerformanceCard(),
          const SizedBox(height: 14),
          _buildMaintenanceCard(),
          const SizedBox(height: 14),
          _buildShortcutsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              Icons.auto_awesome,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimization',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tindakan cepat untuk mempercepat & merawat sistem',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                  ),
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

  Widget _buildPerformanceCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.speed,
            title: 'Performa',
            subtitle: 'Atur pengelolaan power, startup, dan ruang disk',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.power_settings_new,
                label: 'Buka Power Options',
                onTap: () => _run(
                  'Buka Power Options',
                  () => SystemService.openSettingsUri('ms-settings:powersleep'),
                ),
              ),
              ModernActionPill(
                icon: Icons.app_registration,
                label: 'Kelola Startup',
                onTap: () => _run(
                  'Buka Startup',
                  () => SystemService.openTaskManagerStartup(),
                ),
              ),
              ModernActionPill(
                icon: Icons.cleaning_services,
                label: 'Disk Cleanup',
                onTap: () =>
                    _run('Disk Cleanup', () => SystemService.openDiskCleanup()),
              ),
              ModernActionPill(
                icon: Icons.tune,
                label: 'System Properties',
                onTap: () => _run(
                  'System Properties',
                  () => SystemService.openSystemProperties(),
                ),
              ),
              ModernActionPill(
                icon: Icons.memory,
                label: 'Performance Monitor',
                onTap: () => _run(
                  'Performance Monitor',
                  () => SystemService.openPerformanceMonitor(),
                ),
              ),
              ModernActionPill(
                icon: Icons.assignment,
                label: 'Task Manager',
                onTap: () => _run(
                  'Task Manager',
                  () => SystemService.openTaskManagerStartup(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.build_outlined,
            title: 'Maintenance',
            subtitle: 'Pemutakhiran komponen & layanan',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.security,
                label: 'Update Defender',
                onTap: () => _run(
                  'Update Defender',
                  () => SystemService.updateWindowsDefender(),
                ),
              ),
              ModernActionPill(
                icon: Icons.system_update,
                label: 'Cek Windows Update',
                onTap: () => _run(
                  'Cek Update',
                  () => SystemService.runWindowsUpdate(),
                ),
              ),
              ModernActionPill(
                icon: Icons.cable,
                label: 'Update Drivers',
                onTap: () =>
                    _run('Update Drivers', () => SystemService.updateDrivers()),
              ),
              ModernActionPill(
                icon: Icons.pause_circle_outline,
                label: 'Pause Update',
                tone: PillTone.warning,
                onTap: () => _run(
                  'Pause Windows Update',
                  () => SystemService.pauseWindowsUpdateService(),
                ),
              ),
              ModernActionPill(
                icon: Icons.play_circle_outline,
                label: 'Resume Update',
                onTap: () => _run(
                  'Resume Windows Update',
                  () => SystemService.resumeWindowsUpdateService(),
                ),
              ),
              ModernActionPill(
                icon: Icons.block,
                label: 'Disable Update',
                tone: PillTone.danger,
                onTap: () => _run(
                  'Disable Windows Update',
                  () => SystemService.disableWindowsUpdateService(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.bolt,
            title: 'Pintasan Cepat',
            subtitle: 'Buka panel sistem yang sering dibutuhkan',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernActionPill(
                icon: Icons.settings_input_component,
                label: 'Device Manager',
                onTap: () => _run(
                  'Device Manager',
                  () => SystemService.openDeviceManager(),
                ),
              ),
              ModernActionPill(
                icon: Icons.miscellaneous_services,
                label: 'Services',
                onTap: () => _run(
                  'Services',
                  () => SystemService.openServicesConsole(),
                ),
              ),
              ModernActionPill(
                icon: Icons.event,
                label: 'Event Viewer',
                onTap: () =>
                    _run('Event Viewer', () => SystemService.openEventViewer()),
              ),
              ModernActionPill(
                icon: Icons.dashboard_customize_outlined,
                label: 'Computer Mgmt.',
                onTap: () => _run(
                  'Computer Management',
                  () => SystemService.openComputerManagement(),
                ),
              ),
              ModernActionPill(
                icon: Icons.network_wifi,
                label: 'Network',
                onTap: () => _run(
                  'Network Connections',
                  () => SystemService.openNetworkConnections(),
                ),
              ),
              ModernActionPill(
                icon: Icons.local_fire_department_outlined,
                label: 'Firewall',
                onTap: () =>
                    _run('Firewall', () => SystemService.openFirewall()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
