import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/domain/inventory/inventory_models.dart';
import 'package:thermalprinter/features/inventory/inventory_screen.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;

  setUp(() {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('low-stock alert, then stock in brings it back up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final id = await storage.inventory.saveItem(
        name: 'Paneer',
        unit: StockUnit.kg,
        lowStockMilli: 2000,
      );
      await storage.inventory.record(
        stockItemId: id,
        kind: StockMovementKind.opening,
        qtyMilli: 1500,
        clientRequestId: 'r1',
      );
    });
    await tester.pumpWidget(const MaterialApp(home: InventoryScreen()));
    await settle(tester);
    expect(find.text('1 item(s) low on stock'), findsOneWidget);
    expect(find.text('Paneer: 1.5 kg'), findsOneWidget);
    expect(find.text('Off (record stock in and counts only)'), findsOneWidget);

    await tester.tap(find.text('Paneer').last);
    await settle(tester);
    expect(find.text('On hand (expected)'), findsOneWidget);
    expect(find.text('Opening stock'), findsWidgets);

    await tester.tap(find.text('Stock in'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '2.5');
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Amount paid for this quantity (optional)',
      ),
      '750',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('4 kg'), findsOneWidget);
    expect(find.textContaining('₹300.00 per kg'), findsOneWidget);
    expect(find.text('+2.5 kg'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
