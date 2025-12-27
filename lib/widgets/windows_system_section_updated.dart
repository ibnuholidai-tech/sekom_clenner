import 'package:flutter/material.dart';
import '../models/system_status.dart';

class WindowsSystemSection extends StatefulWidget {
  final SystemStatus defenderStatus;
  final SystemStatus updateStatus;
  final SystemStatus driverStatus;
  final SystemStatus windowsActivationStatus;
  final SystemStatus officeActivationStatus;

  final bool clearRecentSelected;
  final bool clearRecycleBinSelected;
  final bool isChecking;

  final VoidCallback onUpdateDefender;
  final VoidCallback onRunWindowsUpdate;
  final VoidCallback onUpdateDrivers;
  final VoidCallback onActivateWindows;
  final VoidCallback onActivateOffice;

  final VoidCallback onOpenActivationShell;
  final VoidCallback onOpenWindowsUpdateSettings;
  final VoidCallback onOpenWindowsSecurity;
  final VoidCallback onOpenDeviceManager;

  final ValueChanged<bool> onClearRecycleBinChanged;
  final ValueChanged<bool> onClearRecentChanged;
  final VoidCallback onRecheckActivation;

  final bool skipActivationOnCheckAll;
  final ValueChanged<bool> onSkipActivationChanged;

  final bool windowsUpdatePaused;
  final VoidCallback onPauseWindowsUpdate;
  final VoidCallback onResumeWindowsUpdate;

  // Compact mode to reduce paddings/spacing
  final bool compactMode;

  const WindowsSystemSection({
    super.key,
    required this.defenderStatus,
    required this.updateStatus,
    required this.driverStatus,
    required this.windowsActivationStatus,
    required this.officeActivationStatus,
    required this.clearRecentSelected,
    required this.clearRecycleBinSelected,
    required this.isChecking,
    required this.onUpdateDefender,
    required this.onRunWindowsUpdate,
    required this.onUpdateDrivers,
    required this.onActivateWindows,
    required this.onActivateOffice,
    required this.onOpenActivationShell,
    required this.onOpenWindowsUpdateSettings,
    required this.onOpenWindowsSecurity,
    required this.onOpenDeviceManager,
    required this.onClearRecycleBinChanged,
    required this.onClearRecentChanged,
    required this.onRecheckActivation,
    required this.skipActivationOnCheckAll,
    required this.onSkipActivationChanged,
    required this.windowsUpdatePaused,
    required this.onPauseWindowsUpdate,
    required this.onResumeWindowsUpdate,
    this.compactMode = false,
  });

  @override
  State<WindowsSystemSection> createState() => _WindowsSystemSectionState();
}

