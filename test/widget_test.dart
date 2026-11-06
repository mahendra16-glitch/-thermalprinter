import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/main.dart';
import 'package:thermalprinter/services/storage_service.dart';

import 'support/test_db.dart';

void main() {
  testWidgets('ThermalPrinterApp smoke test', (WidgetTester tester) async {
    final db = openTestDatabase();
    StorageService.forTesting(db);

    await tester.pumpWidget(const ThermalPrinterApp());
    expect(find.byType(ThermalPrinterApp), findsOneWidget);
    expect(find.text('Printers'), findsWidgets);

    // Let pending database work finish before closing it.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await db.close();
    });
    StorageService.resetForTesting();
  });
}
