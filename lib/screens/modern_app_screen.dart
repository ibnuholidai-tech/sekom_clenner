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
          // Modern Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, 210, 0.7, 0.55).toColor(),
                  HSLColor.fromAHSL(1, 220, 0.7, 0.50).toColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HSLColor.fromAHSL(0.3, 215, 0.7, 0.5).toColor(),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.apps_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aplikasi Default',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola aplikasi yang terinstall di sistem',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
           
          // Modern Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari aplikasi...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
            
          const SizedBox(height: 20),
           
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
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: app.isInstalled 
                                ? Colors.green.withOpacity(0.3) 
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            app.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: app.isInstalled 
                                      ? Colors.green.shade50 
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: app.isInstalled 
                                        ? Colors.green.shade200 
                                        : Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  app.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: app.isInstalled 
                                        ? Colors.green.shade800 
                                        : Colors.red.shade800,
                                  ),
                                ),
                              ),
                              if (app.publisher.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        app.publisher,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: app.isInstalled
                                    ? [Colors.green.shade300, Colors.green.shade500]
                                    : [Colors.red.shade300, Colors.red.shade500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (app.isInstalled ? Colors.green : Colors.red).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              app.isInstalled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          isThreeLine: app.publisher.isNotEmpty,
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 16),
           
          // Modern Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _refreshDefaultApps,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _onAddDefaultApp,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
          // Modern Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromAHSL(1, 150, 0.6, 0.5).toColor(),
                  HSLColor.fromAHSL(1, 170, 0.6, 0.45).toColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HSLColor.fromAHSL(0.3, 160, 0.6, 0.5).toColor(),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.folder_special_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shortcut Aplikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola aplikasi favorit untuk akses cepat',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Enhanced Category Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category.id == _selectedCategoryId;
                
                IconData iconData;
                switch (category.iconName) {
                  case 'work': iconData = Icons.work_outline_rounded; break;
                  case 'web': iconData = Icons.language_rounded; break;
                  case 'build': iconData = Icons.build_circle_outlined; break;
                  case 'play_circle': iconData = Icons.play_circle_outline_rounded; break;
                  case 'code': iconData = Icons.code_rounded; break;
                  case 'security': iconData = Icons.security_rounded; break;
                  case 'apps': iconData = Icons.apps_rounded; break;
                  default: iconData = Icons.folder_open_rounded;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  HSLColor.fromColor(Theme.of(context).primaryColor).withLightness(0.5).toColor(),
                                  Theme.of(context).primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            iconData,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
           
          // Modern Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari aplikasi...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: _gridView
                      ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
                      : null,
                  color: _gridView ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gridView ? Colors.transparent : Colors.grey.shade200),
                  boxShadow: _gridView
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  icon: Icon(
                    _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: _gridView ? Colors.white : Colors.grey.shade700,
                  ),
                  onPressed: () {
                    setState(() {
                      _gridView = !_gridView;
                    });
                  },
                  tooltip: _gridView ? 'List View' : 'Grid View',
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Urutkan',
                icon: Icon(Icons.sort_rounded, color: Colors.grey.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  setState(() {
                    switch (value) {
                      case 'name':
                        _shortcutApps.sort((a, b) => a.name.compareTo(b.name));
                        break;
                      case 'type':
                        _shortcutApps.sort((a, b) => a.fileType.compareTo(b.fileType));
                        break;
                    }
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Nama (A-Z)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'type',
                    child: Row(
                      children: [
                        Icon(Icons.category_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Tipe File'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(Icons.sort_rounded, color: Colors.grey),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Apps list
          Expanded(
            child: _buildAppsList(),
          ),
          
          const SizedBox(height: 16),
          
          // Modern Status Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
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
