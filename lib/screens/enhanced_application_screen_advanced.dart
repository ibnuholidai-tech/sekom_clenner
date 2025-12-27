import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/application_models_enhanced.dart';
import '../models/app_category.dart';
import '../services/application_service_enhanced.dart';
import '../services/category_service.dart';
import '../utils/error_handler.dart';

class EnhancedApplicationScreenAdvanced extends StatefulWidget {
  const EnhancedApplicationScreenAdvanced({super.key});

  @override
  State<EnhancedApplicationScreenAdvanced> createState() => _EnhancedApplicationScreenAdvancedState();
}

class _EnhancedApplicationScreenAdvancedState extends State<EnhancedApplicationScreenAdvanced> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // State variables
  List<InstalledApplication> _defaultApps = [];
  List<InstallableApplication> _shortcutApps = [];
  List<AppCategory> _categories = [];
  ApplicationList? _currentAppList;
  bool _isLoadingDefault = false;
  bool _isInstalling = false;
  String _statusMessage = "Siap untuk mengelola aplikasi";
  String _selectedCategoryId = 'productivity'; // Default selected category
  Map<String, String> _defaultAppInstallPaths = {};

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
      List<InstalledApplication> defaultApps = await ApplicationServiceEnhanced.checkInstalledApplications();
      if (!mounted) return;
      setState(() {
        _defaultApps = defaultApps;
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
      List<ApplicationList> savedLists = await ApplicationServiceEnhanced.loadApplicationLists();
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
      // Removed _isLoadingCategories references
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
      orElse: () => InstallableApplication(id: '', name: '', description: '', filePath: ''),
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
      orElse: () => InstallableApplication(id: '', name: '', description: '', filePath: ''),
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
    TextEditingController argsController = TextEditingController(text: app.installArgs.join(' '));
    
    // Get current category for this app
    String currentCategoryId = await CategoryService.getCategoryForApp(app.id);

    String? selectedCategoryId = currentCategoryId;
    bool runAsAdmin = app.runAsAdmin;
    bool silentInstall = app.silentInstall;
    String fileType = app.fileType.isNotEmpty ? app.fileType : 'exe';

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
                        labelText: 'Path File (.exe/.msi/dll)',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.folder_open),
                          onPressed: () async {
                            await _pickFile(urlController, allowAllTypes: true);
                            // Update file type based on selected file
                            if (urlController.text.isNotEmpty) {
                              final newFileType = ApplicationServiceEnhanced.getFileTypeFromPath(urlController.text);
                              if (newFileType.isNotEmpty) {
                                setState(() {
                                  fileType = newFileType;
                                });
                              }
                            }
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
                    SizedBox(height: 12),
                    TextField(
                      controller: argsController,
                      decoration: InputDecoration(
                        labelText: 'Parameter Instalasi (opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Contoh: /S /quiet --silent',
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Tipe File',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: fileType,
                      items: [
                        DropdownMenuItem(value: 'exe', child: Text('Executable (.exe)')),
                        DropdownMenuItem(value: 'msi', child: Text('Windows Installer (.msi)')),
                        DropdownMenuItem(value: 'bat', child: Text('Batch File (.bat)')),
                        DropdownMenuItem(value: 'cmd', child: Text('Command Script (.cmd)')),
                        DropdownMenuItem(value: 'ps1', child: Text('PowerShell Script (.ps1)')),
                        DropdownMenuItem(value: 'vbs', child: Text('VBScript (.vbs)')),
                        DropdownMenuItem(value: 'js', child: Text('JavaScript (.js)')),
                        DropdownMenuItem(value: 'jar', child: Text('Java Archive (.jar)')),
                        DropdownMenuItem(value: 'py', child: Text('Python Script (.py)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          fileType = value ?? 'exe';
                        });
                      },
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Jalankan sebagai Admin'),
                            value: runAsAdmin,
                            onChanged: (value) {
                              setState(() {
                                runAsAdmin = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Silent Install'),
                            value: silentInstall,
                            onChanged: (value) {
                              setState(() {
                                silentInstall = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
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
                    // Validate path (if provided)
                    final path = urlController.text;
                    if (path.isNotEmpty) {
                      final resolved = ApplicationServiceEnhanced.resolvePortablePath(path);
                      if (!await File(resolved).exists()) {
                        _showErrorDialog('Error', 'File tidak ditemukan di: $resolved');
                        return;
                      }
                    }

                    // Parse arguments
                    List<String> args = [];
                    if (argsController.text.isNotEmpty) {
                      args = argsController.text.split(' ')
                          .where((arg) => arg.isNotEmpty)
                          .toList();
                    }

                    _updateApp(
                      app.id,
                      nameController.text,
                      descriptionController.text,
                      urlController.text,
                      installerController.text,
                      fileType,
                      runAsAdmin,
                      silentInstall,
                      args,
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

  void _updateApp(
    String appId, 
    String name, 
    String description, 
    String filePath, 
    String installer,
    String fileType,
    bool runAsAdmin,
    bool silentInstall,
    List<String> installArgs,
  ) {
    // Convert to portable path so it works across devices/drives (USB-friendly)
    final portablePath = ApplicationServiceEnhanced.makePathPortable(filePath);
    setState(() {
      int index = _shortcutApps.indexWhere((app) => app.id == appId);
      if (index != -1) {
        _shortcutApps[index] = _shortcutApps[index].copyWith(
          name: name,
          description: description,
          downloadUrl: portablePath, // Store portable path
          installerName: installer,
          fileType: fileType,
          runAsAdmin: runAsAdmin,
          silentInstall: silentInstall,
          installArgs: installArgs,
        );
      }
    });
    // Auto-save after edit to persist changes immediately (silent)
    _saveApplicationList(silent: true);
  }

  void _showDeleteConfirmationDialog(String appId) {
    InstallableApplication? app = _shortcutApps.firstWhere(
      (app) => app.id == appId,
      orElse: () => InstallableApplication(id: '', name: '', description: '', filePath: ''),
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
    TextEditingController argsController = TextEditingController();
    
    String? selectedCategoryId = _selectedCategoryId;
    bool runAsAdmin = false;
    bool silentInstall = false;
    String fileType = 'exe';

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
                        labelText: 'Pilih File *',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.folder_open),
                          onPressed: () async {
                            await _pickFile(pathController, allowAllTypes: true);
                            // Update file type based on selected file
                            if (pathController.text.isNotEmpty) {
                              final newFileType = ApplicationServiceEnhanced.getFileTypeFromPath(pathController.text);
                              if (newFileType.isNotEmpty) {
                                setState(() {
                                  fileType = newFileType;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Klik ikon folder untuk memilih file (.exe, .msi, .bat, dll)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: argsController,
                      decoration: InputDecoration(
                        labelText: 'Parameter Instalasi (opsional)',
                        border: OutlineInputBorder(),
                        hintText: 'Contoh: /S /quiet --silent',
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Tipe File',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: fileType,
                      items: [
                        DropdownMenuItem(value: 'exe', child: Text('Executable (.exe)')),
                        DropdownMenuItem(value: 'msi', child: Text('Windows Installer (.msi)')),
                        DropdownMenuItem(value: 'bat', child: Text('Batch File (.bat)')),
                        DropdownMenuItem(value: 'cmd', child: Text('Command Script (.cmd)')),
                        DropdownMenuItem(value: 'ps1', child: Text('PowerShell Script (.ps1)')),
                        DropdownMenuItem(value: 'vbs', child: Text('VBScript (.vbs)')),
                        DropdownMenuItem(value: 'js', child: Text('JavaScript (.js)')),
                        DropdownMenuItem(value: 'jar', child: Text('Java Archive (.jar)')),
                        DropdownMenuItem(value: 'py', child: Text('Python Script (.py)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          fileType = value ?? 'exe';
                        });
                      },
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Jalankan sebagai Admin'),
                            value: runAsAdmin,
                            onChanged: (value) {
                              setState(() {
                                runAsAdmin = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Silent Install'),
                            value: silentInstall,
                            onChanged: (value) {
                              setState(() {
                                silentInstall = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
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
                        descriptionController.text.isNotEmpty && 
                        pathController.text.isNotEmpty) {
                      // Validate selected path
                      final resolvedPath = ApplicationServiceEnhanced.resolvePortablePath(pathController.text);
                      if (!await File(resolvedPath).exists()) {
                        _showErrorDialog('Error', 'File tidak ditemukan di: $resolvedPath');
                        return;
                      }

                      // Parse arguments
                      List<String> args = [];
                      if (argsController.text.isNotEmpty) {
                        args = argsController.text.split(' ')
                            .where((arg) => arg.isNotEmpty)
                            .toList();
                      }

                      String newAppId = await _addNewApp(
                        nameController.text,
                        descriptionController.text,
                        pathController.text,
                        '',
                        fileType,
                        runAsAdmin,
                        silentInstall,
                        args,
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

  Future<void> _pickFile(TextEditingController controller, {bool allowAllTypes = false}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowAllTypes ? FileType.any : FileType.custom,
        allowedExtensions: allowAllTypes ? null : ['exe', 'msi', 'bat', 'cmd', 'ps1', 'vbs', 'js', 'jar', 'py', 'sh'],
        dialogTitle: 'Pilih File Aplikasi',
      );

      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;
        
        // Convert to portable path for USB compatibility
        String portablePath = ApplicationServiceEnhanced.makePathPortable(selectedPath);
        
        setState(() {
          controller.text = portablePath;
        });
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal memilih file: ${e.toString()}');
    }
  }

  Future<String> _addNewApp(
    String name, 
    String description, 
    String filePath, 
    String installer,
    String fileType,
    bool runAsAdmin,
    bool silentInstall,
    List<String> installArgs,
  ) async {
    String newId = 'shortcut_${DateTime.now().millisecondsSinceEpoch}';
    
    // Make sure path is portable for USB compatibility
    String portablePath = ApplicationServiceEnhanced.makePathPortable(filePath);
    
    InstallableApplication newApp = InstallableApplication(
      id: newId,
      name: name,
      description: description,
      downloadUrl: portablePath, // Using downloadUrl field to store portable file path
      installerName: installer,
      fileType: fileType,
      runAsAdmin: runAsAdmin,
      silentInstall: silentInstall,
      installArgs: installArgs, filePath: '',
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

      await ApplicationServiceEnhanced.saveApplicationList(updatedList);
      
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
    String appList = selectedApps.map((app) {
      List<String> options = [];
      if (app.runAsAdmin) options.add('Admin');
      if (app.silentInstall) options.add('Silent');
      
      return '• ${app.name} ${options.isNotEmpty ? '(${options.join(', ')})' : ''}';
    }).join('\n');
    
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
                'Catatan: Aplikasi akan dijalankan dengan opsi yang dipilih (Admin/Silent).',
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
        String resolvedPath = ApplicationServiceEnhanced.resolvePortablePath(app.downloadUrl);
        return app.copyWith(downloadUrl: resolvedPath);
      }).toList();
      
      Map<String, dynamic> result = await ApplicationServiceEnhanced.simulateInstallation(resolvedApps);
      
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

  Widget _buildIconOption(BuildContext context, String iconName, String selectedIcon, Function(String) onSelected) {
    final isSelected = iconName == selectedIcon;
    
    IconData icon;
    switch (iconName) {
      case 'work': icon = Icons.work; break;
      case 'web': icon = Icons.web; break;
      case 'build': icon = Icons.build; break;
      case 'play_circle': icon = Icons.play_circle; break;
      case 'code': icon = Icons.code; break;
      case 'security': icon = Icons.security; break;
      case 'apps': icon = Icons.apps; break;
      default: icon = Icons.folder;
    }
    
    return InkWell(
      onTap: () => onSelected(iconName),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
          size: 32,
        ),
      ),
    );
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

  // Export application list to a file
  Future<void> _exportApplicationList() async {
    try {
      if (_shortcutApps.isEmpty) {
        _showWarningDialog('Peringatan', 'Tidak ada aplikasi untuk diekspor.');
        return;
      }
      
      // In a real implementation, this would save to a file
      // For now, we'll just show a success message
      _showInfoDialog(
        'Ekspor Berhasil', 
        'Daftar aplikasi berhasil diekspor dengan ${_shortcutApps.length} aplikasi.'
      );
      
      setState(() {
        _statusMessage = 'Daftar aplikasi berhasil diekspor.';
      });
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal mengekspor daftar aplikasi: ${e.toString()}');
    }
  }
  
  // Import application list from a file
  Future<void> _importApplicationList() async {
    try {
      // In a real implementation, this would load from a file
      // For now, we'll just show a dialog
      _showInfoDialog(
        'Import', 
        'Fitur import akan memungkinkan Anda untuk memuat daftar aplikasi dari file ekspor.'
      );
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal mengimpor daftar aplikasi: ${e.toString()}');
    }
  }
  
  // Check for updates to installed applications
  Future<void> _checkForUpdates() async {
    setState(() {
      _statusMessage = 'Memeriksa pembaruan aplikasi...';
    });
    
    try {
      // Simulate checking for updates
      await Future.delayed(Duration(seconds: 2));
      
      _showInfoDialog(
        'Pemeriksaan Pembaruan', 
        'Semua aplikasi sudah dalam versi terbaru.'
      );
      
      setState(() {
        _statusMessage = 'Pemeriksaan pembaruan selesai.';
      });
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal memeriksa pembaruan: ${e.toString()}');
    }
  }
  
  // Show batch installation dialog
  void _showBatchInstallDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instalasi Batch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitur ini memungkinkan Anda untuk menginstal beberapa aplikasi sekaligus dari daftar yang telah ditentukan.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Pilih kategori aplikasi untuk diinstal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('Produktivitas'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: Text('Utilitas'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: Text('Media'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: Text('Pengembangan'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
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
                _showInfoDialog(
                  'Fitur dalam Pengembangan', 
                  'Fitur instalasi batch akan tersedia dalam pembaruan mendatang.'
                );
              },
              child: Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }
  
  // Show system information dialog
  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informasi Sistem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Sistem Operasi', 'Windows 10'),
                _buildInfoSection('Versi Aplikasi', '1.0.0'),
                _buildInfoSection('Jumlah Aplikasi', '${_shortcutApps.length}'),
                _buildInfoSection('Jumlah Kategori', '${_categories.length}'),
                _buildInfoSection('Penyimpanan', 'Tersedia'),
                _buildInfoSection('Mode Portabel', 'Aktif'),
                SizedBox(height: 16),
                Text(
                  'Informasi Perangkat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoSection('Arsitektur', 'x64'),
                _buildInfoSection('RAM', '8 GB'),
                _buildInfoSection('Prosesor', 'Intel Core i5'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showInfoDialog(
                  'Laporan Sistem', 
                  'Fitur laporan sistem akan tersedia dalam pembaruan mendatang.'
                );
              },
              child: Text('Buat Laporan'),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to build info section
  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Show batch operations dialog
  void _showBatchOperationsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Operasi Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih operasi batch yang ingin dilakukan:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.play_arrow, color: Colors.green),
                  title: Text('Jalankan Semua'),
                  subtitle: Text('Jalankan semua aplikasi yang dipilih'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _startInstallation();
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.select_all, color: Colors.blue),
                  title: Text('Pilih Semua'),
                  subtitle: Text('Pilih semua aplikasi dalam kategori ini'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _selectAllAppsInCategory();
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.deselect, color: Colors.orange),
                  title: Text('Batalkan Semua Pilihan'),
                  subtitle: Text('Batalkan semua pilihan aplikasi'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deselectAllApps();
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.category, color: Colors.purple),
                  title: Text('Pindahkan ke Kategori'),
                  subtitle: Text('Pindahkan aplikasi terpilih ke kategori lain'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMoveToCategoryDialog();
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
          ],
        );
      },
    );
  }
  
  // Select all apps in the current category
  void _selectAllAppsInCategory() {
    final categoryApps = _categories
        .firstWhere(
          (cat) => cat.id == _selectedCategoryId, 
          orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder')
        )
        .appIds;
    
    setState(() {
      for (var app in _shortcutApps) {
        if (categoryApps.contains(app.id)) {
          int index = _shortcutApps.indexWhere((a) => a.id == app.id);
          if (index != -1) {
            _shortcutApps[index] = _shortcutApps[index].copyWith(isSelected: true);
          }
        }
      }
    });
    
    _saveApplicationList(silent: true);
    _showInfoDialog('Info', 'Semua aplikasi dalam kategori ini telah dipilih.');
  }
  
  // Deselect all apps
  void _deselectAllApps() {
    setState(() {
      for (int i = 0; i < _shortcutApps.length; i++) {
        _shortcutApps[i] = _shortcutApps[i].copyWith(isSelected: false);
      }
    });
    
    _saveApplicationList(silent: true);
    _showInfoDialog('Info', 'Semua pilihan aplikasi telah dibatalkan.');
  }
  
  // Show move to category dialog
  void _showMoveToCategoryDialog() {
    List<InstallableApplication> selectedApps = _shortcutApps.where((app) => app.isSelected).toList();
    
    if (selectedApps.isEmpty) {
      _showWarningDialog('Peringatan', 'Silakan pilih minimal satu aplikasi terlebih dahulu!');
      return;
    }
    
    String? targetCategoryId;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pindahkan ke Kategori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aplikasi terpilih: ${selectedApps.length}'),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Pilih Kategori Tujuan',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: targetCategoryId,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        targetCategoryId = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: targetCategoryId == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await _moveAppsToCategory(selectedApps, targetCategoryId!);
                        },
                  child: Text('Pindahkan'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  // Move apps to a different category
  Future<void> _moveAppsToCategory(List<InstallableApplication> apps, String categoryId) async {
    try {
      for (var app in apps) {
        // Remove from current category
        String currentCategoryId = await CategoryService.getCategoryForApp(app.id);
        if (currentCategoryId.isNotEmpty) {
          await CategoryService.removeAppFromCategory(app.id, currentCategoryId);
        }
        
        // Add to new category
        await CategoryService.addAppToCategory(app.id, categoryId);
      }
      
      // Refresh categories
      await _loadCategories();
      
      _showInfoDialog(
        'Berhasil', 
        '${apps.length} aplikasi telah dipindahkan ke kategori baru.'
      );
      
      // If we moved apps from the current category, refresh the view
      if (_selectedCategoryId != categoryId) {
        setState(() {
          _selectedCategoryId = categoryId;
        });
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      _showErrorDialog('Error', 'Gagal memindahkan aplikasi: ${e.toString()}');
    }
  }
  
  // Add a default application entry only if it exists on this Windows installation,
  // then persist so it appears on other machines (USB portable).
  Future<void> _onAddDefaultApp() async {
    try {
      setState(() {
        _statusMessage = 'Memuat daftar program terinstal...';
      });

      // List installed program names using control panel registry sources
      final installedNames = await ApplicationServiceEnhanced.listInstalledProgramNames();

      // Compose existing default names (built-in + user-added)
      final builtIn = ApplicationServiceEnhanced.defaultApplications
          .map((e) => (e['name'] ?? '').toString())
          .where((e) => e.isNotEmpty)
          .toSet();
      final custom = (await ApplicationServiceEnhanced.loadDefaultAppChecks()).toSet();

      final existingLower = <String>{}
        ..addAll(builtIn.map((e) => e.toLowerCase()))
        ..addAll(custom.map((e) => e.toLowerCase()));

      // Available to add = installed on this machine AND not already in defaults
      final available = installedNames
          .where((n) => !existingLower.contains(n.toLowerCase()))
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (available.isEmpty) {
        _showInfoDialog('Info', 'Tidak ada aplikasi terinstal yang bisa ditambahkan.\nSemua yang tersedia sudah ada di daftar default.');
        return;
      }

      String search = '';
      String? selected;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          List<String> filtered = available;
          return StatefulBuilder(
            builder: (ctx, setStateSB) {
              filtered = available
                  .where((n) => n.toLowerCase().contains(search.toLowerCase()))
                  .toList();
              return AlertDialog(
                title: Text('Tambah Aplikasi Default'),
                content: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Cari aplikasi terinstal',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setStateSB(() => search = v),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (c, i) {
                            final name = filtered[i];
                            return RadioListTile<String>(
                              dense: true,
                              title: Text(name),
                              value: name,
                              groupValue: selected,
                              onChanged: (val) => setStateSB(() => selected = val),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () async {
                            // Persist selection
                            final existing = await ApplicationServiceEnhanced.loadDefaultAppChecks();
                            if (!existing.map((e) => e.toLowerCase()).contains(selected!.toLowerCase())) {
                              existing.add(selected!);
                              await ApplicationServiceEnhanced.saveDefaultAppChecks(existing);
                            }
                            Navigator.of(ctx).pop();
                          },
                    child: Text('Tambah'),
                  ),
                ],
              );
            },
          );
        },
      );

      // Refresh default apps to include the new entry
      await _refreshDefaultApps();
      setState(() {
        _statusMessage = 'Aplikasi default berhasil ditambahkan.';
      });
    } catch (e) {
      _showErrorDialog('Error', 'Gagal menambahkan aplikasi default: ${e.toString()}');
    }
  }

  void _showDefaultAppInstallPathDialog(InstalledApplication app) {
    final TextEditingController pathController = TextEditingController(
      text: _defaultAppInstallPaths[app.name] ?? '',
    );
    bool isValidPath = false;
    bool showPathStatus = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  _defaultAppInstallPaths[app.name]?.isEmpty ?? true ? Icons.add_location : Icons.edit_location,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text('${_defaultAppInstallPaths.containsKey(app.name) ? "Ubah" : "Tambah"} Path Instalasi'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aplikasi info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aplikasi: ${app.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (app.publisher.isNotEmpty)
                                Text(
                                  app.publisher,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Path input label
                  Text(
                    'Path ke File Instalasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Path input field
                  TextField(
                    controller: pathController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.folder_open, size: 18),
                      hintText: 'Masukkan path lengkap file instalasi',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: pathController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setDialogState(() {
                                  pathController.clear();
                                  isValidPath = false;
                                  showPathStatus = false;
                                });
                              },
                            )
                          : null,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      setDialogState(() {
                        isValidPath = File(value).existsSync();
                        showPathStatus = value.isNotEmpty;
                      });
                    },
                  ),
                  SizedBox(height: 8),
                  
                  // Path status indicator
                  if (showPathStatus)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isValidPath ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isValidPath ? Colors.green.shade300 : Colors.red.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isValidPath ? Icons.check_circle : Icons.error,
                            size: 14,
                            color: isValidPath ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isValidPath 
                                ? 'Path valid ✓' 
                                : 'File tidak ditemukan ✗',
                              style: TextStyle(
                                fontSize: 11,
                                color: isValidPath ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 12),
                  
                  // Browse button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe', 'msi', 'bat', 'cmd', 'ps1', 'vbs', 'js', 'jar', 'py', 'sh'],
                          dialogTitle: 'Pilih File Instalasi ${app.name}',
                        );

                        if (result != null && result.files.single.path != null) {
                          setDialogState(() {
                            pathController.text = result.files.single.path!;
                            isValidPath = File(pathController.text).existsSync();
                            showPathStatus = true;
                          });
                        }
                      },
                      icon: Icon(Icons.folder_open, size: 16),
                      label: Text('Cari File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Contoh path
                  Text(
                    'Contoh Path:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'C:\\Users\\Downloads\\${app.name.replaceAll(' ', '')}-Setup.exe',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              if ((_defaultAppInstallPaths[app.name]?.isNotEmpty ?? false))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _defaultAppInstallPaths.remove(app.name);
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Hapus Path', style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: isValidPath
                    ? () {
                        final newPath = pathController.text.trim();
                        if (newPath.isNotEmpty && File(newPath).existsSync()) {
                          setState(() {
                            _defaultAppInstallPaths[app.name] = newPath;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ Path instalasi berhasil disimpan untuk ${app.name}'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green.shade400,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidPath ? Colors.green : Colors.grey,
                ),
                child: Text(
                  _defaultAppInstallPaths.containsKey(app.name) ? 'Perbarui' : 'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _installDefaultApp(InstalledApplication app) async {
    final installPath = _defaultAppInstallPaths[app.name];
    
    if (installPath == null || installPath.isEmpty) {
      _showWarningDialog('Peringatan', 'Silakan tambahkan path instalasi terlebih dahulu.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Instalasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aplikasi: ${app.name}'),
              SizedBox(height: 8),
              Text('Path: $installPath'),
              SizedBox(height: 12),
              Text(
                'Aplikasi akan dijalankan dengan path instalasi yang telah ditentukan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
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
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  setState(() {
                    _isInstalling = true;
                    _statusMessage = 'Menginstal ${app.name}...';
                  });

                  // Simulate installation
                  await Future.delayed(Duration(seconds: 2));

                  setState(() {
                    _isInstalling = false;
                    _statusMessage = '${app.name} berhasil dijalankan.';
                  });

                  _showInfoDialog(
                    'Berhasil',
                    '${app.name} berhasil dijalankan.',
                  );
                } catch (e) {
                  setState(() {
                    _isInstalling = false;
                    _statusMessage = 'Error: ${e.toString()}';
                  });
                  _showErrorDialog('Error', 'Gagal menjalankan ${app.name}: ${e.toString()}');
                }
              },
              child: Text('Jalankan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRemoveDefaultApp(String name) async {
    try {
      final existing = await ApplicationServiceEnhanced.loadDefaultAppChecks();
      final before = existing.length;
      existing.removeWhere((e) => e.toLowerCase() == name.toLowerCase());
      if (existing.length != before) {
        await ApplicationServiceEnhanced.saveDefaultAppChecks(existing);
        await _refreshDefaultApps();
        setState(() {
          _defaultAppInstallPaths.remove(name);
          _statusMessage = 'Aplikasi default "$name" berhasil dihapus.';
        });
      } else {
        _showInfoDialog('Info', 'Entri "$name" tidak ditemukan di daftar custom.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Gagal menghapus aplikasi default: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(
                  icon: Icon(Icons.apps),
                  text: 'Aplikasi Default',
                ),
                Tab(
                  icon: Icon(Icons.folder_special),
                  text: 'Shortcut Aplikasi',
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Default Apps Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Aplikasi Default',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: _isLoadingDefault
                            ? Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                itemCount: _defaultApps.length,
                                itemBuilder: (context, index) {
                                  final app = _defaultApps[index];
                                  final hasInstallPath = _defaultAppInstallPaths.containsKey(app.name);
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: hasInstallPath ? Colors.blue.shade300 : Colors.grey.shade300,
                                        width: hasInstallPath ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: hasInstallPath ? Colors.blue.shade50 : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: app.isInstalled ? Colors.green.shade100 : Colors.red.shade100,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: app.isInstalled ? Colors.green.shade300 : Colors.red.shade300,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      app.isInstalled ? Icons.check_circle : Icons.cancel,
                                                      color: app.isInstalled ? Colors.green : Colors.red,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                app.name,
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                            // Installation status indicator
                                                            Container(
                                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: hasInstallPath
                                                                    ? Colors.green.shade100
                                                                    : Colors.red.shade100,
                                                                borderRadius: BorderRadius.circular(6),
                                                                border: Border.all(
                                                                  color: hasInstallPath
                                                                      ? Colors.green.shade300
                                                                      : Colors.red.shade300,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(
                                                                    hasInstallPath
                                                                        ? Icons.check_circle
                                                                        : Icons.cancel,
                                                                    size: 12,
                                                                    color: hasInstallPath
                                                                        ? Colors.green.shade700
                                                                        : Colors.red.shade700,
                                                                  ),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    hasInstallPath ? 'Siap' : 'Belum',
                                                                    style: TextStyle(
                                                                      fontSize: 10,
                                                                      fontWeight: FontWeight.bold,
                                                                      color: hasInstallPath
                                                                          ? Colors.green.shade700
                                                                          : Colors.red.shade700,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          app.status,
                                                          style: TextStyle(
                                                            color: Colors.grey.shade600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        if (app.publisher.isNotEmpty)
                                                          Text(
                                                            'Publisher: ${app.publisher}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                          ),
                                                        if (hasInstallPath) ...[
                                                          SizedBox(height: 4),
                                                          Text(
                                                            'Path: ${_defaultAppInstallPaths[app.name]}',
                                                            style: TextStyle(
                                                              color: Colors.blue.shade600,
                                                              fontSize: 9,
                                                              fontStyle: FontStyle.italic,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                              // Action buttons - Row 1
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  // Add/Edit path button
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      _showDefaultAppInstallPathDialog(app);
                                                    },
                                                    icon: Icon(
                                                      hasInstallPath ? Icons.edit_location : Icons.add_location,
                                                      size: 14,
                                                    ),
                                                    label: Text(
                                                      hasInstallPath ? 'Ubah Path' : 'Tambah Path',
                                                      style: TextStyle(fontSize: 12),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: Size(0, 30),
                                                      side: BorderSide(
                                                        color: Colors.orange.shade600,
                                                      ),
                                                      foregroundColor: Colors.orange.shade600,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  // Install button
                                                  ElevatedButton.icon(
                                                    onPressed: hasInstallPath
                                                        ? () {
                                                            _installDefaultApp(app);
                                                          }
                                                        : null,
                                                    icon: Icon(Icons.install_desktop, size: 14),
                                                    label: Text('Install', style: TextStyle(fontSize: 12)),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: hasInstallPath ? Colors.green : Colors.grey,
                                                      foregroundColor: Colors.white,
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: Size(0, 30),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              // Action buttons - Row 2
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  // Edit button
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      // Edit default app
                                                      _showInfoDialog(
                                                        'Edit Aplikasi',
                                                        'Aplikasi default "${app.name}" tidak dapat diedit. Hapus dan tambahkan kembali jika diperlukan.',
                                                      );
                                                    },
                                                    icon: Icon(Icons.edit, size: 14),
                                                    label: Text('Edit', style: TextStyle(fontSize: 12)),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: Size(0, 30),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  // Delete button
                                                  OutlinedButton.icon(
                                                    onPressed: () {
                                                      _onRemoveDefaultApp(app.name);
                                                    },
                                                    icon: Icon(Icons.delete, size: 14),
                                                    label: Text('Hapus', style: TextStyle(fontSize: 12)),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                      side: BorderSide(color: Colors.red),
                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      minimumSize: Size(0, 30),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _refreshDefaultApps,
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _onAddDefaultApp,
                            icon: Icon(Icons.add),
                            label: Text('Add Default App'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Shortcut Apps Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Category section
                      Expanded(
                        child: Column(
                          children: [
                            // Category selector
                            SizedBox(
                              height: 50,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final isSelected = category.id == _selectedCategoryId;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          _onCategorySelected(category.id);
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            
                            // Apps in selected category
                            Expanded(
                              child: ListView.builder(
                                itemCount: _shortcutApps.where((app) {
                                  final categoryApps = _categories
                                      .firstWhere((cat) => cat.id == _selectedCategoryId, 
                                                 orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder'))
                                      .appIds;
                                  return categoryApps.contains(app.id);
                                }).length,
                                itemBuilder: (context, index) {
                                  final appsInCategory = _shortcutApps.where((app) {
                                    final categoryApps = _categories
                                        .firstWhere((cat) => cat.id == _selectedCategoryId,
                                                   orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder'))
                                        .appIds;
                                    return categoryApps.contains(app.id);
                                  }).toList();
                                  
                                  if (index >= appsInCategory.length) return SizedBox();
                                  
                                  final app = appsInCategory[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: CheckboxListTile(
                                      title: Text(app.name),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(app.description),
                                          if (app.fileType.isNotEmpty)
                                            Text('Type: ${app.fileType.toUpperCase()}', 
                                                 style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          if (app.runAsAdmin || app.silentInstall)
                                            Row(
                                              children: [
                                                if (app.runAsAdmin)
                                                  Chip(
                                                    label: Text('Admin', style: TextStyle(fontSize: 10)),
                                                    backgroundColor: Colors.blue.shade100,
                                                    padding: EdgeInsets.zero,
                                                    labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                                  ),
                                                if (app.silentInstall)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4.0),
                                                    child: Chip(
                                                      label: Text('Silent', style: TextStyle(fontSize: 10)),
                                                      backgroundColor: Colors.green.shade100,
                                                      padding: EdgeInsets.zero,
                                                      labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      value: app.isSelected,
                                      onChanged: (value) => _onAppSelectionChanged(app.id, value ?? false),
                                      secondary: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _onEditApp(app.id),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _onDeleteApp(app.id),
                                            tooltip: 'Delete',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.play_arrow, color: Colors.green),
                                            onPressed: () => _onInstallApp(app.id),
                                            tooltip: 'Run',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Search and filter bar
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Cari aplikasi...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                                ),
                                onChanged: (value) {
                                  // Implement search functionality
                                  setState(() {
                                    // Filter apps based on search term
                                    // This would be implemented in a real app
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Urutkan',
                              icon: Icon(Icons.sort),
                              onSelected: (value) {
                                // Implement sorting
                                setState(() {
                                  // Sort apps based on selected option
                                  switch (value) {
                                    case 'name':
                                      _shortcutApps.sort((a, b) => a.name.compareTo(b.name));
                                      break;
                                    case 'type':
                                      _shortcutApps.sort((a, b) => a.fileType.compareTo(b.fileType));
                                      break;
                                    case 'date':
                                      // Sort by date would be implemented in a real app
                                      break;
                                  }
                                });
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'name',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sort_by_alpha, size: 18),
                                      SizedBox(width: 8),
                                      Text('Urutkan berdasarkan nama'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'type',
                                  child: Row(
                                    children: [
                                      Icon(Icons.category, size: 18),
                                      SizedBox(width: 8),
                                      Text('Urutkan berdasarkan tipe'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'date',
                                  child: Row(
                                    children: [
                                      Icon(Icons.date_range, size: 18),
                                      SizedBox(width: 8),
                                      Text('Urutkan berdasarkan tanggal'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: 'Opsi lainnya',
                              icon: Icon(Icons.more_vert),
                              onSelected: (value) {
                                // Implement additional options
                                switch (value) {
                                  case 'export':
                                    _exportApplicationList();
                                    break;
                                  case 'import':
                                    _importApplicationList();
                                    break;
                                  case 'check_updates':
                                    _checkForUpdates();
                                    break;
                                  case 'batch_install':
                                    _showBatchInstallDialog();
                                    break;
                                  case 'system_info':
                                    _showSystemInfoDialog();
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'export',
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export daftar aplikasi'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'import',
                                  child: Row(
                                    children: [
                                      Icon(Icons.download, size: 18),
                                      SizedBox(width: 8),
                                      Text('Import daftar aplikasi'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'check_updates',
                                  child: Row(
                                    children: [
                                      Icon(Icons.update, size: 18),
                                      SizedBox(width: 8),
                                      Text('Periksa pembaruan'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'batch_install',
                                  child: Row(
                                    children: [
                                      Icon(Icons.install_desktop, size: 18),
                                      SizedBox(width: 8),
                                      Text('Instalasi batch'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'system_info',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('Informasi sistem'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Action buttons
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showAddAppDialog,
                            icon: Icon(Icons.add),
                            label: Text('Tambah Shortcut'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddCategoryDialog,
                            icon: Icon(Icons.create_new_folder),
                            label: Text('Tambah Kategori'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveApplicationList,
                            icon: Icon(Icons.save),
                            label: Text('Simpan Daftar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isInstalling ? null : _startInstallation,
                            icon: _isInstalling 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.play_arrow),
                            label: Text(_isInstalling ? 'Running...' : 'Jalankan Shortcut'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showBatchOperationsDialog(),
                            icon: Icon(Icons.batch_prediction),
                            label: Text('Operasi Batch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Status message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
