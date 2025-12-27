import 'package:flutter/material.dart';
import '../models/application_models_enhanced.dart';
import '../models/app_category.dart';
import '../services/application_service_enhanced.dart';
import '../services/category_service.dart';
import '../utils/error_handler.dart';

class ModernAppScreen extends StatefulWidget {
  const ModernAppScreen({super.key});

  @override
  State<ModernAppScreen> createState() => _ModernAppScreenState();
}

class _ModernAppScreenState extends State<ModernAppScreen> with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;
  
  // State variables
  List<InstalledApplication> _defaultApps = [];
  List<InstallableApplication> _shortcutApps = [];
  List<AppCategory> _categories = [];
  bool _isLoadingDefault = false;
  String _statusMessage = "Siap untuk mengelola aplikasi";
  String _selectedCategoryId = 'productivity'; // Default selected category
  
  // Search and filter
  String _searchQuery = '';
  
  // View options
  bool _gridView = false; // Default to list view
  
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
          _shortcutApps = List.from(savedLists.first.applications);
        });
      } else {
        if (!mounted) return;
        setState(() {
          _shortcutApps = [];
        });
      }
    } catch (e, st) {
      GlobalErrorHandler.report(e, st);
      if (!mounted) return;
      setState(() {
        _statusMessage = "Error loading shortcuts: ${e.toString()}";
        _shortcutApps = [];
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
                _buildDefaultAppsTab(),
                
                // Shortcut Apps Tab
                _buildShortcutAppsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAppsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
           
          // Search bar
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
           
          // Apps list
          Expanded(
            child: _isLoadingDefault
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _defaultApps.length,
                    itemBuilder: (context, index) {
                      final app = _defaultApps[index];
                      
                      // Apply search filter
                      if (_searchQuery.isNotEmpty && 
                          !app.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return SizedBox.shrink();
                      }
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            app.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(app.status),
                              if (app.publisher.isNotEmpty)
                                Text(
                                  'Publisher: ${app.publisher}',
                                  style: TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: app.isInstalled ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              app.isInstalled ? Icons.check_circle : Icons.cancel,
                              color: app.isInstalled ? Colors.green : Colors.red,
                            ),
                          ),
                          isThreeLine: app.publisher.isNotEmpty,
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
                onPressed: _onAddDefaultApp,
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

  Widget _buildShortcutAppsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_special, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Category selector
          SizedBox(
            height: 50,
            child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category.id == _selectedCategoryId;
                      
                      IconData iconData;
                      switch (category.iconName) {
                        case 'work': iconData = Icons.work; break;
                        case 'web': iconData = Icons.web; break;
                        case 'build': iconData = Icons.build; break;
                        case 'play_circle': iconData = Icons.play_circle; break;
                        case 'code': iconData = Icons.code; break;
                        case 'security': iconData = Icons.security; break;
                        case 'apps': iconData = Icons.apps; break;
                        default: iconData = Icons.folder;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Icon(
                            iconData,
                            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                            size: 18,
                          ),
                          label: Text(category.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                            }
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      );
                    },
                  ),
          ),
          
          SizedBox(height: 16),
           
          // Search and filter bar
          Row(
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
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _gridView = !_gridView;
                  });
                },
                tooltip: _gridView ? 'List View' : 'Grid View',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Urutkan',
                icon: Icon(Icons.sort),
                onSelected: (value) {
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
                  }
                  );
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
            ],
          ),
          
          SizedBox(height: 16),
          
          // Apps list
          Expanded(
            child: _buildAppsList(),
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
    );
  }

  Widget _buildAppsList() {
    // Get apps for the selected category
    final categoryApps = _shortcutApps.where((app) {
      final categoryAppIds = _categories
          .firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => AppCategory(id: '', name: '', description: '', iconName: 'folder'),
          )
          .appIds;
      
      // Apply category filter
      bool inCategory = categoryAppIds.contains(app.id);
      
      // Apply search filter
      bool matchesSearch = _searchQuery.isEmpty || 
          app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return inCategory && matchesSearch;
    }).toList();
    
    if (categoryApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada aplikasi dalam kategori ini',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddAppDialog,
              icon: Icon(Icons.add),
              label: Text('Tambah Aplikasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    // Grid view
    if (_gridView) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: categoryApps.length,
        itemBuilder: (context, index) {
          final app = categoryApps[index];
          
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                // Toggle selection
                setState(() {
                  int idx = _shortcutApps.indexWhere((a) => a.id == app.id);
                  if (idx != -1) {
                    _shortcutApps[idx] = _shortcutApps[idx].copyWith(
                      isSelected: !app.isSelected,
                    );
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getFileTypeIcon(app.fileType),
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            app.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Checkbox(
                          value: app.isSelected,
                          onChanged: (value) {
                            setState(() {
                              int idx = _shortcutApps.indexWhere((a) => a.id == app.id);
                              if (idx != -1) {
                                _shortcutApps[idx] = _shortcutApps[idx].copyWith(
                                  isSelected: value ?? false,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        app.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () {},
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(4),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () {},
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(4),
                          tooltip: 'Delete',
                        ),
                        IconButton(
                          icon: Icon(Icons.play_arrow, size: 18, color: Colors.green),
                          onPressed: () {},
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.all(4),
                          tooltip: 'Run',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    
    // List view
    return ListView.builder(
      itemCount: categoryApps.length,
      itemBuilder: (context, index) {
        final app = categoryApps[index];
        
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          child: CheckboxListTile(
            title: Text(
              app.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.description),
                if (app.fileType.isNotEmpty)
                  Text(
                    'Type: ${app.fileType.toUpperCase()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
            onChanged: (value) {
              setState(() {
                int idx = _shortcutApps.indexWhere((a) => a.id == app.id);
                if (idx != -1) {
                  _shortcutApps[idx] = _shortcutApps[idx].copyWith(
                    isSelected: value ?? false,
                  );
                }
              });
            },
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {},
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {},
                  tooltip: 'Delete',
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () {},
                  tooltip: 'Run',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'exe': return Icons.apps;
      case 'msi': return Icons.install_desktop;
      case 'bat': return Icons.terminal;
      case 'cmd': return Icons.terminal;
      case 'ps1': return Icons.code;
      case 'vbs': return Icons.code;
      case 'js': return Icons.javascript;
      case 'jar': return Icons.coffee;
      case 'py': return Icons.code;
      default: return Icons.insert_drive_file;
    }
  }
  
  void _showAddAppDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Tambah Shortcut Baru'),
            ],
          ),
          content: Text('Fitur tambah aplikasi akan tersedia dalam pembaruan mendatang.'),
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
  
  void _onAddDefaultApp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Tambah Aplikasi Default'),
            ],
          ),
          content: Text('Fitur tambah aplikasi default akan tersedia dalam pembaruan mendatang.'),
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
}
