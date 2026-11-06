import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/bill_repository.dart';
import 'package:thermalprinter/data/repositories/business_profile_repository.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/domain/billing/bill_models.dart';
import 'package:thermalprinter/domain/billing/billing_settings.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/models/print_job.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late OrderRepository orders;
  late BillRepository bills;
  late String orderId;
  var n = 0;
  String rid() => 'req${n++}';

  const gst5 = TaxProfile(
    id: 'gst5',
    name: 'GST 5%',
    rateBp: 500,
    splitMode: TaxSplitMode.cgstSgst,
  );
  const dal = MenuItem(
    id: 'dal',
    categoryId: 'c',
    name: 'Dal Makhani',
    basePrice: Money(25000),
    taxProfileId: 'gst5',
  );
  const water = MenuItem(
    id: 'water',
    categoryId: 'c',
    name: 'Water',
    basePrice: Money(2000),
  );

  ConfiguredItem cfg(MenuItem i) => configureItem(
    item: i,
    groups: const {},
    selected: const {},
    tax: i.taxProfileId == null ? null : gst5,
  );

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    orders = storage.orders;
    bills = storage.bills;
    final m = storage.menu;
    await m.saveTaxProfile(gst5);
    await m.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await m.saveItem(dal);
    await m.saveItem(water);
    await storage.tables.saveArea(const DiningArea(id: 'a', name: 'In'));
    await storage.tables.saveTable(
      const RestaurantTable(id: 't1', areaId: 'a', label: 'T1'),
    );
    await storage.businessProfile.save(
      const BusinessProfile(
        name: 'Spice Route',
        gstin: '27AAAAA0000A1Z5',
        billFooter: 'Thank you',
      ),
    );
    orderId = await orders.createOrder(
      NewOrderRequest(
        clientRequestId: rid(),
        type: OrderType.dineIn,
        tableId: 't1',
      ),
    );
    await orders.addItem(orderId, cfg(dal), qty: 2);
    await orders.addItem(orderId, cfg(water));
    await storage.kitchen.sendToKitchen(orderId, clientRequestId: rid());
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  test('preview calculates without saving', () async {
    final d = await bills.preview(orderId);
    // 2 × 250 + 5% (12.50 + 12.50) + water 20 (untaxed)
    expect(d.calc.grandTotal, const Money(50000 + 2500 + 2000));
    expect(d.unsentUnits, 0);
    expect(await db.select(db.bills).get(), isEmpty);
  });

  test('finalize saves the bill, marks the order billed and prints', () async {
    final id = await bills.finalize(
      orderId,
      clientRequestId: rid(),
      expectedTotal: const Money(54500),
    );
    final b = (await bills.getBill(id))!;
    expect(b.billNumber, '1');
    expect(b.status, BillStatus.finalized);
    expect(b.tableLabel, 'T1');
    expect(b.header.name, 'Spice Route');
    expect(b.header.gstin, '27AAAAA0000A1Z5');
    expect(b.lines.map((l) => l.qty), [2, 1]);
    expect(b.grandTotal, const Money(54500));
    final gst = b.taxes.singleWhere((t) => t.rateBp == 500);
    expect(gst.taxable, const Money(50000));
    expect(gst.cgst, const Money(1250));
    expect(gst.sgst, const Money(1250));

    final o = (await orders.getDetail(orderId))!.order;
    expect(o.status, OrderStatus.billed);
    // Still on the table, waiting for payment.
    final active = await orders.listActive();
    expect(active.single.billTotal, const Money(54500));
    expect(active.single.displayTotal, const Money(54500));

    final jobs = await storage.printJobs.getAllJobs();
    final billJob = jobs.singleWhere((j) => j.printType == 'BILL');
    expect(billJob.effectiveSourceKey, 'BILL:$id');
    final pos = PosOrder.fromJson(billJob.posOrderJson!);
    expect(Bill.fromJson(pos.bill!).grandTotal, const Money(54500));

    final timeline = await orders.timeline(orderId);
    expect(timeline.last.action, 'order.billed');
  });

  test('same request id returns the same bill', () async {
    final req = rid();
    final a = await bills.finalize(orderId, clientRequestId: req);
    final b = await bills.finalize(orderId, clientRequestId: req);
    expect(a, b);
    expect(await db.select(db.bills).get(), hasLength(1));
  });

  test('a changed total is rejected and nothing is saved', () async {
    await expectLater(
      bills.finalize(
        orderId,
        clientRequestId: rid(),
        expectedTotal: const Money(50000),
      ),
      rejects('The bill changed'),
    );
    expect(await db.select(db.bills).get(), isEmpty);
    expect((await orders.getDetail(orderId))!.order.status, OrderStatus.open);
  });

  test('unsent items need confirmation', () async {
    await orders.addItem(orderId, cfg(water));
    await expectLater(
      bills.finalize(orderId, clientRequestId: rid()),
      throwsA(isA<UnsentItemsException>()),
    );
    final id = await bills.finalize(
      orderId,
      clientRequestId: rid(),
      allowUnsent: true,
    );
    expect((await bills.getBill(id))!.lines.last.qty, 2);
  });

  test('an empty order cannot be billed', () async {
    final empty = await orders.createOrder(
      NewOrderRequest(clientRequestId: rid(), type: OrderType.takeaway),
    );
    await expectLater(
      bills.finalize(empty, clientRequestId: rid()),
      rejects('nothing to bill'),
    );
  });

  test('a billed order cannot be edited or billed again', () async {
    await bills.finalize(orderId, clientRequestId: rid());
    await expectLater(
      orders.addItem(orderId, cfg(water)),
      rejects('Void the bill'),
    );
    await expectLater(
      bills.finalize(orderId, clientRequestId: rid()),
      rejects('cannot be billed'),
    );
    // The table is still busy.
    await expectLater(
      orders.createOrder(
        NewOrderRequest(
          clientRequestId: rid(),
          type: OrderType.dineIn,
          tableId: 't1',
        ),
      ),
      throwsA(isA<TableBusyException>()),
    );
  });

  test(
    'void keeps the bill, reopens the order; rebill gets a new number',
    () async {
      final first = await bills.finalize(orderId, clientRequestId: rid());
      await expectLater(bills.voidBill(first, ' '), rejects('reason'));
      await bills.voidBill(first, 'Wrong item');

      final voided = (await bills.getBill(first))!;
      expect(voided.status, BillStatus.voided);
      expect(voided.voidReason, 'Wrong item');
      expect((await orders.getDetail(orderId))!.order.status, OrderStatus.open);
      await expectLater(bills.reprint(first), rejects('voided'));

      await orders.addItem(orderId, cfg(water));
      final second = await bills.finalize(
        orderId,
        clientRequestId: rid(),
        allowUnsent: true,
      );
      final b2 = (await bills.getBill(second))!;
      expect(b2.billNumber, '2');
      expect(b2.grandTotal, const Money(56500));
      expect(await bills.billsForOrder(orderId), hasLength(2));
      expect((await bills.currentBillFor(orderId))!.id, second);

      final actions = (await orders.timeline(orderId)).map((e) => e.action);
      expect(
        actions,
        containsAllInOrder(['order.billed', 'order.bill_voided']),
      );
    },
  );

  test('menu and settings changes never change a finalized bill', () async {
    final id = await bills.finalize(orderId, clientRequestId: rid());
    await storage.menu.saveItem(dal.copyWith(basePrice: const Money(99900)));
    await bills.saveSettings(
      const BillingSettings(
        serviceChargeBp: 1000,
        rounding: RoundingMode.nearestRupee,
      ),
    );
    await storage.businessProfile.save(const BusinessProfile(name: 'New'));
    final b = (await bills.getBill(id))!;
    expect(b.grandTotal, const Money(54500));
    expect(b.serviceCharge, Money.zero);
    expect(b.header.name, 'Spice Route');
    expect(b.lines.first.unitPrice, const Money(25000));
  });

  test('service charge and rounding from settings', () async {
    await bills.saveSettings(
      const BillingSettings(
        serviceChargeBp: 500,
        rounding: RoundingMode.nearestRupee,
      ),
    );
    final id = await bills.finalize(orderId, clientRequestId: rid());
    final b = (await bills.getBill(id))!;
    // Taxable 500 + 20 = 520 -> 5% = 26.00
    expect(b.serviceCharge, const Money(2600));
    expect(b.serviceChargeBp, 500);
    expect(b.grandTotal, const Money(54500 + 2600));
    expect(b.roundOff, Money.zero);
  });

  test('each prefix has its own sequence', () async {
    await bills.saveSettings(const BillingSettings(billNumberPrefix: 'FY26/'));
    final id = await bills.finalize(orderId, clientRequestId: rid());
    expect((await bills.getBill(id))!.billNumber, 'FY26/1');
  });

  test('settings are validated', () async {
    await expectLater(
      bills.saveSettings(const BillingSettings(serviceChargeBp: 6000)),
      rejects('Service charge'),
    );
    await expectLater(
      bills.saveSettings(const BillingSettings(billNumberPrefix: 'INV #')),
      rejects('prefix'),
    );
    await expectLater(
      bills.saveSettings(
        const BillingSettings(
          serviceChargeBp: 500,
          serviceChargeOrderTypes: {},
        ),
      ),
      rejects('order type'),
    );
    expect(await bills.getSettings(), isA<BillingSettings>());
  });

  test(
    'first print of a bill saved without printing is not a duplicate',
    () async {
      final id = await bills.finalize(
        orderId,
        clientRequestId: rid(),
        print: false,
      );
      expect(await bills.printJobsFor(id), isEmpty);
      expect(await bills.reprint(id), isFalse);
      expect(await bills.reprint(id), isTrue);
      final jobs = await bills.printJobsFor(id);
      expect(jobs.map((j) => PosOrder.fromJson(j.posOrderJson!).isReprint), [
        false,
        true,
      ]);
    },
  );

  test('reprint queues a duplicate copy and creates no bill', () async {
    final id = await bills.finalize(orderId, clientRequestId: rid());
    await bills.reprint(id);
    final jobs = (await storage.printJobs.getAllJobs())
        .where((j) => j.printType == 'BILL')
        .toList();
    expect(jobs, hasLength(2));
    final copy = jobs.singleWhere(
      (j) => j.effectiveSourceKey.startsWith('REPRINT:'),
    );
    expect(PosOrder.fromJson(copy.posOrderJson!).isReprint, isTrue);
    expect(await db.select(db.bills).get(), hasLength(1));
    expect(await bills.printJobsFor(id), hasLength(2));
  });
}
