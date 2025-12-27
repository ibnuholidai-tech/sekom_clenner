import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/system_status.dart';

import '../services/system_service.dart';

import '../widgets/combined_cleaning_section.dart';

import '../widgets/windows_system_section.dart';

import '../widgets/system_suggestions_section.dart';

import '../widgets/storage_ram_info_section.dart';

import '../widgets/quick_actions_section.dart';

import 'uninstaller_screen.dart';

import 'battery_screen.dart';

import 'testing_screen.dart';

import '../utils/error_handler.dart';

import 'state/status_message_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Browser selection states

  bool _chromeSelected = true;

  bool _edgeSelected = true;

  bool _firefoxSelected = true;

  bool _resetBrowserSelected = true;

  bool _selectAllBrowsers = true;

  // System folders selection states

  bool _objects3dSelected = false;

  bool _documentsSelected = false;

  bool _downloadsSelected = false;

  bool _musicSelected = false;

  bool _picturesSelected = false;

  bool _videosSelected = false;

  bool _selectAllFolders = false;

  // Windows system states

  bool _clearRecentSelected = false;

  bool _clearRecycleBinSelected = false;

  bool _isChecking = false;

  bool _isCleaning = false;

  bool _skipActivationOnCheckAll = false;

  bool _windowsUpdatePaused = false;

  // Compact layout toggle for System Cleaner tab - enabled by default

  final bool _compactMode = true;

  // System status

  SystemStatus _defenderStatus = SystemStatus(status: "Checking...");

  SystemStatus _updateStatus = SystemStatus(status: "Checking...");

  SystemStatus _driverStatus = SystemStatus(status: "Checking...");

  SystemStatus _windowsActivationStatus = SystemStatus(status: "Checking...");

  SystemStatus _officeActivationStatus = SystemStatus(status: "Checking...");

  // Folder information

  List<FolderInfo> _folderInfos = [];

  // Realtime folder watchers (event-based) during "Check All"

  final Map<String, StreamSubscription<FileSystemEvent>?> _folderWatchSubs = {};

  final Map<String, Timer?> _folderDebouncers = {};

  void _setStatusMessage(String message) {
    ref.read(statusMessageProvider.notifier).state = message;
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    Future.microtask(() async {
      try {
        await _checkFolderSizesFast();

        // Jika masih kosong/0 B untuk semua folder yang ada, lakukan perhitungan akurat.

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        final existsList = _folderInfos.where((f) => f.exists).toList();

        final allZero =
            existsList.isNotEmpty && existsList.every((f) => f.sizeBytes == 0);

        if (_folderInfos.isEmpty || allZero) {
          final accurate = await SystemService.getFolderSizesUltraFast();

          if (!mounted) return;

          setState(() {
            _folderInfos = accurate;
          });
        }
      } catch (e, st) {
        GlobalErrorHandler.logError(
          'Error in initState folder size check',

          e,

          st,
        );
      }
    });

    // Cek status Windows Update (Paused/Active/Disabled) saat awal aplikasi

    Future.microtask(() async {
      try {
        final paused = await SystemService.isWindowsUpdatePaused();

        final disabled = await SystemService.isWindowsUpdateDisabled();

        if (!mounted) return;

        setState(() {
          _windowsUpdatePaused = paused || disabled;

          if (disabled) {
            _updateStatus = SystemStatus(
              status: "Service disabled",

              isActive: false,

              needsUpdate: true,
            );
          }
        });
      } catch (e, st) {
        GlobalErrorHandler.logError(
          'Error checking Windows Update status on init',

          e,

          st,
        );
      }
    });
  }

  @override
  void dispose() {
    _stopFolderEventWatch();

    _tabController.dispose();

    super.dispose();
  }

  // Browser selection methods

  void _onChromeChanged(bool value) {
    setState(() {
      _chromeSelected = value;

      _updateSelectAllBrowsers();
    });
  }

  void _onEdgeChanged(bool value) {
    setState(() {
      _edgeSelected = value;

      _updateSelectAllBrowsers();
    });
  }

  void _onFirefoxChanged(bool value) {
    setState(() {
      _firefoxSelected = value;

      _updateSelectAllBrowsers();
    });
  }

  void _onResetBrowserChanged(bool value) {
    setState(() {
      _resetBrowserSelected = value;
    });
  }

  void _onSelectAllBrowsersChanged(bool value) {
    setState(() {
      _selectAllBrowsers = value;

      _chromeSelected = value;

      _edgeSelected = value;

      _firefoxSelected = value;
    });
  }

  void _updateSelectAllBrowsers() {
    _selectAllBrowsers = _chromeSelected && _edgeSelected && _firefoxSelected;
  }

  // System folders selection methods

  void _onObjects3dChanged(bool value) {
    setState(() {
      _objects3dSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onDocumentsChanged(bool value) {
    setState(() {
      _documentsSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onDownloadsChanged(bool value) {
    setState(() {
      _downloadsSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onMusicChanged(bool value) {
    setState(() {
      _musicSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onPicturesChanged(bool value) {
    setState(() {
      _picturesSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onVideosChanged(bool value) {
    setState(() {
      _videosSelected = value;

      _updateSelectAllFolders();
    });
  }

  void _onSelectAllFoldersChanged(bool value) {
    setState(() {
      _selectAllFolders = value;

      _objects3dSelected = value;

      _documentsSelected = value;

      _downloadsSelected = value;

      _musicSelected = value;

      _picturesSelected = value;

      _videosSelected = value;
    });
  }

  void _updateSelectAllFolders() {
    _selectAllFolders =
        _objects3dSelected &&
        _documentsSelected &&
        _downloadsSelected &&
        _musicSelected &&
        _picturesSelected &&
        _videosSelected;
  }

  void _onClearRecentChanged(bool value) {
    setState(() {
      _clearRecentSelected = value;
    });
  }

  void _onClearRecycleBinChanged(bool value) {
    setState(() {
      _clearRecycleBinSelected = value;
    });
  }

  // System checking methods

  Future<void> _checkAllStatus() async {
    // Anti double-tap guard

    if (_isChecking) return;

    // Mulai pengukur waktu

    final sw = Stopwatch()..start();

    setState(() {
      _isChecking = true;

      // Reset status indikator agar user melihat proses berjalan

      _defenderStatus = SystemStatus(status: "Checking...");

      _updateStatus = SystemStatus(status: "Checking...");

      _driverStatus = SystemStatus(status: "Checking...");

      _windowsActivationStatus = SystemStatus(status: "Checking...");

      _officeActivationStatus = SystemStatus(status: "Checking...");
    });

    _setStatusMessage("Menjalankan pemeriksaan sistem...");

    _startFolderEventWatch();

    try {
      // Hitung ukuran folder secara paralel (tidak memblok UI)

      _checkFolderSizesFast();

      // Status awal sudah di-set saat mulai; biarkan tanpa setState tambahan untuk mengurangi flicker.

      // _statusMessage tetap: "Menjalankan pemeriksaan sistem..."

      // Kumpulkan semua pemeriksaan cepat (native/Dart) dan tunggu hasilnya

      final defenderF = SystemService.checkWindowsDefender().catchError(
        (e, st) => SystemStatus(
          status: "❌ Defender error: ${e.toString()}",

          isActive: false,
        ),
      );

      final updateF = SystemService.checkWindowsUpdate().catchError(
        (e, st) => SystemStatus(
          status: "❌ Windows Update error: ${e.toString()}",

          isActive: false,
        ),
      );

      final driverF = SystemService.checkDrivers().catchError(
        (e, st) => SystemStatus(
          status: "❌ Driver check error: ${e.toString()}",

          isActive: false,
        ),
      );

      final windowsActF = _skipActivationOnCheckAll
          ? Future.value(
              SystemStatus(
                status: "⏭️ Dilewati (tekan Cek Ulang)",

                isActive: false,
              ),
            )
          : SystemService.checkWindowsActivationQuick().catchError(
              (e, st) => SystemStatus(
                status: "❌ Windows Activation error: ${e.toString()}",

                isActive: false,
              ),
            );

      final officeActF = _skipActivationOnCheckAll
          ? Future.value(
              SystemStatus(
                status: "⏭️ Dilewati (tekan Cek Ulang)",

                isActive: false,
              ),
            )
          : SystemService.checkOfficeActivationQuick().catchError(
              (e, st) => SystemStatus(
                status: "❌ Office Activation error: ${e.toString()}",

                isActive: false,
              ),
            );

      final results = await Future.wait<SystemStatus>([
        defenderF,

        updateF,

        driverF,

        windowsActF,

        officeActF,
      ]);

      if (!mounted) return;

      final elapsed = sw.elapsedMilliseconds / 1000;

      sw.stop();

      setState(() {
        _defenderStatus = results[0];

        _updateStatus = results[1];

        _driverStatus = results[2];

        _windowsActivationStatus = results[3];

        _officeActivationStatus = results[4];
      });

      _setStatusMessage(
        "Semua pemeriksaan selesai (${elapsed.toStringAsFixed(2)} dtk)",
      );

      // Update indikator tombol Pause Windows Update dan cek status disabled

      try {
        final paused = await SystemService.isWindowsUpdatePaused();

        final disabled = await SystemService.isWindowsUpdateDisabled();

        if (mounted) {
          setState(() {
            _windowsUpdatePaused = paused || disabled;

            // If the service is disabled, update the status text to reflect this

            if (disabled && _updateStatus.isActive) {
              _updateStatus = SystemStatus(
                status: "Service disabled",

                isActive: false,

                needsUpdate: true,
              );
            }
          });
        }
      } catch (_) {}

      // Lakukan pemeriksaan mendalam aktivasi di background jika perlu

      final w = _windowsActivationStatus.status.toLowerCase();

      if (w.contains("cannot verify") || w.contains("ditunda")) {
        _refreshWindowsActivationInBackground();
      }

      final o = _officeActivationStatus.status.toLowerCase();

      if (o.contains("cannot verify") || o.contains("ditunda")) {
        _refreshOfficeActivationInBackground();
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);

      if (mounted) {
        setState(() {
          _isChecking = false;
        });

        _setStatusMessage("Error: ${e.toString()}");
      }
    } finally {
      // Akhiri status checking segera agar tombol tidak terkunci

      _stopFolderEventWatch();

      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }

      // Lakukan refresh akhir non-blocking agar UI tidak terasa lambat

      Future.microtask(() => _refreshFolderSizesAccurate());
    }
  }

  // ignore: unused_element

  Future<void> _checkFolderSizes() async {
    try {
      final folderInfos = await SystemService.getFolderSizes();

      if (!mounted) return;

      if (_folderInfos.isEmpty) {
        setState(() {
          _folderInfos = folderInfos;
        });
      } else {
        _applyStableFolderInfos(folderInfos);
      }
    } catch (e, st) {
      GlobalErrorHandler.logError('Error checking folder sizes', e, st);

      debugPrint('Error checking folder sizes: $e');
    }
  }

  // Stabilkan update ukuran agar tidak kembali ke 0 B bila hasil sementara gagal.

  // Catatan: Selama "Check All" (_isChecking == true) selalu pakai nilai terbaru (realtime),

  // untuk memastikan UI mengikuti perubahan file/folder secara langsung.

  void _applyStableFolderInfos(List<FolderInfo> next) {
    // Realtime mode: bypass stabilizer

    if (_isChecking) {
      setState(() {
        _folderInfos = next;
      });

      return;
    }

    final prevByName = {for (final f in _folderInfos) f.name: f};

    final merged = <FolderInfo>[];

    for (final n in next) {
      final p = prevByName[n.name];

      if (p != null) {
        // Tahan sementara hanya jika hasil baru 0 B dan sebelumnya > 0 (hindari kedip).

        // Jika ukuran baru > 0 atau berbeda, gunakan nilai baru agar lebih akurat.

        final keepPrevZero = n.exists && n.sizeBytes == 0 && p.sizeBytes > 0;

        if (keepPrevZero) {
          merged.add(
            FolderInfo(
              name: p.name,

              path: n.path.isNotEmpty ? n.path : p.path,

              size: p.size,

              exists: p.exists || n.exists,

              sizeBytes: p.sizeBytes,
            ),
          );

          continue;
        }
      }

      merged.add(n);
    }

    setState(() {
      _folderInfos = merged;
    });
  }

  // Versi cepat untuk ukuran folder (batas waktu agar UI tidak menunggu lama)

  Future<void> _checkFolderSizesFast() async {
    try {
      final folderInfos = await SystemService.getFolderSizesUltraFast(
        timeout: const Duration(seconds: 6),
      );

      if (!mounted) return;

      if (_folderInfos.isEmpty) {
        setState(() {
          _folderInfos = folderInfos;
        });
      } else {
        _applyStableFolderInfos(folderInfos);
      }
    } catch (e, st) {
      // Jika gagal, biarkan diam-diam agarakan menghambat UI

      GlobalErrorHandler.logError('Error checking folder sizes (fast)', e, st);

      debugPrint('Error checking folder sizes (fast): $e');
    }
  }

  // Event-based folder size watch during "Check All"

  void _startFolderEventWatch() {
    _stopFolderEventWatch();

    final user = Platform.environment['USERPROFILE'] ?? '';

    if (user.isEmpty) return;

    final names = <String>[
      '3D Objects',

      'Documents',

      'Downloads',

      'Music',

      'Pictures',

      'Videos',
    ];

    for (final name in names) {
      try {
        final dir = Directory('$user\\$name');

        if (!dir.existsSync()) continue;

        // Debounce per-folder agar tidak terlalu sering refresh saat banyak event

        _folderDebouncers[name]?.cancel();

        _folderDebouncers[name] = null;

        final sub = dir.watch(recursive: true).listen((event) {
          _folderDebouncers[name]?.cancel();

          _folderDebouncers[name] = Timer(
            const Duration(milliseconds: 700),

            () async {
              try {
                final info = await SystemService.getSingleFolderInfo(
                  name,

                  useUltraFast: true,
                );

                if (!mounted) return;

                final next = List<FolderInfo>.from(_folderInfos);

                final i = next.indexWhere((f) => f.name == name);

                if (i >= 0) {
                  next[i] = info;
                } else {
                  next.add(info);
                }

                setState(() {
                  _folderInfos = next;
                });
              } catch (_) {}
            },
          );
        }, onError: (_) {});

        _folderWatchSubs[name] = sub;
      } catch (_) {}
    }
  }

  void _stopFolderEventWatch() {
    for (final sub in _folderWatchSubs.values) {
      try {
        sub?.cancel();
      } catch (_) {}
    }

    _folderWatchSubs.clear();

    for (final t in _folderDebouncers.values) {
      try {
        t?.cancel();
      } catch (_) {}
    }

    _folderDebouncers.clear();
  }

  Future<void> _refreshFolderSizesAccurate() async {
    try {
      // Final refresh pakai ultra-fast agar tidak menahan _isChecking terlalu lama

      final infos = await SystemService.getFolderSizesUltraFast(
        timeout: const Duration(seconds: 6),
      );

      if (!mounted) return;

      setState(() {
        _folderInfos = infos;
      });
    } catch (e, st) {
      GlobalErrorHandler.logError('Error in refreshFolderSizesAccurate', e, st);
    }
  }

  // System action methods

  Future<void> _updateDefender() async {
    _setStatusMessage("Updating Windows Defender...");

    bool success = await SystemService.updateWindowsDefender();

    if (success) {
      setState(() {
        _defenderStatus = SystemStatus(status: "✅ Updated", isActive: true);

        _setStatusMessage("Windows Defender updated successfully");
      });
    } else {
      if (mounted) {
        _setStatusMessage("Failed to update Windows Defender");
      }

      GlobalErrorHandler.showError('Gagal memperbarui Windows Defender');
    }
  }

  Future<void> _runWindowsUpdate() async {
    _setStatusMessage("Running Windows Update...");

    bool success = await SystemService.runWindowsUpdate();

    if (success) {
      setState(() {
        _updateStatus = SystemStatus(
          status: "✅ Updates installed",

          isActive: true,
        );

        _setStatusMessage("Windows Update completed successfully");
      });
    } else {
      if (mounted) {
        _setStatusMessage("Failed to run Windows Update");
      }

      GlobalErrorHandler.showError('Gagal menjalankan Windows Update');
    }
  }

  // Pastikan elevated; jika tidak, minta relaunch sebagai Administrator

  Future<bool> _ensureAdminOrRelaunch() async {
    final elevated = await SystemService.isElevated();

    if (elevated) return true;

    // Catatan: Pada mode debug, relaunch akan memutus sesi flutter run (ini normal).

    // Tetap lanjutkan agar UAC muncul dan aplikasi dibuka ulang sebagai Administrator.

    final relaunch = await _showConfirmationDialog(
      'Memerlukan Administrator',

      'Fitur ini memerlukan hak Administrator.\nIngin membuka ulang aplikasi dengan "Run as administrator"?',
    );

    if (relaunch == true) {
      _setStatusMessage("Membuka ulang aplikasi sebagai Administrator...");

      final ok = await SystemService.relaunchAsAdmin();

      if (ok) {
        // Tutup instance non-elevated agar tidak ada dua instance berjalan

        Future.delayed(const Duration(milliseconds: 300), () {
          exit(0);
        });
      }
    }

    return false;
  }

  Future<void> _pauseWindowsUpdate() async {
    // Cek elevasi, relaunch jika perlu

    final canProceed = await _ensureAdminOrRelaunch();

    if (!canProceed) return;

    bool? confirm = await _showConfirmationDialog(
      'Pause Windows Update (Until 2077)',

      'Tindakan ini akan menjeda Windows Update hingga tahun 2077 melalui registry pause settings.\n\nLanjutkan?',
    );

    if (confirm != true) return;

    setState(() {
      _isChecking = true;

      _setStatusMessage("Menjeda Windows Update hingga tahun 2077...");
    });

    try {
      final ok = await SystemService.pauseWindowsUpdateService();

      if (!mounted) return;

      setState(() {
        if (ok) {
          _setStatusMessage(
            "Windows Update berhasil dijeda hingga tahun 2077.",
          );

          _updateStatus = SystemStatus(
            status: "Paused until 2077",

            isActive: false,
          );

          _windowsUpdatePaused = true;
        } else {
          _setStatusMessage(
            "Gagal menjeda Windows Update. Coba jalankan aplikasi sebagai Administrator.",
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // Disable Windows Update service completely

  Future<void> _disableWindowsUpdate() async {
    // Cek elevasi, relaunch jika perlu

    final canProceed = await _ensureAdminOrRelaunch();

    if (!canProceed) return;

    bool? confirm = await _showConfirmationDialog(
      'Disable Windows Update Service',

      'Tindakan ini akan menonaktifkan layanan Windows Update sepenuhnya.\n\nLanjutkan?',
    );

    if (confirm != true) return;

    setState(() {
      _isChecking = true;

      _setStatusMessage("Menonaktifkan layanan Windows Update...");
    });

    try {
      final ok = await SystemService.disableWindowsUpdateService();

      if (!mounted) return;

      // Verify the service is actually disabled

      final isDisabled = await SystemService.isWindowsUpdateDisabled();

      setState(() {
        if (ok && isDisabled) {
          _setStatusMessage("Layanan Windows Update berhasil dinonaktifkan.");

          _updateStatus = SystemStatus(
            status: "Service disabled",

            isActive: false,
          );

          _windowsUpdatePaused =
              true; // Use the same flag to indicate update is not active
        } else if (ok) {
          _setStatusMessage(
            "Layanan Windows Update dinonaktifkan, tetapi perlu verifikasi status.",
          );

          _updateStatus = SystemStatus(
            status: "Service disabled",

            isActive: false,
          );

          _windowsUpdatePaused = true;
        } else {
          _setStatusMessage(
            "Gagal menonaktifkan Windows Update. Coba jalankan aplikasi sebagai Administrator.",
          );
        }
      });

      // Refresh the status after a short delay to ensure UI is updated

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        final checkDisabled = await SystemService.isWindowsUpdateDisabled();

        if (checkDisabled) {
          setState(() {
            _updateStatus = SystemStatus(
              status: "Service disabled",

              isActive: false,
            );
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resumeWindowsUpdate() async {
    // Cek elevasi, relaunch jika perlu

    final canProceed = await _ensureAdminOrRelaunch();

    if (!canProceed) return;

    bool? confirm = await _showConfirmationDialog(
      'Reset Windows Update to Normal State',

      'Tindakan ini akan menghapus pengaturan pause Windows Update, mengaktifkan layanan jika dinonaktifkan, dan mengaktifkan kembali pembaruan.\n\nLanjutkan?',
    );

    if (confirm != true) return;

    setState(() {
      _isChecking = true;

      _setStatusMessage("Mengaktifkan kembali Windows Update...");
    });

    try {
      // First, make sure the service is enabled (if it was disabled)

      bool serviceEnabled = true;

      // Check if the service is disabled and try to enable it

      final isDisabled = await SystemService.isWindowsUpdateDisabled();

      if (isDisabled) {
        serviceEnabled = await SystemService.enableWindowsUpdateService();

        if (!serviceEnabled && mounted) {
          _setStatusMessage(
              "Gagal mengaktifkan layanan Windows Update. Mencoba menghapus pengaturan pause...",
            );
        }
      }

      // Then try to resume (remove pause settings)

      final ok = await SystemService.resumeWindowsUpdateService();

      if (!mounted) return;

      setState(() {
        if (ok && serviceEnabled) {
          _setStatusMessage(
            "Windows Update berhasil diaktifkan kembali ke keadaan normal.",
          );

          _updateStatus = SystemStatus(
            status: "Updates resumed",

            isActive: true,
          );

          _windowsUpdatePaused = false;
        } else if (ok) {
          _setStatusMessage(
            "Pengaturan pause berhasil dihapus, tetapi layanan Windows Update masih dinonaktifkan.",
          );

          _updateStatus = SystemStatus(
            status: "Service still disabled",

            isActive: false,
          );
        } else {
          _setStatusMessage(
            "Gagal mengaktifkan Windows Update. Coba jalankan aplikasi sebagai Administrator.",
          );
        }
      });

      // Refresh the Windows Update status after a short delay

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final paused = await SystemService.isWindowsUpdatePaused();

        final disabled = await SystemService.isWindowsUpdateDisabled();

        setState(() {
          _windowsUpdatePaused = paused;

          if (!paused && !disabled) {
            _updateStatus = SystemStatus(status: "Active", isActive: true);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _updateDrivers() async {
    _setStatusMessage("Updating drivers...");

    bool success = await SystemService.updateDrivers();

    if (success) {
      setState(() {
        _driverStatus = SystemStatus(
          status: "✅ Scan completed",

          isActive: true,
        );

        _setStatusMessage("Driver scan completed successfully");
      });
    } else {
      if (mounted) {
        _setStatusMessage("Failed to update drivers");
      }

      GlobalErrorHandler.showError('Gagal memperbarui driver');
    }
  }

  Future<void> _activateWindows() async {
    bool? confirm = await _showConfirmationDialog(
      'Konfirmasi Aktivasi Windows',

      'Apakah Anda yakin ingin mengaktifkan Windows?\n\n'
          'Script akan dijalankan melalui PowerShell dengan perintah:\n'
          'irm https://get.activated.win | iex\n\n'
          '⚠️ Pastikan Anda memiliki koneksi internet yang stabil.',
    );

    if (confirm == true) {
      _setStatusMessage("Activating Windows...");

      bool success = await SystemService.activateWindows();

      if (success) {
        _setStatusMessage("Verifying Windows activation status...");

        final st = await SystemService.checkWindowsActivation();

        setState(() {
          _windowsActivationStatus = st;

          _setStatusMessage("Windows activation completed: ${st.status}");
        });
      } else {
        if (mounted) {
          _setStatusMessage("Failed to activate Windows");
        }

        GlobalErrorHandler.showError(
          'Gagal mengaktifkan Windows. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  Future<void> _activateOffice() async {
    bool? confirm = await _showConfirmationDialog(
      'Konfirmasi Aktivasi Office',

      'Apakah Anda yakin ingin mengaktifkan Microsoft Office?\n\n'
          'Script akan dijalankan melalui PowerShell dengan perintah:\n'
          'irm https://get.activated.win | iex\n\n'
          '⚠️ Pastikan Anda memiliki koneksi internet yang stabil.',
    );

    if (confirm == true) {
      _setStatusMessage("Activating Office...");

      bool success = await SystemService.activateOffice();

      if (success) {
        _setStatusMessage("Verifying Office activation status...");

        final st = await SystemService.checkOfficeActivation();

        setState(() {
          _officeActivationStatus = st;

          _setStatusMessage("Office activation completed: ${st.status}");
        });
      } else {
        if (mounted) {
          _setStatusMessage("Failed to activate Office");
        }

        GlobalErrorHandler.showError(
          'Gagal mengaktifkan Office. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  Future<void> _openActivationShell() async {
    bool? confirm = await _showConfirmationDialog(
      'Buka PowerShell Aktivasi',

      'Ini akan membuka jendela PowerShell dan menjalankan:\n'
          'irm https://get.activated.win | iex\n\n'
          'Lanjutkan?',
    );

    if (confirm == true) {
      _setStatusMessage("Membuka PowerShell Aktivasi...");

      bool ok = await SystemService.openActivationPowerShell();

      _setStatusMessage(
          ok
              ? "PowerShell dibuka. Ikuti instruksi untuk aktivasi Windows/Office."
              : "Gagal membuka PowerShell Aktivasi.",
        );
    }
  }

  Future<void> _openWindowsUpdateSettings() async {
    if (!Platform.isWindows) {
      GlobalErrorHandler.showWarning('Fitur hanya tersedia di Windows.');

      _setStatusMessage('Fitur hanya tersedia di Windows.');

      return;
    }

    _setStatusMessage("Membuka Windows Update settings...");

    try {
      final ok = await SystemService.openWindowsUpdateSettings();

      if (!mounted) return;

      _setStatusMessage(
          ok
              ? "Windows Update settings dibuka."
              : "Gagal membuka Windows Update settings.",
        );

      if (!ok) {
        GlobalErrorHandler.showError("Gagal membuka Windows Update settings.");
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);

      if (!mounted) return;

      _setStatusMessage(
          "Gagal membuka Windows Update settings: ${e.toString()}",
        );
    }
  }

  Future<void> _openWindowsSecurity() async {
    if (!Platform.isWindows) {
      GlobalErrorHandler.showWarning('Fitur hanya tersedia di Windows.');

      _setStatusMessage('Fitur hanya tersedia di Windows.');

      return;
    }

    _setStatusMessage("Membuka Windows Security...");

    try {
      final ok = await SystemService.openWindowsSecurity();

      if (!mounted) return;

      _setStatusMessage(
          ok ? "Windows Security dibuka." : "Gagal membuka Windows Security.",
        );

      if (!ok) {
        GlobalErrorHandler.showError("Gagal membuka Windows Security.");
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);

      if (!mounted) return;

      _setStatusMessage("Gagal membuka Windows Security: ${e.toString()}");
    }
  }

  Future<void> _openDeviceManager() async {
    if (!Platform.isWindows) {
      GlobalErrorHandler.showWarning('Fitur hanya tersedia di Windows.');

      _setStatusMessage('Fitur hanya tersedia di Windows.');

      return;
    }

    _setStatusMessage("Membuka Device Manager...");

    try {
      final ok = await SystemService.openDeviceManager();

      if (!mounted) return;

      _setStatusMessage(
          ok ? "Device Manager dibuka." : "Gagal membuka Device Manager.",
        );

      if (!ok) {
        GlobalErrorHandler.showError("Gagal membuka Device Manager.");
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);

      if (!mounted) return;

      _setStatusMessage("Gagal membuka Device Manager: ${e.toString()}");
    }
  }

  // Activation re-check (background) helpers

  Future<void> _refreshWindowsActivationInBackground() async {
    try {
      final st = await SystemService.checkWindowsActivation();

      if (!mounted) return;

      if (st.status.isNotEmpty &&
          st.status != _windowsActivationStatus.status) {
        setState(() {
          _windowsActivationStatus = st;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshOfficeActivationInBackground() async {
    try {
      final st = await SystemService.checkOfficeActivation();

      if (!mounted) return;

      if (st.status.isNotEmpty && st.status != _officeActivationStatus.status) {
        setState(() {
          _officeActivationStatus = st;
        });
      }
    } catch (_) {}
  }

  // Selection methods

  void _selectAllEverything() {
    setState(() {
      _selectAllBrowsers = true;

      _selectAllFolders = true;

      _resetBrowserSelected = true;

      _clearRecentSelected = true;

      _clearRecycleBinSelected = true;

      _onSelectAllBrowsersChanged(true);

      _onSelectAllFoldersChanged(true);
    });
  }

  void _deselectAllEverything() {
    setState(() {
      _selectAllBrowsers = false;

      _selectAllFolders = false;

      _resetBrowserSelected = false;

      _clearRecentSelected = false;

      _clearRecycleBinSelected = false;

      _onSelectAllBrowsersChanged(false);

      _onSelectAllFoldersChanged(false);
    });
  }


  // Cleaning method

  Future<void> _startCleaning() async {
    bool browserSelected = _chromeSelected || _edgeSelected || _firefoxSelected;

    bool folderSelected =
        _objects3dSelected ||
        _documentsSelected ||
        _downloadsSelected ||
        _musicSelected ||
        _picturesSelected ||
        _videosSelected;

    bool recentSelected = _clearRecentSelected;

    bool recycleSelected = _clearRecycleBinSelected;

    if (!browserSelected &&
        !folderSelected &&
        !recentSelected &&
        !recycleSelected) {
      _showWarningDialog(
        'Peringatan',

        'Silakan pilih minimal satu opsi untuk dijalankan!',
      );

      return;
    }

    String confirmMessage =
        'Apakah Anda yakin ingin melakukan operasi berikut?\n\n';

    if (browserSelected) confirmMessage += '✓ Data browser akan dihapus\n';

    if (folderSelected)
      confirmMessage += '✓ File di folder sistem akan dihapus PERMANEN\n';

    if (recentSelected)
      confirmMessage +=
          '✓ Jejak recent (Start/Search, Quick Access, Office) akan dihapus & Photos akan di-unpin\n';

    if (recycleSelected) confirmMessage += '✓ Recycle Bin akan dikosongkan\n';

    bool? confirm = await _showConfirmationDialog('Konfirmasi', confirmMessage);

    if (confirm != true) return;

    setState(() {
      _isCleaning = true;

      _setStatusMessage("Memulai proses pembersihan (paralel)...");
    });

    try {
      List<String> cleanedBrowsers = [];

      List<String> cleanedFolders = [];

      bool recentCleared = false;

      bool recycleCleared = false;

      Future<List<String>>? fBrowsers;

      Future<List<String>>? fFolders;

      Future<bool>? fRecent;

      Future<bool>? fRecycle;

      // Launch all selected tasks in parallel

      if (browserSelected && _resetBrowserSelected) {
        fBrowsers = SystemService.cleanBrowsers(
          chrome: _chromeSelected,

          edge: _edgeSelected,

          firefox: _firefoxSelected,

          resetBrowser: _resetBrowserSelected,
        );
      }

      if (folderSelected) {
        fFolders = SystemService.cleanSystemFolders(
          documents: _documentsSelected,

          downloads: _downloadsSelected,

          music: _musicSelected,

          pictures: _picturesSelected,

          videos: _videosSelected,

          objects3d: _objects3dSelected,
        );
      }

      if (recentSelected) {
        fRecent = SystemService.clearRecentFiles();
      }

      if (recycleSelected) {
        fRecycle = SystemService.clearRecycleBin();
      }

      final tasks = <Future<dynamic>>[];

      final List<String> errorMsgs = [];

      if (fBrowsers != null) {
        final fb0 = fBrowsers;

        final fb = fb0.catchError((e, st) {
          errorMsgs.add("Reset browser gagal: ${e.toString()}");

          return <String>[];
        });

        fBrowsers = fb;

        tasks.add(fb);
      }

      if (fFolders != null) {
        final ff0 = fFolders;

        final ff = ff0.catchError((e, st) {
          errorMsgs.add("Bersihkan folder sistem gagal: ${e.toString()}");

          return <String>[];
        });

        fFolders = ff;

        tasks.add(ff);
      }

      if (fRecent != null) {
        final fr0 = fRecent;

        final fr = fr0.catchError((e, st) {
          errorMsgs.add("Clear Recent Files gagal: ${e.toString()}");

          return false;
        });

        fRecent = fr;

        tasks.add(fr);
      }

      if (fRecycle != null) {
        final frb0 = fRecycle;

        final frb = frb0.catchError((e, st) {
          errorMsgs.add("Kosongkan Recycle Bin gagal: ${e.toString()}");

          return false;
        });

        fRecycle = frb;

        tasks.add(frb);
      }

      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }

      if (fBrowsers != null) cleanedBrowsers = await fBrowsers;

      if (fFolders != null) cleanedFolders = await fFolders;

      if (fRecent != null) recentCleared = await fRecent;

      if (fRecycle != null) recycleCleared = await fRecycle;

      // Show results

      String resultMessage = '';

      if (cleanedBrowsers.isNotEmpty) {
        resultMessage +=
            '✅ Browser berhasil di-reset:\n${cleanedBrowsers.join('\n')}\n\n';
      }

      if (cleanedFolders.isNotEmpty) {
        resultMessage +=
            '✅ Folder sistem berhasil dibersihkan:\n${cleanedFolders.join('\n')}\n\n';
      }

      if (recentCleared) {
        resultMessage +=
            '✅ Recent files berhasil dihapus (termasuk unpin Photos).\n\n';
      }

      if (recycleCleared) {
        resultMessage += '✅ Recycle Bin berhasil dikosongkan.\n\n';
      }

      if (errorMsgs.isNotEmpty) {
        resultMessage +=
            '❌ Beberapa operasi gagal:\n- ${errorMsgs.join('\n- ')}\n\n';
      }

      if (resultMessage.isNotEmpty) {
        _showInfoDialog('Selesai', resultMessage.trim());

        _setStatusMessage("Pembersihan selesai.");
      } else {
        _setStatusMessage("Tidak ada aksi yang dilakukan.");

        _showInfoDialog(
          'Info',

          'Tidak ada browser atau folder yang dipilih untuk dibersihkan.',
        );
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);

      _setStatusMessage("❌ Gagal melakukan pembersihan: ${e.toString()}");

      _showErrorDialog(
        'Error',

        'Terjadi kesalahan saat proses pembersihan:\n${e.toString()}',
      );
    } finally {
      setState(() {
        _isCleaning = false;
      });
    }
  }

  // Dialog methods

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),

          content: Text(content),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),

              child: Text('Batal'),
            ),

            TextButton(
              onPressed: () => Navigator.of(context).pop(true),

              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  void _showWarningDialog(String title, String content) {
    showDialog(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),

          content: Text(content),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),

              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),

          content: Text(content),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),

              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),

          content: Text(content),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),

              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: const [
            Text('versi 1.0.5', style: TextStyle(fontSize: 10)),

            Text(
              'Sekom Cleaner',

              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            Text('by Ibnu', style: TextStyle(fontSize: 10)),
          ],
        ),

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        centerTitle: true,

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),

          child: Container(
            width: double.infinity,

            color: Theme.of(context).colorScheme.inversePrimary,

            child: TabBar(
              controller: _tabController,

              isScrollable: false, // Make tabs fill the full width

              labelPadding: EdgeInsets.symmetric(horizontal: 10),

              indicatorWeight: 3,

              tabs: [
                Tab(
                  icon: Icon(Icons.cleaning_services, size: 18),

                  text: 'System Cleaner',
                ),

                Tab(
                  icon: Icon(Icons.delete_outline, size: 18),

                  text: 'Shortcut',
                ),

                Tab(
                  icon: Icon(Icons.battery_charging_full, size: 18),

                  text: 'Battery Health',
                ),

                Tab(
                  icon: Icon(Icons.lightbulb_outline, size: 18),

                  text: 'Optimization',
                ),

                Tab(icon: Icon(Icons.science, size: 18), text: 'Testing'),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,

        children: [
          // System Cleaner Tab
          _buildSystemCleanerTab(),

          // Uninstaller Tab
          UninstallerScreen(),

          // Battery Health Tab
          BatteryScreen(),

          // System Optimization Tab
          _buildSystemOptimizationTab(),

          // Testing Tab
          TestingScreen(),
        ],
      ),
    );
  }

  Widget _buildSystemOptimizationTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Header with title and description
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),

            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,

                          color: Colors.amber,

                          size: 20,
                        ),

                        SizedBox(width: 8),

                        Text(
                          'System Optimization',

                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    Text(
                      'Optimize your system with these recommended actions to improve performance, security, and privacy.',

                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content - System Suggestions
          Expanded(child: SystemSuggestionsSection(compactMode: _compactMode)),
        ],
      ),
    );
  }

  Widget _buildSystemCleanerTab() {
    return Column(
      children: [
        // Sticky action bar at top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),

                blurRadius: 6,

                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Row(
            children: [
              // Left: primary actions
              Wrap(
                spacing: 10,

                runSpacing: 8,

                children: [
                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkAllStatus,

                    icon: const Icon(Icons.search),

                    label: const Text('🔍 Check All'),
                  ),

                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _selectAllEverything,

                    icon: const Icon(Icons.check_box),

                    label: const Text('✅ Pilih Semua'),
                  ),

                  ElevatedButton.icon(
                    onPressed: _isChecking ? null : _deselectAllEverything,

                    icon: const Icon(Icons.check_box_outline_blank),

                    label: const Text('❌ Batal Pilih'),
                  ),

                  ElevatedButton.icon(
                    onPressed: (_isCleaning || _isChecking)
                        ? null
                        : _startCleaning,

                    icon: const Icon(Icons.cleaning_services),

                    label: const Text('🧹 Bersihkan'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,

                      foregroundColor: Colors.white,
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),

                    icon: const Icon(Icons.exit_to_app),

                    label: const Text('❌ Keluar'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,

                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),

        // Ultra-compact content with minimal scrolling
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),

            child: Column(
              children: [
                // Main content in a 2x2 grid layout
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // Left column - Combined cleaning section and space for new feature
                      Expanded(
                        flex: 5,

                        child: Column(
                          children: [
                            // Combined cleaning section (browser + folders)
                            CombinedCleaningSection(
                              chromeSelected: _chromeSelected,

                              edgeSelected: _edgeSelected,

                              firefoxSelected: _firefoxSelected,

                              resetBrowserSelected: _resetBrowserSelected,

                              selectAllBrowsers: _selectAllBrowsers,

                              onChromeChanged: _onChromeChanged,

                              onEdgeChanged: _onEdgeChanged,

                              onFirefoxChanged: _onFirefoxChanged,

                              onResetBrowserChanged: _onResetBrowserChanged,

                              onSelectAllBrowsersChanged:
                                  _onSelectAllBrowsersChanged,

                              objects3dSelected: _objects3dSelected,

                              documentsSelected: _documentsSelected,

                              downloadsSelected: _downloadsSelected,

                              musicSelected: _musicSelected,

                              picturesSelected: _picturesSelected,

                              videosSelected: _videosSelected,

                              selectAllFolders: _selectAllFolders,

                              folderInfos: _folderInfos,

                              onObjects3dChanged: _onObjects3dChanged,

                              onDocumentsChanged: _onDocumentsChanged,

                              onDownloadsChanged: _onDownloadsChanged,

                              onMusicChanged: _onMusicChanged,

                              onPicturesChanged: _onPicturesChanged,

                              onVideosChanged: _onVideosChanged,

                              onSelectAllFoldersChanged:
                                  _onSelectAllFoldersChanged,
                            ),

                            // Storage and RAM info section
                            Expanded(child: StorageRamInfoSection()),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Right column
                      Expanded(
                        flex: 7,

                        child: Column(
                          children: [
                            // Windows Status section (top right)
                            Expanded(
                              flex: 3,

                              child: WindowsSystemSection(
                                defenderStatus: _defenderStatus,

                                updateStatus: _updateStatus,

                                driverStatus: _driverStatus,

                                windowsActivationStatus:
                                    _windowsActivationStatus,

                                officeActivationStatus: _officeActivationStatus,

                                clearRecentSelected: _clearRecentSelected,

                                isChecking: _isChecking,

                                onUpdateDefender: _updateDefender,

                                onRunWindowsUpdate: _runWindowsUpdate,

                                onUpdateDrivers: _updateDrivers,

                                onActivateWindows: _activateWindows,

                                onActivateOffice: _activateOffice,

                                onOpenActivationShell: _openActivationShell,

                                onOpenWindowsUpdateSettings:
                                    _openWindowsUpdateSettings,

                                onOpenWindowsSecurity: _openWindowsSecurity,

                                onOpenDeviceManager: _openDeviceManager,

                                clearRecycleBinSelected:
                                    _clearRecycleBinSelected,

                                onClearRecycleBinChanged:
                                    _onClearRecycleBinChanged,

                                onClearRecentChanged: _onClearRecentChanged,

                                onRecheckActivation: () {
                                  _refreshWindowsActivationInBackground();

                                  _refreshOfficeActivationInBackground();
                                },

                                skipActivationOnCheckAll:
                                    _skipActivationOnCheckAll,

                                onSkipActivationChanged: (v) {
                                  setState(() {
                                    _skipActivationOnCheckAll = v;
                                  });
                                },

                                windowsUpdatePaused: _windowsUpdatePaused,

                                onPauseWindowsUpdate: _pauseWindowsUpdate,

                                onResumeWindowsUpdate: _resumeWindowsUpdate,

                                onDisableWindowsUpdate: _disableWindowsUpdate,

                                compactMode: true, // Always use compact mode

                                showPart:
                                    1, // Show only the first part (status rows)
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Quick Actions shortcuts
                            const QuickActionsSection(),

                            const SizedBox(height: 6),

                            // Windows Controls section (bottom right)
                            Expanded(
                              flex: 3, // Increased flex to make it more visible

                              child: Card(
                                margin: EdgeInsets.zero,

                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),

                                  child: WindowsSystemSection(
                                    defenderStatus: _defenderStatus,

                                    updateStatus: _updateStatus,

                                    driverStatus: _driverStatus,

                                    windowsActivationStatus:
                                        _windowsActivationStatus,

                                    officeActivationStatus:
                                        _officeActivationStatus,

                                    clearRecentSelected: _clearRecentSelected,

                                    isChecking: _isChecking,

                                    onUpdateDefender: _updateDefender,

                                    onRunWindowsUpdate: _runWindowsUpdate,

                                    onUpdateDrivers: _updateDrivers,

                                    onActivateWindows: _activateWindows,

                                    onActivateOffice: _activateOffice,

                                    onOpenActivationShell: _openActivationShell,

                                    onOpenWindowsUpdateSettings:
                                        _openWindowsUpdateSettings,

                                    onOpenWindowsSecurity: _openWindowsSecurity,

                                    onOpenDeviceManager: _openDeviceManager,

                                    clearRecycleBinSelected:
                                        _clearRecycleBinSelected,

                                    onClearRecycleBinChanged:
                                        _onClearRecycleBinChanged,

                                    onClearRecentChanged: _onClearRecentChanged,

                                    onRecheckActivation: () {
                                      _refreshWindowsActivationInBackground();

                                      _refreshOfficeActivationInBackground();
                                    },

                                    skipActivationOnCheckAll:
                                        _skipActivationOnCheckAll,

                                    onSkipActivationChanged: (v) {
                                      setState(() {
                                        _skipActivationOnCheckAll = v;
                                      });
                                    },

                                    windowsUpdatePaused: _windowsUpdatePaused,

                                    onPauseWindowsUpdate: _pauseWindowsUpdate,

                                    onResumeWindowsUpdate: _resumeWindowsUpdate,

                                    onDisableWindowsUpdate:
                                        _disableWindowsUpdate,

                                    compactMode:
                                        true, // Always use compact mode

                                    showPart:
                                        2, // Show only the second part (Windows Update control and options)
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Compact status bar at bottom
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,

                    vertical: 8,
                  ),

                  margin: const EdgeInsets.only(top: 8, bottom: 4),

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,

                    borderRadius: BorderRadius.circular(4),

                    border: Border.all(color: Colors.grey.shade300),
                  ),

                  child: Row(
                    children: [
                      if (_isChecking || _isCleaning)
                        Container(
                          width: 16,

                          height: 16,

                          margin: const EdgeInsets.only(right: 8),

                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),

                      Expanded(
                        child: Text(
                          ref.watch(statusMessageProvider),

                          style: const TextStyle(
                            fontSize: 13,

                            fontWeight: FontWeight.w500,
                          ),

                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
