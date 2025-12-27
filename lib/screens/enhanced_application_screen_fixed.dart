import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/application_models.dart';
import '../models/app_category.dart';
import '../services/application_service.dart';
import '../services/category_service.dart';
import '../widgets/installed_apps_section.dart';
import '../widgets/app_category_section.dart';
import '../utils/error_handler.dart';

class EnhancedApplicationScreen extends StatefulWidget {
  const EnhancedApplicationScreen({super.key});

  @override
  State<EnhancedApplicationScreen> createState() => _EnhancedApplicationScreenState();
}

class _EnhancedApplicationScreenState extends State<EnhancedApplicationScreen> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // State variables
  List<InstalledApplication> _defaultApps = [];
  List<InstallableApplication> _shortcutApps = [];
  List<AppCategory> _categories = [];
  ApplicationList? _currentAppList;
  bool _isLoadingDefault = false;
  bool _isLoadingCategories = false;
  bool _isInstalling = false;
  String _statusMessage = "Siap untuk mengelola aplikasi";
  Set<String> _customDefaultNames = {};
  String _selectedCategoryId = 'productivity'; // Default selected category

  // Predefined categories
  List<AppCategory> predefinedCategories = [
    AppCategory(id: 'productivity', name: 'Produktivitas', description: 'Aplikasi produktivitas', iconName: 'work'),
    AppCategory(id: 'browser', name: 'Browserss', description: 'Aplikasi browser', iconName: 'web'),
    AppCategory(id: 'media', name: 'Media', description: 'Aplikasi media', iconName: 'play_circle'),
    AppCategory(id: 'other', name: 'Lainnya', description: 'Kategori lainnya', iconName: 'folder'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _refreshDefaultApps();
    await _loadShortcutList();
    await _loadCategories();
  }

  Future<void> _refreshDefaultApps() async {
    setState(() {
      _isLoadingDefault = true;
      _statusMessage = "Memeriksa aplikasi default...";
    });

    try {
      List<InstalledApplication> defaultApps = await ApplicationService.checkInstalledApplications();
      List<String> custom = await ApplicationService.loadDefaultAppChecks();
      if (!mounted) return;
      setState(() {
        _defaultApps = defaultApps;
        _customDefaultNames = custom.toSet();
        _statusMessage = "Pemeriksaan aplikasi selesai";
      });
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      if (mounted) {
        setState(() {
          _statusMessage = "Error: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDefault = false;
        });
      }
    }
  }

  Future<void> _loadShortcutList() async {
    try {
      // Load saved shortcuts from storage
      List<ApplicationList> savedLists = await ApplicationService.loadApplicationLists();
      if (!mounted) return;
      if (savedLists.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _currentAppList = savedLists.first;
          _shortcutApps = List.from(savedLists.first.applications);
        });
      } else {
        // Initialize empty list with proper ApplicationList structure
        ApplicationList emptyList = ApplicationList(
          applications: [],
          name: 'Shortcut Applications',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        if (!mounted) return;
        setState(() {
          _currentAppList = emptyList;
          _shortcutApps = [];
        });
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      if (!mounted) return;
      setState(() {
        _statusMessage = "Error loading shortcuts: ${e.toString()}";
        _shortcutApps = [];
        // Create fallback ApplicationList
        _currentAppList = ApplicationList(
          applications: [],
          name: 'Shortcut Applications',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      List<AppCategory> categories = await CategoryService.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        
        // Assign apps to "other" category if they don't belong to any category
        bool needsSave = false;
        
        List<String> allCategoryAppIds = [];
        for (final cat in categories) {
          allCategoryAppIds.addAll(cat.appIds);
        }
        
        List<String> uncategorizedAppIds = [];
        for (final app in _shortcutApps) {
          if (!allCategoryAppIds.contains(app.id)) {
            uncategorizedAppIds.add(app.id);
          }
        }
        
        if (uncategorizedAppIds.isNotEmpty) {
          int otherIndex = categories.indexWhere((cat) => cat.id == 'other');
          if (otherIndex != -1) {
            List<String> updatedOtherAppIds = List.from(categories[otherIndex].appIds)..addAll(uncategorizedAppIds);
            categories[otherIndex] = categories[otherIndex].copyWith(appIds: updatedOtherAppIds);
            needsSave = true;
          }
        }
        
        if (needsSave) {
          CategoryService.saveCategories(categories);
        }
      });
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      if (mounted) {
        setState(() {
          _statusMessage = "Error loading categories: ${e.toString()}";
          _categories = predefinedCategories;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _onAppSelectionChanged(String appId, bool isSelected) {
    setState(() {
      int index = _shortcutApps.indexWhere((app) => app.id == appId);
      if (index != -1) {
        _shortcutApps[index] = _shortcutApps[index].copyWith(isSelected: isSelected);
      }
    });
    // Auto-save selection state so it persists across sessions/PCs (silent)
    _saveApplicationList(silent: true);
  }

  void _onEditApp(String appId) {
    InstallableApplication? app = _shortcutApps.firstWhere(
      (app) => app.id == appId,
      orElse: () => InstallableApplication(id: '', name: '', description: '', downloadUrl: '', installerName: '', filePath: ''),
    );
    
    if (app.id.isNotEmpty) {
      _showEditAppDialog(app);
    }
  }

  void _onDeleteApp(String appId) {
    _showDeleteConfirmationDialog(appId);
  }

  void _onInstallApp(String appId) {
    InstallableApplication? app = _shortcutApps.firstWhere(
      (app) => app.id == appId,
      orElse: () => InstallableApplication(id: '', name: '', description: '', downloadUrl: '', installerName: '', filePath: ''),
    );

    if (app.id.isNotEmpty) {
      _showInstallConfirmationDialog([app]);
    }
  }

  void _showEditAppDialog(InstallableApplication app) async {
    TextEditingController nameController = TextEditingController(text: app.name);
    TextEditingController descriptionController = TextEditingController(text: app.description);
    TextEditingController urlController = TextEditingController(text: app.downloadUrl);
    TextEditingController installerController = TextEditingController(text: app.installerName);
    
    // Get current category for this app
    String currentCategoryId = await CategoryService.getCategoryForApp(app.id);

    String? selectedCategoryId = currentCategoryId;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Aplikasi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Aplikasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'Path File (.exe/.msi)',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.folder_open),
                          onPressed: () async {
                            await _pickFile(urlController);
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: installerController,
                      decoration: InputDecoration(
                        labelText: 'Nama File Installer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedCategoryId,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate path (if provided)
                    final path = urlController.text;
                    if (path.isNotEmpty) {
                      final resolved = ApplicationService.resolvePortablePath(path);
                      final lower = resolved.toLowerCase();
                      if (!(lower.endsWith('.exe') || lower.endsWith('.msi'))) {
                        _showErrorDialog('Error', 'Path harus file .exe atau .msi yang valid.');
                        return;
                      }
                      if (!await File(resolved).exists()) {
                        _showErrorDialog('Error', 'File tidak ditemukan di: $resolved');
                        return;
                      }
                    }

                    _updateApp(
                      app.id,
                      nameController.text,
                      descriptionController.text,
                      urlController.text,
                      installerController.text,
                    );
                    
                    // Update category if changed
                    if (selectedCategoryId != null && selectedCategoryId != currentCategoryId) {
                      await CategoryService.addAppToCategory(app.id, selectedCategoryId!);
                      await _loadCategories(); // Refresh categories
                    }
                    
                    Navigator.of(context).pop();
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _updateApp(String appId, String name, String description, String filePath, String installer) {
    // Convert to portable path so it works across devices/drives (USB-friendly)
    final portablePath = ApplicationService.makePathPortable(filePath);
    setState(() {
      int index = _shortcutApps.indexWhere((app) => app.id == appId);
      if (index != -1) {
        _shortcutApps[index] = _shortcutApps[index].copyWith(
          name: name,
          description: description,
          downloadUrl: portablePath, // Store portable path
          installerName: installer,
        );
      }
    });
    // Auto-save after edit to persist changes immediately (silent)
    _saveApplicationList(silent: true);
  }

  void _showDeleteConfirmationDialog(String appId) {
    InstallableApplication? app = _shortcutApps.firstWhere(
      (app) => app.id == appId,
      orElse: () => InstallableApplication(id: '', name: '', description: '', downloadUrl: '', installerName: '', filePath: ''),
    );

    if (app.id.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus shortcut "${app.name}" dari daftar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteApp(appId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteApp(String appId) async {
    // Remove app from categories
    String categoryId = await CategoryService.getCategoryForApp(appId);
    if (categoryId.isNotEmpty) {
      await CategoryService.removeAppFromCategory(appId, categoryId);
    }
    
    setState(() {
      _shortcutApps.removeWhere((app) => app.id == appId);
    });
    
    // Auto-save after deletion (silent)
    await _saveApplicationList(silent: true);
    
    // Refresh categories
    await _loadCategories();
  }

  void _showAddAppDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController pathController = TextEditingController();
    
    String? selectedCategoryId = _selectedCategoryId;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Shortcut Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Aplikasi *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: pathController,
                      decoration: InputDecoration(
                        labelText: 'Pilih File (.exe/.msi) *',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.folder_open),
                          onPressed: () async {
                            await _pickFile(pathController);
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Klik ikon folder untuk memilih file .exe atau .msi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedCategoryId,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && 
                        descriptionController.text.isNotEmpty && 
                        pathController.text.isNotEmpty) {
                      // Validate selected path
                      final resolvedPath = ApplicationService.resolvePortablePath(pathController.text);
                      final lower = resolvedPath.toLowerCase();
                      if (!(lower.endsWith('.exe') || lower.endsWith('.msi'))) {
                        _showErrorDialog('Error', 'Path harus file .exe atau .msi yang valid.');
                        return;
                      }
                      if (!await File(resolvedPath).exists()) {
                        _showErrorDialog('Error', 'File tidak ditemukan di: $resolvedPath');
                        return;
                      }

                      String newAppId = await _addNewApp(
                        nameController.text,
                        descriptionController.text,
                        pathController.text,
                        '',
                      );
                      
                      // Add to selected category
                      if (selectedCategoryId != null && newAppId.isNotEmpty) {
                        await CategoryService.addAppToCategory(newAppId, selectedCategoryId!);
                        await _loadCategories(); // Refresh categories
                      }
                      
                      Navigator.of(context).pop();
                    } else {
                      _showWarningDialog('Peringatan', 'Harap isi semua field yang wajib diisi!');
                    }
                  },
                  child: Text('Tambah'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _pickFile(TextEditingController controller) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe', 'msi'],
        dialogTitle: 'Pilih File Aplikasi (.exe/.msi)',
      );

      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;
        
        // Convert to portable path for USB compatibility
        String portablePath = ApplicationService.makePathPortable(selectedPath);
        
        setState(() {
          controller.text = portablePath;
        });
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal memilih file: ${e.toString()}');
    }
  }

  Future<String> _addNewApp(String name, String description, String filePath, String installer) async {
    String newId = 'shortcut_${DateTime.now().millisecondsSinceEpoch}';
    
    // Make sure path is portable for USB compatibility
    String portablePath = ApplicationService.makePathPortable(filePath);
    
    InstallableApplication newApp = InstallableApplication(
      id: newId,
      name: name,
      description: description,
      downloadUrl: portablePath, // Using downloadUrl field to store portable file path
      installerName: installer,
      filePath: portablePath,
    );

    setState(() {
      _shortcutApps.add(newApp);
    });
    
    // Auto save after adding (silent)
    await _saveApplicationList(silent: true);
    
    return newId;
  }

  Future<void> _saveApplicationList({bool silent = false}) async {
    try {
      // Ensure we have a current app list structure
      _currentAppList ??= ApplicationList(
          applications: [],
          name: 'Shortcut Applications',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

      ApplicationList updatedList = ApplicationList(
        applications: _shortcutApps,
        name: 'Shortcut Applications',
        createdAt: _currentAppList!.createdAt,
        updatedAt: DateTime.now(),
      );

      await ApplicationService.saveApplicationList(updatedList);
      
      setState(() {
        _statusMessage = "Daftar shortcut berhasil disimpan (${_shortcutApps.length} shortcut)";
        _currentAppList = updatedList;
      });

      if (!silent) {
        _showInfoDialog('Berhasil', 'Daftar shortcut berhasil disimpan dengan ${_shortcutApps.length} shortcut.');
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
      _showErrorDialog('Error', 'Gagal menyimpan daftar aplikasi: ${e.toString()}');
    }
  }

  Future<void> _startInstallation() async {
    List<InstallableApplication> selectedApps = _shortcutApps.where((app) => app.isSelected).toList();
    
    if (selectedApps.isEmpty) {
      _showWarningDialog('Peringatan', 'Silakan pilih minimal satu shortcut untuk dijalankan!');
      return;
    }

    _showInstallConfirmationDialog(selectedApps);
  }

  void _showInstallConfirmationDialog(List<InstallableApplication> selectedApps) {
    String appList = selectedApps.map((app) => '• ${app.name}').join('\n');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Jalankan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shortcut yang akan dijalankan:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(appList),
              ),
              SizedBox(height: 12),
              Text(
                'Catatan: Aplikasi akan dijalankan dari file .exe atau .msi yang sudah Anda tentukan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performInstallation(selectedApps);
              },
              child: Text('Jalankan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performInstallation(List<InstallableApplication> selectedApps) async {
    setState(() {
      _isInstalling = true;
      _statusMessage = "Menjalankan aplikasi...";
    });

    try {
      // Resolve portable paths before execution
      List<InstallableApplication> resolvedApps = selectedApps.map((app) {
        String resolvedPath = ApplicationService.resolvePortablePath(app.downloadUrl);
        return app.copyWith(downloadUrl: resolvedPath);
      }).toList();
      
      Map<String, dynamic> result = await ApplicationService.simulateInstallation(resolvedApps);
      
      setState(() {
        _statusMessage = "Selesai menjalankan aplikasi";
      });

      _showInstallationResultDialog(result);
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
      _showErrorDialog('Error', 'Terjadi kesalahan saat menjalankan aplikasi: ${e.toString()}');
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  void _showInstallationResultDialog(Map<String, dynamic> result) {
    List<String> successful = result['successful'] ?? [];
    List<String> failed = result['failed'] ?? [];
    int total = result['total'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hasil Eksekusi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total shortcut: $total'),
                SizedBox(height: 12),
                if (successful.isNotEmpty) ...[
                  Text(
                    'Berhasil dijalankan (${successful.length}):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ...successful.map((app) => Text('✅ $app')),
                  SizedBox(height: 12),
                ],
                if (failed.isNotEmpty) ...[
                  Text(
                    'Gagal dijalankan (${failed.length}):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  ...failed.map((app) => Text('❌ $app')),
                ],
              ],
            ),
          ),
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

  void _showAddCategoryDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    String iconName = 'folder';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Kategori Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Text('Pilih Ikon:'),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildIconOption(context, 'folder', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'work', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'web', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'build', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'play_circle', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'code', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'security', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'apps', iconName, (value) => setState(() => iconName = value)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && 
                        descriptionController.text.isNotEmpty) {
                      
                      // Generate unique ID
                      String categoryId = 'category_${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Create new category
                      AppCategory newCategory = AppCategory(
                        id: categoryId,
                        name: nameController.text,
                        description: descriptionController.text,
                        iconName: iconName,
                      );
                      
                      await CategoryService.addCategory(newCategory);
                      await _loadCategories(); // Refresh categories
                      
                      Navigator.of(context).pop();
                    } else {
                      _showWarningDialog('Peringatan', 'Harap isi semua field yang wajib diisi!');
                    }
                  },
                  child: Text('Tambah'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showEditCategoryDialog(String categoryId) async {
    // Find category
    final category = _categories.firstWhere((c) => c.id == categoryId, orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder'));
    if (category.id.isEmpty) return;

    TextEditingController nameController = TextEditingController(text: category.name);
    TextEditingController descriptionController = TextEditingController(text: category.description);
    String iconName = category.iconName.isNotEmpty ? category.iconName : 'folder';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Kategori'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Text('Pilih Ikon:'),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildIconOption(context, 'folder', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'work', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'web', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'build', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'play_circle', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'code', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'security', iconName, (value) => setState(() => iconName = value)),
                        _buildIconOption(context, 'apps', iconName, (value) => setState(() => iconName = value)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                      AppCategory updated = category.copyWith(
                        name: nameController.text,
                        description: descriptionController.text,
                        iconName: iconName,
                      );
                      await CategoryService.updateCategory(updated);
                      await _loadCategories();
                      Navigator.of(context).pop();
                    } else {
                      _showWarningDialog('Peringatan', 'Harap isi semua field yang wajib diisi!');
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDeleteCategory(String categoryId) async {
    final category = _categories.firstWhere((c) => c.id == categoryId, orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder'));
    if (category.id.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Kategori'),
          content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"? Aplikasi dalam kategori ini akan dipindahkan ke kategori "Lainnya".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await CategoryService.deleteCategory(categoryId);
                await _loadCategories();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconOption(BuildContext context, String iconName, String selectedIcon, Function(String) onSelected) {
    bool isSelected = iconName == selectedIcon;
    return GestureDetector(
      onTap: () => onSelected(iconName),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Icon(
          _getIconData(iconName),
          size: 24,
          color: isSelected ? Colors.blue : Colors.grey.shade600,
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'folder':
        return Icons.folder;
      case 'work':
        return Icons.work;
      case 'web':
        return Icons.web;
      case 'build':
        return Icons.build;
      case 'play_circle':
        return Icons.play_circle;
      case 'code':
        return Icons.code;
      case 'security':
        return Icons.security;
      case 'apps':
        return Icons.apps;
      default:
        return Icons.folder;
    }
  }

  // Dialog helper methods
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
        title: Text('Enhanced Application Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Default Apps'),
            Tab(text: 'Shortcuts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Default Apps Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isLoadingDefault ? null : _refreshDefaultApps,
                      child: _isLoadingDefault
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Refresh'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingDefault
                    ? Center(child: CircularProgressIndicator())
                    : InstalledAppsSection(
                        defaultApps: _defaultApps,
                        isLoading: _isLoadingDefault,
                        onRefresh: _refreshDefaultApps,
                        onAddDefault: () {}, // TODO: Implement add default app
                        customNames: _customDefaultNames,
                        onRemoveDefault: (name) {}, // TODO: Implement remove default app
                      ),
              ),
            ],
          ),
          // Shortcuts Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showAddAppDialog,
                      child: Text('Add Shortcut'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _showAddCategoryDialog,
                      child: Text('Add Category'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isInstalling ? null : _startInstallation,
                      child: _isInstalling
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Run Selected'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingCategories
                    ? Center(child: CircularProgressIndicator())
                    : AppCategorySection(
                        categories: _categories,
                        apps: _shortcutApps,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: _onCategorySelected,
                        onAppSelectionChanged: _onAppSelectionChanged,
                        onEditApp: _onEditApp,
                        onDeleteApp: _onDeleteApp,
                        onInstallApp: _onInstallApp,
                        onAddShortcut: _showAddAppDialog,
                        onEditCategory: _showEditCategoryDialog,
                        onDeleteCategory: _confirmDeleteCategory,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
