import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/application_models.dart';
import '../services/application_service.dart';

class InstalledAppsSection extends StatefulWidget {
  final List<InstalledApplication> defaultApps;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onAddDefault;
  final Set<String> customNames;
  final void Function(String name) onRemoveDefault;
  final void Function(InstallableApplication app)? onAddInstallPath;
  final void Function(InstallableApplication app)? onInstallApp;

  const InstalledAppsSection({
    super.key,
    required this.defaultApps,
    required this.isLoading,
    required this.onRefresh,
    required this.onAddDefault,
    required this.customNames,
    required this.onRemoveDefault,
    this.onAddInstallPath,
    this.onInstallApp,
  });

  @override
  State<InstalledAppsSection> createState() => _InstalledAppsSectionState();
}

class _InstalledAppsSectionState extends State<InstalledAppsSection> {
  List<InstallableApplication> _installPaths = [];

  @override
  void initState() {
    super.initState();
    _loadInstallPaths();
  }

  Future<void> _loadInstallPaths() async {
    try {
      List<ApplicationList> savedLists = await ApplicationService.loadApplicationLists();
      if (savedLists.isNotEmpty) {
        setState(() {
          _installPaths = savedLists.first.applications;
        });
      }
    } catch (e) {
      // Silently fail if no saved paths
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.apps, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Aplikasi Default',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Add Install Path button
                    IconButton(
                      onPressed: widget.isLoading ? null : _showAddInstallPathDialog,
                      icon: Icon(Icons.add_location_alt),
                      tooltip: 'Tambah Path Instalasi',
                    ),
                    IconButton(
                      onPressed: widget.isLoading ? null : widget.onAddDefault,
                      icon: Icon(Icons.add),
                      tooltip: 'Tambah Aplikasi Default',
                    ),
                    IconButton(
                      onPressed: widget.isLoading ? null : widget.onRefresh,
                      icon: widget.isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.refresh),
                      tooltip: 'Refresh Status',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            if (widget.isLoading && widget.defaultApps.isEmpty)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Memeriksa aplikasi default...'),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: widget.defaultApps.length,
                  itemBuilder: (context, index) {
                    final app = widget.defaultApps[index];
                    return _buildDefaultAppItem(app);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAppItem(InstalledApplication app) {
    Color statusColor = app.isInstalled ? Colors.green : Colors.orange;
    IconData statusIcon = app.isInstalled ? Icons.check_circle : Icons.download;
    String statusText = app.isInstalled ? 'Terinstal' : 'Belum Terinstal';
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: app.isInstalled ? Colors.green.shade50 : Colors.orange.shade50,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      app.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons - Show: Add Path (if uninstalled), Edit, Install (if uninstalled), Delete
              if (!app.isInstalled) ...[
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.add_location_alt, color: Colors.blue.shade600, size: 18),
                  tooltip: 'Tambah Path Instalasi',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showAddInstallPathForApp(app.name),
                ),
              ],
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.green.shade600, size: 18),
                tooltip: 'Edit Aplikasi',
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showEditAppDialog(app),
              ),
              // Install button - only for uninstalled apps
              if (!app.isInstalled) ...[
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.download_for_offline_outlined, color: Colors.purple.shade600, size: 18),
                  tooltip: 'Instal Aplikasi',
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showInstallDialog(app),
                ),
              ],
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                tooltip: 'Hapus dari Aplikasi Default',
                padding: EdgeInsets.all(4),
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _showDeleteConfirmationDialog(app),
              ),
            ],
          ),
          if (!app.isInstalled) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Perlu diinstal',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showEditAppDialog(InstalledApplication app) {
    TextEditingController pathController = TextEditingController();
    String selectedFilePath = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Edit: ${app.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12),
                    Text(
                      'Tambah path instalasi untuk melakukan instalasi otomatis',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: pathController,
                      decoration: InputDecoration(
                        labelText: 'Path File (.exe / .msi)',
                        hintText: 'C:\\path\\to\\installer.exe',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.folder_open),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe', 'msi'],
                          dialogTitle: 'Pilih File Instalasi untuk ${app.name}',
                        );
                        if (result != null) {
                          setState(() {
                            selectedFilePath = result.files.first.path ?? '';
                            pathController.text = selectedFilePath;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    if (pathController.text.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blue.shade600, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Path siap untuk diinstal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: pathController.text.isEmpty
                      ? null
                      : () {
                          String portablePath = ApplicationService.makePathPortable(selectedFilePath);
                          
                          InstallableApplication newApp = InstallableApplication(
                            id: 'default_${app.name}_${DateTime.now().millisecondsSinceEpoch}',
                            name: app.name,
                            description: 'Instalasi untuk ${app.name}',
                            downloadUrl: portablePath,
                            installerName: selectedFilePath.split('\\').last,
                            filePath: portablePath,
                          );
                          
                          widget.onAddInstallPath?.call(newApp);
                          Navigator.of(ctx).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${app.name} siap diinstal. Silakan klik Instal atau ke tab Shortcut Aplikasi.')),
                          );
                        },
                  icon: Icon(Icons.save),
                  label: Text('Simpan & Instal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddInstallPathDialog() async {
    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController pathController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Path Instalasi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Aplikasi',
                    hintText: 'Contoh: My Custom App',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Deskripsi singkat aplikasi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pathController,
                        decoration: InputDecoration(
                          labelText: 'Path File (.exe / .msi)',
                          hintText: 'C:\\path\\to\\app.exe',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickFileForPath(pathController),
                      icon: Icon(Icons.folder_open),
                      label: Text('Browse'),
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
              onPressed: () {
                if (nameController.text.isNotEmpty && pathController.text.isNotEmpty) {
                  _addInstallPathApp(
                    nameController.text,
                    descriptionController.text,
                    pathController.text,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama dan path tidak boleh kosong')),
                  );
                }
              },
              child: Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showAddInstallPathForApp(String appName) async {
    TextEditingController pathController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Path Instalasi untuk $appName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pilih file instalasi (.exe atau .msi) untuk $appName'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pathController,
                        decoration: InputDecoration(
                          labelText: 'Path File',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickFileForPath(pathController),
                      icon: Icon(Icons.folder_open),
                      label: Text('Browse'),
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
              onPressed: () {
                if (pathController.text.isNotEmpty) {
                  String portablePath = ApplicationService.makePathPortable(pathController.text);
                  
                  InstallableApplication newApp = InstallableApplication(
                    id: 'default_${DateTime.now().millisecondsSinceEpoch}',
                    name: appName,
                    description: 'Path instalasi untuk $appName',
                    downloadUrl: portablePath,
                    installerName: pathController.text.split('\\').last,
                    filePath: portablePath,
                  );
                  
                  widget.onAddInstallPath?.call(newApp);
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Path instalasi untuk $appName berhasil ditambahkan')),
                  );
                }
              },
              child: Text('Simpan Path'),
            ),
          ],
        );
      },
    );
  }

  void _addInstallPathApp(String name, String description, String filePath) {
    String portablePath = ApplicationService.makePathPortable(filePath);
    
    InstallableApplication newApp = InstallableApplication(
      id: 'custom_install_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description.isNotEmpty ? description : 'Custom installation path',
      downloadUrl: portablePath,
      installerName: filePath.split('\\').last,
      filePath: portablePath,
    );
    
    setState(() {
      _installPaths.add(newApp);
    });
    
    widget.onAddInstallPath?.call(newApp);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Path instalasi untuk "$name" berhasil ditambahkan')),
    );
  }

  Future<void> _pickFileForPath(TextEditingController controller) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe', 'msi'],
        dialogTitle: 'Pilih File Aplikasi (.exe/.msi)',
      );

      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;
        setState(() {
          controller.text = selectedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih file: ${e.toString()}')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(InstalledApplication app) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus dari Aplikasi Default?'),
          content: Text('Yakin ingin menghapus "${app.name}" dari daftar aplikasi default yang dipantau?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onRemoveDefault(app.name);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${app.name} dihapus dari daftar default')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showInstallDialog(InstalledApplication app) {
    TextEditingController pathController = TextEditingController();
    String selectedFilePath = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Instal: ${app.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih file installer (.exe atau .msi) untuk melakukan instalasi otomatis',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: pathController,
                      decoration: InputDecoration(
                        labelText: 'Path File Installer',
                        hintText: 'C:\\path\\to\\installer.exe',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.folder_open),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['exe', 'msi'],
                          dialogTitle: 'Pilih File Instalasi untuk ${app.name}',
                        );
                        if (result != null) {
                          setState(() {
                            selectedFilePath = result.files.first.path ?? '';
                            pathController.text = selectedFilePath;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    if (pathController.text.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'File siap diinstal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Catatan: Installer akan dijalankan sesuai tipe file (EXE atau MSI)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: pathController.text.isEmpty
                      ? null
                      : () async {
                          String portablePath = ApplicationService.makePathPortable(selectedFilePath);
                          
                          InstallableApplication installApp = InstallableApplication(
                            id: 'install_${app.name}_${DateTime.now().millisecondsSinceEpoch}',
                            name: app.name,
                            description: 'Instalasi untuk ${app.name}',
                            downloadUrl: portablePath,
                            installerName: selectedFilePath.split('\\').last,
                            filePath: portablePath,
                          );
                          
                          // Call the onInstallApp callback if provided
                          widget.onInstallApp?.call(installApp);
                          
                          Navigator.of(ctx).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${app.name} instalasi dimulai...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: Icon(Icons.download_for_offline_outlined),
                  label: Text('Instal Sekarang'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
