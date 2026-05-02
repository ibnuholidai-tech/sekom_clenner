import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/system_status.dart';
import '../../services/system_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_handler.dart';
import '../../widgets/modern/modern_card.dart';
import '../../widgets/modern/modern_pill.dart';
import '../state/status_message_provider.dart';
import '../../widgets/keyboard_test_complete_fixed.dart';
import '../../widgets/sound_test_lr.dart';
import '../../widgets/microphone_test.dart';
import '../../widgets/webcam_test.dart';

/// Modern System Cleaner — the main page shown in the design.
/// Wires browser/folder cleaning, system status checks, and quick tests.
class ModernSystemCleanerScreen extends ConsumerStatefulWidget {
  const ModernSystemCleanerScreen({super.key});

  @override
  ConsumerState<ModernSystemCleanerScreen> createState() =>
      _ModernSystemCleanerScreenState();
}

class _ModernSystemCleanerScreenState
    extends ConsumerState<ModernSystemCleanerScreen> {
  // Browser selection
  bool _chromeSelected = true;
  bool _edgeSelected = true;
  bool _firefoxSelected = true;
  bool _braveSelected = false;
  bool _resetBrowserSelected = true;

  // System folder selection
  final Map<String, bool> _folderSelected = {
    'Downloads': false,
    'Documents': false,
    'Pictures': false,
    'Music': false,
    'Videos': false,
    '3D Objects': false,
  };

  // Other options
  bool _clearRecentSelected = false;
  bool _clearRecycleBinSelected = false;

  // Status
  bool _isChecking = false;
  bool _isCleaning = false;

  // Cached results
  SystemStatus _defenderStatus = SystemStatus(status: 'Memeriksa...');
  SystemStatus _updateStatus = SystemStatus(status: 'Memeriksa...');
  SystemStatus _winActStatus = SystemStatus(status: 'Memeriksa...');
  SystemStatus _officeActStatus = SystemStatus(status: 'Memeriksa...');
  List<FolderInfo> _folderInfos = [];
  Map<String, dynamic> _ramInfo = {};
  List<Map<String, dynamic>> _diskInfo = [];

  void _setStatus(String s) =>
      ref.read(statusMessageProvider.notifier).state = s;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialScan);
  }

  Future<void> _initialScan() async {
    await _checkAll();
  }

  Future<void> _checkAll() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _setStatus('Menjalankan pemeriksaan sistem...');

    try {
      final results = await Future.wait<dynamic>([
        SystemService.checkWindowsDefender().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.checkWindowsUpdate().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.checkWindowsActivationQuick().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.checkOfficeActivationQuick().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.getFolderSizesUltraFast(
          timeout: const Duration(seconds: 6),
        ).catchError((_) => <FolderInfo>[]),
        SystemService.getRamInfo().catchError(
          (_) => <String, dynamic>{},
        ),
        SystemService.getPhysicalDiskInfo().catchError(
          (_) => <Map<String, dynamic>>[],
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _defenderStatus = results[0] as SystemStatus;
        _updateStatus = results[1] as SystemStatus;
        _winActStatus = results[2] as SystemStatus;
        _officeActStatus = results[3] as SystemStatus;
        _folderInfos = results[4] as List<FolderInfo>;
        _ramInfo = results[5] as Map<String, dynamic>;
        _diskInfo = results[6] as List<Map<String, dynamic>>;
      });
      _setStatus('Pemeriksaan selesai.');
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _setStatus('Error: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _selectAll(bool value) {
    setState(() {
      _chromeSelected = value;
      _edgeSelected = value;
      _firefoxSelected = value;
      _braveSelected = value;
      _resetBrowserSelected = value;
      for (final k in _folderSelected.keys) {
        _folderSelected[k] = value;
      }
      _clearRecentSelected = value;
      _clearRecycleBinSelected = value;
    });
  }

  Future<void> _startCleaning() async {
    final anyBrowser = _chromeSelected ||
        _edgeSelected ||
        _firefoxSelected ||
        _braveSelected;
    final anyFolder = _folderSelected.values.any((e) => e);
    if (!anyBrowser &&
        !anyFolder &&
        !_clearRecentSelected &&
        !_clearRecycleBinSelected) {
      _showInfo('Pilih minimal satu opsi untuk dibersihkan.');
      return;
    }

    final confirm = await _confirm(
      'Konfirmasi Pembersihan',
      'Lanjutkan membersihkan item yang dipilih?',
    );
    if (confirm != true) return;

    setState(() => _isCleaning = true);
    _setStatus('Membersihkan...');

    try {
      final tasks = <Future<dynamic>>[];
      if (anyBrowser) {
        tasks.add(
          SystemService.cleanBrowsers(
            chrome: _chromeSelected,
            edge: _edgeSelected,
            firefox: _firefoxSelected,
            resetBrowser: _resetBrowserSelected,
          ),
        );
      }
      if (anyFolder) {
        tasks.add(
          SystemService.cleanSystemFolders(
            documents: _folderSelected['Documents'] ?? false,
            downloads: _folderSelected['Downloads'] ?? false,
            music: _folderSelected['Music'] ?? false,
            pictures: _folderSelected['Pictures'] ?? false,
            videos: _folderSelected['Videos'] ?? false,
            objects3d: _folderSelected['3D Objects'] ?? false,
          ),
        );
      }
      if (_clearRecentSelected) tasks.add(SystemService.clearRecentFiles());
      if (_clearRecycleBinSelected) tasks.add(SystemService.clearRecycleBin());

      await Future.wait(tasks);
      _setStatus('Pembersihan selesai.');
      if (!mounted) return;
      _showInfo('Pembersihan selesai.');
      // Refresh folder sizes after cleaning
      Future.microtask(_initialScan);
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _setStatus('Error: $e');
    } finally {
      if (mounted) setState(() => _isCleaning = false);
    }
  }

  // ---- Helpers ----
  void _showInfo(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
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

  String _totalDetectedSize() {
    final folderTotal = _folderInfos
        .where((f) => _folderSelected[f.name] ?? false)
        .fold<int>(0, (sum, f) => sum + f.sizeBytes);
    return _formatBytes(folderTotal);
  }

  // ---- Open generic test screens ----
  void _openTest(Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => child),
    );
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
          LayoutBuilder(
            builder: (ctx, c) {
              final wide = c.maxWidth >= 980;
              if (!wide) {
                return Column(
                  children: [
                    _buildLeftColumn(),
                    const SizedBox(height: 14),
                    _buildRightColumn(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildLeftColumn()),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: _buildRightColumn()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ModernCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sekom Cleaner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bersihkan, periksa, dan optimalkan PC Anda',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _smallButton(
                icon: Icons.refresh,
                label: _isChecking ? 'Memeriksa...' : 'Scan Ulang',
                onTap: _isChecking ? null : _checkAll,
              ),
              _smallButton(
                icon: Icons.checklist_rounded,
                label: 'Pilih semua',
                onTap: () => _selectAll(true),
              ),
              _primaryButton(
                icon: _isCleaning ? Icons.hourglass_top : Icons.delete_sweep,
                label: _isCleaning ? 'Membersihkan...' : 'Bersihkan',
                onTap: _isCleaning ? null : _startCleaning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  // ---- Left column ----
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCleaningOptionsCard(),
        const SizedBox(height: 14),
        _buildBrowserCard(),
        const SizedBox(height: 14),
        _buildFoldersCard(),
        const SizedBox(height: 14),
        _buildStorageRamCard(),
      ],
    );
  }

  Widget _buildCleaningOptionsCard() {
    return ModernCard(
      child: Row(
        children: [
          const Expanded(
            child: ModernSectionHeader(
              icon: Icons.tune_rounded,
              title: 'Cleaning Options',
              subtitle: 'Pilih browser dan folder yang ingin dibersihkan',
            ),
          ),
          ModernBadge(
            text: 'Data terdeteksi  ${_totalDetectedSize()}',
            background: AppTheme.pillBlue,
            foreground: AppTheme.pillBlueText,
            icon: Icons.data_usage,
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModernSectionHeader(
            icon: Icons.travel_explore,
            title: 'Browser Cleanup',
            subtitle: 'Cache, cookies, history, downloads',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernSelectablePill(
                icon: Icons.public,
                label: 'Chrome',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                selected: _chromeSelected,
                onTap: () =>
                    setState(() => _chromeSelected = !_chromeSelected),
              ),
              ModernSelectablePill(
                icon: Icons.web,
                label: 'Edge',
                tint: AppTheme.pillTeal,
                tintText: AppTheme.pillTealText,
                selected: _edgeSelected,
                onTap: () => setState(() => _edgeSelected = !_edgeSelected),
              ),
              ModernSelectablePill(
                icon: Icons.local_fire_department,
                label: 'Firefox',
                tint: AppTheme.pillAmber,
                tintText: AppTheme.pillAmberText,
                selected: _firefoxSelected,
                onTap: () =>
                    setState(() => _firefoxSelected = !_firefoxSelected),
              ),
              ModernSelectablePill(
                icon: Icons.shield_moon_outlined,
                label: 'Brave',
                tint: AppTheme.pillPink,
                tintText: AppTheme.pillPinkText,
                selected: _braveSelected,
                onTap: () => setState(() => _braveSelected = !_braveSelected),
              ),
              ModernSelectablePill(
                icon: Icons.restart_alt,
                label: 'Reset Browser',
                tint: AppTheme.pillPurple,
                tintText: AppTheme.pillPurpleText,
                selected: _resetBrowserSelected,
                onTap: () => setState(
                  () => _resetBrowserSelected = !_resetBrowserSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersCard() {
    final folderIcons = <String, IconData>{
      'Downloads': Icons.download_outlined,
      'Documents': Icons.description_outlined,
      'Pictures': Icons.image_outlined,
      'Music': Icons.music_note_outlined,
      'Videos': Icons.movie_outlined,
      '3D Objects': Icons.view_in_ar_outlined,
    };
    final tints = <List<Color>>[
      [AppTheme.pillBlue, AppTheme.pillBlueText],
      [AppTheme.pillGreen, AppTheme.pillGreenText],
      [AppTheme.pillPink, AppTheme.pillPinkText],
      [AppTheme.pillPurple, AppTheme.pillPurpleText],
      [AppTheme.pillTeal, AppTheme.pillTealText],
      [AppTheme.pillAmber, AppTheme.pillAmberText],
    ];

    final infoMap = {for (final f in _folderInfos) f.name: f};
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModernSectionHeader(
            icon: Icons.folder_open,
            title: 'System Folders',
            subtitle: 'Bersihkan isi folder pengguna terpilih',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _folderSelected.length; i++)
                ModernSelectablePill(
                  icon: folderIcons[_folderSelected.keys.elementAt(i)] ??
                      Icons.folder,
                  label: _folderSelected.keys.elementAt(i),
                  trailingText: infoMap[_folderSelected.keys.elementAt(i)]
                      ?.size,
                  tint: tints[i % tints.length][0],
                  tintText: tints[i % tints.length][1],
                  selected:
                      _folderSelected[_folderSelected.keys.elementAt(i)] ??
                          false,
                  onTap: () => setState(() {
                    final k = _folderSelected.keys.elementAt(i);
                    _folderSelected[k] = !(_folderSelected[k] ?? false);
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRamCard() {
    final ramTotalGb = _formatBytes(
      ((_ramInfo['totalMemoryBytes'] as num?)?.toInt() ?? 0),
    );
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModernSectionHeader(
            icon: Icons.storage_rounded,
            title: 'Storage & RAM Info',
            subtitle: 'Ringkasan disk fisik dan kapasitas RAM',
          ),
          const SizedBox(height: 12),
          if (_diskInfo.isEmpty && _ramInfo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Memuat info perangkat keras...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final disk in _diskInfo) _diskTile(disk),
                _ramTile(ramTotalGb),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _diskTile(Map<String, dynamic> disk) {
    final name = (disk['model'] ?? disk['friendlyName'] ?? 'Disk').toString();
    final type = (disk['mediaType'] ?? disk['type'] ?? '').toString();
    final size = (disk['sizeFormatted'] ??
            disk['size']?.toString() ??
            disk['capacity']?.toString() ??
            '')
        .toString();
    final health = (disk['healthStatus'] ?? '').toString();
    final temp = (disk['temperature'] ?? '').toString();
    final isSsd = type.toLowerCase().contains('ssd');
    final ok = health.toLowerCase().contains('ok') ||
        health.toLowerCase().contains('healthy') ||
        health.isEmpty;
    return Container(
      width: 270,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pillBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSsd ? Icons.bolt : Icons.album,
                size: 16,
                color: AppTheme.pillBlueText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.pillBlueText,
                  ),
                ),
              ),
              ModernBadge(
                text: ok ? 'Sehat' : 'Periksa',
                background: ok ? AppTheme.pillGreen : AppTheme.pillRed,
                foreground: ok ? AppTheme.pillGreenText : AppTheme.pillRedText,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tipe: ${type.isEmpty ? "-" : type} • $size',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          if (temp.isNotEmpty)
            Text(
              'Suhu: $temp',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ramTile(String ramTotal) {
    final ramGb = ((_ramInfo['totalMemoryBytes'] as num?)?.toDouble() ?? 0) /
        (1024 * 1024 * 1024);
    final warn = ramGb < 8;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn ? AppTheme.pillRed : AppTheme.pillGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                size: 16,
                color: warn ? AppTheme.pillRedText : AppTheme.pillGreenText,
              ),
              const SizedBox(width: 6),
              Text(
                'RAM Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: warn ? AppTheme.pillRedText : AppTheme.pillGreenText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ramTotal.isEmpty ? '—' : ramTotal,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: warn ? AppTheme.pillRedText : AppTheme.pillGreenText,
            ),
          ),
          Text(
            warn ? 'RAM rendah, pertimbangkan upgrade' : 'Kapasitas memadai',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Right column ----
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSecurityCard(),
        const SizedBox(height: 14),
        _buildRecentCard(),
        const SizedBox(height: 14),
        _buildQuickTestCard(),
      ],
    );
  }

  Widget _buildSecurityCard() {
    Widget statusRow({
      required IconData icon,
      required Color iconColor,
      required Color iconBg,
      required String title,
      required SystemStatus status,
      Widget? action,
    }) {
      final isActive = status.isActive;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    status.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ModernBadge(
              text: isActive ? 'Aktif' : 'Periksa',
              background: isActive ? AppTheme.pillGreen : AppTheme.pillAmber,
              foreground:
                  isActive ? AppTheme.pillGreenText : AppTheme.pillAmberText,
            ),
            if (action != null) ...[const SizedBox(width: 6), action],
          ],
        ),
      );
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.shield_outlined,
            title: 'Keamanan & Aktivasi',
            subtitle: 'Status Defender, Update, dan aktivasi',
          ),
          const SizedBox(height: 6),
          statusRow(
            icon: Icons.shield_rounded,
            iconColor: AppTheme.pillGreenText,
            iconBg: AppTheme.pillGreen,
            title: 'Windows Defender',
            status: _defenderStatus,
          ),
          const Divider(),
          statusRow(
            icon: Icons.system_update_alt,
            iconColor: AppTheme.pillBlueText,
            iconBg: AppTheme.pillBlue,
            title: 'Windows Update',
            status: _updateStatus,
            action: TextButton(
              onPressed: () => SystemService.openWindowsUpdateSettings(),
              child: const Text('Buka', style: TextStyle(fontSize: 11)),
            ),
          ),
          const Divider(),
          statusRow(
            icon: Icons.workspace_premium,
            iconColor: AppTheme.pillPurpleText,
            iconBg: AppTheme.pillPurple,
            title: 'Aktivasi Windows',
            status: _winActStatus,
            action: TextButton(
              onPressed: () async {
                final ok = await SystemService.openActivationPowerShell();
                _setStatus(
                  ok ? 'PowerShell Aktivasi dibuka' : 'Gagal membuka PowerShell',
                );
              },
              child: const Text('Aktivasi', style: TextStyle(fontSize: 11)),
            ),
          ),
          const Divider(),
          statusRow(
            icon: Icons.business_center_outlined,
            iconColor: AppTheme.pillTealText,
            iconBg: AppTheme.pillTeal,
            title: 'Aktivasi Office',
            status: _officeActStatus,
            action: TextButton(
              onPressed: () async {
                final ok = await SystemService.openActivationPowerShell();
                _setStatus(
                  ok ? 'PowerShell Aktivasi dibuka' : 'Gagal membuka PowerShell',
                );
              },
              child: const Text('Aktivasi', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.history,
            title: 'Recent & Recycle Bin',
            subtitle: 'Hapus item yang baru dibuka & isi tempat sampah',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernSelectablePill(
                icon: Icons.history_toggle_off,
                label: 'Hapus Recent',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                selected: _clearRecentSelected,
                onTap: () => setState(
                  () => _clearRecentSelected = !_clearRecentSelected,
                ),
              ),
              ModernSelectablePill(
                icon: Icons.delete_outline,
                label: 'Kosongkan Bin',
                tint: AppTheme.pillRed,
                tintText: AppTheme.pillRedText,
                selected: _clearRecycleBinSelected,
                onTap: () => setState(
                  () => _clearRecycleBinSelected = !_clearRecycleBinSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModernSectionHeader(
            icon: Icons.science_outlined,
            title: 'Tes Cepat',
            subtitle: 'Tes hardware tanpa pindah halaman',
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ModernActionPill(
                icon: Icons.volume_up,
                label: 'Test Sound',
                tint: AppTheme.pillBlue,
                tintText: AppTheme.pillBlueText,
                onTap: () => _openTest(const SoundTestLR()),
              ),
              ModernActionPill(
                icon: Icons.keyboard_alt_outlined,
                label: 'Test Keyboard',
                tint: AppTheme.pillGreen,
                tintText: AppTheme.pillGreenText,
                onTap: () => _openTest(const KeyboardTestCompleteFixed()),
              ),
              ModernActionPill(
                icon: Icons.mic_none_outlined,
                label: 'Test Mic',
                tint: AppTheme.pillPurple,
                tintText: AppTheme.pillPurpleText,
                onTap: () => _openTest(const MicrophoneTest()),
              ),
              ModernActionPill(
                icon: Icons.videocam_outlined,
                label: 'Test Kamera',
                tint: AppTheme.pillPink,
                tintText: AppTheme.pillPinkText,
                onTap: () => _openTest(const WebcamTest()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
