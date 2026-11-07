import 'package:flutter/material.dart';

import '../features/menu/menu_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/reports/reports_screen.dart';
import '../domain/staff/staff_models.dart';
import '../features/shifts/shift_screen.dart';
import '../features/staff/staff_screen.dart';
import '../features/tables/tables_screen.dart';
import '../services/storage_service.dart';
import 'settings_screen.dart';

/// Top-level navigation: a bottom bar on phones, a side rail on tablets.
/// Printers, the print queue and history live under Settings.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _Destination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  /// Shown when the signed-in person has any of these (empty: always).
  final List<Permission> needsAny;

  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.screen, [
    this.needsAny = const [],
  ]);
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String _current = 'Tables';
  String? _startupError;
  StorageService? _s;

  static const _destinations = [
    _Destination(
      'Tables',
      Icons.table_restaurant_outlined,
      Icons.table_restaurant,
      TablesScreen(),
    ),
    _Destination(
      'Orders',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      OrdersScreen(),
    ),
    _Destination(
      'Shift',
      Icons.point_of_sale_outlined,
      Icons.point_of_sale,
      ShiftScreen(),
      [Permission.manageShift, Permission.recordExpense],
    ),
    _Destination(
      'Reports',
      Icons.insert_chart_outlined,
      Icons.insert_chart,
      ReportsScreen(),
      [Permission.viewReports],
    ),
    _Destination(
      'Menu',
      Icons.restaurant_menu_outlined,
      Icons.restaurant_menu,
      MenuScreen(),
      [Permission.viewMenu, Permission.editMenu],
    ),
    _Destination(
      'Settings',
      Icons.settings_outlined,
      Icons.settings,
      SettingsScreen(),
    ),
  ];

  @override
  void dispose() {
    _s?.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  List<_Destination> _visible() {
    final session = _s?.session;
    return [
      for (final d in _destinations)
        if (d.needsAny.isEmpty ||
            session == null ||
            d.needsAny.any(session.can))
          d,
    ];
  }

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (!mounted) return;
      _s = s;
      s.session.addListener(_onSession);
      setState(() => _startupError = s.legacyImportError);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final visible = _visible();
    var index = visible.indexWhere((d) => d.label == _current);
    if (index < 0) index = 0;
    final body = Column(
      children: [
        if (_startupError != null)
          MaterialBanner(
            backgroundColor: Colors.amber.shade100,
            leading: const Icon(Icons.warning_amber_rounded),
            content: Text(
              '$_startupError\nYour earlier data is kept unchanged and the '
              'import will be tried again next time the app starts.',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => _startupError = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              for (final d in visible)
                KeyedSubtree(key: ValueKey(d.label), child: d.screen),
            ],
          ),
        ),
        if (_s?.session.current != null) _AccountBar(storage: _s!),
      ],
    );

    void select(int i) => setState(() => _current = visible[i].label);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in visible)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: select,
        destinations: [
          for (final d in visible)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

/// Who is signed in, with Lock and Change PIN. Shown only while staff
/// login is on.
class _AccountBar extends StatelessWidget {
  final StorageService storage;

  const _AccountBar({required this.storage});

  @override
  Widget build(BuildContext context) {
    final u = storage.session.current!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${u.name} · ${u.role.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => changeMyPin(context),
                child: const Text('Change PIN'),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.lock, size: 18),
                label: const Text('Lock'),
                onPressed: () => storage.staff.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
