# Sekom UI Sample Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the modern Sekom Cleaner UI to match the provided sample screens with a blue top header, horizontal icon navigation, pale content background, and sample-style cards while preserving all current pages.

**Architecture:** `ModernMainScreen` becomes the app shell with a responsive top navigation bar and eight page targets. `AppTheme` and shared modern widgets provide the visual tokens so existing pages inherit the sample look. Existing feature screens remain responsible for their own behavior.

**Tech Stack:** Flutter, Material 3, Riverpod, existing widget tests in `flutter_test`.

---

## Files

- Modify: `test/ui_test.dart`
  - Add a failing widget test for the sample top navigation and eight menu labels.
  - Update the existing optimization navigation test name/expectations from sidebar language to top navigation language.
- Modify: `lib/screens/modern_main_screen.dart`
  - Replace sidebar shell with sample-inspired top header and horizontal navigation.
  - Add `ModernAppScreen` as the `Application Manager` page target.
- Modify: `lib/theme/app_theme.dart`
  - Tune global page/card/header colors, card radius, and subtle shadow tokens.
- Modify: `lib/widgets/modern/modern_card.dart`
  - Align shared card/header radius and shadow defaults with the new sample tokens.
- Modify: `lib/widgets/modern/modern_pill.dart`
  - Keep API stable and reduce radius slightly so pills/cards fit the sample UI.
- Modify: `lib/screens/modern/modern_shortcut_screen.dart`
  - Remove the extra modern page header so the embedded shortcut page resembles the sample layout.
- Modify: `lib/screens/modern/modern_battery_screen.dart`
  - Remove the extra modern page header so the embedded battery page resembles the sample layout.
- Modify: `lib/screens/modern/modern_testing_screen.dart`
  - Remove the extra modern page header so the embedded testing page resembles the sample layout.

---

### Task 1: Add Failing Top Navigation Widget Test

**Files:**
- Modify: `test/ui_test.dart`

- [ ] **Step 1: Update the shell smoke test**

Replace the first test in `test/ui_test.dart` with this version:

```dart
testWidgets('renders sample top navigation with all pages', (tester) async {
  await pumpApp(tester);

  expect(find.byKey(const ValueKey('sampleTopNavigation')), findsOneWidget);
  expect(find.text('SEKOM Group'), findsOneWidget);

  const labels = [
    'System Cleaner',
    'Application Manager',
    'Shortcut',
    'Battery Health',
    'Optimization',
    'Info System',
    'Testing',
    'Reset',
  ];

  for (final label in labels) {
    expect(find.text(label), findsWidgets);
  }

  expect(find.text('Pilihan aktif'), findsOneWidget);
  expect(find.text('Estimasi bersih'), findsOneWidget);
  expect(find.text('Total ditemukan'), findsOneWidget);
  expect(find.text('Scan Ulang'), findsOneWidget);
  expect(find.text('Bersihkan'), findsOneWidget);
});
```

- [ ] **Step 2: Update the navigation behavior test**

Replace the `sidebar switches to optimization tab` test in `test/ui_test.dart` with:

```dart
testWidgets('top navigation switches to optimization tab', (tester) async {
  await pumpApp(tester);

  await tester.tap(find.text('Optimization').first);
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.byKey(const ValueKey('sampleTopNavigation')), findsOneWidget);
  expect(find.text('Optimization'), findsWidgets);
  expect(find.text('Performa'), findsOneWidget);
  expect(find.text('18 aksi'), findsOneWidget);
});
```

- [ ] **Step 3: Add an Application Manager route check**

Add this test inside the existing `Modern Sekom Cleaner UI` group:

```dart
testWidgets('top navigation opens application manager page', (tester) async {
  await pumpApp(tester);

  await tester.tap(find.text('Application Manager').first);
  await tester.pump(const Duration(milliseconds: 300));

  expect(find.text('Aplikasi Default'), findsWidgets);
  expect(find.text('Shortcut Aplikasi'), findsWidgets);
});
```

- [ ] **Step 4: Run the targeted test and confirm RED**

Run:

```powershell
flutter test test/ui_test.dart
```

Expected: FAIL because `sampleTopNavigation` and/or `Application Manager` are not present in the current shell.

- [ ] **Step 5: Commit the failing test**

```powershell
git add -- test/ui_test.dart
git commit -m "test: cover sample top navigation"
```

---

### Task 2: Replace Sidebar Shell With Sample Top Navigation

**Files:**
- Modify: `lib/screens/modern_main_screen.dart`

- [ ] **Step 1: Add the Application Manager import**

Ensure imports include:

```dart
import 'modern_app_screen.dart';
```

- [ ] **Step 2: Replace the navigation item model**

Use this model so labels, icons, and pages live together:

```dart
class _NavItem {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.builder,
  });
}
```

- [ ] **Step 3: Replace `_items` with eight page targets**

