import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/data/repositories/shift_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/domain/shifts/shift_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late ShiftRepository shifts;
  late PaymentRepository payments;
  var n = 0;
  String rid() => 'req${n++}';

  const thali = MenuItem(
    id: 'thali',
    categoryId: 'c',
    name: 'Thali',
    basePrice: Money(90000),
  );

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  /// A ₹900 takeaway bill; returns the bill id.
  Future<String> newBill() async {
    final o = await storage.orders.createOrder(
      NewOrderRequest(clientRequestId: rid(), type: OrderType.takeaway),
    );
    await storage.orders.addItem(
      o,
      configureItem(item: thali, groups: const {}, selected: const {}),
    );
    return storage.bills.finalize(
      o,
      clientRequestId: rid(),
      allowUnsent: true,
      print: false,
    );
  }

  Future<String> pay(String billId, PaymentMethod m, int paise) =>
      payments.record(
        PaymentRequest(
          billId: billId,
          method: m,
          amount: Money(paise),
          staffConfirmed: m != PaymentMethod.cash,
          clientRequestId: rid(),
        ),
      );

  Future<String> openShift([int opening = 100000]) => shifts.open(
    openingCash: Money(opening),
    staffName: 'Asha',
    clientRequestId: rid(),
  );

  Future<String> expense(int paise, ExpenseSource from, [String c = 'Gas']) =>
      shifts.recordExpense(
        category: c,
        amount: Money(paise),
        paidFrom: from,
        clientRequestId: rid(),
      );

  Future<String> move(CashMovementKind k, int paise) => shifts.addMovement(
    kind: k,
    amount: Money(paise),
    reason: 'test',
    clientRequestId: rid(),
  );

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    shifts = storage.shifts;
    payments = storage.payments;
    await storage.menu.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await storage.menu.saveItem(thali);
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  test('open needs a name; only one shift at a time; idempotent', () async {
    await expectLater(
      shifts.open(
        openingCash: Money.zero,
        staffName: ' ',
        clientRequestId: rid(),
      ),
      rejects('name'),
    );
    final req = rid();
    final a = await shifts.open(
      openingCash: const Money(50000),
      staffName: 'Asha',
      clientRequestId: req,
    );
    final b = await shifts.open(
      openingCash: const Money(50000),
      staffName: 'Asha',
      clientRequestId: req,
    );
    expect(a, b);
    await expectLater(openShift(), rejects('already open'));
    final s = (await shifts.currentShift())!;
    expect(s.openingCash, const Money(50000));
    expect(s.openedBy, 'Asha');
  });

  test('expected cash from sales, refunds, movements and expenses', () async {
    final shift = await openShift(100000); // ₹1000
    final bill = await newBill(); // ₹900
    await pay(bill, PaymentMethod.cash, 50000);
    await pay(bill, PaymentMethod.upi, 30000);
    final small = await pay(bill, PaymentMethod.cash, 10000);
    await payments.reverse(small, reason: 'oops', clientRequestId: rid());
    await move(CashMovementKind.addition, 20000);
    await move(CashMovementKind.withdrawal, 30000);
    await expense(15000, ExpenseSource.cash);
    await expense(5000, ExpenseSource.upi, 'Vegetables');

    final s = await shifts.summary(shift);
    expect(s.openingCash, const Money(100000));
    expect(s.cashSales, const Money(60000));
    expect(s.cashRefunds, const Money(10000));
    expect(s.cashAdded, const Money(20000));
    expect(s.cashTakenOut, const Money(30000));
    expect(s.cashExpenses, const Money(15000));
    // 1000 + 600 − 100 + 200 − 300 − 150
    expect(s.expectedCash, const Money(125000));
    // UPI is never drawer cash.
    expect(s.nonCash['UPI'], const Money(30000));
    expect(s.otherExpenses, const Money(5000));
    expect(s.billCount, 1);
    expect(s.paymentCount, 3);
  });

  test('cash expenses and movements need an open shift', () async {
    await expectLater(
      expense(1000, ExpenseSource.cash),
      rejects('Open a shift'),
    );
    await expectLater(
      move(CashMovementKind.addition, 1000),
      rejects('Open a shift'),
    );
    // Non-cash expenses do not.
    final id = await expense(1000, ExpenseSource.bank, 'Rent');
    final date = await storage.orders.currentBusinessDate();
    final list = await shifts.expensesForDate(date);
    expect(list.single.id, id);
    expect(list.single.shiftId, isNull);
  });

  test('cannot take out more cash than the drawer should hold', () async {
    await openShift(10000);
    await expectLater(
      move(CashMovementKind.withdrawal, 10001),
      rejects('should be in the drawer'),
    );
    await expectLater(
      expense(20000, ExpenseSource.cash),
      rejects('should be in the drawer'),
    );
    await move(CashMovementKind.withdrawal, 10000);
  });

  test('cancelled entries keep their record but stop counting', () async {
    final shift = await openShift(10000);
    final e = await expense(2000, ExpenseSource.cash);
    final m = await move(CashMovementKind.addition, 5000);
    await expectLater(shifts.voidExpense(e, ''), rejects('reason'));
    await shifts.voidExpense(e, 'typo');
    await shifts.voidMovement(m, 'typo');
    final s = await shifts.summary(shift);
    expect(s.expectedCash, const Money(10000));
    final exps = await shifts.expensesForShift(shift);
    expect(exps.single.isVoided, isTrue);
    expect(exps.single.voidReason, 'typo');
  });

  test('close: variance needs a reason; closed shifts never change', () async {
    final shift = await openShift(100000);
    final bill = await newBill();
    await pay(bill, PaymentMethod.cash, 20000);
    final e = await expense(1000, ExpenseSource.cash);
    // Expected 1000 + 200 − 10 = 1190.
    await expectLater(
      shifts.close(shift, countedCash: const Money(118000), staffName: 'Ravi'),
      rejects('short by ₹10.00'),
    );
    final variance = await shifts.close(
      shift,
      countedCash: const Money(118000),
      staffName: 'Ravi',
      varianceReason: 'Change given wrong',
      denominations: const {50000: 2, 10000: 1, 5000: 1, 2000: 1, 1000: 1},
    );
    expect(variance, const Money(-1000));
    final s = (await shifts.getShift(shift))!;
    expect(s.isOpen, isFalse);
    expect(s.expectedCash, const Money(119000));
    expect(s.countedCash, const Money(118000));
    expect(s.closedBy, 'Ravi');
    expect(await shifts.currentShift(), isNull);

    await expectLater(shifts.voidExpense(e, 'x'), rejects('closed'));
    await expectLater(
      shifts.close(shift, countedCash: Money.zero, staffName: 'Ravi'),
      rejects('already closed'),
    );

    // Payments still work with no shift open, and are reported apart.
    await pay(bill, PaymentMethod.cash, 30000);
    final date = await storage.orders.currentBusinessDate();
    expect(await shifts.cashOutsideShifts(date), const Money(30000));
    expect((await shifts.summary(shift)).cashSales, const Money(20000));

    // The closing report was queued.
    final job = (await storage.printJobs.getAllJobs()).singleWhere(
      (j) => j.printType == 'SHIFT_REPORT',
    );
    final r = PosOrder.fromJson(job.posOrderJson!).report!;
    expect(r['open'], isFalse);
    expect(r['variance'], -1000);
    expect(r['varianceReason'], 'Change given wrong');
    expect((r['expenses'] as List).single['category'], 'Gas');
  });

  test('exact count closes without a reason', () async {
    final shift = await openShift(50000);
    expect(
      await shifts.close(
        shift,
        countedCash: const Money(50000),
        staffName: 'Asha',
        print: false,
      ),
      Money.zero,
    );
    // A new shift can open now.
    await openShift(0);
  });

  test('categories: defaults plus ones used before', () async {
    await expense(100, ExpenseSource.upi, 'Ice');
    final cats = await shifts.expenseCategories();
    expect(cats, contains('Vegetables'));
    expect(cats, contains('Ice'));
    expect(cats.where((c) => c == 'Gas'), hasLength(1));
  });

  test('denomination count', () {
    expect(
      countDenominations(const {50000: 2, 2000: 3, 100: 4}),
      const Money(106400),
    );
  });
}
