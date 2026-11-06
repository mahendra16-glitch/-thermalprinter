import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/features/menu/menu_screen.dart';
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

  Future<void> settleDb(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('empty menu explains how to start', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    await settleDb(tester);
    expect(find.text('Your menu is empty'), findsOneWidget);
    expect(find.text('Import CSV'), findsOneWidget);
  });

  testWidgets('lists items, filters by search and category', (tester) async {
    await tester.runAsync(() async {
      final menu = storage.menu;
      await menu.saveCategory(const MenuCategory(id: 's', name: 'Starters'));
      await menu.saveCategory(const MenuCategory(id: 'd', name: 'Drinks'));
      await menu.saveItem(
        const MenuItem(
          id: 'a',
          categoryId: 's',
          name: 'Paneer Tikka',
          sku: 'PT',
          basePrice: Money(18000),
        ),
      );
      await menu.saveItem(
        const MenuItem(
          id: 'b',
          categoryId: 'd',
          name: 'Sweet Lassi',
          basePrice: Money(9000),
        ),
      );
      await menu.saveItem(
        const MenuItem(
          id: 'c',
          categoryId: 'd',
          name: 'Old Soda',
          basePrice: Money(4000),
          isActive: false,
        ),
      );
    });

    await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
    await settleDb(tester);

    expect(find.text('Paneer Tikka'), findsOneWidget);
    expect(find.text('Sweet Lassi'), findsOneWidget);
    expect(find.text('₹180.00'), findsOneWidget);
    expect(find.text('Old Soda'), findsNothing, reason: 'turned-off hidden');
    expect(find.text('2 item(s)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pt');
    await tester.pump();
    expect(find.text('Paneer Tikka'), findsOneWidget);
    expect(find.text('Sweet Lassi'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Drinks'));
    await tester.pump();
    expect(find.text('Paneer Tikka'), findsNothing);
    expect(find.text('Sweet Lassi'), findsOneWidget);
  });
}
