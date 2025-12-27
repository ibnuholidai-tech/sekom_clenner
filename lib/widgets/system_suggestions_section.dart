import 'package:flutter/material.dart';
import '../config/system_suggestions.dart';
import '../services/system_service.dart';

class SystemSuggestionsSection extends StatefulWidget {
  final String category;
  final bool compactMode;

  const SystemSuggestionsSection({
    super.key,
    this.category = 'All',
    this.compactMode = true,
  });

  @override
  State<SystemSuggestionsSection> createState() => _SystemSuggestionsSectionState();
}

class _SystemSuggestionsSectionState extends State<SystemSuggestionsSection> {
  List<SystemSuggestion> _suggestions = [];
  String _selectedCategory = 'All';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _loadSuggestions();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await SystemService.isElevated();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  void _loadSuggestions() {
    setState(() {
      if (_selectedCategory == 'All') {
        _suggestions = SystemSuggestions.getAllSuggestions();
      } else {
        _suggestions = SystemSuggestions.getSuggestionsByCategory(_selectedCategory);
      }
    });
  }

  void _onCategoryChanged(String? category) {
    if (category != null && category != _selectedCategory) {
      setState(() {
        _selectedCategory = category;
      });
      _loadSuggestions();
    }
  }

  Future<void> _executeAction(SystemSuggestion suggestion) async {
    if (suggestion.requiresAdmin && !_isAdmin) {
      final relaunch = await _showAdminPromptDialog();
      if (relaunch) {
        await SystemService.relaunchAsAdmin();
        return;
      } else {
        return;
      }
    }

    // Execute the appropriate action based on the suggestion
    switch (suggestion.title) {
      case 'Disable Startup Programs':
        await SystemService.openTaskManagerStartup();
        break;
      case 'Optimize Visual Effects':
        await _openPerformanceOptions();
        break;
      case 'Disk Cleanup':
        await SystemService.openDiskCleanup();
        break;
      case 'Defragment Hard Drive':
        await _openDefragmentation();
        break;
      case 'Disable Background Apps':
        await _openBackgroundAppsSettings();
        break;
      case 'Enable Windows Firewall':
        await _openFirewallSettings();
        break;
      case 'Update Windows Defender':
        await SystemService.updateWindowsDefender();
        break;
      case 'Enable BitLocker':
        await _openBitLockerSettings();
        break;
      case 'Check for Malware':
        await SystemService.openWindowsSecurity();
        break;
      case 'Enable Controlled Folder Access':
        await _openRansomwareProtection();
        break;
      case 'Disable Activity History':
        await _openActivityHistorySettings();
        break;
      case 'Manage App Permissions':
        await _openAppPermissions();
        break;
      case 'Disable Advertising ID':
        await _openPrivacySettings();
        break;
      case 'Clear Browsing Data':
        // This is already handled by the browser cleaning feature
        _showInfoDialog('Browser Cleaning', 'Use the Browser Cleaning feature in the System Cleaner tab to clear browser data.');
        break;
      case 'Disable Telemetry':
        await _openTelemetrySettings();
        break;
      case 'Schedule Automatic Maintenance':
        await _openMaintenanceSettings();
        break;
      case 'Check Disk for Errors':
        await _runCheckDisk();
        break;
      case 'Update Device Drivers':
        await SystemService.openDeviceManager();
        break;
      case 'Monitor System Health':
        await _openReliabilityMonitor();
        break;
      case 'Create System Restore Point':
        await _createRestorePoint();
        break;
      default:
        // Default action for unknown suggestions
        _showInfoDialog('Action Not Implemented', 'This action is not yet implemented.');
        break;
    }
  }

  // Helper methods for executing actions
  Future<void> _openPerformanceOptions() async {
    await SystemService.openSystemProperties();
    _showInfoDialog('Performance Options', 'In the System Properties dialog, go to the Advanced tab and click on Settings under Performance.');
  }

  Future<void> _openDefragmentation() async {
    try {
      await SystemService.openDiskManagement();
      _showInfoDialog('Defragmentation', 'Right-click on a drive and select Properties, then go to the Tools tab and click Optimize.');
    } catch (_) {}
  }

  Future<void> _openBackgroundAppsSettings() async {
    try {
      await SystemService.openSettingsUri('ms-settings:privacy-backgroundapps');
    } catch (_) {
      _showInfoDialog('Background Apps', 'Go to Settings > Privacy > Background apps to manage which apps can run in the background.');
    }
  }

  Future<void> _openFirewallSettings() async {
    try {
      await SystemService.openFirewall();
    } catch (_) {
      _showInfoDialog('Windows Firewall', 'Go to Control Panel > System and Security > Windows Defender Firewall.');
    }
  }

