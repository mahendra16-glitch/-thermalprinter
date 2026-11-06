import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'printers_screen.dart';
import 'queue_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    StorageService.getInstance().then((s) {
      if (mounted && s.legacyImportError != null) {
        setState(() => _startupError = s.legacyImportError);
      }
    });
  }

  final List<Widget> _screens = const [
    PrintersScreen(),
    QueueScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.print_rounded),
            label: 'Printers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
