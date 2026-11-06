import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/features/orders/order_screen.dart';
import 'package:thermalprinter/features/tables/tables_screen.dart';
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
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> seed(WidgetTester tester) => tester.runAsync(() async {
    final m = storage.menu;
    await m.saveCategory(const MenuCategory(id: 's', name: 'Starters'));
    await m.saveOptionGroup(
      const OptionGroup(
        id: 'size',
        name: 'Size',
        kind: OptionGroupKind.variant,
        minSelect: 1,
      ),
    );
    await m.saveOptionChoice(
      const OptionChoice(id: 'half', groupId: 'size', name: 'Half'),
    );
    await m.saveOptionChoice(
      const OptionChoice(
        id: 'full',
        groupId: 'size',
        name: 'Full',
        priceDelta: Money(8000),
      ),
    );
    await m.saveItem(
      const MenuItem(
        id: 'tea',
        categoryId: 's',
        name: 'Masala Tea',
        sku: 'MT',
        basePrice: Money(2000),
      ),
    );
    await m.saveItem(
      const MenuItem(
        id: 'tikka',
        categoryId: 's',
        name: 'Paneer Tikka',
        basePrice: Money(18000),
        optionGroupIds: ['size'],
      ),
    );
    await storage.tables.saveArea(const DiningArea(id: 'in', name: 'Indoor'));
    await storage.tables.saveTable(
      const RestaurantTable(id: 't1', areaId: 'in', label: 'T1', seats: 4),
    );
    await storage.tables.saveTable(
      const RestaurantTable(id: 't2', areaId: 'in', label: 'T2'),
    );
  });

  testWidgets('add plain and optioned items on a phone', (tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed(tester);
    late String orderId;
    await tester.runAsync(() async {
      orderId = await storage.orders.createOrder(
        const NewOrderRequest(
          clientRequestId: 'w1',
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      );
    });

    await tester.pumpWidget(MaterialApp(home: OrderScreen(orderId: orderId)));
    await settle(tester);
    expect(find.text('Order #1 · T1'), findsOneWidget);

    // No favourites, so the menu shows everything.
    await tester.tap(find.text('Masala Tea'));
    await settle(tester);
    await tester.tap(find.text('Masala Tea'));
    await settle(tester);
    expect(find.text('Order (2)'), findsOneWidget);

    // Item with a required variant opens the options sheet.
    await tester.tap(find.text('Paneer Tikka'));
    await tester.pumpAndSettle();
    expect(find.text('Size: choose one.'), findsOneWidget);
    await tester.tap(find.textContaining('Full'));
    await tester.pump();
    await tester.tap(find.text('Less spicy'));
    await tester.pump();
    await tester.tap(find.text('Add  ₹260.00'));
    await tester.pumpAndSettle();
    await settle(tester);

    final d = (await tester.runAsync(() => storage.orders.getDetail(orderId)))!;
    expect(d.lines.map((l) => '${l.qty} ${l.displayName}'), [
      '2 Masala Tea',
      '1 Paneer Tikka (Full)',
    ]);
    expect(d.lines.last.notes, 'Less spicy');
    expect(d.totals.itemsTotal, const Money(4000 + 26000));

    await tester.tap(find.text('Order (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Paneer Tikka (Full)'), findsOneWidget);
    expect(find.text('₹300.00'), findsNWidgets(2)); // items + before tax
  });

  testWidgets('short code + Enter adds the item', (tester) async {
    await seed(tester);
    late String orderId;
    await tester.runAsync(() async {
      orderId = await storage.orders.createOrder(
        const NewOrderRequest(clientRequestId: 'w2', type: OrderType.takeaway),
      );
    });
    await tester.pumpWidget(MaterialApp(home: OrderScreen(orderId: orderId)));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'mt');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    final d = (await tester.runAsync(() => storage.orders.getDetail(orderId)))!;
    expect(d.lines.single.itemName, 'Masala Tea');
  });

  testWidgets('tables screen shows running orders', (tester) async {
    await seed(tester);
    await tester.runAsync(() async {
      final id = await storage.orders.createOrder(
        const NewOrderRequest(
          clientRequestId: 'w3',
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      );
      final snap = await storage.menu.loadSnapshot();
      final tea = snap.items.firstWhere((i) => i.id == 'tea');
      await storage.orders.addItem(id, _plain(tea), qty: 3);
    });
    await tester.pumpWidget(const MaterialApp(home: TablesScreen()));
    await settle(tester);
    expect(find.text('Running · #1'), findsOneWidget);
    expect(find.text('₹60.00'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('All (1/2 busy)'), findsOneWidget);
  });

  testWidgets('send to kitchen creates a KOT and only new items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed(tester);
    late String orderId;
    await tester.runAsync(() async {
      orderId = await storage.orders.createOrder(
        const NewOrderRequest(
          clientRequestId: 'w4',
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      );
    });
    await tester.pumpWidget(MaterialApp(home: OrderScreen(orderId: orderId)));
    await settle(tester);
    await tester.tap(find.text('Masala Tea'));
    await settle(tester);
    // Wide layout: the menu grid comes first, the order panel second.
    await tester.tap(find.text('Masala Tea').first);
    await settle(tester);
    expect(find.text('Send to kitchen (2 new)'), findsOneWidget);
    await tester.tap(find.text('Send to kitchen (2 new)'));
    await settle(tester);
    await settle(tester);
    expect(find.textContaining('Send to kitchen'), findsNothing);
    expect(find.textContaining('in kitchen'), findsOneWidget);

    final tickets = (await tester.runAsync(
      () => storage.kitchen.ticketsFor(orderId),
    ))!;
    expect(tickets.single.lines.single.qty, 2);
    final jobs = (await tester.runAsync(() => storage.printJobs.getAllJobs()))!;
    expect(jobs.single.printType, 'KOT');
  });

  testWidgets('generate, save and print a bill, then void it', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed(tester);
    late String orderId;
    await tester.runAsync(() async {
      orderId = await storage.orders.createOrder(
        const NewOrderRequest(
          clientRequestId: 'w5',
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      );
      final tea = (await storage.menu.loadSnapshot()).items.firstWhere(
        (i) => i.id == 'tea',
      );
      await storage.orders.addItem(orderId, _plain(tea), qty: 2);
      await storage.kitchen.sendToKitchen(orderId, clientRequestId: 'k5');
    });
    await tester.pumpWidget(MaterialApp(home: OrderScreen(orderId: orderId)));
    await settle(tester);

    await tester.tap(find.text('Generate bill'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Bill preview'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    await tester.tap(find.text('Save & print'));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    await settle(tester);

    expect(find.text('Bill 1 · ₹40.00 · Unpaid'), findsOneWidget);
    expect(find.text('Generate bill'), findsNothing);
    final bills = (await tester.runAsync(
      () => storage.bills.billsForOrder(orderId),
    ))!;
    expect(bills.single.grandTotal, const Money(4000));
    final jobs = (await tester.runAsync(() => storage.printJobs.getAllJobs()))!;
    expect(jobs.where((j) => j.printType == 'BILL'), hasLength(1));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Void bill'));
    await settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Wrong item billed'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Void bill'));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    await settle(tester);
    expect(find.text('Generate bill'), findsOneWidget);
    final after = (await tester.runAsync(
      () => storage.bills.billsForOrder(orderId),
    ))!;
    expect(after.single.isVoided, isTrue);
    expect(after.single.voidReason, 'Wrong item billed');
  });

  testWidgets('part cash, then UPI only after staff confirm', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await seed(tester);
    late String orderId;
    await tester.runAsync(() async {
      orderId = await storage.orders.createOrder(
        const NewOrderRequest(
          clientRequestId: 'w6',
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      );
      final tea = (await storage.menu.loadSnapshot()).items.firstWhere(
        (i) => i.id == 'tea',
      );
      await storage.orders.addItem(orderId, _plain(tea), qty: 2);
      await storage.bills.finalize(
        orderId,
        clientRequestId: 'b6',
        allowUnsent: true,
        print: false,
      );
    });
    await tester.pumpWidget(MaterialApp(home: OrderScreen(orderId: orderId)));
    await settle(tester);
    expect(find.textContaining('Unpaid'), findsOneWidget);

    Future<void> openPayment() async {
      await tester.tap(find.textContaining('Collect payment'));
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> record(String button) async {
      await tester.tap(find.text(button));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.widgetWithText(FilledButton, 'Record'));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await settle(tester);
      await tester.pump(const Duration(seconds: 1));
    }

    await openPayment();
    expect(find.text('Balance'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount collected now'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Cash received (optional)'),
      '50',
    );
    await tester.pump();
    expect(find.text('Change to give: ₹40.00'), findsOneWidget);
    await record('Record cash payment');
    expect(find.textContaining('Part paid'), findsOneWidget);
    expect(find.text('Collect payment · ₹30.00'), findsOneWidget);
    expect(find.text('Void bill'), findsNothing);

    await openPayment();
    await tester.tap(find.text('UPI'));
    await tester.pump();
    expect(find.textContaining('does not prove'), findsOneWidget);
    await tester.tap(find.text('Record UPI payment'));
    await tester.pump();
    expect(find.textContaining('Tick the box'), findsOneWidget);
    await tester.tap(find.textContaining('I checked our UPI app'));
    await tester.pump();
    await record('Record UPI payment');

    expect(find.textContaining('Paid · Bill 1'), findsOneWidget);
    final s = (await tester.runAsync(() async {
      final bill = await storage.bills.currentBillFor(orderId);
      return storage.payments.summaryFor(bill!.id);
    }))!;
    expect(s.entries.map((e) => e.amount.paise), [1000, 3000]);
    expect(s.entries.last.confirmation, 'staffConfirmed');
  });
}

ConfiguredItem _plain(MenuItem i) =>
    configureItem(item: i, groups: const {}, selected: const {});
