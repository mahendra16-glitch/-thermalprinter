import '../../core/util/money.dart';
import '../menu/menu_models.dart';
import '../orders/order_models.dart';
import 'billing_settings.dart';

/// What a tax amount was charged on.
enum TaxBase { items, serviceCharge }

/// One line of the bill as calculated.
class BillLineCalc {
  final String orderLineId;
  final String name;
  final String variantText;
  final List<String> addons;
  final int qty;
  final Money unitPrice;

  /// unitPrice × qty, as entered (may already include tax).
  final Money gross;

  /// This line's share of the order discount.
  final Money discount;
  final int taxRateBp;
  final bool taxInclusive;
  final TaxSplitMode taxSplitMode;

  const BillLineCalc({
    required this.orderLineId,
    required this.name,
    required this.variantText,
    required this.addons,
    required this.qty,
    required this.unitPrice,
    required this.gross,
    required this.discount,
    required this.taxRateBp,
    required this.taxInclusive,
    required this.taxSplitMode,
  });

  Money get net => gross - discount;
}

/// Tax for all lines that share a rate, pricing and split mode.
///
/// For CGST + SGST each half is calculated and rounded separately, so the
/// two printed amounts are always equal.
class TaxGroupCalc {
  final TaxBase base;
  final int rateBp;
  final bool inclusive;
  final TaxSplitMode splitMode;

  /// Value the tax is charged on (excludes the tax itself).
  final Money taxable;
  final Money cgst;
  final Money sgst;
  final Money igst;

  /// Tax shown on a single line ([TaxSplitMode.none]).
  final Money other;

  const TaxGroupCalc({
    required this.base,
    required this.rateBp,
    required this.inclusive,
    required this.splitMode,
    required this.taxable,
    this.cgst = Money.zero,
    this.sgst = Money.zero,
    this.igst = Money.zero,
    this.other = Money.zero,
  });

  Money get tax => cgst + sgst + igst + other;
}

/// A complete bill calculation. All amounts are integer paise.
///
/// Printed order and identity:
/// ```
/// itemsTotal
/// - discount
/// + serviceCharge
/// + exclusive tax (items and service charge)
/// + roundOff
/// = grandTotal
/// ```
/// Inclusive tax is already inside [itemsTotal] and is shown as
/// "included".
class BillCalculation {
  final List<BillLineCalc> lines;
  final Money itemsTotal;
  final Money discount;
  final Money serviceCharge;
  final int serviceChargeBp;
  final List<TaxGroupCalc> taxes;
  final Money roundOff;
  final Money grandTotal;
  final RoundingMode rounding;

  const BillCalculation({
    required this.lines,
    required this.itemsTotal,
    required this.discount,
    required this.serviceCharge,
    required this.serviceChargeBp,
    required this.taxes,
    required this.roundOff,
    required this.grandTotal,
    required this.rounding,
  });

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  Money get totalTax => taxes.fold(Money.zero, (s, t) => s + t.tax);

  /// Tax added on top of prices.
  Money get exclusiveTax =>
      taxes.where((t) => !t.inclusive).fold(Money.zero, (s, t) => s + t.tax);

  /// Tax already inside menu prices.
  Money get inclusiveTax =>
      taxes.where((t) => t.inclusive).fold(Money.zero, (s, t) => s + t.tax);

  /// Total before rounding.
  Money get beforeRounding => grandTotal - roundOff;

  Money get taxableTotal => taxes.fold(Money.zero, (s, t) => s + t.taxable);
}

/// Rounds a / b half up. a >= 0, b > 0.
int _div(int a, int b) => (a * 2 + b) ~/ (b * 2);

