import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/kitchen_repository.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/kitchen_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/models/print_job.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/queue/print_queue_manager.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late OrderRepository orders;
  late KitchenRepository kitchen;
  var n = 0;
  String rid() => 'req${n++}';

  const extras = OptionGroup(
    id: 'extras',
    name: 'Extras',
    kind: OptionGroupKind.addon,
    maxSelect: 2,
    choices: [
      OptionChoice(
        id: 'cheese',
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
    stationId: 'oven',
    optionGroupIds: ['extras'],
  );
  const tea = MenuItem(
    id: 'tea',
    categoryId: 'c',
    name: 'Tea',
    basePrice: Money(2000),
    stationId: 'bar',
  );
  const soup = MenuItem(
    id: 'soup',
    categoryId: 'c',
    name: 'Soup',
    basePrice: Money(9000),
  );

  ConfiguredItem cfg(MenuItem i, [Set<String> addons = const {}]) =>
      configureItem(
        item: i,
        groups: const {'extras': extras},
        selected: {if (addons.isNotEmpty) 'extras': addons},
      );

  PrinterDevice printer(String id, PrinterRole role) => PrinterDevice(
    id: id,
    name: id,
    connectionType: ConnectionType.network,
    role: role,
  );

  late String orderId;

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    orders = storage.orders;
    kitchen = storage.kitchen;
    final m = storage.menu;
    await m.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await m.saveStation(const KitchenStation(id: 'oven', name: 'Oven'));
    await m.saveStation(const KitchenStation(id: 'bar', name: 'Bar'));
    await m.saveOptionGroup(extras);
    await m.saveOptionChoice(extras.choices.single);
    for (final i in [pizza, tea, soup]) {
      await m.saveItem(i);
    }
    await storage.tables.saveArea(const DiningArea(id: 'a', name: 'In'));
    await storage.tables.saveTable(
      const RestaurantTable(id: 't1', areaId: 'a', label: 'T1'),
    );
    for (final p in [
      printer('ovenP', PrinterRole.kitchen),
      printer('barP', PrinterRole.bar),
      printer('mainP', PrinterRole.kot),
    ]) {
      await storage.savePrinter(p);
    }
    await kitchen.setStationPrinters('oven', ['ovenP']);
    await kitchen.setStationPrinters('bar', ['barP']);
    await kitchen.setStationPrinters(KitchenRepository.defaultStation, [
      'mainP',
    ]);
    orderId = await orders.createOrder(
      NewOrderRequest(
        clientRequestId: rid(),
        type: OrderType.dineIn,
        tableId: 't1',
      ),
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<List<PrintJob>> jobs() => storage.printJobs.getAllJobs();

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  test('one ticket per station, routed to that station\'s printer', () async {
    await orders.addItem(orderId, cfg(pizza, {'cheese'}), notes: 'well done');
    await orders.addItem(orderId, cfg(tea), qty: 2);
    await orders.addItem(orderId, cfg(soup));

    final r = await kitchen.sendToKitchen(orderId, clientRequestId: rid());
    expect(r.ticketIds, hasLength(3));
    expect(r.jobCount, 3);
    expect(r.unroutedStations, isEmpty);

    final tickets = await kitchen.ticketsFor(orderId);
    expect(tickets.map((t) => t.stationName).toSet(), {
      'Oven',
      'Bar',
      'Kitchen',
    });
    expect(tickets.every((t) => t.roundNo == 1), isTrue);

    final all = await jobs();
    final byPrinter = {for (final j in all) j.targetPrinterId: j};
    expect(byPrinter.keys.toSet(), {'ovenP', 'barP', 'mainP'});
    final ovenOrder = PosOrder.fromJson(byPrinter['ovenP']!.posOrderJson!);
    expect(ovenOrder.type, 'KOT');
    expect(ovenOrder.tableNumber, 'T1');
    expect(ovenOrder.stationName, 'Oven');
    expect(ovenOrder.items.single.name, 'Pizza');
    expect(ovenOrder.items.single.addOns, ['Extra cheese']);
    expect(ovenOrder.items.single.notes, 'well done');
    expect(byPrinter['barP']!.sourceKey, startsWith('KOT:'));

    final lines = (await orders.getDetail(orderId))!.lines;
    expect(lines.every((l) => l.sentQty == l.qty), isTrue);
  });

  test('only new units go in the next round; repeat send is safe', () async {
    final teaLine = await orders.addItem(orderId, cfg(tea), qty: 2);
    final req = rid();
    await kitchen.sendToKitchen(orderId, clientRequestId: req);
    // The same tap delivered twice: no second ticket.
    await kitchen.sendToKitchen(orderId, clientRequestId: req);
    expect(await kitchen.ticketsFor(orderId), hasLength(1));
    await expectLater(
      kitchen.sendToKitchen(orderId, clientRequestId: rid()),
      rejects('Nothing new'),
    );

    await orders.setLineQty(teaLine, 3); // one more tea
    await orders.addItem(orderId, cfg(soup));
    await kitchen.sendToKitchen(orderId, clientRequestId: rid());

    final round2 = (await kitchen.ticketsFor(orderId))
        .where((t) => t.roundNo == 2)
        .toList();
    final printed = {
      for (final t in round2)
        for (final l in t.lines) l.itemName: l.qty,
    };
    expect(printed, {'Tea': 1, 'Soup': 1});
  });

  test('station without a printer uses the default station printers', () async {
    await kitchen.setStationPrinters('bar', []);
    await orders.addItem(orderId, cfg(tea));
    await kitchen.sendToKitchen(orderId, clientRequestId: rid());
    expect((await jobs()).single.targetPrinterId, 'mainP');
  });

  test('no printers at all: queued by role and reported', () async {
    for (final s in ['oven', 'bar', KitchenRepository.defaultStation]) {
      await kitchen.setStationPrinters(s, []);
    }
    await orders.addItem(orderId, cfg(tea));
    final r = await kitchen.sendToKitchen(orderId, clientRequestId: rid());
    expect(r.unroutedStations, ['Bar']);
    final j = (await jobs()).single;
    expect(j.targetPrinterId, isNull);
    expect(j.targetRole, PrinterRole.kot);
  });

  test('void: only sent units, needs a reason, prints a void ticket', () async {
    final line = await orders.addItem(orderId, cfg(pizza), qty: 3);
    await expectLater(
      kitchen.voidItems(line, qty: 1, reason: 'x', clientRequestId: rid()),
      rejects('Nothing to void'),
    );
    await kitchen.sendToKitchen(orderId, clientRequestId: rid());
    await expectLater(
      kitchen.voidItems(line, qty: 4, reason: 'x', clientRequestId: rid()),
      rejects('1 to 3'),
    );
    await expectLater(
      kitchen.voidItems(line, qty: 1, reason: ' ', clientRequestId: rid()),
      rejects('reason'),
    );
    final req = rid();
    await kitchen.voidItems(
      line,
      qty: 2,
      reason: 'Customer changed mind',
      clientRequestId: req,
    );
    await kitchen.voidItems(
      line,
      qty: 2,
      reason: 'Customer changed mind',
      clientRequestId: req,
    ); // retried tap: ignored

    final l = (await orders.getDetail(orderId))!.lines.single;
    expect(l.voidedQty, 2);
    expect(l.billableQty, 1);
    expect(
      (await orders.getDetail(orderId))!.totals.itemsTotal,
      const Money(30000),
    );

    final voidTicket = (await kitchen.ticketsFor(orderId))
        .singleWhere((t) => t.kind == KitchenTicketKind.voided);
    expect(voidTicket.lines.single.qty, 2);
    final voidJob = (await jobs()).last;
    final pos = PosOrder.fromJson(voidJob.posOrderJson!);
    expect(pos.kotKind, 'VOID');
    expect(pos.reason, 'Customer changed mind');
    expect(voidJob.targetPrinterId, 'ovenP');

    // Sent items block cancelling until everything is voided.
    await expectLater(orders.cancel(orderId, 'left'), rejects('Void them'));
    await kitchen.voidItems(
      line,
      qty: 1,
      reason: 'left',
      clientRequestId: rid(),
    );
    await orders.cancel(orderId, 'Customer left');
  });

  test(
    'reprint makes a marked copy, no new ticket, no quantity change',
    () async {
      await orders.addItem(orderId, cfg(tea), qty: 2);
      final r = await kitchen.sendToKitchen(orderId, clientRequestId: rid());
      final count = await kitchen.reprintTicket(r.ticketIds.single);
      expect(count, 1);
      expect(await kitchen.ticketsFor(orderId), hasLength(1));
      final all = await jobs();
      expect(all, hasLength(2));
      final copy = all.last;
      expect(copy.sourceKey, startsWith('REPRINT:KOT:'));
      expect(PosOrder.fromJson(copy.posOrderJson!).isReprint, isTrue);
      expect((await orders.getDetail(orderId))!.lines.single.sentQty, 2);
    },
  );

  test('a printer failure never rolls back the ticket or the order', () async {
    await orders.addItem(orderId, cfg(tea));
    await kitchen.sendToKitchen(orderId, clientRequestId: rid());

    var fail = true;
    final queue = await PrintQueueManager.createForTesting(storage, (
      o,
      d,
      m,
    ) async {
      if (fail) throw Exception('Printer offline');
    });
    await queue.syncFromStorage();
    await _settle(queue);

    var t = (await kitchen.ticketsFor(orderId)).single;
    expect(t.printState, TicketPrintState.failed);
    expect(t.lastError, 'Printer offline');
    expect((await orders.getDetail(orderId))!.lines.single.sentQty, 1);

    fail = false;
    await queue.retryJob(t.jobs.single.id);
    await _settle(queue);
    t = (await kitchen.ticketsFor(orderId)).single;
    expect(t.printState, TicketPrintState.printed);
  });
}

Future<void> _settle(PrintQueueManager q) async {
  for (var i = 0; i < 100; i++) {
    await q.processNext();
    if (!q.currentQueue.any((j) => j.isActive)) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
