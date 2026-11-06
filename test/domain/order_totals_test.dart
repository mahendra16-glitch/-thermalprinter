import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';

OrderLine line(int unitPaise, int qty, {int voided = 0, int sent = 0}) =>
    OrderLine(
      id: 'l$unitPaise$qty',
      orderId: 'o',
      itemName: 'x',
      basePrice: Money(unitPaise),
      unitPrice: Money(unitPaise),
      qty: qty,
      voidedQty: voided,
      sentQty: sent,
    );

void main() {
  test('items total, count and voided units', () {
    final t = OrderTotals.of([
      line(18000, 2),
      line(9050, 3, voided: 1),
    ], OrderDiscount.none);
    expect(t.itemsTotal, const Money(36000 + 18100));
    expect(t.itemCount, 4);
    expect(t.discount, Money.zero);
  });

  test('percent discount rounds half up to the paisa', () {
    // 10% of ₹123.45 = 12.345 -> 12.35
    expect(
      OrderTotals.discountAmount(
        const Money(12345),
        const OrderDiscount(kind: DiscountKind.percent, value: 1000),
      ),
      const Money(1235),
    );
  });

  test('amount discount cannot exceed the total', () {
    final t = OrderTotals.of([
      line(5000, 1),
    ], const OrderDiscount(kind: DiscountKind.amount, value: 9000));
    expect(t.discount, const Money(5000));
    expect(t.afterDiscount, Money.zero);
  });

  test('unsent and billable quantities', () {
    final l = line(100, 5, sent: 2, voided: 1);
    expect(l.billableQty, 4);
    expect(l.unsentQty, 2);
  });

  group('business date', () {
    test('midnight start', () {
      expect(businessDateFor(DateTime(2026, 11, 6, 0, 30)), '2026-11-06');
    });

    test('4 am start counts 1 am as the previous day', () {
      expect(
        businessDateFor(DateTime(2026, 11, 6, 1, 0), dayStartHour: 4),
        '2026-11-05',
      );
      expect(
        businessDateFor(DateTime(2026, 11, 6, 4, 0), dayStartHour: 4),
        '2026-11-06',
      );
    });

    test('month and year boundaries', () {
      expect(
        businessDateFor(DateTime(2027, 1, 1, 2, 0), dayStartHour: 3),
        '2026-12-31',
      );
    });
  });
}
