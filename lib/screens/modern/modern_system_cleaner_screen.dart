import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/system_status.dart';
import '../../services/cleaning_history_service.dart';
import '../../services/system_service.dart';
import '../../state/cleaning_history_provider.dart';
import '../../state/cleaning_preset_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/error_handler.dart';
import '../../widgets/modern/cleaning_history_dialog.dart';
import '../../widgets/modern/modern_card.dart';
import '../../widgets/modern/modern_pill.dart';
import '../state/status_message_provider.dart';
import '../../widgets/keyboard_test_complete_fixed.dart';
import '../../widgets/sound_test_lr.dart';
import '../../widgets/microphone_test.dart';
import '../../widgets/webcam_test.dart';

/// Modern System Cleaner — designed to mirror the reference screenshot.
///
/// Layout:
/// - Top header card: mascot + title/version + inline quick-test pills +
///   Riwayat / Scan Ulang / Pilih semua / Bersihkan actions on the right.
/// - Two columns when wide (>= 980px):
///   * Left:  Cleaning Options card (Browser pills + Folder pills + preset
///            row) + Storage & RAM card (RAM tile + per-disk tiles, only
///            tinted when there is a problem).
///   * Right: Battery Health card + Security/Activation rows +
///            Recent apps card + 2x2 hardware quick-test grid + a
///            Kosongkan Bin / Fast Startup pill row.
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
  bool _fastStartupSelected = false;

  // Status flags
  bool _isChecking = false;
  bool _isCleaning = false;

  // Cached results
  SystemStatus _defenderStatus = SystemStatus(status: 'Memeriksa...');
  SystemStatus _winActStatus = SystemStatus(status: 'Memeriksa...');
  SystemStatus _officeActStatus = SystemStatus(status: 'Memeriksa...');
  List<FolderInfo> _folderInfos = [];
  Map<String, dynamic> _ramInfo = {};
  List<Map<String, dynamic>> _diskInfo = [];
  BatteryStatus _batteryStatus = BatteryStatus();

  void _setStatus(String s) =>
      ref.read(statusMessageProvider.notifier).state = s;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _applyCurrentPresetIfNotCustom();
      await _initialScan();
    });
  }

  void _applyCurrentPresetIfNotCustom() {
    final preset = ref.read(cleaningPresetProvider);
    if (preset == CleaningPreset.custom) return;
    _applyPreset(preset, persist: false);
  }

  void _applyPreset(CleaningPreset preset, {bool persist = true}) {
    final selection = CleaningSelection.forPreset(preset);
    setState(() {
      _chromeSelected = selection.chrome;
      _edgeSelected = selection.edge;
      _firefoxSelected = selection.firefox;
      _braveSelected = selection.brave;
      _resetBrowserSelected = selection.resetBrowser;
      for (final key in _folderSelected.keys) {
        _folderSelected[key] = selection.folders[key] ?? false;
      }
      _clearRecentSelected = selection.clearRecent;
      _clearRecycleBinSelected = selection.clearRecycleBin;
    });
    if (persist) {
      ref.read(cleaningPresetProvider.notifier).set(preset);
    }
    _setStatus('Preset diterapkan: ${preset.label}.');
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
        SystemService.checkWindowsActivationQuick().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.checkOfficeActivationQuick().catchError(
          (_) => SystemStatus(status: 'Error', isActive: false),
        ),
        SystemService.getFolderSizesUltraFast(
          timeout: const Duration(seconds: 6),
        ).catchError((_) => <FolderInfo>[]),
        SystemService.getRamInfo().catchError((_) => <String, dynamic>{}),
        SystemService.getPhysicalDiskInfo().catchError(
          (_) => <Map<String, dynamic>>[],
        ),
        SystemService.getBatteryStatus().catchError(
          (_) => BatteryStatus(),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _defenderStatus = results[0] as SystemStatus;
        _winActStatus = results[1] as SystemStatus;
        _officeActStatus = results[2] as SystemStatus;
        _folderInfos = results[3] as List<FolderInfo>;
        _ramInfo = results[4] as Map<String, dynamic>;
        _diskInfo = results[5] as List<Map<String, dynamic>>;
        _batteryStatus = results[6] as BatteryStatus;
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

  bool get _isAllSelected =>
      _chromeSelected &&
      _edgeSelected &&
      _firefoxSelected &&
      _braveSelected &&
      _resetBrowserSelected &&
      _folderSelected.values.every((v) => v) &&
      _clearRecentSelected &&
      _clearRecycleBinSelected;

  Future<void> _startCleaning() async {
    // NOTE: Brave is included in the "anyBrowser" check because the user can
    // select the Brave pill, but SystemService.cleanBrowsers does not yet
    // accept a brave parameter — Brave-specific cleanup is a backend TODO.
    final anyBrowser =
        _chromeSelected || _edgeSelected || _firefoxSelected || _braveSelected;
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

    final start = DateTime.now();
    final actions = <String>[];
    final detectedSize = _selectedFolderTotalBytes();
    try {
      final tasks = <Future<dynamic>>[];
      // Skip the Chromium-family clean call entirely if the only selected
      // browser is Brave — cleanBrowsers does not yet support Brave so it
      // would record a no-op cleaning to history.
      final chromiumBrowsersSelected =
          _chromeSelected || _edgeSelected || _firefoxSelected;
      if (chromiumBrowsersSelected) {
        actions.add('Browser');
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
        actions.add('Folder pengguna');
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
      if (_clearRecentSelected) {
        actions.add('Recent');
        tasks.add(SystemService.clearRecentFiles());
      }
      if (_clearRecycleBinSelected) {
        actions.add('Recycle Bin');
        tasks.add(SystemService.clearRecycleBin());
      }

      await Future.wait(tasks);
      _setStatus('Pembersihan selesai.');
      await ref
          .read(cleaningHistoryProvider.notifier)
          .append(
            CleaningRecord(
              timestamp: start,
              duration: DateTime.now().difference(start),
              detectedSizeBytes: detectedSize,
              items: actions,
              preset: ref.read(cleaningPresetProvider).name,
            ),
          );
      if (!mounted) return;
      if (_braveSelected && !chromiumBrowsersSelected) {
        _showInfo(
            'Brave terpilih, tetapi backend belum mendukung — tidak ada yang dibersihkan.');
      } else {
        _showInfo('Pembersihan selesai.');
      }
      Future.microtask(_initialScan);
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _setStatus('Error: $e');
    } finally {
      if (mounted) setState(() => _isCleaning = false);
    }
  }

  int _selectedFolderTotalBytes() {
    return _folderInfos
        .where((f) => _folderSelected[f.name] ?? false)
        .fold<int>(0, (sum, f) => sum + f.sizeBytes);
  }

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

  void _openTest(Widget child) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final wide = c.maxWidth >= 980;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                _buildLeftColumn(),
                const SizedBox(height: 14),
                _buildRightColumn(),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildLeftColumn()),
                  const SizedBox(width: 14),
                  Expanded(flex: 5, child: _buildRightColumn()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    final palette = context.appColors;
    return ModernCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: LayoutBuilder(
        builder: (ctx, c) {
          final wide = c.maxWidth >= 760;
          final titleBlock = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD33C), Color(0xFFFFB020)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sekom Cleaner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v1.1.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );

          final quickTests = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniRadioPill(
                label: 'Test Sound',
                onTap: () => _openTest(const SoundTestLR()),
              ),
              _miniRadioPill(
                label: 'Test Keyboard',
                onTap: () => _openTest(const KeyboardTestCompleteFixed()),
              ),
              _miniRadioPill(
                label: 'Test Mic',
                onTap: () => _openTest(const MicrophoneTest()),
              ),
              _miniRadioPill(label: 'Bersihkan', onTap: _startCleaning),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => CleaningHistoryDialog.show(context),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Riwayat'),
              ),
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkAll,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(_isChecking ? 'Memeriksa...' : 'Scan Ulang'),
              ),
              _selectAllChip(),
              ElevatedButton.icon(
                onPressed: _isCleaning ? null : _startCleaning,
                icon: Icon(
                  _isCleaning ? Icons.hourglass_top : Icons.delete_sweep,
                  size: 16,
                ),
                label: Text(_isCleaning ? 'Membersihkan...' : 'Bersihkan'),
              ),
            ],
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                titleBlock,
                const SizedBox(width: 16),
                Expanded(child: quickTests),
                const SizedBox(width: 12),
                actions,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              quickTests,
              const SizedBox(height: 10),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _miniRadioPill({
    required String label,
    required VoidCallback onTap,
  }) {
    final palette = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            border: Border.all(color: palette.cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.cardBorder, width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectAllChip() {
    final palette = context.appColors;
    final all = _isAllSelected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectAll(!all),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            border: Border.all(color: palette.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: all ? AppTheme.primary : palette.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: all ? AppTheme.primary : palette.cardBorder,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: all
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Pilih semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- LEFT COLUMN ----------
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCleaningOptionsCard(),
        const SizedBox(height: 14),
        _buildStorageRamCard(),
      ],
    );
  }

  Widget _buildCleaningOptionsCard() {
    final palette = context.appColors;
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.cleaning_services_outlined,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cleaning Options',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pilih browser dan folder yang ingin dibersihkan',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ModernBadge.tone(
                tone: PillTone.primary,
                text: 'Data terdeteksi  ${_totalDetectedSize()}',
                icon: Icons.dataset_linked_outlined,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.cleaning_services,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Browser Cleanup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ModernSelectablePill(
                icon: Icons.public,
                label: 'Chrome',
                selected: _chromeSelected,
                onTap: () =>
                    setState(() => _chromeSelected = !_chromeSelected),
              ),
              ModernSelectablePill(
                icon: Icons.web,
                label: 'Edge',
                selected: _edgeSelected,
                onTap: () => setState(() => _edgeSelected = !_edgeSelected),
              ),
              ModernSelectablePill(
                icon: Icons.local_fire_department,
                label: 'Firefox',
                selected: _firefoxSelected,
                onTap: () =>
                    setState(() => _firefoxSelected = !_firefoxSelected),
              ),
              ModernSelectablePill(
                icon: Icons.shield_moon_outlined,
                label: 'Brave',
                selected: _braveSelected,
                onTap: () =>
                    setState(() => _braveSelected = !_braveSelected),
              ),
              ModernSelectablePill(
                icon: Icons.restart_alt,
                label: 'Reset Browser',
                selected: _resetBrowserSelected,
                onTap: () => setState(
                  () => _resetBrowserSelected = !_resetBrowserSelected,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'System Folders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              _selectAllChip(),
            ],
          ),
          const SizedBox(height: 10),
          _buildFolderPills(),

          const SizedBox(height: 14),
          _presetRow(),
        ],
      ),
    );
  }

  Widget _presetRow() {
    final current = ref.watch(cleaningPresetProvider);
    final palette = context.appColors;
    Widget chip(CleaningPreset preset) {
      final selected = current == preset;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyPreset(preset),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.10)
                  : palette.cardBackground,
              border: Border.all(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.32)
                    : palette.cardBorder,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              preset.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primaryDark : palette.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(
          'Preset:',
          style: TextStyle(
            fontSize: 11,
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip(CleaningPreset.light),
              chip(CleaningPreset.standard),
              chip(CleaningPreset.deep),
              chip(CleaningPreset.custom),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderPills() {
    final folderIcons = <String, IconData>{
      'Downloads': Icons.download_outlined,
      'Documents': Icons.description_outlined,
      'Pictures': Icons.image_outlined,
      'Music': Icons.music_note_outlined,
      'Videos': Icons.movie_outlined,
      '3D Objects': Icons.view_in_ar_outlined,
    };
    final infoMap = {for (final f in _folderInfos) f.name: f};

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final name in _folderSelected.keys)
          ModernSelectablePill(
            icon: folderIcons[name] ?? Icons.folder,
            label: name,
            trailingText: infoMap[name]?.size ?? 'Not found',
            selected: _folderSelected[name] ?? false,
            onTap: () => setState(() {
              _folderSelected[name] = !(_folderSelected[name] ?? false);
            }),
          ),
      ],
    );
  }

  Widget _buildStorageRamCard() {
    final palette = context.appColors;
    final ramTotalGb = _formatBytes(
      ((_ramInfo['totalMemoryBytes'] as num?)?.toInt() ?? 0),
    );
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage & RAM Info',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pantau kapasitas dan kesehatan perangkat.',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isChecking ? null : _checkAll,
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_diskInfo.isEmpty && _ramInfo.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Memuat info perangkat keras...',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            _ramTile(ramTotalGb),
            for (final disk in _diskInfo) ...[
              const SizedBox(height: 10),
              _diskTile(disk),
            ],
          ],
        ],
      ),
    );
  }

  Widget _ramTile(String ramTotal) {
    final palette = context.appColors;
    final ramGb =
        ((_ramInfo['totalMemoryBytes'] as num?)?.toDouble() ?? 0) /
        (1024 * 1024 * 1024);
    final warn = ramGb > 0 && ramGb < 8;

    final bg = warn
        ? AppTheme.danger.withValues(alpha: 0.10)
        : palette.cardBackground;
    final borderColor = warn
        ? AppTheme.danger.withValues(alpha: 0.30)
        : palette.cardBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warn
                  ? AppTheme.danger.withValues(alpha: 0.18)
                  : AppTheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.memory_rounded,
              size: 20,
              color: warn ? AppTheme.danger : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAM Total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ramTotal.startsWith('0 ') ? '—' : ramTotal,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (warn)
            const ModernBadge.tone(
              tone: PillTone.danger,
              text: 'RAM rendah',
              icon: Icons.warning_amber_rounded,
            ),
        ],
      ),
    );
  }

  Widget _diskTile(Map<String, dynamic> disk) {
    final palette = context.appColors;
    final name = (disk['model'] ?? disk['friendlyName'] ?? 'Disk').toString();
    final type = (disk['mediaType'] ?? disk['type'] ?? '').toString();
    final size =
        (disk['sizeFormatted'] ??
                disk['size']?.toString() ??
                disk['capacity']?.toString() ??
                '')
            .toString();
    final health = (disk['healthStatus'] ?? '').toString();
    final temp = (disk['temperature'] ?? '').toString();
    final isSsd = type.toLowerCase().contains('ssd');
    final ok =
        health.toLowerCase().contains('ok') ||
        health.toLowerCase().contains('healthy') ||
        health.isEmpty;

    final bg = ok
        ? palette.cardBackground
        : AppTheme.danger.withValues(alpha: 0.10);
    final borderColor = ok
        ? palette.cardBorder
        : AppTheme.danger.withValues(alpha: 0.30);
    final iconBubbleBg = ok
        ? AppTheme.primary.withValues(alpha: 0.18)
        : AppTheme.danger.withValues(alpha: 0.18);
    final iconColor = ok ? AppTheme.primary : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBubbleBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSsd ? Icons.bolt : Icons.album,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSsd ? 'SSD' : 'Disk',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ModernBadge.tone(
                tone: ok ? PillTone.success : PillTone.danger,
                text: ok ? 'Bagus' : 'Periksa',
                icon: ok
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.sd_storage_outlined,
                  size: 14, color: palette.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Capacity ${size.isEmpty ? "-" : size}',
                style:
                    TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              if (temp.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.device_thermostat_outlined,
                    size: 14, color: palette.textSecondary),
                const SizedBox(width: 4),
                Text(
                  temp,
                  style:
                      TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 6,
              backgroundColor: palette.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                ok ? AppTheme.success : AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- RIGHT COLUMN ----------
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBatteryCard(),
        const SizedBox(height: 14),
        _buildSecurityCard(),
        const SizedBox(height: 14),
        _buildRecentCard(),
        const SizedBox(height: 14),
        _buildQuickTestGrid(),
      ],
    );
  }

  Widget _buildBatteryCard() {
    final palette = context.appColors;
    final hasBattery = _batteryStatus.isPresent;
    final percentStr =
        hasBattery ? '${_batteryStatus.chargeLevel}%' : '—';
    final cond = _batteryStatus.healthStatus.isEmpty
        ? 'Unknown'
        : _batteryStatus.healthStatus;

    return ModernCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.battery_charging_full_rounded,
              color: AppTheme.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Battery Health',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      hasBattery ? percentStr : 'Tidak ada baterai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (hasBattery) ...[
                      Text(
                        '  •  ',
                        style: TextStyle(
                            fontSize: 12, color: palette.textMuted),
                      ),
                      Text(
                        cond,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isChecking ? null : _checkAll,
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusBlock(
            title: 'Windows Defender',
            detail: _defenderStatus.status.isEmpty
                ? 'Memeriksa...'
                : _defenderStatus.status,
            isActive: _defenderStatus.isActive,
            trailing: TextButton(
              onPressed: () => SystemService.openWindowsUpdateSettings(),
              child:
                  const Text('Buka Security', style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(height: 12),
          _statusBlock(
            title: 'Windows Activation',
            detail: _winActStatus.status.isEmpty
                ? 'Memeriksa...'
                : _winActStatus.status,
            isActive: _winActStatus.isActive,
            trailing: TextButton(
              onPressed: () async {
                final ok = await SystemService.openActivationPowerShell();
                _setStatus(ok
                    ? 'PowerShell Aktivasi dibuka'
                    : 'Gagal membuka PowerShell');
              },
              child: const Text('Shell', style: TextStyle(fontSize: 11)),
            ),
          ),
          const SizedBox(height: 12),
          _statusBlock(
            title: 'Office Activation',
            detail: _officeActStatus.status.isEmpty
                ? 'Memeriksa...'
                : _officeActStatus.status,
            isActive: _officeActStatus.isActive,
            trailing: ElevatedButton(
              onPressed: () async {
                final ok = await SystemService.openActivationPowerShell();
                _setStatus(ok
                    ? 'PowerShell Aktivasi dibuka'
                    : 'Gagal membuka PowerShell');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: const Text('Activate'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBlock({
    required String title,
    required String detail,
    required bool isActive,
    Widget? trailing,
  }) {
    final palette = context.appColors;
    final accent = isActive ? AppTheme.success : AppTheme.danger;
    final fgText =
        isActive ? AppTheme.pillGreenText : AppTheme.pillRedText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard() {
    final palette = context.appColors;
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Semua Aplikasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ModernSelectablePill(
            icon: Icons.history,
            label: 'Hapus Recent Semua Aplikasi',
            trailingText: 'Jump List, Recent, Search',
            selected: _clearRecentSelected,
            onTap: () => setState(
              () => _clearRecentSelected = !_clearRecentSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _quickTestPill(
              icon: Icons.volume_up_rounded,
              label: 'Test Sound',
              tone: PillTone.primary,
              onTap: () => _openTest(const SoundTestLR()),
            ),
            _quickTestPill(
              icon: Icons.keyboard_alt_rounded,
              label: 'Test Keyboard',
              tone: PillTone.success,
              onTap: () => _openTest(const KeyboardTestCompleteFixed()),
            ),
            _quickTestPill(
              icon: Icons.photo_camera_outlined,
              label: 'Test Kamera',
              tone: PillTone.primary,
              onTap: () => _openTest(const WebcamTest()),
            ),
            _quickTestPill(
              icon: Icons.mic_rounded,
              label: 'Test Mic',
              tone: PillTone.success,
              onTap: () => _openTest(const MicrophoneTest()),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ModernSelectablePill(
                icon: Icons.delete_outline,
                label: 'Kosongkan Bin',
                selected: _clearRecycleBinSelected,
                onTap: () => setState(
                  () => _clearRecycleBinSelected = !_clearRecycleBinSelected,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ModernSelectablePill(
                icon: Icons.flash_on_outlined,
                label: 'Fast Startup',
                selected: _fastStartupSelected,
                onTap: () => setState(
                  () => _fastStartupSelected = !_fastStartupSelected,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickTestPill({
    required IconData icon,
    required String label,
    required PillTone tone,
    required VoidCallback onTap,
  }) {
    final accent =
        tone == PillTone.success ? AppTheme.success : AppTheme.primary;
    final bg = accent.withValues(alpha: 0.12);
    final borderColor = accent.withValues(alpha: 0.30);
    final fg = tone == PillTone.success
        ? AppTheme.pillGreenText
        : AppTheme.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
