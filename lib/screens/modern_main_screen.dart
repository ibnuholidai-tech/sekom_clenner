import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'modern/modern_system_cleaner_screen.dart';
import 'modern/modern_battery_screen.dart';
import 'modern/modern_optimization_screen.dart';
import 'modern/modern_info_system_screen.dart';
import 'modern/modern_reset_screen.dart';
import 'modern/modern_testing_screen.dart';
import 'modern/modern_shortcut_screen.dart';
import 'state/status_message_provider.dart';

/// Main shell of the modernized Sekom Cleaner UI.
///
/// Provides:
/// - A left navigation rail (Settings header + 7 tabs + footer).
/// - A right-hand content pane that swaps between modern screens.
class ModernMainScreen extends ConsumerStatefulWidget {
  const ModernMainScreen({super.key});

  @override
  ConsumerState<ModernMainScreen> createState() => _ModernMainScreenState();
}

class _ModernMainScreenState extends ConsumerState<ModernMainScreen> {
  int _selectedIndex = 0;
  bool _railExpanded = true;

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.cleaning_services_outlined,
      label: 'System Cleaner',
      tint: Color(0xFFE6EFFC),
      activeTint: AppTheme.primary,
    ),
    _NavItem(
      icon: Icons.delete_sweep_outlined,
      label: 'Shortcut',
      tint: Color(0xFFFCE7EE),
      activeTint: Color(0xFFB8336A),
    ),
    _NavItem(
      icon: Icons.battery_charging_full_outlined,
      label: 'Battery Health',
      tint: Color(0xFFE3F4E5),
      activeTint: Color(0xFF1B7A3B),
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      label: 'Optimization',
      tint: Color(0xFFEFE9FB),
      activeTint: Color(0xFF6D49C1),
    ),
    _NavItem(
      icon: Icons.info_outline,
      label: 'Info System',
      tint: Color(0xFFE0F4F1),
      activeTint: Color(0xFF0E7C6C),
    ),
    _NavItem(
      icon: Icons.science_outlined,
      label: 'Testing',
      tint: Color(0xFFFCEFD9),
      activeTint: Color(0xFFB7791F),
    ),
    _NavItem(
      icon: Icons.refresh,
      label: 'Reset',
      tint: Color(0xFFFCE6E6),
      activeTint: Color(0xFFB91C1C),
    ),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const ModernSystemCleanerScreen();
      case 1:
        return const ModernShortcutScreen();
      case 2:
        return const ModernBatteryScreen();
      case 3:
        return const ModernOptimizationScreen();
      case 4:
        return const ModernInfoSystemScreen();
      case 5:
        return const ModernTestingScreen();
      case 6:
        return const ModernResetScreen();
      default:
        return const ModernSystemCleanerScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusMessage = ref.watch(statusMessageProvider);
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              items: _items,
              selectedIndex: _selectedIndex,
              expanded: _railExpanded,
              onSelected: (i) => setState(() => _selectedIndex = i),
              onToggle: () =>
                  setState(() => _railExpanded = !_railExpanded),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildBody()),
                  _StatusBar(message: statusMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color tint;
  final Color activeTint;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.tint,
    required this.activeTint,
  });
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final width = expanded ? 230.0 : 78.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.sidebar,
        border: Border(
          right: BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarHeader(expanded: expanded),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                return _SidebarItem(
                  item: items[i],
                  selected: selectedIndex == i,
                  expanded: expanded,
                  onTap: () => onSelected(i),
                );
              },
            ),
          ),
          _SidebarFooter(expanded: expanded, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool expanded;
  const _SidebarHeader({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pintasan & tools',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? item.activeTint : Colors.transparent;
    final iconColor = selected ? Colors.white : item.activeTint;
    final fg = selected ? Colors.white : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: expanded ? '' : item.label,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment:
                    expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.18)
                          : item.tint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(item.icon, size: 18, color: iconColor),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  const _SidebarFooter({required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'I',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'by Ibnu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: onToggle,
            tooltip: expanded ? 'Persempit' : 'Perlebar',
            icon: Icon(
              expanded ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String message;
  const _StatusBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.isEmpty ? 'Siap.' : message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text(
            'Sekom Cleaner',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
