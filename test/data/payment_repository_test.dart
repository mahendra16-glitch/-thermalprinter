import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/business_profile_repository.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/domain/billing/bill_models.dart';
import 'package:thermalprinter/domain/billing/billing_settings.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late OrderRepository orders;
  late PaymentRepository payments;
  late String orderId;
  late String billId;
  var n = 0;
  String rid() => 'req${n++}';

  const thali = MenuItem(
    id: 'thali',
    categoryId: 'c',
    name: 'Thali',
    basePrice: Money(50000),
  );

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  Future<String> pay(
    PaymentMethod m,
    int paise, {
    int? tendered,
    String reference = '',
    String name = '',
  }) => payments.record(
    PaymentRequest(
      billId: billId,
      method: m,
      amount: Money(paise),
      tendered: tendered == null ? null : Money(tendered),
      reference: reference,
      methodName: name,
      staffConfirmed: m != PaymentMethod.cash,
      clientRequestId: rid(),
    ),
  );

  Future<OrderStatus> status() async =>
      (await orders.getDetail(orderId))!.order.status;

  Future<BillPaymentSummary> summary() => payments.summaryFor(billId);

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    orders = storage.orders;
    payments = storage.payments;
    await storage.menu.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await storage.menu.saveItem(thali);
    await storage.tables.saveArea(const DiningArea(id: 'a', name: 'In'));
    await storage.tables.saveTable(
      const RestaurantTable(id: 't1', areaId: 'a', label: 'T1'),
    );
    await storage.businessProfile.save(
      const BusinessProfile(name: 'Spice Route', upiId: 'spice@okbank'),
    );
    orderId = await orders.createOrder(
      NewOrderRequest(
        clientRequestId: rid(),
        type: OrderType.dineIn,
        tableId: 't1',
      ),
    );
    await orders.addItem(
      orderId,
      configureItem(item: thali, groups: const {}, selected: const {}),
    );
    billId = await storage.bills.finalize(
      orderId,
      clientRequestId: rid(),
      allowUnsent: true,
      print: false,
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  test('unpaid until a payment is posted', () async {
    final s = await summary();
    expect(s.status, PaymentStatus.unpaid);
    expect(s.balance, const Money(50000));
    expect(await status(), OrderStatus.billed);
  });

  test('₹500 fully in cash, with change', () async {
    final id = await pay(PaymentMethod.cash, 50000, tendered: 60000);
    final e = (await payments.getEntry(id))!;
    expect(e.change, const Money(10000));
    expect(e.confirmation, '');
    final s = await summary();
    expect(s.status, PaymentStatus.paid);
    expect(s.balance, Money.zero);
    expect(await status(), OrderStatus.settled);
    // The table is free again.
    expect(await orders.listActive(), isEmpty);
  });

  test('₹500 fully by recorded UPI is staff-confirmed only', () async {
    await expectLater(
      payments.record(
        PaymentRequest(
          billId: billId,
          method: PaymentMethod.upi,
          amount: const Money(50000),
          clientRequestId: rid(),
        ),
      ),
      rejects('Confirm that you checked'),
    );
    final id = await pay(PaymentMethod.upi, 50000, reference: '4123 5566');
    final e = (await payments.getEntry(id))!;
    expect(e.confirmation, staffConfirmed);
    expect(e.reference, '4123 5566');
    expect(await status(), OrderStatus.settled);
  });

  test('₹200 cash + ₹300 UPI', () async {
    await pay(PaymentMethod.cash, 20000);
    expect((await summary()).status, PaymentStatus.partlyPaid);
    expect(await status(), OrderStatus.billed);
    await pay(PaymentMethod.upi, 30000);
    expect((await summary()).status, PaymentStatus.paid);
    expect(await status(), OrderStatus.settled);
  });

  test('₹100 cash now and ₹400 later; due stays visible', () async {
    await pay(PaymentMethod.cash, 10000);
    var dues = await payments.listDues();
    expect(dues.single.summary.balance, const Money(40000));
    await pay(PaymentMethod.cash, 40000);
    dues = await payments.listDues();
    expect(dues, isEmpty);
    final s = await summary();
    expect(s.entries, hasLength(2), reason: 'earlier payment not overwritten');
  });

  test('₹200 UPI now and ₹300 cash later', () async {
    await pay(PaymentMethod.upi, 20000);
    await pay(PaymentMethod.cash, 30000, tendered: 30000);
    expect((await summary()).status, PaymentStatus.paid);
  });

  test('card and other methods; other needs a name', () async {
    await pay(PaymentMethod.card, 20000, reference: 'slip 77');
    await expectLater(pay(PaymentMethod.other, 100), rejects('name'));
    await pay(PaymentMethod.other, 30000, name: 'Zomato');
    final s = await summary();
    expect(s.entries.last.methodLabel, 'Zomato');
    expect(s.status, PaymentStatus.paid);
  });

  test('cannot collect more than the balance or ₹0', () async {
    await expectLater(pay(PaymentMethod.cash, 50001), rejects('balance'));
    await expectLater(pay(PaymentMethod.cash, 0), rejects('above'));
    await expectLater(
      pay(PaymentMethod.cash, 20000, tendered: 10000),
      rejects('less than'),
    );
    await pay(PaymentMethod.cash, 50000);
    await expectLater(pay(PaymentMethod.cash, 100), rejects('no payment'));
  });

  test('same request id records one payment', () async {
    final r = PaymentRequest(
      billId: billId,
      method: PaymentMethod.cash,
      amount: const Money(10000),
      clientRequestId: rid(),
    );
    final a = await payments.record(r);
    final b = await payments.record(r);
    expect(a, b);
    expect((await summary()).entries, hasLength(1));
  });

  test('reversal keeps the original and reopens the balance', () async {
    final p = await pay(PaymentMethod.upi, 50000);
    expect(await status(), OrderStatus.settled);
    await expectLater(
      payments.reverse(p, reason: '', clientRequestId: rid()),
      rejects('reason'),
    );
    final rev = await payments.reverse(
      p,
      reason: 'UPI not received',
      clientRequestId: rid(),
    );
    final s = await summary();
    expect(s.entries, hasLength(2));
    expect(s.entries.first.id, p);
    expect(s.paid, Money.zero);
    expect(s.livePayments, isEmpty);
    // Settled orders go to dues; the table stays free.
    expect(await status(), OrderStatus.due);
    expect(await orders.listActive(), isEmpty);
    expect((await payments.listDues()).single.order.id, orderId);

    await expectLater(
      payments.reverse(p, reason: 'again', clientRequestId: rid()),
      rejects('already reversed'),
    );
    await expectLater(
      payments.reverse(rev, reason: 'x', clientRequestId: rid()),
      rejects('cannot be reversed'),
    );
    // Paying the due settles it.
    await pay(PaymentMethod.cash, 50000);
    expect(await status(), OrderStatus.settled);
  });

  test(
    'a bill with payments cannot be voided until they are reversed',
    () async {
      final p = await pay(PaymentMethod.cash, 10000);
      await expectLater(
        storage.bills.voidBill(billId, 'wrong'),
        rejects('Reverse the payments'),
      );
      await payments.reverse(p, reason: 'mistake', clientRequestId: rid());
      await storage.bills.voidBill(billId, 'wrong');
      expect(await status(), OrderStatus.open);
      await expectLater(pay(PaymentMethod.cash, 100), rejects('voided'));
    },
  );

  test('close as due needs a customer and frees the table', () async {
    await pay(PaymentMethod.cash, 10000);
    await expectLater(
      payments.closeAsDue(orderId, 'pays tomorrow'),
      rejects('name or phone'),
    );
    await orders.updateDetails(
      orderId,
      customerName: 'Ravi',
      customerPhone: '',
      notes: '',
    );
    await payments.closeAsDue(orderId, 'pays tomorrow');
    final o = (await orders.getDetail(orderId))!.order;
    expect(o.status, OrderStatus.due);
    expect(o.dueNote, 'pays tomorrow');
    expect(await orders.listActive(), isEmpty);
    expect((await payments.listDues()).single.summary.balance.paise, 40000);
    await pay(PaymentMethod.upi, 40000);
    expect(await status(), OrderStatus.settled);
  });

  test('day totals by method are net of reversals', () async {
    final a = await pay(PaymentMethod.cash, 20000);
    await pay(PaymentMethod.upi, 10000);
    await payments.reverse(a, reason: 'x', clientRequestId: rid());
    final date = await orders.currentBusinessDate();
    final totals = netByMethod(await payments.entriesForDate(date));
    expect(totals['Cash'], Money.zero);
    expect(totals['UPI'], const Money(10000));
  });

  test('receipts and bill reprints show the payments', () async {
    final p = await pay(PaymentMethod.cash, 20000, tendered: 50000);
    await payments.printReceipt(p);
    await storage.bills.reprint(billId);
    final jobs = await storage.printJobs.getAllJobs();
    final receipt = PosOrder.fromJson(
      jobs.singleWhere((j) => j.printType == 'PAYMENT_RECEIPT').posOrderJson!,
    );
    final r = receipt.bill!['receipt'] as Map;
    expect(r['amount'], 20000);
    expect(r['change'], 30000);
    final billJob = PosOrder.fromJson(
      jobs.singleWhere((j) => j.printType == 'BILL').posOrderJson!,
    );
    final b = Bill.fromJson(billJob.bill!);
    expect(b.paid, const Money(20000));
    expect(b.balance, const Money(30000));
    expect(b.upiQr, isEmpty, reason: 'UPI QR on bills is off by default');
  });

  test('UPI QR is printed for the balance only when turned on', () async {
    await storage.bills.saveSettings(const BillingSettings(printUpiQr: true));
    await pay(PaymentMethod.cash, 10000);
    await storage.bills.reprint(billId);
    final job = (await storage.printJobs.getAllJobs()).single;
    final b = Bill.fromJson(PosOrder.fromJson(job.posOrderJson!).bill!);
    expect(b.upiQr, startsWith('upi://pay?pa=spice%40okbank'));
    expect(b.upiQr, contains('am=400.00'));
    expect(await payments.upiLinkFor(billId), b.upiQr);
  });

  test('a ₹0 bill settles straight away', () async {
    final o2 = await orders.createOrder(
      NewOrderRequest(clientRequestId: rid(), type: OrderType.takeaway),
    );
    await orders.addItem(
      o2,
      configureItem(item: thali, groups: const {}, selected: const {}),
    );
    await orders.setDiscount(
      o2,
      const OrderDiscount(
        kind: DiscountKind.percent,
        value: 10000,
        reason: 'Staff meal',
      ),
    );
    await storage.bills.finalize(o2, clientRequestId: rid(), allowUnsent: true);
    expect((await orders.getDetail(o2))!.order.status, OrderStatus.settled);
  });
}
