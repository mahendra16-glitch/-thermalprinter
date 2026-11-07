import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/staff/staff_models.dart';
import 'package:thermalprinter/features/orders/order_screen.dart';
import 'package:thermalprinter/features/payments/payment_actions.dart';
import 'package:thermalprinter/domain/billing/bill_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/features/staff/staff_gate.dart';
import 'package:thermalprinter/screens/main_navigation_screen.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

/// Every main tab, on a small phone, with the system font at 1.5x: nothing
/// may overflow or throw.
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
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Widget app(Widget home) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.5)),
      child: StaffGate(child: child!),
    ),
    home: home,
  );

  void smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('all tabs at 1.5x text on a 360 dp phone', (tester) async {
    smallPhone(tester);
    await tester.pumpWidget(app(const MainNavigationScreen()));
    await settle(tester);
    for (final tab in [
      'Orders',
      'Shift',
      'Reports',
      'Menu',
      'Settings',
      'Tables',
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await settle(tester);
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('sign-in and PIN pad at 1.5x text', (tester) async {
    smallPhone(tester);
    await tester.runAsync(() async {
      await storage.staff.setUpOwner(name: 'Meera Krishnamurthy', pin: '4826');
      await storage.staff.addStaff(
        name: 'Ravi',
        role: StaffRole.waiter,
        pin: '2468',
      );
      await storage.staff.signOut();
    });
    await tester.pumpWidget(app(const Scaffold(body: Text('APP'))));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ravi'));
    await settle(tester);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  testWidgets('order screen and payment screen at 1.5x text', (tester) async {
    smallPhone(tester);
    late String orderId, openOrderId;
    late Bill bill;
    late BillPaymentSummary summary;
    const item = MenuItem(
      id: 'i1',
      categoryId: 'c',
      name: 'Paneer Butter Masala with Garlic Naan (Family Pack)',
      basePrice: Money(125000),
    );
    final cfg = configureItem(item: item, groups: const {}, selected: const {});
    await tester.runAsync(() async {
      await storage.menu.saveCategory(
        const MenuCategory(id: 'c', name: 'Main course and specials'),
      );
      await storage.menu.saveItem(item);
      orderId = await storage.orders.createOrder(
        NewOrderRequest(clientRequestId: 'r1', type: OrderType.takeaway),
      );
      await storage.orders.addItem(orderId, cfg);
      final billId = await storage.bills.finalize(
        orderId,
        clientRequestId: 'r2',
        allowUnsent: true,
        print: false,
      );
      bill = (await storage.bills.getBill(billId))!;
      summary = await storage.payments.summaryFor(billId);
      openOrderId = await storage.orders.createOrder(
        NewOrderRequest(clientRequestId: 'r3', type: OrderType.takeaway),
      );
      await storage.orders.addItem(openOrderId, cfg);
    });

    await tester.pumpWidget(
      app(PaymentScreen(bill: bill, summary: summary, shiftOpen: false)),
    );
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'payment screen');

    await tester.pumpWidget(app(OrderScreen(orderId: openOrderId)));
    await settle(tester);
    expect(tester.takeException(), isNull, reason: 'order screen');
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
