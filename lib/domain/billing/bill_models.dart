import '../../core/util/money.dart';
import '../menu/menu_models.dart';
import 'bill_calculator.dart';
import 'billing_settings.dart';

/// Stored bill status. Payment status (unpaid / partly paid / paid) is
/// derived from the payment ledger, never stored here.
enum BillStatus { finalized, voided }

extension BillStatusX on BillStatus {
  String get label => this == BillStatus.finalized ? 'Final' : 'Voided';

  static BillStatus parse(String? s) =>
      BillStatus.values.where((e) => e.name == s).firstOrNull ??
      BillStatus.finalized;
}

/// Business details copied onto the bill when it is finalized, so later
/// profile edits do not change printed bills.
class BillHeader {
  final String name;
  final String address;
  final String phone;
  final String gstin;
  final String fssai;
  final String footer;

  const BillHeader({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.gstin = '',
    this.fssai = '',
    this.footer = '',
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'gstin': gstin,
    'fssai': fssai,
    'footer': footer,
  };

  factory BillHeader.fromJson(Map<String, dynamic> j) => BillHeader(
    name: j['name'] as String? ?? '',
    address: j['address'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    gstin: j['gstin'] as String? ?? '',
    fssai: j['fssai'] as String? ?? '',
    footer: j['footer'] as String? ?? '',
  );
}

class BillLine {
  final String name;
  final String variantText;
  final String addonsText;
  final int qty;
  final Money unitPrice;
  final Money gross;
  final Money discount;
  final int taxRateBp;
  final bool taxInclusive;

  const BillLine({
    required this.name,
    this.variantText = '',
    this.addonsText = '',
    required this.qty,
    required this.unitPrice,
    required this.gross,
    this.discount = Money.zero,
    this.taxRateBp = 0,
    this.taxInclusive = false,
  });

  String get displayName => variantText.isEmpty ? name : '$name ($variantText)';

  Map<String, Object?> toJson() => {
    'name': name,
    'variantText': variantText,
    'addonsText': addonsText,
    'qty': qty,
    'unitPrice': unitPrice.paise,
    'gross': gross.paise,
    'discount': discount.paise,
    'taxRateBp': taxRateBp,
    'taxInclusive': taxInclusive,
  };

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
    name: j['name'] as String? ?? '',
    variantText: j['variantText'] as String? ?? '',
    addonsText: j['addonsText'] as String? ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 0,
    unitPrice: Money((j['unitPrice'] as num?)?.toInt() ?? 0),
    gross: Money((j['gross'] as num?)?.toInt() ?? 0),
    discount: Money((j['discount'] as num?)?.toInt() ?? 0),
    taxRateBp: (j['taxRateBp'] as num?)?.toInt() ?? 0,
    taxInclusive: j['taxInclusive'] as bool? ?? false,
  );
}

class BillTax {
  final TaxBase base;
  final int rateBp;
  final bool inclusive;
  final TaxSplitMode splitMode;
  final Money taxable;
  final Money cgst;
  final Money sgst;
  final Money igst;
  final Money other;