Use this list in `_ModernMainScreenState`:

```dart
static final List<_NavItem> _items = [
  _NavItem(
    icon: Icons.cleaning_services,
    label: 'System Cleaner',
    builder: (_) => const ModernSystemCleanerScreen(),
  ),
  _NavItem(
    icon: Icons.grid_view_rounded,
    label: 'Application Manager',
    builder: (_) => const ModernAppScreen(),
  ),
  _NavItem(
    icon: Icons.delete_outline_rounded,
    label: 'Shortcut',
    builder: (_) => const ModernShortcutScreen(),
  ),
  _NavItem(
    icon: Icons.battery_charging_full,
    label: 'Battery Health',
    builder: (_) => const ModernBatteryScreen(),
  ),
  _NavItem(
    icon: Icons.auto_awesome,
    label: 'Optimization',
    builder: (_) => const ModernOptimizationScreen(),
  ),
  _NavItem(
    icon: Icons.info,
    label: 'Info System',
    builder: (_) => const ModernInfoSystemScreen(),
  ),
  _NavItem(
    icon: Icons.science,
    label: 'Testing',
    builder: (_) => const ModernTestingScreen(),
  ),
  _NavItem(
    icon: Icons.refresh,
    label: 'Reset',
    builder: (_) => const ModernResetScreen(),
  ),
];
```

- [ ] **Step 4: Replace `_buildBody`**

Use:

```dart
Widget _buildBody() {
  final item = _items[_selectedIndex];
  return KeyedSubtree(
    key: ValueKey('page-${item.label}'),
    child: item.builder(context),
  );
}
```

- [ ] **Step 5: Replace `build` with a vertical sample shell**

