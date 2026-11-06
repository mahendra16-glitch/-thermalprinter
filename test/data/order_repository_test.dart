import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/clock.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late OrderRepository orders;
  var req = 0;

  const size = OptionGroup(
    id: 'size',
    name: 'Size',
    kind: OptionGroupKind.variant,
    minSelect: 1,
    choices: [
      OptionChoice(id: 'half', groupId: 'size', name: 'Half'),
      OptionChoice(
        id: 'full',
        groupId: 'size',
        name: 'Full',
        priceDelta: Money(8000),
      ),
    ],
  );
  const tikka = MenuItem(
    id: 'tikka',
    categoryId: 'starters',
    name: 'Paneer Tikka',
    basePrice: Money(18000),
    taxProfileId: 'gst5',
    optionGroupIds: ['size'],
  );
  const tea = MenuItem(
    id: 'tea',
    categoryId: 'starters',
    name: 'Tea',
    basePrice: Money(2000),
  );
  const gst5 = TaxProfile(
    id: 'gst5',
    name: 'GST 5%',
    rateBp: 500,
    isInclusive: true,
    splitMode: TaxSplitMode.cgstSgst,
  );

  ConfiguredItem full() => configureItem(
    item: tikka,
    groups: {'size': size},
    selected: {
      'size': {'full'},
    },
    tax: gst5,
  );
  ConfiguredItem teaItem() =>
      configureItem(item: tea, groups: const {}, selected: const {});

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    orders = storage.orders;
    Clock.now = () => DateTime(2026, 11, 6, 20, 0);
    final menu = storage.menu;
    await menu.saveTaxProfile(gst5);
    await menu.saveCategory(const MenuCategory(id: 'starters', name: 'S'));
    await menu.saveOptionGroup(size);
    for (final c in size.choices) {
      await menu.saveOptionChoice(c);
    }
    await menu.saveItem(tikka);
    await menu.saveItem(tea);
    await storage.tables.saveArea(const DiningArea(id: 'in', name: 'Indoor'));
    for (final t in ['t1', 't2', 't3']) {
      await storage.tables.saveTable(
        RestaurantTable(id: t, areaId: 'in', label: t.toUpperCase()),
      );
    }
  });
  tearDown(() async {
    Clock.now = DateTime.now;
    StorageService.resetForTesting();
    await db.close();
  });

  Future<String> dineIn(String table, {bool shared = false}) =>
      orders.createOrder(
        NewOrderRequest(
          clientRequestId: 'r${req++}',
          type: OrderType.dineIn,
          tableId: table,
          allowSharedTable: shared,
        ),
      );

  Future<String> takeaway() => orders.createOrder(
    NewOrderRequest(clientRequestId: 'r${req++}', type: OrderType.takeaway),
  );

  Future<void> markSent(String lineId, int sent) =>
      (db.update(db.orderLines)..where((l) => l.id.equals(lineId))).write(
        OrderLinesCompanion(sentQty: Value(sent)),
      );

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  group('creating orders', () {
    test('order numbers are sequential per business day', () async {
      final a = await dineIn('t1');
      final b = await takeaway();
      Clock.now = () => DateTime(2026, 11, 7, 10, 0);
      final c = await takeaway();
      expect((await orders.getDetail(a))!.order.orderNo, 1);
      expect((await orders.getDetail(b))!.order.orderNo, 2);
      final next = (await orders.getDetail(c))!.order;
      expect(next.orderNo, 1);
      expect(next.businessDate, '2026-11-07');
    });

    test('business day start hour shifts late-night orders', () async {
      await orders.setDayStartHour(4);
      Clock.now = () => DateTime(2026, 11, 7, 1, 30);
      final id = await takeaway();
      expect((await orders.getDetail(id))!.order.businessDate, '2026-11-06');
    });

    test('same request id twice creates one order (double tap)', () async {
      const r = NewOrderRequest(
        clientRequestId: 'same',
        type: OrderType.takeaway,
      );
      final a = await orders.createOrder(r);
      final b = await orders.createOrder(r);
      expect(a, b);
      expect(await orders.listActive(), hasLength(1));
    });

    test('a busy table is refused unless sharing is explicit', () async {
      final first = await dineIn('t1');
      await expectLater(
        dineIn('t1'),
        throwsA(
          isA<TableBusyException>().having(
            (e) => e.existingOrderId,
            'existing',
            first,
          ),
        ),
      );
      await dineIn('t1', shared: true);
      expect(await orders.listActive(), hasLength(2));
    });

    test('dine-in needs an active table; takeaway has none', () async {
      await expectLater(
        orders.createOrder(
          const NewOrderRequest(clientRequestId: 'x', type: OrderType.dineIn),
        ),
        rejects('Choose a table'),
      );
      await storage.tables.setTableActive('t3', false);
      await expectLater(dineIn('t3'), rejects('not available'));
      await expectLater(
        orders.createOrder(
          const NewOrderRequest(
            clientRequestId: 'y',
            type: OrderType.takeaway,
            tableId: 't1',
          ),
        ),
        rejects('Only dine-in'),
      );
    });
  });

  group('lines', () {
    test('snapshot of name, options, price and tax is stored', () async {
      final o = await dineIn('t1');
      await orders.addItem(o, full(), qty: 2, notes: 'less spicy');
      final line = (await orders.getDetail(o))!.lines.single;
      expect(line.displayName, 'Paneer Tikka (Full)');
      expect(line.unitPrice, const Money(26000));
      expect(line.qty, 2);
      expect(line.taxRateBp, 500);
      expect(line.taxInclusive, isTrue);
      expect(line.taxSplitMode, TaxSplitMode.cgstSgst);
      expect(line.options.single.name, 'Full');
      expect(line.notes, 'less spicy');
    });

    test('menu edits after ordering do not change the order', () async {
      final o = await dineIn('t1');
      await orders.addItem(o, full());
      await storage.menu.saveItem(
        tikka.copyWith(name: 'Paneer Tikka Special', basePrice: const Money(1)),
      );
      await storage.menu.saveOptionChoice(
        size.choices.last.copyWithName('Large'),
      );
      final line = (await orders.getDetail(o))!.lines.single;
      expect(line.itemName, 'Paneer Tikka');
      expect(line.variantText, 'Full');
      expect(line.unitPrice, const Money(26000));
    });

    test('identical items merge; different notes or options do not', () async {
      final o = await takeaway();
      await orders.addItem(o, teaItem());
      await orders.addItem(o, teaItem(), qty: 2);
      await orders.addItem(o, teaItem(), notes: 'no sugar');
      await orders.addItem(o, full());
      final d = (await orders.getDetail(o))!;
      expect(d.lines.map((l) => l.qty), [3, 1, 1]);
      expect(d.totals.itemsTotal, const Money(2000 * 4 + 26000));
      expect(d.totals.itemCount, 5);
    });

    test('quantity rules', () async {
      final o = await takeaway();
      final l = await orders.addItem(o, teaItem(), qty: 3);
      await orders.setLineQty(l, 1);
      await expectLater(orders.setLineQty(l, 0), rejects('1 to 999'));
      await expectLater(
        orders.addItem(o, teaItem(), qty: 1000),
        rejects('1 to 999'),
      );
    });

    test('items sent to the kitchen cannot be reduced or removed', () async {
      final o = await dineIn('t1');
      final l = await orders.addItem(o, teaItem(), qty: 3);
      await markSent(l, 2);
      await orders.setLineQty(l, 4); // adding more is fine
      await orders.setLineQty(l, 2); // down to the sent quantity is fine
      await expectLater(orders.setLineQty(l, 1), rejects('already sent'));
      await expectLater(orders.removeLine(l), rejects('Void it'));
      await expectLater(orders.setLineNotes(l, 'x'), rejects('already sent'));
      await expectLater(
        orders.cancel(o, 'customer left'),
        rejects('Void them'),
      );
    });

    test('unsent lines can be removed; it is logged', () async {
      final o = await takeaway();
      final l = await orders.addItem(o, teaItem());
      await orders.removeLine(l);
      expect((await orders.getDetail(o))!.lines, isEmpty);
      final events = (await orders.timeline(o)).map((e) => e.action);
      expect(events, [
        'order.created',
        'order.item_added',
        'order.item_removed',
      ]);
    });
  });

  group('order actions', () {
    test('discount requires a reason and is capped by totals', () async {
      final o = await takeaway();
      await orders.addItem(o, teaItem());
      await expectLater(
        orders.setDiscount(
          o,
          const OrderDiscount(kind: DiscountKind.percent, value: 1000),
        ),
        rejects('reason'),
      );
      await orders.setDiscount(
        o,
        const OrderDiscount(
          kind: DiscountKind.amount,
          value: 5000,
          reason: 'Regular customer',
        ),
      );
      final d = (await orders.getDetail(o))!;
      expect(d.totals.discount, const Money(2000));
      expect(d.order.discount.reason, 'Regular customer');
      await orders.setDiscount(o, OrderDiscount.none);
      expect((await orders.getDetail(o))!.totals.discount, Money.zero);
    });

    test('hold and resume', () async {
      final o = await takeaway();
      await orders.hold(o);
      expect((await orders.getDetail(o))!.order.status, OrderStatus.held);
      await expectLater(orders.hold(o), rejects('on hold'));
      await orders.resume(o);
      expect((await orders.getDetail(o))!.order.status, OrderStatus.open);
    });

    test('cancel needs a reason, keeps lines and frees the table', () async {
      final o = await dineIn('t1');
      await orders.addItem(o, teaItem());
      await expectLater(orders.cancel(o, ' '), rejects('reason'));
      await orders.cancel(o, 'Customer left');
      final d = (await orders.getDetail(o))!;
      expect(d.order.status, OrderStatus.cancelled);
      expect(d.order.cancelReason, 'Customer left');
      expect(d.lines, hasLength(1), reason: 'never silently discarded');
      await expectLater(
        orders.addItem(o, teaItem()),
        rejects('cannot be changed'),
      );
      await dineIn('t1'); // table is free again
      final closed = await orders.listClosedFor('2026-11-06');
      expect(closed.single.order.id, o);
    });

    test('move to a free table; a busy table needs explicit sharing', () async {
      final a = await dineIn('t1');
      await dineIn('t2');
      await orders.moveToTable(a, 't3');
      expect((await orders.getDetail(a))!.order.tableId, 't3');
      await expectLater(
        orders.moveToTable(a, 't2'),
        throwsA(isA<TableBusyException>()),
      );
      await orders.moveToTable(a, 't2', allowSharedTable: true);
      final t = await takeaway();
      await expectLater(orders.moveToTable(t, 't1'), rejects('Only dine-in'));
    });

    test(
      'merge moves lines (with kitchen progress) and closes source',
      () async {
        final a = await dineIn('t1');
        final b = await dineIn('t2');
        await orders.addItem(a, teaItem());
        final lb = await orders.addItem(b, full(), qty: 2);
        await markSent(lb, 1);
        await orders.mergeInto(b, a);

        final target = (await orders.getDetail(a))!;
        expect(target.lines, hasLength(2));
        expect(target.lines.last.sentQty, 1);
        final source = (await orders.getDetail(b))!;
        expect(source.order.status, OrderStatus.cancelled);
        expect(source.order.cancelReason, 'Merged into order #1');
        expect(source.lines, isEmpty);
        await expectLater(orders.mergeInto(a, a), rejects('different order'));
      },
    );

    test('split selected lines into a new takeaway order', () async {
      final a = await dineIn('t1');
      final keep = await orders.addItem(a, teaItem());
      final move = await orders.addItem(a, full());
      final b = await orders.splitToNewOrder(
        a,
        [move],
        const NewOrderRequest(
          clientRequestId: 'split',
          type: OrderType.takeaway,
        ),
      );
      expect((await orders.getDetail(a))!.lines.single.id, keep);
      final nb = (await orders.getDetail(b))!;
      expect(nb.lines.single.id, move);
      expect(nb.order.type, OrderType.takeaway);
      final events = (await orders.timeline(a)).map((e) => e.action);
      expect(events, contains('order.split_out'));
    });

    test('details validation', () async {
      final o = await dineIn('t1');
      await orders.updateDetails(
        o,
        customerName: 'Asha',
        customerPhone: '98765 43210',
        guests: 4,
        notes: 'Birthday',
      );
      final d = (await orders.getDetail(o))!.order;
      expect(d.customerPhone, '9876543210');
      expect(d.guests, 4);
      await expectLater(
        orders.updateDetails(
          o,
          customerName: '',
          customerPhone: '12',
          notes: '',
        ),
        rejects('Phone'),
      );
    });

    test('active list and table guards', () async {
      final a = await dineIn('t1');
      await orders.addItem(a, full());
      final active = await orders.listActive();
      expect(active.single.totals.itemsTotal, const Money(26000));
      await expectLater(
        storage.tables.setTableActive('t1', false),
        rejects('running order'),
      );
      await expectLater(
        storage.tables.setAreaActive('in', false),
        rejects('1 running order'),
      );
    });
  });
}

extension on OptionChoice {
  OptionChoice copyWithName(String name) => OptionChoice(
    id: id,
    groupId: groupId,
    name: name,
    priceDelta: const Money(1),
  );
}