  const BillTax({
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

  factory BillTax.of(TaxGroupCalc t) => BillTax(
    base: t.base,
    rateBp: t.rateBp,
    inclusive: t.inclusive,
    splitMode: t.splitMode,
    taxable: t.taxable,
    cgst: t.cgst,
    sgst: t.sgst,
    igst: t.igst,
    other: t.other,
  );

  Money get tax => cgst + sgst + igst + other;

  Map<String, Object?> toJson() => {
    'base': base.name,
    'rateBp': rateBp,
    'inclusive': inclusive,
    'splitMode': splitMode.name,
    'taxable': taxable.paise,
    'cgst': cgst.paise,
    'sgst': sgst.paise,
    'igst': igst.paise,
    'other': other.paise,
  };

  factory BillTax.fromJson(Map<String, dynamic> j) {
    Money m(String k) => Money((j[k] as num?)?.toInt() ?? 0);
    return BillTax(
      base: j['base'] == TaxBase.serviceCharge.name
          ? TaxBase.serviceCharge
          : TaxBase.items,
      rateBp: (j['rateBp'] as num?)?.toInt() ?? 0,
      inclusive: j['inclusive'] as bool? ?? false,
      splitMode: TaxSplitModeX.parse(j['splitMode'] as String?),
      taxable: m('taxable'),
      cgst: m('cgst'),
      sgst: m('sgst'),
      igst: m('igst'),
      other: m('other'),
    );
  }
}

/// A payment line printed on a bill or receipt. [amount] is negative for a
/// reversal.
class BillPaymentLine {
  final String label;
  final Money amount;
  final String reference;

  const BillPaymentLine(this.label, this.amount, {this.reference = ''});

  Map<String, Object?> toJson() => {
    'label': label,
    'amount': amount.paise,
    'reference': reference,
  };

  factory BillPaymentLine.fromJson(Map<String, dynamic> j) => BillPaymentLine(
    j['label'] as String? ?? '',
    Money((j['amount'] as num?)?.toInt() ?? 0),
    reference: j['reference'] as String? ?? '',
  );
}

/// A finalized (or voided) bill with everything needed to print it again
/// exactly as it was.
class Bill {
  final String id;
  final String orderId;
  final String billNumber;
  final String businessDate;
  final BillStatus status;
  final int orderNo;
  final String orderTypeLabel;
  final String tableLabel;
  final String customerName;
  final String customerPhone;
  final String staffName;
  final BillHeader header;
  final List<BillLine> lines;
  final List<BillTax> taxes;
  final Money itemsTotal;
  final Money discount;
  final String discountLabel;
  final Money serviceCharge;
  final int serviceChargeBp;
  final Money roundOff;
  final Money grandTotal;
  final RoundingMode rounding;
  final DateTime createdAt;
  final DateTime? voidedAt;
  final String voidReason;

  /// Added at print time from the payment ledger (not stored on the bill).
  final List<BillPaymentLine> payments;

  /// UPI payment link to print as a QR, or empty.
  final String upiQr;

  const Bill({
    required this.id,
    required this.orderId,
    required this.billNumber,
    required this.businessDate,
    required this.status,
    required this.orderNo,
    required this.orderTypeLabel,
    this.tableLabel = '',
    this.customerName = '',
    this.customerPhone = '',
    this.staffName = '',
    required this.header,
    required this.lines,
    required this.taxes,
    required this.itemsTotal,
    required this.discount,
    this.discountLabel = '',
    required this.serviceCharge,
    this.serviceChargeBp = 0,
    required this.roundOff,
    required this.grandTotal,
    this.rounding = RoundingMode.none,
    required this.createdAt,
    this.voidedAt,
    this.voidReason = '',
    this.payments = const [],
    this.upiQr = '',
  });

  Money get paid => payments.fold(Money.zero, (s, p) => s + p.amount);

  Money get balance => grandTotal - paid;

  /// The same bill with print-time payment details.
  Bill withPrintExtras({
    required List<BillPaymentLine> payments,
    String upiQr = '',
  }) => Bill.fromJson({
    ...toJson(),
    'payments': payments.map((p) => p.toJson()).toList(),
    'upiQr': upiQr,
  });

  bool get isVoided => status == BillStatus.voided;

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  Money get totalTax => taxes.fold(Money.zero, (s, t) => s + t.tax);

  Map<String, Object?> toJson() => {
    'id': id,
    'orderId': orderId,
    'billNumber': billNumber,
    'businessDate': businessDate,
    'status': status.name,
    'orderNo': orderNo,
    'orderTypeLabel': orderTypeLabel,
    'tableLabel': tableLabel,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'staffName': staffName,
    'header': header.toJson(),
    'lines': lines.map((l) => l.toJson()).toList(),
    'taxes': taxes.map((t) => t.toJson()).toList(),
    'itemsTotal': itemsTotal.paise,
    'discount': discount.paise,
    'discountLabel': discountLabel,
    'serviceCharge': serviceCharge.paise,
    'serviceChargeBp': serviceChargeBp,
    'roundOff': roundOff.paise,
    'grandTotal': grandTotal.paise,
    'rounding': rounding.name,
    'createdAt': createdAt.toIso8601String(),
    'voidedAt': voidedAt?.toIso8601String(),
    'voidReason': voidReason,
    if (payments.isNotEmpty)
      'payments': payments.map((p) => p.toJson()).toList(),
    if (upiQr.isNotEmpty) 'upiQr': upiQr,
  };

  factory Bill.fromJson(Map<String, dynamic> j) {
    Money m(String k) => Money((j[k] as num?)?.toInt() ?? 0);
    return Bill(
      id: j['id'] as String? ?? '',
      orderId: j['orderId'] as String? ?? '',
      billNumber: j['billNumber'] as String? ?? '',
      businessDate: j['businessDate'] as String? ?? '',
      status: BillStatusX.parse(j['status'] as String?),
      orderNo: (j['orderNo'] as num?)?.toInt() ?? 0,
      orderTypeLabel: j['orderTypeLabel'] as String? ?? '',
      tableLabel: j['tableLabel'] as String? ?? '',
      customerName: j['customerName'] as String? ?? '',
      customerPhone: j['customerPhone'] as String? ?? '',
      staffName: j['staffName'] as String? ?? '',
      header: BillHeader.fromJson(
        (j['header'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      lines: [
        for (final l in (j['lines'] as List? ?? const []))
          BillLine.fromJson((l as Map).cast<String, dynamic>()),
      ],
      taxes: [
        for (final t in (j['taxes'] as List? ?? const []))
          BillTax.fromJson((t as Map).cast<String, dynamic>()),
      ],
      itemsTotal: m('itemsTotal'),
      discount: m('discount'),
      discountLabel: j['discountLabel'] as String? ?? '',
      serviceCharge: m('serviceCharge'),
      serviceChargeBp: (j['serviceChargeBp'] as num?)?.toInt() ?? 0,
      roundOff: m('roundOff'),
      grandTotal: m('grandTotal'),
      rounding: RoundingModeX.parse(j['rounding'] as String?),
      createdAt:
          DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime(2000),
      voidedAt: DateTime.tryParse(j['voidedAt'] as String? ?? ''),
      voidReason: j['voidReason'] as String? ?? '',
      payments: [
        for (final p in (j['payments'] as List? ?? const []))
          BillPaymentLine.fromJson((p as Map).cast<String, dynamic>()),
      ],
      upiQr: j['upiQr'] as String? ?? '',
    );
  }
}
