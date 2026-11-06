import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/clock.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/data/repositories/report_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/domain/reports/report_models.dart';
import 'package:thermalprinter/domain/shifts/shift_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/services/report_csv.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late ReportRepository reports;
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
    categoryId: 'main',
    name: 'Dal Makhani',
    basePrice: Money(25000),
    taxProfileId: 'gst5',
  );
  const water = MenuItem(
    id: 'water',
    categoryId: 'drinks',
    name: 'Water',
    basePrice: Money(2000),
  );

  ConfiguredItem cfg(MenuItem i) => configureItem(
    item: i,
    groups: const {},
    selected: const {},
    tax: i.taxProfileId == null ? null : gst5,
  );

  Future<String> newOrder(OrderType type, {String? table}) =>
      storage.orders.createOrder(
        NewOrderRequest(clientRequestId: rid(), type: type, tableId: table),
      );

  Future<String> bill(String orderId) => storage.bills.finalize(
    orderId,
    clientRequestId: rid(),
    allowUnsent: true,
    print: false,
  );

  Future<String> pay(String billId, PaymentMethod m, int paise) =>
      storage.payments.record(
        PaymentRequest(
          billId: billId,
          method: m,
          amount: Money(paise),
          staffConfirmed: m != PaymentMethod.cash,
          clientRequestId: rid(),
        ),
      );

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    reports = storage.reports;
    final m = storage.menu;
    await m.saveTaxProfile(gst5);
    await m.saveCategory(const MenuCategory(id: 'main', name: 'Mains'));
    await m.saveCategory(const MenuCategory(id: 'drinks', name: 'Drinks'));
    await m.saveItem(dal);
    await m.saveItem(water);
    await storage.tables.saveArea(const DiningArea(id: 'a', name: 'In'));
    await storage.tables.saveTable(
      const RestaurantTable(id: 't1', areaId: 'a', label: 'T1'),
    );
  });
  tearDown(() async {
    Clock.now = DateTime.now;
    StorageService.resetForTesting();
    await db.close();
  });

  test('empty day: zeros and nothing to check', () async {
    final today = await storage.orders.currentBusinessDate();
    final r = await reports.build(ReportPeriod.day(today));
    expect(r.totals.bills, 0);
    expect(r.totals.billed, Money.zero);
    expect(r.totals.averageBill, Money.zero);
    expect(r.collected, Money.zero);
    expect(r.issues, isEmpty);
    expect(r.dues, isEmpty);
  });

  /// A day with split, part and refunded payments, a voided bill, a
  /// cancelled order, an item void, a discount and expenses.
  Future<SalesReport> busyDay() async {
    // 1. Dine-in T1: 2 dal (5% GST added) + water; one extra water sent to
    //    the kitchen and voided. 520 + 25 tax = 545.
    final o1 = await newOrder(OrderType.dineIn, table: 't1');
    await storage.orders.addItem(o1, cfg(dal), qty: 2);
    final w = await storage.orders.addItem(o1, cfg(water), qty: 2);
    await storage.kitchen.sendToKitchen(o1, clientRequestId: rid());
    await storage.kitchen.voidItems(
      w,
      qty: 1,
      reason: 'Wrong item',
      clientRequestId: rid(),
    );
    final b1 = await bill(o1);
    await pay(b1, PaymentMethod.cash, 30000); // before any shift
    await storage.shifts.open(
      openingCash: const Money(100000),
      staffName: 'Asha',
      clientRequestId: rid(),
    );
    await pay(b1, PaymentMethod.upi, 24500);

    // 2. Takeaway: 2 dal, 10% off. 500 − 50 = 450 + 22.50 tax = 472.50.
    final o2 = await newOrder(OrderType.takeaway);
    await storage.orders.addItem(o2, cfg(dal), qty: 2);
    await storage.orders.setDiscount(
      o2,
      const OrderDiscount(
        kind: DiscountKind.percent,
        value: 1000,
        reason: 'Regular',
      ),
    );
    final b2 = await bill(o2);
    final cash = await pay(b2, PaymentMethod.cash, 10000);
    await storage.payments.reverse(
      cash,
      reason: 'Overcharged',
      clientRequestId: rid(),
    );
    await pay(b2, PaymentMethod.upi, 5000);

    // 3. Cancelled before the kitchen.
    final o3 = await newOrder(OrderType.takeaway);
    await storage.orders.addItem(o3, cfg(water));
    await storage.orders.cancel(o3, 'Customer left');

    // 4. Takeaway water: billed, voided, billed again, paid by card.
    final o4 = await newOrder(OrderType.takeaway);
    await storage.orders.addItem(o4, cfg(water));
    await storage.bills.voidBill(await bill(o4), 'Wrong table');
    await pay(await bill(o4), PaymentMethod.card, 2000);

    // Expenses: one from the drawer, one from the bank.
    await storage.shifts.recordExpense(
      category: 'Gas',
      amount: const Money(15000),
      paidFrom: ExpenseSource.cash,
      clientRequestId: rid(),
    );
    await storage.shifts.recordExpense(
      category: 'Rent',
      amount: const Money(50000),
      paidFrom: ExpenseSource.bank,
      clientRequestId: rid(),
    );

    final today = await storage.orders.currentBusinessDate();
    return reports.build(ReportPeriod.day(today));
  }

  test('sales totals come from finalized bills only', () async {
    final r = await busyDay();
    final t = r.totals;
    expect(t.bills, 3);
    expect(t.itemQty, 2 + 1 + 2 + 1);
    expect(t.itemsTotal, const Money(52000 + 50000 + 2000));
    expect(t.discount, const Money(5000));
    expect(t.exclusiveTax, const Money(2500 + 2250));
    expect(t.inclusiveTax, Money.zero);
    expect(t.billed, const Money(54500 + 47250 + 2000));
    // Net before tax = items − discount.
    expect(t.netSales, const Money(104000 - 5000));
    expect(t.averageBill, const Money(34583)); // 1037.50 / 3
    expect(r.issues, isEmpty);
  });

  test('collections by payment, refunds kept apart', () async {
    final r = await busyDay();
    final cash = r.collections.singleWhere((c) => c.method == 'Cash');
    expect(cash.payments, 2);
    expect(cash.received, const Money(40000));
    expect(cash.reversals, 1);
    expect(cash.reversed, const Money(10000));
    expect(cash.net, const Money(30000));
    expect(r.collectedBy('UPI'), const Money(29500));
    expect(r.collectedBy('Card'), const Money(2000));
    expect(r.collections.map((c) => c.method), ['Cash', 'UPI', 'Card']);
    expect(r.collected, const Money(61500));
    expect(r.collectedForPeriodBills, const Money(61500));
    expect(r.collectedForOtherBills, Money.zero);
    expect(r.refunds, const Money(10000));
    // The first cash payment was taken before the shift opened.
    expect(r.cashOutsideShifts, const Money(30000));
    expect(r.ledger, hasLength(6));

    // Billed = paid + still to collect.
    expect(r.paidOnPeriodBills, const Money(61500));
    expect(r.outstandingOnPeriodBills, const Money(47250 - 5000));
    expect(r.paidOnPeriodBills + r.outstandingOnPeriodBills, r.totals.billed);
    expect(r.splitPaidBills, 1);
    expect(r.partPaidBills, 1);
    expect(r.unpaidBills, 0);
    expect(r.dues.single.balance, const Money(42250));
    expect(r.duesTotal, const Money(42250));
  });

  test('items, categories, tax, groups', () async {
    final r = await busyDay();
    final dalRow = r.items.singleWhere((i) => i.name == 'Dal Makhani');
    expect(dalRow.qty, 4);
    expect(dalRow.category, 'Mains');
    expect(dalRow.gross, const Money(100000));
    expect(dalRow.discount, const Money(5000));
    expect(dalRow.net, const Money(95000));
    final waterRow = r.items.singleWhere((i) => i.name == 'Water');
    expect(waterRow.qty, 2);
    expect(r.categories.map((c) => c.name), ['Mains', 'Drinks']);

    final tax = r.taxes.single;
    expect(tax.rateBp, 500);
    expect(tax.taxable, const Money(95000));
    expect(tax.cgst, const Money(1250 + 1125));
    expect(tax.sgst, const Money(1250 + 1125));
    expect(tax.tax, r.totals.totalTax);
    expect(tax.label, 'Items CGST+SGST 5%');

    expect(
      r.byOrderType.map((g) => (g.label, g.bills, g.billed)),
      containsAll([
        ('Dine-in', 1, const Money(54500)),
        ('Takeaway', 2, const Money(49250)),
      ]),
    );
    expect(r.byTable.single.label, 'T1');
    expect(r.byStaff.single.label, 'Not set');
  });

  test('voids, cancellations, refunds, discounts, expenses', () async {
    final r = await busyDay();
    expect(r.voidedBills.single.voidReason, 'Wrong table');
    expect(r.voidedBillsTotal, const Money(2000));
    expect(r.voidedBills.single.state, BillPayState.voided);
    expect(r.cancelledCount, 1);
    expect(r.cancelledOrders.single.reason, 'Customer left');
    expect(r.cancelledOrders.single.value, const Money(2000));
    expect(r.itemVoids.single.itemName, 'Water');
    expect(r.itemVoids.single.reason, 'Wrong item');
    expect(r.reversals.single.amount, const Money(10000));
    expect(r.reversals.single.reason, 'Overcharged');
    expect(r.discounts.single.amount, const Money(5000));
    expect(r.discounts.single.reason, 'Regular');
    expect(r.expensesTotal, const Money(65000));
    expect(r.expensesBySource, {
      'Cash (drawer)': const Money(15000),
      'Bank transfer': const Money(50000),
    });
    expect(r.shifts.single.openedBy, 'Asha');
  });

  test('a payment for an earlier bill counts as collected, not sold', () async {
    Clock.now = () => DateTime(2026, 11, 6, 13);
    final o = await newOrder(OrderType.takeaway);
    await storage.orders.addItem(o, cfg(water));
    final b = await bill(o);
    Clock.now = () => DateTime(2026, 11, 7, 13);
    await pay(b, PaymentMethod.cash, 2000);

    final day7 = await reports.build(const ReportPeriod.day('2026-11-07'));
    expect(day7.totals.bills, 0);
    expect(day7.collected, const Money(2000));
    expect(day7.collectedForOtherBills, const Money(2000));

    final day6 = await reports.build(const ReportPeriod.day('2026-11-06'));
    expect(day6.totals.billed, const Money(2000));
    expect(day6.collected, Money.zero);
    expect(day6.paidOnPeriodBills, const Money(2000));
    expect(day6.outstandingOnPeriodBills, Money.zero);

    final both = await reports.build(
      const ReportPeriod('2026-11-06', '2026-11-07'),
    );
    expect(both.totals.bills, 1);
    expect(both.collectedForPeriodBills, const Money(2000));
    expect(both.issues, isEmpty);
  });

  test('reconciliation finds data that does not add up', () async {
    final o = await newOrder(OrderType.takeaway);
    await storage.orders.addItem(o, cfg(dal));
    final b = await bill(o);
    await pay(b, PaymentMethod.cash, 26250);
    final today = await storage.orders.currentBusinessDate();
    expect((await reports.build(ReportPeriod.day(today))).issues, isEmpty);

    // Tamper with stored rows the way a bad edit or bug might.
    await (db.update(db.billLines)..where((l) => l.billId.equals(b))).write(
      const BillLinesCompanion(grossPaise: Value(20000)),
    );
    await (db.update(db.orders)..where((x) => x.id.equals(o))).write(
      OrdersCompanion(status: Value(OrderStatus.billed.name)),
    );
    final r = await reports.build(ReportPeriod.day(today));
    final text = r.issues.map((i) => i.toString()).join('\n');
    expect(text, contains('item lines add up to ₹200.00'));
    expect(text, contains('fully paid but not marked Paid'));
  });

  test('print summary queues a report job', () async {
    await busyDay();
    final today = await storage.orders.currentBusinessDate();
    await reports.printSummary(ReportPeriod.day(today), includeItems: true);
    final job = (await storage.printJobs.getAllJobs()).singleWhere(
      (j) => j.printType == 'SALES_REPORT',
    );
    final data = PosOrder.fromJson(job.posOrderJson!).report!;
    expect(data['title'], 'DAILY REPORT');
    final titles = [
      for (final s in (data['sections'] as List).cast<Map>()) s['title'],
    ];
    expect(titles, contains('MONEY COLLECTED (by payment date)'));
    expect(titles, contains('ITEM SALES (after discount)'));
    expect(data['issues'], 0);
    final audit = await db.select(db.auditLog).get();
    expect(audit.map((a) => a.action), contains('report.printed'));
  });

  test('CSV export: one file per report, plain amounts, safe text', () async {
    final o = await newOrder(OrderType.takeaway);
    await storage.orders.updateDetails(
      o,
      customerName: '=HYPERLINK("x")',
      customerPhone: '',
      notes: '',
    );
    await storage.orders.addItem(o, cfg(dal), qty: 4);
    final b = await bill(o);
    await pay(b, PaymentMethod.cash, 50000);
    final today = await storage.orders.currentBusinessDate();
    final r = await reports.build(ReportPeriod.day(today));
    final files = ReportCsv.files(r);
    expect(files.keys, contains('bills-$today.csv'));
    expect(files.keys, hasLength(8));
    final bills = ReportCsv.bills(r);
    expect(bills.first.first, 'bill_no');
    final row = bills[1];
    expect(row[6], "'=HYPERLINK(\"x\")");
    expect(row[15], '1050.00'); // total
    expect(row[16], '500.00'); // paid
    expect(row[17], '550.00'); // balance
    expect(row[18], 'Part paid');
    final summary = ReportCsv.summary(r);
    expect(
      summary,
      contains(
        predicate<List<Object?>>(
          (x) => x[0] == 'collected' && x[1] == 'Cash_net' && x[2] == '500.00',
        ),
      ),
    );
    expect(files['summary-$today.csv']!.startsWith('﻿'), isTrue);
  });
}
