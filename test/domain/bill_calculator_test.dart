import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/domain/billing/bill_calculator.dart';
import 'package:thermalprinter/domain/billing/billing_settings.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';

var _n = 0;

OrderLine line(
  int unitPaise,
  int qty, {
  int rateBp = 0,
  bool inclusive = false,
  TaxSplitMode split = TaxSplitMode.cgstSgst,
  int voided = 0,
}) => OrderLine(
  id: 'l${_n++}',
  orderId: 'o',
  itemName: 'Item $_n',
  basePrice: Money(unitPaise),
  unitPrice: Money(unitPaise),
  taxRateBp: rateBp,
  taxInclusive: inclusive,
  taxSplitMode: split,
  qty: qty,
  sentQty: voided,
  voidedQty: voided,
);

BillCalculation calc(
  List<OrderLine> lines, {
  OrderDiscount discount = OrderDiscount.none,
  OrderType type = OrderType.dineIn,
  BillingSettings settings = BillingSettings.defaults,
}) => calculateBill(
  lines: lines,
  discount: discount,
  orderType: type,
  settings: settings,
);

void main() {
  test('exclusive 5% CGST+SGST is added on top', () {
    final b = calc([line(10000, 2, rateBp: 500)]);
    final t = b.taxes.single;
    expect(t.taxable, const Money(20000));
    expect(t.cgst, const Money(500));
    expect(t.sgst, const Money(500));
    expect(b.grandTotal, const Money(21000));
    expect(b.exclusiveTax, const Money(1000));
  });

  test('inclusive 5% is taken out of the price; total stays the same', () {
    final b = calc([line(10500, 1, rateBp: 500, inclusive: true)]);
    final t = b.taxes.single;
    expect(t.inclusive, isTrue);
    expect(t.taxable, const Money(10000));
    expect(t.cgst, const Money(250));
    expect(t.sgst, const Money(250));
    expect(b.grandTotal, const Money(10500));
    expect(b.inclusiveTax, const Money(500));
    expect(b.exclusiveTax, Money.zero);
  });

  test('inclusive 18% single-line tax rounds half up', () {
    // 100 × 18 / 118 = 15.254… -> 15.25
    final b = calc([
      line(10000, 1, rateBp: 1800, inclusive: true, split: TaxSplitMode.none),
    ]);
    expect(b.taxes.single.other, const Money(1525));
    expect(b.taxes.single.taxable, const Money(8475));
    expect(b.grandTotal, const Money(10000));
  });

  test('IGST is a single amount', () {
    final b = calc([line(10000, 1, rateBp: 1200, split: TaxSplitMode.igst)]);
    expect(b.taxes.single.igst, const Money(1200));
    expect(b.taxes.single.cgst, Money.zero);
    expect(b.grandTotal, const Money(11200));
  });

  test('mixed rates with a percent discount shared before tax', () {
    final b = calc(
      [
        line(20000, 1, rateBp: 500),
        line(10000, 1, rateBp: 1800),
        line(5000, 1),
      ],
      discount: const OrderDiscount(
        kind: DiscountKind.percent,
        value: 1000,
        reason: 'Regular',
      ),
    );
    expect(b.itemsTotal, const Money(35000));
    expect(b.discount, const Money(3500));
    expect(b.lines.map((l) => l.discount.paise), [2000, 1000, 500]);
    expect(b.taxes.map((t) => t.rateBp), [0, 500, 1800]);
    expect(b.taxes[0].tax, Money.zero);
    expect(b.taxes[0].taxable, const Money(4500));
    expect(b.taxes[1].taxable, const Money(18000));
    expect(b.taxes[1].tax, const Money(900));
    expect(b.taxes[2].taxable, const Money(9000));
    expect(b.taxes[2].tax, const Money(1620));
    expect(b.grandTotal, const Money(34020));
  });

  test('discount shares always add up to the discount', () {
    final b = calc([
      line(3333, 1),
      line(3333, 1),
      line(3334, 1),
    ], discount: const OrderDiscount(kind: DiscountKind.amount, value: 100));
    expect(b.lines.map((l) => l.discount.paise), [33, 33, 34]);
  });

  test('voided units are not billed', () {
    final b = calc([line(10000, 3, voided: 1), line(5000, 2, voided: 2)]);
    expect(b.lines, hasLength(1));
    expect(b.lines.single.qty, 2);
    expect(b.grandTotal, const Money(20000));
  });

  group('rounding', () {
    Money total(int paise, RoundingMode m) => calc([
      line(paise, 1),
    ], settings: BillingSettings(rounding: m)).grandTotal;

    test('none keeps exact paise', () {
      expect(total(34020, RoundingMode.none), const Money(34020));
    });

    test('nearest rupee', () {
      expect(total(34020, RoundingMode.nearestRupee), const Money(34000));
      expect(total(34050, RoundingMode.nearestRupee), const Money(34100));
      expect(total(34049, RoundingMode.nearestRupee), const Money(34000));
    });

    test('nearest 50 paise', () {
      expect(total(34026, RoundingMode.nearestHalfRupee), const Money(34050));
      expect(total(34024, RoundingMode.nearestHalfRupee), const Money(34000));
    });

    test('always down / always up', () {
      expect(total(34099, RoundingMode.downRupee), const Money(34000));
      expect(total(34001, RoundingMode.upRupee), const Money(34100));
      expect(total(34000, RoundingMode.upRupee), const Money(34000));
    });

    test('round off is printed as the difference', () {
      final b = calc([
        line(34020, 1),
      ], settings: const BillingSettings(rounding: RoundingMode.nearestRupee));
      expect(b.roundOff, const Money(-20));
      expect(b.beforeRounding, const Money(34020));
    });
  });

  group('service charge', () {
    const settings = BillingSettings(
      serviceChargeBp: 1000,
      serviceChargeTaxBp: 500,
      serviceChargeTaxSplit: TaxSplitMode.cgstSgst,
    );

    test('applies to dine-in on the pre-tax value, with its own tax', () {
      final b = calc([line(10000, 1, rateBp: 500)], settings: settings);
      expect(b.serviceCharge, const Money(1000));
      expect(b.serviceChargeBp, 1000);
      final sc = b.taxes.singleWhere((t) => t.base == TaxBase.serviceCharge);
      expect(sc.taxable, const Money(1000));
      expect(sc.tax, const Money(50));
      expect(b.grandTotal, const Money(10000 + 500 + 1000 + 50));
    });

    test('is calculated on the value without inclusive tax', () {
      final b = calc([
        line(10500, 1, rateBp: 500, inclusive: true),
      ], settings: settings);
      expect(b.serviceCharge, const Money(1000));
    });

    test('does not apply to other order types unless chosen', () {
      final b = calc(
        [line(10000, 1, rateBp: 500)],
        type: OrderType.takeaway,
        settings: settings,
      );
      expect(b.serviceCharge, Money.zero);
      expect(b.serviceChargeBp, 0);
      expect(b.grandTotal, const Money(10500));
    });

    test('is off by default', () {
      expect(calc([line(10000, 1)]).serviceCharge, Money.zero);
    });
  });

  test('totals always add up (random orders)', () {
    final r = Random(42);
    const rates = [0, 500, 1200, 1800, 2800];
    for (var round = 0; round < 500; round++) {
      final lines = [
        for (var i = 0; i < 1 + r.nextInt(6); i++)
          line(
            1 + r.nextInt(99999),
            1 + r.nextInt(5),
            rateBp: rates[r.nextInt(rates.length)],
            inclusive: r.nextBool(),
            split: TaxSplitMode.values[r.nextInt(3)],
          ),
      ];
      final discount = r.nextBool()
          ? OrderDiscount(
              kind: DiscountKind.percent,
              value: r.nextInt(5001),
              reason: 'x',
            )
          : OrderDiscount(
              kind: DiscountKind.amount,
              value: r.nextInt(20000),
              reason: 'x',
            );
      final settings = BillingSettings(
        serviceChargeBp: r.nextBool() ? r.nextInt(1500) : 0,
        serviceChargeTaxBp: r.nextBool() ? 500 : 0,
        rounding: RoundingMode.values[r.nextInt(RoundingMode.values.length)],
      );
      final b = calc(lines, discount: discount, settings: settings);

      expect(
        b.lines.fold<int>(0, (s, l) => s + l.discount.paise),
        b.discount.paise,
      );
      expect(
        b.grandTotal,
        b.itemsTotal -
            b.discount +
            b.serviceCharge +
            b.exclusiveTax +
            b.roundOff,
      );
      final itemNet = b.lines.fold<int>(0, (s, l) => s + l.net.paise);
      final itemGroups = b.taxes.where((t) => t.base == TaxBase.items);
      expect(
        itemGroups.fold<int>(
          0,
          (s, t) => s + t.taxable.paise + (t.inclusive ? t.tax.paise : 0),
        ),
        itemNet,
      );
      expect(b.grandTotal.isNegative, isFalse);
      for (final t in b.taxes) {
        expect(t.cgst, t.sgst);
        expect(t.taxable.isNegative, isFalse);
      }
    }
  });
}
