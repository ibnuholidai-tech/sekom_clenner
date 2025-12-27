import 'package:flutter/material.dart';
import 'package:sekom_clenner/widgets/modern_loading.dart';
import 'package:sekom_clenner/widgets/glass_card.dart';
import 'package:sekom_clenner/widgets/animated_list_wrapper.dart';
import 'package:sekom_clenner/config/service_locator.dart';
import 'package:sekom_clenner/services/system_service.dart';
import 'package:sekom_clenner/utils/result.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:badges/badges.dart' as badges;

/// Example screen yang mendemonstrasikan penggunaan fitur-fitur modern
class ModernExampleScreen extends StatefulWidget {
  const ModernExampleScreen({super.key});

  @override
  State<ModernExampleScreen> createState() => _ModernExampleScreenState();
}

class _ModernExampleScreenState extends State<ModernExampleScreen> {
  bool _isLoading = false;
  List<String> _items = [];
  String _statusMessage = 'Ready';

  // Menggunakan Service Locator
  late final SystemService _systemService;

  @override
  void initState() {
    super.initState();
    // Get service dari service locator
    _systemService = locate<SystemService>();
    _loadData();
  }

  /// Example: Load data dengan Result pattern
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading data...';
    });

    // Simulate async operation dengan Result pattern
    final result = await _fetchDataWithErrorHandling();

    result.fold(
      (failure) {
        // Handle error
        setState(() {
          _statusMessage = 'Error: ${failure.message}';
          _isLoading = false;
        });
      },
      (data) {
        // Handle success
        setState(() {
          _items = data;
          _statusMessage = 'Data loaded successfully';
          _isLoading = false;
        });
      },
    );
  }

  /// Example: Async operation dengan Result pattern
  Future<Result<List<String>>> _fetchDataWithErrorHandling() async {
    return ResultHelper.tryCatch(
      action: () async {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        // Return dummy data
        return [
          'Chrome Browser',
          'Edge Browser',
          'Firefox Browser',
          'Temp Files',
          'Cache Files',
          'Downloads Folder',
        ];
      },
      onError: (error) =>
          ServerFailure(message: 'Failed to fetch data: $error'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Modern Features Demo'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: ModernLoading.overlay(
        isLoading: _isLoading,
        message: 'Loading...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card dengan Glass Effect
              _buildStatusCard(),

              const SizedBox(height: 24),

              // Loading Indicators Demo
              _buildLoadingIndicatorsDemo(),

              const SizedBox(height: 24),

              // Glass Cards Demo
              _buildGlassCardsDemo(),

              const SizedBox(height: 24),

              // Animated List Demo
              _buildAnimatedListDemo(),

              const SizedBox(height: 24),

              // Badges Demo
              _buildBadgesDemo(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh),
        label: const Text('Reload Data'),
      ).animate().scale(duration: 300.ms).fadeIn(),
    );
  }

  Widget _buildStatusCard() {
    return GlassCardHover(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Glass card tapped!')));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: AutoSizeText(
                  'System Status',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              badges.Badge(
                badgeContent: Text(
                  _items.length.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                child: const Icon(Icons.notifications),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingIndicatorsDemo() {
    return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loading Indicators',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildLoadingItem('Circle', ModernLoading.circle(size: 40)),
                  _buildLoadingItem('Wave', ModernLoading.wave(size: 40)),
                  _buildLoadingItem('Pulse', ModernLoading.pulse(size: 40)),
                  _buildLoadingItem('Ring', ModernLoading.ring(size: 40)),
                  _buildLoadingItem('Ripple', ModernLoading.ripple(size: 40)),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingItem(String label, Widget loading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 60, height: 60, child: Center(child: loading)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildGlassCardsDemo() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Glass Cards',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    height: 120,
                    child: const Center(
                      child: Text(
                        'Light Glass',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassCardDark(
                    height: 120,
                    child: const Center(
                      child: Text(
                        'Dark Glass',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildAnimatedListDemo() {
    return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Animated List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No items yet. Click reload to load data.'),
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: AnimatedListWrapper(
                    itemCount: _items.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(_items[index]),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tapped: ${_items[index]}'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(begin: -0.2, end: 0);
  }

  Widget _buildBadgesDemo() {
    return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Badges',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  badges.Badge(
                    badgeContent: const Text(
                      '3',
                      style: TextStyle(color: Colors.white),
                    ),
                    child: const Icon(Icons.shopping_cart, size: 32),
                  ),
                  badges.Badge(
                    badgeContent: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.green,
                    ),
                    child: const Icon(Icons.mail, size: 32),
                  ),
                  badges.Badge(
                    badgeContent: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.orange,
                    ),
                    child: const Icon(Icons.notifications, size: 32),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: -0.2, end: 0);
  }
}
