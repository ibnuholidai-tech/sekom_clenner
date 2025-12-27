import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/app_category.dart';
import '../models/application_models.dart';

class AppCategorySection extends StatelessWidget {
  final List<AppCategory> categories;
  final List<InstallableApplication> apps;
  final String selectedCategoryId;
  final Function(String) onCategorySelected;
  final Function(String, bool) onAppSelectionChanged;
  final Function(String) onEditApp;
  final Function(String) onDeleteApp;
  final Function(String) onInstallApp;
  final VoidCallback? onAddShortcut;
  final Function(String)? onEditCategory;
  final Function(String)? onDeleteCategory;

  const AppCategorySection({
    super.key,
    required this.categories,
    required this.apps,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onAppSelectionChanged,
    required this.onEditApp,
    required this.onDeleteApp,
    required this.onInstallApp,
    this.onAddShortcut,
    this.onEditCategory,
    this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryTabs(context),
        const SizedBox(height: 16),
        _buildAppsList(context),
      ],
    );
  }

  Widget _buildCategoryTabs(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selectedCategoryId;
          
          // Count apps in this category
          final appCount = apps.where((app) => 
            category.appIds.contains(app.id)).length;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => onCategorySelected(category.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category.iconName),
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: 6),
                    // Edit category button
                    GestureDetector(
                      onTap: () {
                        if (onEditCategory != null) onEditCategory!(category.id);
                      },
                      child: Icon(
                        Icons.edit,
                        size: 14,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 6),
                    // Delete category button (small)
                    GestureDetector(
                      onTap: () {
                        if (onDeleteCategory != null) onDeleteCategory!(category.id);
                      },
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: isSelected ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    if (appCount > 0) ...[
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Colors.white.withOpacity(0.3) 
                            : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$appCount',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppsList(BuildContext context) {
    // Filter apps by selected category
    final selectedCategory = categories.firstWhere(
      (cat) => cat.id == selectedCategoryId,
      orElse: () => categories.first,
    );
    
    final categoryApps = apps.where((app) => 
      selectedCategory.appIds.contains(app.id)).toList();
    
    if (categoryApps.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(selectedCategory.iconName),
                size: 64,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 16),
              Text(
                'Belum ada aplikasi dalam kategori ${selectedCategory.name}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tambahkan aplikasi baru atau pindahkan aplikasi ke kategori ini',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onAddShortcut,
                    icon: Icon(Icons.add),
                    label: Text('Add Shortcut'),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onEditCategory != null) onEditCategory!(selectedCategory.id);
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Category'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        itemCount: categoryApps.length,
        itemBuilder: (context, index) {
          final app = categoryApps[index];
          return _buildAppItem(context, app);
        },
      ),
    );
  }

  Widget _buildAppItem(BuildContext context, InstallableApplication app) {
    // Determine installation status
    bool isInstallPathAvailable = app.filePath.isNotEmpty;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: app.isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
          width: app.isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: app.isSelected ? Colors.blue.shade50 : Colors.white,
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
          child: InkWell(
            onTap: () => onAppSelectionChanged(app.id, !app.isSelected),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Checkbox
                      Checkbox(
                        value: app.isSelected,
                        onChanged: (value) {
                          onAppSelectionChanged(app.id, value ?? false);
                        },
                      ),
                      SizedBox(width: 12),
                      // App icon placeholder
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Icon(
                          _getAppIcon(app.name),
                          size: 24,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(width: 16),
                      // App info
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
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Installation status indicator
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isInstallPathAvailable 
                                      ? Colors.green.shade100 
                                      : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isInstallPathAvailable 
                                        ? Colors.green.shade300 
                                        : Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isInstallPathAvailable 
                                          ? Icons.check_circle 
                                          : Icons.cancel,
                                        size: 14,
                                        color: isInstallPathAvailable 
                                          ? Colors.green.shade700 
                                          : Colors.red.shade700,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        isInstallPathAvailable ? 'Siap' : 'Belum',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isInstallPathAvailable 
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
                              app.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (app.filePath.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'Path: ${app.filePath}',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ] else ...[
                              SizedBox(height: 4),
                              Text(
                                'Tambahkan path instalasi',
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
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
                          _showInstallPathDialog(context, app);
                        },
                        icon: Icon(
                          app.filePath.isEmpty ? Icons.add_location : Icons.edit_location,
                          size: 16,
                        ),
                        label: Text(
                          app.filePath.isEmpty ? 'Tambah Path' : 'Ubah Path',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
                          side: BorderSide(
                            color: Colors.orange.shade600,
                          ),
                          foregroundColor: Colors.orange.shade600,
                        ),
                      ),
                      SizedBox(width: 8),
                      // Install button (only if path is available)
                      ElevatedButton.icon(
                        onPressed: isInstallPathAvailable 
                          ? () => onInstallApp(app.id)
                          : null,
                        icon: Icon(
                          Icons.install_desktop,
                          size: 16,
                        ),
                        label: Text('Install'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInstallPathAvailable 
                            ? Colors.green 
                            : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Run button
                      ElevatedButton.icon(
                        onPressed: () => onInstallApp(app.id),
                        icon: Icon(Icons.play_arrow, size: 16),
                        label: Text('Jalankan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
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
                        onPressed: () => onEditApp(app.id),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                      SizedBox(width: 8),
                      // Delete button
                      OutlinedButton.icon(
                        onPressed: () => onDeleteApp(app.id),
                        icon: Icon(Icons.delete, size: 16),
                        label: Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInstallPathDialog(BuildContext context, InstallableApplication app) {
    final TextEditingController pathController = TextEditingController(
      text: app.filePath,
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
                  app.filePath.isEmpty ? Icons.add_location : Icons.edit_location,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text('${app.filePath.isEmpty ? "Tambah" : "Ubah"} Path Instalasi'),
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
                              if (app.description.isNotEmpty)
                                Text(
                                  app.description,
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
              if (app.filePath.isNotEmpty)
                TextButton(
                  onPressed: () {
                    onDeleteApp(app.id);
                    Navigator.pop(context);
                  },
                  child: Text('Hapus App', style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                onPressed: isValidPath
                    ? () {
                        final newPath = pathController.text.trim();
                        if (newPath.isNotEmpty && File(newPath).existsSync()) {
                          onEditApp(app.id);
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
                  app.filePath.isEmpty ? 'Simpan' : 'Perbarui',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'work': return Icons.work;
      case 'web': return Icons.web;
      case 'build': return Icons.build;
      case 'play_circle': return Icons.play_circle;
      case 'code': return Icons.code;
      case 'security': return Icons.security;
      default: return Icons.folder;
    }
  }

  IconData _getAppIcon(String appName) {
    String lowerName = appName.toLowerCase();
    
    if (lowerName.contains('office')) return Icons.work;
    if (lowerName.contains('firefox')) return Icons.web;
    if (lowerName.contains('chrome')) return Icons.web;
    if (lowerName.contains('edge')) return Icons.web;
    if (lowerName.contains('winrar') || lowerName.contains('7-zip')) return Icons.archive;
    if (lowerName.contains('rustdesk') || lowerName.contains('teamviewer')) return Icons.desktop_windows;
    if (lowerName.contains('directx')) return Icons.games;
    if (lowerName.contains('vlc')) return Icons.play_circle;
    if (lowerName.contains('notepad')) return Icons.edit_note;
    
    return Icons.apps;
  }
}
