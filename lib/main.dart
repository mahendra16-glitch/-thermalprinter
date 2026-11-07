import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/staff/staff_gate.dart';
import 'screens/main_navigation_screen.dart';
import 'services/storage_service.dart';
import 'queue/print_queue_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline storage & background queue processor
  await StorageService.getInstance();
  await PrintQueueManager.getInstance();

  runApp(const ThermalPrinterApp());
}

class ThermalPrinterApp extends StatelessWidget {
  const ThermalPrinterApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal POS Printer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      // The sign-in screen covers every screen and dialog while locked.
      builder: (context, child) =>
          StaffGate(navigatorKey: navigatorKey, child: child!),
      home: const MainNavigationScreen(),
    );
  }
}
