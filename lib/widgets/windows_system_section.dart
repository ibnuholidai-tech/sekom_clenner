import 'package:flutter/material.dart';
import '../models/system_status.dart';
import 'default_apps_section.dart';

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
  final VoidCallback onDisableWindowsUpdate;

  // Compact mode to reduce paddings/spacing
  final bool compactMode;

  // Which part of the section to show (1 = status rows, 2 = Windows Update control and options)
  final int showPart;

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
    required this.onDisableWindowsUpdate,
    this.compactMode = false,
    this.showPart = 0, // 0 = show all, 1 = first part, 2 = second part
  });

  @override
  State<WindowsSystemSection> createState() => _WindowsSystemSectionState();
}

class _WindowsSystemSectionState extends State<WindowsSystemSection> {
  @override
  Widget build(BuildContext context) {
    final double pad = widget.compactMode ? 12.0 : 16.0;

    // Determine which parts to show based on showPart parameter
    final bool showFirstPart = widget.showPart == 0 || widget.showPart == 1;
    final bool showSecondPart = widget.showPart == 0 || widget.showPart == 2;

    // Determine title based on which part is shown
    String title = 'Windows System';
    if (widget.showPart == 1) {
      title = 'Windows Status';
    } else if (widget.showPart == 2) {
      title = 'Windows Controls';
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  widget.showPart == 2 ? Icons.settings : Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                  size: widget.compactMode ? 20 : 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: widget.compactMode ? 15 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!widget.compactMode && widget.showPart == 0)
                        Text(
                          'Status & tindakan cepat untuk Defender, Update, Driver, dan Aktivasi',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.compactMode ? 6 : 8),

            // Status rows (first part)
            if (showFirstPart) ...[
              _buildSystemStatusRow(
                'Windows Defender',
                widget.defenderStatus,
                widget.onUpdateDefender,
                'Update',
                onOpen: widget.onOpenWindowsSecurity,
                openText: 'Lihat',
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
              const SizedBox(height: 8),
              // Default Applications Checker
              const DefaultAppsSection(),
            ],

            // Add spacing between parts if showing both
            if (showFirstPart && showSecondPart) const SizedBox(height: 12),

            // Windows Update toggle control and options (second part)
            if (showSecondPart) ...[
              // Windows Update toggle control - more compact
              Row(
                children: [
                  Text(
                    'Windows Update Control',
                    style: TextStyle(
                      fontSize: widget.compactMode ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: widget.compactMode ? 4 : 6),
              // Windows Update Control Boxes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator - Enhanced with three states (Active, Paused, Disabled)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(
                        widget.windowsUpdatePaused,
                        widget.updateStatus,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusBorderColor(
                          widget.windowsUpdatePaused,
                          widget.updateStatus,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(
                            widget.windowsUpdatePaused,
                            widget.updateStatus,
                          ),
                          size: 16,
                          color: _getStatusTextColor(
                            widget.windowsUpdatePaused,
                            widget.updateStatus,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(
                            widget.windowsUpdatePaused,
                            widget.updateStatus,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusTextColor(
                              widget.windowsUpdatePaused,
                              widget.updateStatus,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Control buttons in a row - Simplified to 2 buttons
                  Row(
                    children: [
                      // Pause button
                      Expanded(
                        child: Tooltip(
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
                              widget.windowsUpdatePaused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              size: 16,
                            ),
                            label: Text(
                              widget.windowsUpdatePaused
                                  ? 'Resume Updates'
                                  : 'Pause 2077',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.windowsUpdatePaused
                                  ? Colors.green.shade600
                                  : Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Disable button - using the disableWindowsUpdate callback
                      Expanded(
                        child: Tooltip(
                          message: 'Disable Windows Update service completely',
                          child: ElevatedButton.icon(
                            onPressed: widget.isChecking
                                ? null
                                : widget.onDisableWindowsUpdate,
                            icon: Icon(Icons.block, size: 16),
                            label: Text(
                              'Disable Update',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Reset/Normal button - Combined functionality
                  SizedBox(
                    width: double.infinity,
                    child: Tooltip(
                      message:
                          'Reset Windows Update to normal state (enable service and resume updates)',
                      child: OutlinedButton.icon(
                        onPressed: widget.isChecking
                            ? null
                            : widget.onResumeWindowsUpdate,
                        icon: Icon(Icons.settings_backup_restore, size: 16),
                        label: Text(
                          'Reset to Normal State',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Options - more compact in compact mode
              if (widget.compactMode) ...[
                // Horizontal row of checkboxes with tooltips
                Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: 'Lewati cek Aktivasi saat "Check All"',
                        child: _buildCompactCheckbox(
                          'Lewati Aktivasi',
                          widget.skipActivationOnCheckAll,
                          widget.isChecking
                              ? null
                              : widget.onSkipActivationChanged,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: 'Hapus Recent Items & Unpin Photos',
                        child: _buildCompactCheckbox(
                          'Hapus Recent',
                          widget.clearRecentSelected,
                          widget.onClearRecentChanged,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: 'Kosongkan Recycle Bin',
                        child: _buildCompactCheckbox(
                          'Kosongkan Bin',
                          widget.clearRecycleBinSelected,
                          widget.onClearRecycleBinChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
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
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to build compact checkbox items
  Widget _buildCompactCheckbox(
    String label,
    bool value,
    Function(bool)? onChanged,
  ) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: onChanged == null ? Colors.grey : Colors.blue,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 12))),
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

  // Helper methods for status indicator
  bool _isServiceDisabled(SystemStatus updateStatus) {
    final String status = updateStatus.status.toLowerCase();
    // Enhanced detection of disabled service with multiple keywords
    return status.contains('disabled') ||
        status.contains('service disabled') ||
        status.contains('dinonaktifkan') ||
        status.contains('layanan dinonaktifkan') ||
        (!updateStatus.isActive && status.contains('service'));
  }

  Color _getStatusBackgroundColor(bool isPaused, SystemStatus updateStatus) {
    if (_isServiceDisabled(updateStatus)) {
      return Colors.red.shade50; // Red background for disabled
    } else if (isPaused) {
      return Colors.orange.shade50; // Orange background for paused
    } else {
      return Colors.green.shade50; // Green background for active
    }
  }

  Color _getStatusBorderColor(bool isPaused, SystemStatus updateStatus) {
    if (_isServiceDisabled(updateStatus)) {
      return Colors.red.shade200; // Red border for disabled
    } else if (isPaused) {
      return Colors.orange.shade200; // Orange border for paused
    } else {
      return Colors.green.shade200; // Green border for active
    }
  }

  IconData _getStatusIcon(bool isPaused, SystemStatus updateStatus) {
    if (_isServiceDisabled(updateStatus)) {
      return Icons.block; // Block icon for disabled
    } else if (isPaused) {
      return Icons.pause_circle; // Pause icon for paused
    } else {
      return Icons.play_circle; // Play icon for active
    }
  }

  Color _getStatusTextColor(bool isPaused, SystemStatus updateStatus) {
    if (_isServiceDisabled(updateStatus)) {
      return Colors.red.shade700; // Red text for disabled
    } else if (isPaused) {
      return Colors.orange.shade700; // Orange text for paused
    } else {
      return Colors.green.shade700; // Green text for active
    }
  }

  String _getStatusText(bool isPaused, SystemStatus updateStatus) {
    if (_isServiceDisabled(updateStatus)) {
      return 'Windows Update: Disabled'; // Text for disabled state
    } else if (isPaused) {
      return 'Windows Update: Paused'; // Text for paused state
    } else {
      // For active state, check if there's more specific status information
      if (updateStatus.status.toLowerCase().contains('up-to-date')) {
        return 'Windows Update: Up-to-date';
      } else if (updateStatus.status.toLowerCase().contains('need')) {
        return 'Windows Update: Updates needed';
      } else {
        return 'Windows Update: Active'; // Default active state
      }
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

    // Tampilkan detail jika tersedia (untuk Windows/Office Activation)
    final String displayText =
        (status.detail != null &&
            (status.status.contains("Activated") ||
                status.status.contains("✅")) &&
            status.detail!.isNotEmpty)
        ? status.detail!
        : status.status;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: widget.compactMode ? 10 : 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // More compact system status row with status chip next to the title
  Widget _buildSystemStatusRow(
    String title,
    SystemStatus status,
    VoidCallback onAction,
    String actionText, {
    VoidCallback? onOpen,
    String openText = 'Lihat',
  }) {
    final bool showAction =
        (status.needsUpdate || !status.isActive) && !widget.isChecking;
    final bool isCompact = widget.compactMode;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4.0 : 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _iconFor(title),
            size: isCompact ? 16 : 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          // Title
          SizedBox(
            width: 110, // Fixed width for title
            child: Text(
              title,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status chip (now next to title instead of below)
          Expanded(
            child: Tooltip(
              message:
                  (status.detail != null && status.detail!.trim().isNotEmpty)
                  ? '${status.status}\n${status.detail}'
                  : status.status,
              child: _statusChip(status),
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: 24,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined, size: 12),
                label: Text(openText, style: const TextStyle(fontSize: 9)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 24),
                ),
              ),
            ),
          ],
          if (showAction) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: 24,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.build_circle_outlined, size: 12),
                label: Text(actionText, style: const TextStyle(fontSize: 9)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