class _WindowsSystemSectionState extends State<WindowsSystemSection> {
  @override
  Widget build(BuildContext context) {
    final double pad = widget.compactMode ? 12.0 : 16.0;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Windows System',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Status & tindakan cepat untuk Defender, Update, Driver, dan Aktivasi',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            // Status rows
            _buildSystemStatusRow(
              'Windows Defender',
              widget.defenderStatus,
              widget.onUpdateDefender,
              'Update',
              onOpen: widget.onOpenWindowsSecurity,
              openText: 'Lihat',
            ),
            _buildSystemStatusRow(
              'Windows Update',
              widget.updateStatus,
              widget.onRunWindowsUpdate,
              'Run Update',
              onOpen: widget.onOpenWindowsUpdateSettings,
              openText: 'Lihat',
            ),
            _buildSystemStatusRow(
              'Drivers',
              widget.driverStatus,
              widget.onUpdateDrivers,
              'Scan',
              onOpen: widget.onOpenDeviceManager,
              openText: 'Device Manager',
            ),
            _buildSystemStatusRow(
              'Windows Activation',
              widget.windowsActivationStatus,
              widget.onActivateWindows,
              'Activate',
              onOpen: widget.onOpenActivationShell,
              openText: 'Buka Shell',
            ),
            _buildSystemStatusRow(
              'Office Activation',
              widget.officeActivationStatus,
              widget.onActivateOffice,
              'Activate',
            ),

            const SizedBox(height: 12),

            // Windows Update toggle control
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Windows Update Control',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Status pill
                Container(
                  decoration: BoxDecoration(
                    color: (widget.windowsUpdatePaused
                        ? Colors.orange.shade50
                        : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.windowsUpdatePaused
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.windowsUpdatePaused
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        size: 16,
                        color: widget.windowsUpdatePaused
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.windowsUpdatePaused ? 'Paused' : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.windowsUpdatePaused
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: widget.windowsUpdatePaused
                      ? 'Resume: Remove pause settings and re-enable Windows Update'
                      : 'Pause: Set Windows Update to pause until 2077 via registry',
                  child: ElevatedButton.icon(
                    onPressed: widget.isChecking
                        ? null
                        : (widget.windowsUpdatePaused
                            ? widget.onResumeWindowsUpdate
                            : widget.onPauseWindowsUpdate),
                    icon: Icon(
                      widget.windowsUpdatePaused ? Icons.play_arrow : Icons.pause,
                    ),
                    label: Text(
                      widget.windowsUpdatePaused
                          ? 'Resume Updates'
                          : 'Pause 2077',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.windowsUpdatePaused
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Options
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Lewati cek Aktivasi saat "Check All"',
                style: TextStyle(fontSize: 12),
              ),
              value: widget.skipActivationOnCheckAll,
              onChanged: widget.isChecking
                  ? null
                  : (v) => widget.onSkipActivationChanged(v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Hapus Recent Items (Start/Search + Quick Access + Office) & Unpin Photos',
                style: TextStyle(fontSize: 12),
              ),
              value: widget.clearRecentSelected,
              onChanged: (v) => widget.onClearRecentChanged(v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Kosongkan Recycle Bin',
                style: TextStyle(fontSize: 12),
              ),
              value: widget.clearRecycleBinSelected,
              onChanged: (v) => widget.onClearRecycleBinChanged(v ?? false),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String title) {
    switch (title) {
      case 'Windows Defender':
        return Icons.shield_outlined;
      case 'Windows Update':
        return Icons.system_update_alt;
      case 'Drivers':
        return Icons.usb;
      case 'Windows Activation':
        return Icons.verified_user_outlined;
      case 'Office Activation':
        return Icons.apps;
      default:
        return Icons.info_outline;
    }
  }

  Widget _statusChip(SystemStatus status) {
    final bool isChecking = status.status.toLowerCase().contains('checking');
    final bool good = status.isActive && !status.needsUpdate;
    final bool warn = status.needsUpdate && status.isActive;
    final bool bad = !status.isActive && !isChecking;

    Color bg;
    Color border;
    Color fg;

    if (isChecking) {
      bg = Colors.grey.shade100;
      border = Colors.grey.shade300;
      fg = Colors.grey.shade800;
    } else if (good) {
      bg = Colors.green.shade50;
      border = Colors.green.shade200;
      fg = Colors.green.shade700;
    } else if (warn) {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade200;
      fg = Colors.orange.shade700;
    } else if (bad) {
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.grey.shade100;
      border = Colors.grey.shade300;
      fg = Colors.grey.shade800;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        status.status,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSystemStatusRow(
    String title,
    SystemStatus status,
    VoidCallback onAction,
    String actionText, {
    VoidCallback? onOpen,
    String openText = 'Lihat',
  }) {
    final bool showAction = (status.needsUpdate || !status.isActive) && !widget.isChecking;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(title), size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Tooltip(
                  message: (status.detail != null && status.detail!.trim().isNotEmpty)
                      ? '${status.status}\n${status.detail}'
                      : status.status,
                  child: _statusChip(status),
                ),
              ],
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: Text(openText, style: const TextStyle(fontSize: 10)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ),
          ],
          if (showAction) ...[
            const SizedBox(width: 6),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.build_circle_outlined, size: 14),
                label: Text(actionText, style: const TextStyle(fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