  Future<void> _openBitLockerSettings() async {
    try {
      await SystemService.openSettingsUri('ms-settings:windowsdefender-deviceperformanceandhealth');
      _showInfoDialog('BitLocker', 'Search for "BitLocker" in the Start menu to access BitLocker Drive Encryption settings.');
    } catch (_) {}
  }

  Future<void> _openRansomwareProtection() async {
    try {
      await SystemService.openSettingsUri('windowsdefender://threatsettings/');
      _showInfoDialog('Ransomware Protection', 'In Windows Security, go to Virus & threat protection > Ransomware protection.');
    } catch (_) {}
  }

  Future<void> _openActivityHistorySettings() async {
    try {
      await SystemService.openSettingsUri('ms-settings:privacy-activityhistory');
    } catch (_) {
      _showInfoDialog('Activity History', 'Go to Settings > Privacy > Activity history to manage activity history settings.');
    }
  }

  Future<void> _openAppPermissions() async {
    try {
      await SystemService.openSettingsUri('ms-settings:privacy');
    } catch (_) {
      _showInfoDialog('App Permissions', 'Go to Settings > Privacy to manage app permissions.');
    }
  }

  Future<void> _openPrivacySettings() async {
    try {
      await SystemService.openSettingsUri('ms-settings:privacy-general');
    } catch (_) {
      _showInfoDialog('Privacy Settings', 'Go to Settings > Privacy > General to manage privacy settings.');
    }
  }

  Future<void> _openTelemetrySettings() async {
    try {
      await SystemService.openSettingsUri('ms-settings:privacy-feedback');
    } catch (_) {
      _showInfoDialog('Telemetry Settings', 'Go to Settings > Privacy > Diagnostics & feedback to manage telemetry settings.');
    }
  }

  Future<void> _openMaintenanceSettings() async {
    try {
      await SystemService.openControlPanel();
      _showInfoDialog('Maintenance Settings', 'In Control Panel, go to System and Security > Security and Maintenance > Automatic Maintenance.');
    } catch (_) {}
  }

  Future<void> _runCheckDisk() async {
    _showInfoDialog('Check Disk', 'To run Check Disk, open Command Prompt as administrator and type: chkdsk C: /f /r');
  }

  Future<void> _openReliabilityMonitor() async {
    try {
      await SystemService.openSystemInformation();
      _showInfoDialog('Reliability Monitor', 'In System Information, go to the Reliability Monitor section.');
    } catch (_) {}
  }

  Future<void> _createRestorePoint() async {
    try {
      await SystemService.openSystemProperties();
      _showInfoDialog('System Restore', 'In System Properties, go to the System Protection tab and click Create.');
    } catch (_) {}
  }

  Future<bool> _showAdminPromptDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Administrator Rights Required'),
        content: Text('This action requires administrator privileges. Would you like to restart the application as administrator?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Restart as Admin'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compactMode ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'System Optimization Suggestions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Spacer(),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Performance', child: Text('Performance')),
                    DropdownMenuItem(value: 'Security', child: Text('Security')),
                    DropdownMenuItem(value: 'Privacy', child: Text('Privacy')),
                    DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                  ],
                  onChanged: _onCategoryChanged,
                  underline: Container(height: 1, color: Colors.grey[300]),
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: widget.compactMode,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.compactMode ? 8.0 : 16.0,
                      vertical: widget.compactMode ? 0.0 : 4.0,
                    ),
                    title: Text(
                      suggestion.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: widget.compactMode ? 13.0 : 14.0,
                      ),
                    ),
                    subtitle: Text(
                      suggestion.description,
                      style: TextStyle(
                        fontSize: widget.compactMode ? 12.0 : 13.0,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _executeAction(suggestion),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.compactMode ? 8.0 : 12.0,
                          vertical: widget.compactMode ? 4.0 : 8.0,
                        ),
                        textStyle: TextStyle(
                          fontSize: widget.compactMode ? 11.0 : 12.0,
                        ),
                      ),
                      child: Text(suggestion.actionText),
                    ),
                    leading: Icon(
                      _getCategoryIcon(suggestion.category),
                      color: _getCategoryColor(suggestion.category),
                      size: widget.compactMode ? 18.0 : 24.0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Performance':
        return Icons.speed;
      case 'Security':
        return Icons.security;
      case 'Privacy':
        return Icons.privacy_tip;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.lightbulb_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Performance':
        return Colors.blue;
      case 'Security':
        return Colors.green;
      case 'Privacy':
        return Colors.purple;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
