import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/domain/reports/report_models.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

/// Rough timing on the development PC, through the real repositories (one
/// transaction per action, as in the app). Phones are slower; the numbers
/// are reported in docs/IMPLEMENTATION_PLAN.md and the limits here are
/// only there to catch a big slow-down.
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

  test('400 bills with 3 items each: order flow and reports', () async {
    await storage.menu.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    final items = [
      for (var i = 0; i < 30; i++)
        MenuItem(
          id: 'i$i',
          categoryId: 'c',
          name: 'Item $i',
          basePrice: Money(5000 + i * 1000),
        ),
    ];
    for (final i in items) {
      await storage.menu.saveItem(i);
    }
    var n = 0;
    final sw = Stopwatch()..start();
    const orders = 400;
    for (var k = 0; k < orders; k++) {
      final o = await storage.orders.createOrder(
        NewOrderRequest(clientRequestId: 'o$k', type: OrderType.takeaway),
      );
      for (var j = 0; j < 3; j++) {
        await storage.orders.addItem(
          o,
          configureItem(
            item: items[(k + j * 7) % items.length],
            groups: const {},
            selected: const {},
          ),
        );
      }
      final billId = await storage.bills.finalize(
        o,
        clientRequestId: 'b$k',
        allowUnsent: true,
        print: false,
      );
      final due = (await storage.payments.summaryFor(billId)).balance;
      await storage.payments.record(
        PaymentRequest(
          billId: billId,
          method: k.isEven ? PaymentMethod.cash : PaymentMethod.upi,
          amount: due,
          staffConfirmed: k.isOdd,
          clientRequestId: 'p${n++}',
        ),
      );
    }
    final perOrderMs = sw.elapsedMilliseconds / orders;

    final today = await storage.orders.currentBusinessDate();
    sw.reset();
    final r = await storage.reports.build(ReportPeriod.day(today));
    final reportMs = sw.elapsedMilliseconds;
    sw.reset();
    final dues = await storage.payments.listDues();
    final duesMs = sw.elapsedMilliseconds;

    // ignore: avoid_print
    print(
      'PERF order+3 items+bill+payment: ${perOrderMs.toStringAsFixed(1)} ms '
      'each; report for $orders bills: $reportMs ms; dues list: $duesMs ms',
    );
    expect(r.totals.bills, orders);
    expect(r.issues, isEmpty, reason: 'ledger check');
    expect(r.outstandingOnPeriodBills, Money.zero);
    expect(dues, isEmpty);
    expect(reportMs, lessThan(10000));
    expect(perOrderMs, lessThan(500));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
