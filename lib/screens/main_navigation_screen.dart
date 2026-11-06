import 'package:flutter/material.dart';

import '../features/menu/menu_screen.dart';
import '../features/orders/orders_screen.dart';
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

  const _Destination(this.label, this.icon, this.selectedIcon);
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _startupError;

  static const _destinations = [
    _Destination(
      'Tables',
      Icons.table_restaurant_outlined,
      Icons.table_restaurant,
    ),
    _Destination('Orders', Icons.receipt_long_outlined, Icons.receipt_long),
    _Destination('Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu),
    _Destination('Settings', Icons.settings_outlined, Icons.settings),
  ];

  final List<Widget> _screens = const [
    TablesScreen(),
    OrdersScreen(),
    MenuScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (mounted && s.legacyImportError != null) {
        setState(() => _startupError = s.legacyImportError);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
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
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
      ],
    );

    void select(int i) => setState(() => _currentIndex = i);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
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
        selectedIndex: _currentIndex,
        onDestinationSelected: select,
        destinations: [
          for (final d in _destinations)
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
