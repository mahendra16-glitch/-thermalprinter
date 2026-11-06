import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/features/reports/reports_screen.dart';
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

  testWidgets('today: sales, collections and items', (tester) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      const thali = MenuItem(
        id: 'thali',
        categoryId: 'c',
        name: 'Thali',
        basePrice: Money(90000),
      );
      await storage.menu.saveCategory(
        const MenuCategory(id: 'c', name: 'Meals'),
      );
      await storage.menu.saveItem(thali);
      final o = await storage.orders.createOrder(
        NewOrderRequest(clientRequestId: 'o1', type: OrderType.takeaway),
      );
      await storage.orders.addItem(
        o,
        configureItem(item: thali, groups: const {}, selected: const {}),
      );
      final b = await storage.bills.finalize(
        o,
        clientRequestId: 'b1',
        allowUnsent: true,
        print: false,
      );
      await storage.payments.record(
        PaymentRequest(
          billId: b,
          method: PaymentMethod.upi,
          amount: const Money(40000),
          staffConfirmed: true,
          clientRequestId: 'p1',
        ),
      );
    });

    await tester.pumpWidget(const MaterialApp(home: ReportsScreen()));
    await settle(tester);
    expect(find.text('Checked against the payment ledger'), findsOneWidget);
    expect(find.text('Total billed'), findsOneWidget);
    expect(find.text('₹900.00'), findsWidgets);
    expect(find.text('Net collected'), findsOneWidget);
    expect(find.text('₹400.00'), findsWidgets);
    expect(find.text('Still to collect'), findsOneWidget);
    expect(find.text('₹500.00'), findsWidgets);

    await tester.tap(find.text('Items'));
    await settle(tester);
    expect(find.text('Thali'), findsOneWidget);

    await tester.tap(find.text('Bills'));
    await settle(tester);
    expect(find.text('Part paid'), findsOneWidget);
  });
}