Use:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppTheme.pageBackground,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          _TopHeader(
            items: _items,
            selectedIndex: _selectedIndex,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppTheme.pageBackground,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 6: Add `_TopHeader`**

Add this widget below `_NavItem`:

```dart
class _TopHeader extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TopHeader({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sampleTopNavigation'),
      width: double.infinity,
      height: 162,
      decoration: const BoxDecoration(
        color: AppTheme.sampleHeader,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Text(
            'SEKOM Group',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minItemWidth = 136.0;
                final naturalWidth = constraints.maxWidth / items.length;
                final itemWidth = naturalWidth < minItemWidth
                    ? minItemWidth
                    : naturalWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: itemWidth * items.length,
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          SizedBox(
                            width: itemWidth,
                            child: _TopNavItem(
                              item: items[i],
                              selected: selectedIndex == i,
                              onTap: () => onSelected(i),
                            ),
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
    );
  }
}
```

- [ ] **Step 7: Add `_TopNavItem`**

Add this widget below `_TopHeader`:

```dart
class _TopNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TopNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.78);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: item.label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(item.icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 3,
                width: selected ? 72 : 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Remove obsolete sidebar classes**

Delete the full class declarations named `_Sidebar`, `_SidebarHeader`, `_SidebarItem`, and `_SidebarFooter` from `lib/screens/modern_main_screen.dart`. Also remove the `_railExpanded` field from `_ModernMainScreenState` because the new top navigation has no collapse state.

- [ ] **Step 9: Run targeted test and confirm the shell portion is GREEN**

Run:

```powershell
flutter test test/ui_test.dart
```

Expected: tests may still fail only if shared theme/wrapper changes are needed, but `sampleTopNavigation`, `SEKOM Group`, and `Application Manager` should now be found.

- [ ] **Step 10: Commit shell changes**

```powershell
git add -- lib/screens/modern_main_screen.dart
git commit -m "feat: add sample top navigation shell"
```

---

### Task 3: Align Theme And Shared Modern Widgets

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/widgets/modern/modern_card.dart`
- Modify: `lib/widgets/modern/modern_pill.dart`

- [ ] **Step 1: Update sample theme tokens**

In `AppTheme`, update or add these constants:

```dart
static const Color sampleHeader = Color(0xFF97C2EF);
static const Color primary = Color(0xFF2F80F2);
static const Color primaryDark = Color(0xFF285E9F);
static const Color accent = Color(0xFF54A0FF);

static const Color pageBackground = Color(0xFFF4F6FB);
static const Color sidebar = Color(0xFFF4F6FB);
static const Color cardBackground = Color(0xFFF7F9FE);
static const Color cardBorder = Color(0xFFE3E8F1);
```

- [ ] **Step 2: Update radius and shadow tokens**

In `AppTheme`, use:

```dart
static double get cardRadius => 8.0;
static double get pillRadius => 999.0;

static List<BoxShadow> get cardShadow => const [
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 10,
    offset: Offset(0, 3),
  ),
];
```

- [ ] **Step 3: Update theme component radius**

In `buildLightTheme`, set button and card border radius to 8:

```dart
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(8),
),
```

Apply this to `cardTheme`, `elevatedButtonTheme`, and `outlinedButtonTheme`.

- [ ] **Step 4: Make `ModernPageHeader` sample-compatible**

In `lib/widgets/modern/modern_card.dart`, keep the public constructor unchanged and change only the `ModernPageHeader` `ModernCard` wrapper arguments:

```dart
radius: 8,
shadow: AppTheme.cardShadow,
padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
```

Leave the existing `LayoutBuilder` body in `ModernPageHeader` intact.

- [ ] **Step 5: Reduce high radii in modern pills**

In `lib/widgets/modern/modern_pill.dart`, make these exact radius edits:

- In `ModernSelectablePill`, change `InkWell` and outer `Container` radii from `14` to `8`.
- In `ModernSelectablePill`, change the leading icon container radius from `8` to `6`.
- In `ModernActionPill`, change `InkWell` and outer `Container` radii from `12` to `8`.
- In `ModernCompactSelectTile`, change `InkWell` radius from `10` to `8`.
- In `ModernCompactSelectTile`, change outer `AnimatedContainer` radius from `16` to `8`.
- In `ModernCompactSelectTile`, change the leading icon container radius from `8` to `6`.
- In `ModernBadge`, change the badge radius from `10` to `8`.

The resulting rectangular tile code should use:

```dart
borderRadius: BorderRadius.circular(8),
```

Keep circular controls and `BorderRadius.circular(999)` unchanged.

- [ ] **Step 6: Run tests**

Run:

```powershell
flutter test test/ui_test.dart
```

Expected: PASS for the updated top navigation tests. If a test fails because text changed, keep the production UI wording aligned with the sample and update only the assertion that names old shell behavior.

- [ ] **Step 7: Commit theme/widget changes**

```powershell
git add -- lib/theme/app_theme.dart lib/widgets/modern/modern_card.dart lib/widgets/modern/modern_pill.dart
git commit -m "style: align modern theme with sample ui"
```

---

### Task 4: Remove Extra Headers From Embedded Sample Pages

**Files:**
- Modify: `lib/screens/modern/modern_shortcut_screen.dart`
- Modify: `lib/screens/modern/modern_battery_screen.dart`
- Modify: `lib/screens/modern/modern_testing_screen.dart`

- [ ] **Step 1: Simplify Shortcut wrapper**

Replace the `build` method in `ModernShortcutScreen` with:

```dart
@override
Widget build(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: const UninstallerScreen(),
  );
}
```

Remove unused imports:

```dart
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
```

- [ ] **Step 2: Simplify Battery wrapper**

Replace the `build` method in `ModernBatteryScreen` with:

```dart
@override
Widget build(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: const BatteryScreen(),
  );
}
```

Remove unused imports:

```dart
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
```

- [ ] **Step 3: Simplify Testing wrapper**

Replace the `build` method in `ModernTestingScreen` with:

```dart
@override
Widget build(BuildContext context) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: const TestingScreen(),
  );
}
```

Remove unused imports:

```dart
import '../../theme/app_theme.dart';
import '../../widgets/modern/modern_card.dart';
```

- [ ] **Step 4: Run targeted tests**

Run:

```powershell
flutter test test/ui_test.dart
```

Expected: PASS. Existing tests for reset confirmation and browser selection still pass.

- [ ] **Step 5: Commit wrapper changes**

```powershell
git add -- lib/screens/modern/modern_shortcut_screen.dart lib/screens/modern/modern_battery_screen.dart lib/screens/modern/modern_testing_screen.dart
git commit -m "style: simplify embedded sample page wrappers"
```

---

### Task 5: Final Verification

**Files:**
- No code changes unless verification reveals a concrete issue.

- [ ] **Step 1: Run Flutter analysis**

Run:

```powershell
flutter analyze
```

Expected: no new errors from edited files.

- [ ] **Step 2: Run focused widget tests**

Run:

```powershell
flutter test test/ui_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run the smoke widget test**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: PASS. If it still expects old shell-specific wording, update the smoke test to assert `SEKOM Group`, `System Cleaner`, `Browser Cleanup`, and `Bersihkan`.

- [ ] **Step 4: Optional desktop launch check**

Run:

```powershell
flutter run -d windows
```

Expected: the app starts with the sample-style blue header, eight horizontal nav items, and the System Cleaner page visible.

- [ ] **Step 5: Final commit if verification required small fixes**

If Step 1-4 required small fixes, commit them:

```powershell
git add -- test/ui_test.dart test/widget_test.dart lib/screens/modern_main_screen.dart lib/theme/app_theme.dart lib/widgets/modern/modern_card.dart lib/widgets/modern/modern_pill.dart lib/screens/modern/modern_shortcut_screen.dart lib/screens/modern/modern_battery_screen.dart lib/screens/modern/modern_testing_screen.dart
git commit -m "fix: polish sample ui refresh verification"
```
