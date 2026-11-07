import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/inventory_repository.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/inventory/inventory_models.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/features/inventory/inventory_screen.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late InventoryRepository inv;
  late String flour, cheese, cola;
  var n = 0;
  String rid() => 'req${n++}';

  const extras = OptionGroup(
    id: 'extras',
    name: 'Extras',
    kind: OptionGroupKind.addon,
    maxSelect: 2,
    choices: [
      OptionChoice(
        id: 'xcheese',
        groupId: 'extras',
        name: 'Extra cheese',
        priceDelta: Money(3000),
      ),
    ],
  );
  const pizza = MenuItem(
    id: 'pizza',
    categoryId: 'c',
    name: 'Pizza',
    basePrice: Money(30000),
    optionGroupIds: ['extras'],
  );
  const coke = MenuItem(
    id: 'coke',
    categoryId: 'c',
    name: 'Cola',
    basePrice: Money(5000),
  );
  const water = MenuItem(
    id: 'water',
    categoryId: 'c',
    name: 'Water',
    basePrice: Money(2000),
  );

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  ConfiguredItem cfg(MenuItem i, [Set<String> addons = const {}]) =>
      configureItem(
        item: i,
        groups: const {'extras': extras},
        selected: {if (addons.isNotEmpty) 'extras': addons},
      );

  Future<int> onHand(String id) async => (await inv.item(id))!.onHandMilli;

  Future<String> newOrder(List<ConfiguredItem> items) async {
    final o = await storage.orders.createOrder(
      NewOrderRequest(clientRequestId: rid(), type: OrderType.takeaway),
    );
    for (final c in items) {
      await storage.orders.addItem(o, c);
    }
    return o;
  }

  Future<String> bill(String orderId, {String? requestId}) =>
      storage.bills.finalize(
        orderId,
        clientRequestId: requestId ?? rid(),
        allowUnsent: true,
        print: false,
      );

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    inv = storage.inventory;
    final m = storage.menu;
    await m.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await m.saveOptionGroup(extras);
    await m.saveOptionChoice(extras.choices.single);
    for (final i in [pizza, coke, water]) {
      await m.saveItem(i);
    }
    flour = await inv.saveItem(name: 'Flour', unit: StockUnit.kg);
    cheese = await inv.saveItem(
      name: 'Cheese',
      unit: StockUnit.g,
      lowStockMilli: 500 * 1000,
    );
    cola = await inv.saveItem(name: 'Cola can', unit: StockUnit.pcs);
    await inv.record(
      stockItemId: flour,
      kind: StockMovementKind.opening,
      qtyMilli: 10000, // 10 kg
      clientRequestId: rid(),
    );
    await inv.record(
      stockItemId: cheese,
      kind: StockMovementKind.opening,
      qtyMilli: 2000 * 1000, // 2000 g
      clientRequestId: rid(),
    );
    await inv.record(
      stockItemId: cola,
      kind: StockMovementKind.opening,
      qtyMilli: 24000,
      clientRequestId: rid(),
    );
    // Pizza: 0.25 kg flour + 100 g cheese; extra cheese: +50 g. Cola: 1 can.
    await inv.setRecipeLine(
      menuItemId: 'pizza',
      stockItemId: flour,
      qtyMilli: 250,
    );
    await inv.setRecipeLine(
      menuItemId: 'pizza',
      stockItemId: cheese,
      qtyMilli: 100 * 1000,
    );
    await inv.setRecipeLine(
      choiceId: 'xcheese',
      stockItemId: cheese,
      qtyMilli: 50 * 1000,
    );
    await inv.setRecipeLine(
      menuItemId: 'coke',
      stockItemId: cola,
      qtyMilli: 1000,
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  test('quantities in thousandths', () {
    expect(Qty.format(1250), '1.25');
    expect(Qty.format(2000), '2');
    expect(Qty.format(-500), '-0.5');
    expect(Qty.format(1), '0.001');
    expect(Qty.parse('1.25'), 1250);
    expect(Qty.parse('0.150'), 150);
    expect(Qty.parse('3'), 3000);
    expect(Qty.parse('.5'), 500);
    expect(Qty.parse('1.2345'), isNull);
    expect(Qty.parse('abc'), isNull);
    expect(Qty.parse(''), isNull);
  });

  test('stock items, stock in, wastage and counts', () async {
    expect(
      () => inv.saveItem(name: 'flour', unit: StockUnit.kg),
      rejects('already a stock item'),
    );
    expect(
      () => inv.saveItem(id: flour, name: 'Flour', unit: StockUnit.g),
      rejects('unit cannot change'),
    );
    expect(
      () => inv.record(
        stockItemId: flour,
        kind: StockMovementKind.opening,
        qtyMilli: 1000,
        clientRequestId: rid(),
      ),
      rejects('Opening stock is only'),
    );

    final req = rid();
    for (var i = 0; i < 2; i++) {
      await inv.record(
        stockItemId: flour,
        kind: StockMovementKind.purchase,
        qtyMilli: 5000,
        costPaise: 22500, // ₹225 for 5 kg
        reason: 'Bill 41',
        clientRequestId: req,
      );
    }
    expect(await onHand(flour), 15000, reason: 'retry recorded once');
    expect((await inv.item(flour))!.lastCostPerUnitPaise, 4500);

    expect(
      () => inv.record(
        stockItemId: flour,
        kind: StockMovementKind.wastage,
        qtyMilli: 500,
        clientRequestId: rid(),
      ),
      rejects('reason'),
    );
    await inv.record(
      stockItemId: flour,
      kind: StockMovementKind.wastage,
      qtyMilli: 500,
      reason: 'Got wet',
      clientRequestId: rid(),
    );
    expect(await onHand(flour), 14500);

    expect(
      () => inv.countStock(
        stockItemId: flour,
        countedMilli: 14000,
        reason: '',
        clientRequestId: rid(),
      ),
      rejects('0.5 kg less'),
    );
    expect(
      await inv.countStock(
        stockItemId: flour,
        countedMilli: 14000,
        reason: 'Spilled',
        clientRequestId: rid(),
      ),
      -500,
    );
    expect(
      await inv.countStock(
        stockItemId: flour,
        countedMilli: 14000,
        reason: '',
        clientRequestId: rid(),
      ),
      0,
    );
    expect(await onHand(flour), 14000);
    final actions = (await db.select(db.auditLog).get()).map((r) => r.action);
    expect(
      actions,
      containsAll(['stock.purchase', 'stock.wastage', 'stock.count']),
    );
  });

  test('deduction off: sales take nothing', () async {
    final o = await newOrder([cfg(pizza), cfg(coke)]);
    await bill(o);
    expect(await onHand(cola), 24000);
    expect(await onHand(flour), 10000);
  });

  test('on the bill: once, with options, and back on void', () async {
    await inv.setDeductOn(DeductOn.bill);
    final o = await newOrder([
      cfg(pizza, {'xcheese'}),
      cfg(pizza),
      cfg(coke),
      cfg(coke),
      cfg(water), // no recipe: uses no stock
    ]);
    final req = rid();
    final billId = await bill(o, requestId: req);
    await bill(o, requestId: req); // retried request
    await storage.bills.reprint(billId);
    await storage.bills.reprint(billId);
    expect(await onHand(flour), 10000 - 2 * 250);
    expect(await onHand(cheese), (2000 - 100 - 150) * 1000);
    expect(await onHand(cola), 22000);

    // A recipe change later does not change what the void gives back.
    await inv.setRecipeLine(
      menuItemId: 'pizza',
      stockItemId: flour,
      qtyMilli: 400,
    );
    await storage.bills.voidBill(billId, 'Wrong items');
    expect(await onHand(flour), 10000);
    expect(await onHand(cheese), 2000 * 1000);
    expect(await onHand(cola), 24000);
    final kinds = (await db.select(db.stockMovements).get())
        .map((m) => m.kind)
        .toList();
    expect(kinds.where((k) => k == 'saleReturn'), hasLength(5));

    // Billed again after the void: taken again, with the new recipe.
    await bill(o);
    expect(await onHand(flour), 10000 - 2 * 400);
  });

  test('on KOT: sent units once; unsent units on the bill', () async {
    await inv.setDeductOn(DeductOn.kot);
    final o = await newOrder([cfg(pizza), cfg(pizza)]);
    final req = rid();
    await storage.kitchen.sendToKitchen(o, clientRequestId: req);
    await storage.kitchen.sendToKitchen(o, clientRequestId: req);
    expect(await onHand(flour), 10000 - 500);

    // A cola added later and billed without a KOT is taken by the bill.
    await storage.orders.addItem(o, cfg(coke));
    final billId = await bill(o);
    expect(await onHand(flour), 9500, reason: 'pizzas not taken twice');
    expect(await onHand(cola), 23000);

    // Voiding the bill gives back only what the bill took.
    await storage.bills.voidBill(billId, 'Correction');
    expect(await onHand(cola), 24000);
    expect(await onHand(flour), 9500, reason: 'the food was made');
  });

  test('items voided after KOT stay used; the rest are billed', () async {
    await inv.setDeductOn(DeductOn.kot);
    final o = await newOrder([cfg(pizza)]);
    await storage.orders.addItem(o, cfg(pizza));
    await storage.kitchen.sendToKitchen(o, clientRequestId: rid());
    final lines = await (db.select(
      db.orderLines,
    )..where((l) => l.orderId.equals(o))).get();
    await storage.kitchen.voidItems(
      lines.first.id,
      qty: 1,
      reason: 'Burnt',
      clientRequestId: rid(),
    );
    await bill(o);
    expect(await onHand(flour), 10000 - 500);
  });

  test('switching from bill to KOT mid-order does not take twice', () async {
    await inv.setDeductOn(DeductOn.kot);
    final o = await newOrder([cfg(coke)]);
    await storage.kitchen.sendToKitchen(o, clientRequestId: rid());
    await inv.setDeductOn(DeductOn.bill);
    await bill(o);
    expect(await onHand(cola), 23000);
  });

  test('low stock and below zero', () async {
    await inv.setDeductOn(DeductOn.bill);
    final o = await newOrder([for (var i = 0; i < 16; i++) cfg(pizza)]);
    await bill(o);
    final c = (await inv.item(cheese))!;
    expect(c.onHandMilli, 400 * 1000);
    expect(c.isLow, isTrue);
    expect((await inv.watchLow().first).map((i) => i.name), ['Cheese']);
    final o2 = await newOrder([for (var i = 0; i < 5; i++) cfg(pizza)]);
    await bill(o2);
    final c2 = (await inv.item(cheese))!;
    expect(c2.isNegative, isTrue, reason: 'sales are never blocked');
  });

  test('movements CSV', () async {
    await inv.record(
      stockItemId: flour,
      kind: StockMovementKind.wastage,
      qtyMilli: 250,
      reason: '=bad',
      clientRequestId: rid(),
    );
    final today = await storage.orders.currentBusinessDate();
    final csv = await stockMovementsCsv(storage, today, today);
    expect(csv, startsWith('﻿time,business_date,item'));
    expect(csv, contains('Flour,kg,wastage,-0.25'));
    expect(csv, contains("'=bad"));
    expect(csv, contains('Cola can,pcs,opening,24'));
  });
}
