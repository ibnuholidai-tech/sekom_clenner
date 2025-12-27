import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/application_models_enhanced.dart';

class DefaultAppsTab extends StatefulWidget {
  final List<InstalledApplication> defaultApps;
  final bool isLoadingDefault;
  final Function refreshDefaultApps;
  final Function onAddDefaultApp;
  final Function(String)? onEditApp;
  final Function(String)? onDeleteApp;
  final Function(String)? onInstallApp;

  const DefaultAppsTab({
    super.key,
    required this.defaultApps,
    required this.isLoadingDefault,
    required this.refreshDefaultApps,
    required this.onAddDefaultApp,
    this.onEditApp,
    this.onDeleteApp,
    this.onInstallApp,
  });

  @override
  State<DefaultAppsTab> createState() => _DefaultAppsTabState();
}

class _DefaultAppsTabState extends State<DefaultAppsTab> {
  String _searchQuery = '';
  Map<String, String> _appInstallPaths = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari aplikasi...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          SizedBox(height: 16),

          Expanded(
            child: widget.isLoadingDefault
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: widget.defaultApps.length,
                    itemBuilder: (context, index) {
                      final app = widget.defaultApps[index];

                      if (_searchQuery.isNotEmpty &&
                          !app.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return SizedBox.shrink();
                      }

                      final hasInstallPath = _appInstallPaths.containsKey(app.name);

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
                                                'Path: ${_appInstallPaths[app.name]}',
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
                                          _showInstallPathDialog(app);
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
                                                if (widget.onInstallApp != null) {
                                                  widget.onInstallApp!(app.name);
                                                }
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
                                          if (widget.onEditApp != null) {
                                            widget.onEditApp!(app.name);
                                          }
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
                                          if (widget.onDeleteApp != null) {
                                            widget.onDeleteApp!(app.name);
                                          }
                                          setState(() {
                                            _appInstallPaths.remove(app.name);
                                          });
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
                onPressed: () => widget.refreshDefaultApps(),
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => widget.onAddDefaultApp(),
                icon: Icon(Icons.add),
                label: Text('Add Default App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInstallPathDialog(InstalledApplication app) {
    final TextEditingController pathController = TextEditingController(
      text: _appInstallPaths[app.name] ?? '',
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
                  _appInstallPaths[app.name]?.isEmpty ?? true ? Icons.add_location : Icons.edit_location,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text('${_appInstallPaths.containsKey(app.name) ? "Ubah" : "Tambah"} Path Instalasi'),
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
              if ((_appInstallPaths[app.name]?.isNotEmpty ?? false))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _appInstallPaths.remove(app.name);
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
                            _appInstallPaths[app.name] = newPath;
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
                  _appInstallPaths.containsKey(app.name) ? 'Perbarui' : 'Simpan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}