/// Calculates a bill for the billable units of [lines].
///
/// Steps (all integer paise, half-up rounding):
/// 1. Each line's gross = unit price × billable qty.
/// 2. The order discount is shared across lines in proportion to gross
///    (largest remainder, so the shares add up exactly).
/// 3. Lines are grouped by tax rate, inclusive/exclusive and split mode;
///    tax is calculated once per group on the discounted value.
///    Exclusive: tax = value × rate. Inclusive: tax = value × rate /
///    (100% + rate), and the taxable value is the rest.
/// 4. Service charge (if it applies) = rate × taxable value of the items,
///    with its own configured tax.
/// 5. The total is rounded as configured; the difference is "round off".
BillCalculation calculateBill({
  required List<OrderLine> lines,
  required OrderDiscount discount,
  required OrderType orderType,
  required BillingSettings settings,
}) {
  final billable = lines.where((l) => l.billableQty > 0).toList();
  final gross = [for (final l in billable) l.unitPrice.paise * l.billableQty];
  final itemsTotal = gross.fold(0, (a, b) => a + b);
  final discountTotal = OrderTotals.discountAmount(
    Money(itemsTotal),
    discount,
  ).paise;

  // 2. Discount shares (largest remainder).
  final shares = List<int>.filled(billable.length, 0);
  if (discountTotal > 0 && itemsTotal > 0) {
    final rema = <(int, int)>[];
    var given = 0;
    for (var i = 0; i < billable.length; i++) {
      final exact = gross[i] * discountTotal;
      shares[i] = exact ~/ itemsTotal;
      given += shares[i];
      rema.add((i, exact % itemsTotal));
    }
    rema.sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    for (var k = 0; k < discountTotal - given; k++) {
      shares[rema[k].$1]++;
    }
  }

  final calcLines = [
    for (var i = 0; i < billable.length; i++)
      BillLineCalc(
        orderLineId: billable[i].id,
        name: billable[i].itemName,
        variantText: billable[i].variantText,
        addons: billable[i].addons.map((a) => a.name).toList(),
        qty: billable[i].billableQty,
        unitPrice: billable[i].unitPrice,
        gross: Money(gross[i]),
        discount: Money(shares[i]),
        taxRateBp: billable[i].taxRateBp,
        taxInclusive: billable[i].taxRateBp > 0 && billable[i].taxInclusive,
        taxSplitMode: billable[i].taxRateBp > 0
            ? billable[i].taxSplitMode
            : TaxSplitMode.none,
      ),
  ];

  // 3. Item tax groups, in a stable order (rate, then exclusive first).
  final groups = <(int, bool, TaxSplitMode), int>{};
  for (final l in calcLines) {
    final key = (l.taxRateBp, l.taxInclusive, l.taxSplitMode);
    groups[key] = (groups[key] ?? 0) + l.net.paise;
  }
  final keys = groups.keys.toList()
    ..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      if (c != 0) return c;
      if (a.$2 != b.$2) return a.$2 ? 1 : -1;
      return a.$3.index.compareTo(b.$3.index);
    });
  final taxes = [
    for (final k in keys)
      _taxGroup(TaxBase.items, groups[k]!, k.$1, k.$2, k.$3),
  ];

  // 4. Service charge on the pre-tax item value.
  var serviceCharge = 0;
  final scBp = settings.serviceChargeAppliesTo(orderType)
      ? settings.serviceChargeBp
      : 0;
  if (scBp > 0) {
    final base = taxes.fold<int>(0, (s, t) => s + t.taxable.paise);
    serviceCharge = _div(base * scBp, 10000);
    if (serviceCharge > 0 && settings.serviceChargeTaxBp > 0) {
      taxes.add(
        _taxGroup(
          TaxBase.serviceCharge,
          serviceCharge,
          settings.serviceChargeTaxBp,
          false,
          settings.serviceChargeTaxSplit,
        ),
      );
    }
  }

  // 5. Rounding.
  final raw =
      itemsTotal -
      discountTotal +
      serviceCharge +
      taxes.where((t) => !t.inclusive).fold<int>(0, (s, t) => s + t.tax.paise);
  final rounded = settings.rounding.apply(Money(raw));

  return BillCalculation(
    lines: calcLines,
    itemsTotal: Money(itemsTotal),
    discount: Money(discountTotal),
    serviceCharge: Money(serviceCharge),
    serviceChargeBp: scBp,
    taxes: taxes,
    roundOff: Money(rounded.paise - raw),
    grandTotal: rounded,
    rounding: settings.rounding,
  );
}

TaxGroupCalc _taxGroup(
  TaxBase base,
  int value,
  int rateBp,
  bool inclusive,
  TaxSplitMode split,
) {
  if (rateBp <= 0 || value <= 0) {
    return TaxGroupCalc(
      base: base,
      rateBp: rateBp < 0 ? 0 : rateBp,
      inclusive: false,
      splitMode: TaxSplitMode.none,
      taxable: Money(value),
    );
  }
  final denom = inclusive ? 10000 + rateBp : 10000;
  if (split == TaxSplitMode.cgstSgst) {
    final half = _div(value * rateBp, denom * 2);
    return TaxGroupCalc(
      base: base,
      rateBp: rateBp,
      inclusive: inclusive,
      splitMode: split,
      taxable: Money(inclusive ? value - 2 * half : value),
      cgst: Money(half),
      sgst: Money(half),
    );
  }
  final tax = _div(value * rateBp, denom);
  return TaxGroupCalc(
    base: base,
    rateBp: rateBp,
    inclusive: inclusive,
    splitMode: split,
    taxable: Money(inclusive ? value - tax : value),
    igst: split == TaxSplitMode.igst ? Money(tax) : Money.zero,
    other: split == TaxSplitMode.igst ? Money.zero : Money(tax),
  );
}
