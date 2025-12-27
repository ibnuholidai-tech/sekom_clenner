import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/default_app.dart';
import '../services/system_service.dart';
import '../utils/app_preferences.dart';

class DefaultAppsSection extends StatefulWidget {
  const DefaultAppsSection({super.key});

  @override
  State<DefaultAppsSection> createState() => _DefaultAppsSectionState();
}

class _DefaultAppsSectionState extends State<DefaultAppsSection> {
  List<DefaultApp> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await SystemService.checkDefaultApps();
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      print('Error loading default apps: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  DefaultApp? get _firstMissingApp {
    try {
      return _apps.firstWhere((app) => !app.isInstalled && app.isRequired);
    } catch (e) {
      return null;
    }
  }

  int get _missingCount {
    return _apps.where((app) => !app.isInstalled && app.isRequired).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingCard();
    }

    final firstMissing = _firstMissingApp;
    final isAllInstalled = firstMissing == null;

    return _buildMainCard(isAllInstalled, firstMissing);
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isAllInstalled, DefaultApp? firstMissing) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isAllInstalled
              ? LinearGradient(
                  colors: [
                    Color(0xFF10B981).withOpacity(0.1),
                    Color(0xFF059669).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Color(0xFFF59E0B).withOpacity(0.1),
                    Color(0xFFEF4444).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: isAllInstalled
                ? Color(0xFF10B981).withOpacity(0.2)
                : Color(0xFFF59E0B).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: firstMissing != null
                ? () => _installApp(firstMissing)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  _buildStatusIcon(isAllInstalled),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextContent(isAllInstalled, firstMissing),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isAllInstalled) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: isAllInstalled
            ? LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isAllInstalled
                ? Color(0xFF10B981).withOpacity(0.3)
                : Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        isAllInstalled
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildTextContent(bool isAllInstalled, DefaultApp? firstMissing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          firstMissing != null
              ? firstMissing.displayName
              : 'All Essential Apps',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAllInstalled
                    ? Color(0xFF10B981).withOpacity(0.15)
                    : Color(0xFFF59E0B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    firstMissing != null
                        ? Icons.download_rounded
                        : Icons.verified_rounded,
                    size: 14,
                    color: isAllInstalled
                        ? Color(0xFF059669)
                        : Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    firstMissing != null ? 'Click to install' : 'All installed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAllInstalled
                          ? Color(0xFF059669)
                          : Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            if (firstMissing != null && _missingCount > 1) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${_missingCount - 1} more',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.refresh_rounded,
          onPressed: _loadApps,
          tooltip: 'Refresh status',
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.settings_rounded,
          onPressed: _showSettings,
          tooltip: 'Configure apps',
          color: Colors.grey.shade700,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
        tooltip: tooltip,
        color: color,
        splashRadius: 20,
      ),
    );
  }

  Future<void> _installApp(DefaultApp app) async {
    try {
      if (app.installerPath == null || app.installerPath!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installer path not configured for ${app.displayName}',
            ),
            action: SnackBarAction(
              label: 'Configure',
              onPressed: _showSettings,
            ),
          ),
        );
        return;
      }

      await SystemService.launchInstaller(app.installerPath);

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '🚀 Launching ${app.displayName} installer...',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      Future.delayed(const Duration(seconds: 3), _loadApps);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) =>
          _DefaultAppsSettingsDialog(apps: _apps, onSave: _loadApps),
    );
  }
}

// Settings Dialog (80% x 85%)
class _DefaultAppsSettingsDialog extends StatefulWidget {
  final List<DefaultApp> apps;
  final VoidCallback onSave;

  const _DefaultAppsSettingsDialog({required this.apps, required this.onSave});

  @override
  State<_DefaultAppsSettingsDialog> createState() =>
      _DefaultAppsSettingsDialogState();
}

class _DefaultAppsSettingsDialogState
    extends State<_DefaultAppsSettingsDialog> {
  late Map<String, String?> _paths;
  late Map<String, bool> _requiredStatus;

  @override
  void initState() {
    super.initState();
    _paths = {for (var app in widget.apps) app.id: app.installerPath};
    _requiredStatus = {for (var app in widget.apps) app.id: app.isRequired};
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: widget.apps
                      .map((app) => _buildAppRow(app))
                      .toList(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.tune_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure installer paths and requirements',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppRow(DefaultApp app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: app.isInstalled
                      ? Color(0xFF10B981).withOpacity(0.1)
                      : Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  app.isInstalled
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: app.isInstalled
                      ? Color(0xFF10B981)
                      : Color(0xFFEF4444),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Icon(app.iconData, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  app.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              _buildRequiredToggle(app),
            ],
          ),
          const SizedBox(height: 8),
          _buildInstallerPathSection(app),
        ],
      ),
    );
  }

  Widget _buildRequiredToggle(DefaultApp app) {
    final isRequired = _requiredStatus[app.id] ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRequired
            ? Color(0xFF10B981).withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRequired
              ? Color(0xFF10B981).withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRequired ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: isRequired ? Color(0xFF059669) : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            'Required',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isRequired ? Color(0xFF059669) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isRequired,
              onChanged: (value) {
                setState(() {
                  _requiredStatus[app.id] = value;
                });
              },
              activeColor: Color(0xFF10B981),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallerPathSection(DefaultApp app) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _paths[app.id] ?? 'No installer path set',
              style: TextStyle(
                fontSize: 11,
                color: _paths[app.id] != null
                    ? Colors.grey.shade700
                    : Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: () => _browsePath(app.id),
            icon: Icon(Icons.upload_file_rounded, size: 14),
            label: Text('Browse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _browsePath(String appId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe', 'msi'],
        dialogTitle: 'Select Installer',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _paths[appId] = result.files.single.path;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _save() async {
    try {
      for (var entry in _paths.entries) {
        if (entry.value != null && entry.value!.isNotEmpty) {
          await AppPreferences.saveInstallerPath(entry.key, entry.value!);
        }
      }
      for (var entry in _requiredStatus.entries) {
        await AppPreferences.saveAppRequiredStatus(entry.key, entry.value);
      }
      widget.onSave();
      if (!mounted) return;
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: '✅ Settings saved successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }
}
