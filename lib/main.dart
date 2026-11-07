import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/staff/staff_gate.dart';
import 'screens/error_log_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/error_log.dart';
import 'services/storage_service.dart';
import 'queue/print_queue_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLog.instance.install();
  if (kReleaseMode) {
    // Instead of a red error screen: a short note; details are in the log.
    ErrorWidget.builder = (details) => const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This part of the screen could not be shown. The error was saved '
            'in Settings > App error log.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Initialize offline storage & background queue processor. If the data
  // cannot be opened, say so instead of starting with nothing.
  try {
    await StorageService.getInstance();
    await PrintQueueManager.getInstance();
  } catch (e, st) {
    await ErrorLog.instance.record(e, st, source: 'startup');
    runApp(StartupErrorApp(error: e));
    return;
  }

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
