import 'package:intl/intl.dart';

import '../core/util/money.dart';
import '../domain/billing/bill_calculator.dart';
import '../domain/billing/bill_models.dart';
import '../domain/menu/menu_models.dart';
import '../models/pos_order.dart';
import '../models/printer_device.dart';
import 'receipt_document.dart';

/// Builds the printed document for a queued [PosOrder].
///
/// Only fields that are present are printed; nothing is filled in with
/// sample data.
class ReceiptLayouts {
  static ReceiptDocument forOrder(PosOrder o, PrinterDevice device) {
    switch (o.type.toUpperCase()) {
      case 'KOT':
        return kot(o);
      case 'PRINTER_TEST':
        return testPage(o, device);
      case 'BILL' when o.bill != null:
        return taxBill(Bill.fromJson(o.bill!), duplicate: o.isReprint);
      case 'PAYMENT_RECEIPT' when o.bill != null:
        return paymentReceipt(o.bill!, duplicate: o.isReprint);
      default:
        return bill(o);
    }
  }

  /// Kitchen ticket: large, readable, only what the kitchen needs.
  static ReceiptDocument kot(PosOrder o) {
    final d = ReceiptDocument();
    final isVoid = o.kotKind.toUpperCase() == 'VOID';
    if (o.isReprint) {
      d.text('*** REPRINT ***', align: ReceiptAlign.center, bold: true);
    }
    d.text(
      isVoid ? 'VOID / CANCEL' : 'KOT',
      align: ReceiptAlign.center,
      size: ReceiptTextSize.large,
      bold: true,
    );
    if ((o.stationName ?? '').isNotEmpty) {
      d.text(
        o.stationName!.toUpperCase(),
        align: ReceiptAlign.center,
        size: ReceiptTextSize.tall,
        bold: true,
      );
    }
    d.divider('=');
    final where = (o.tableNumber ?? '').isNotEmpty
        ? 'TABLE ${o.tableNumber}'
        : o.orderType.toUpperCase();
    d.text(where, size: ReceiptTextSize.large, bold: true);
    d.columns(
      ['Order #${o.orderId}', if (o.kotRound != null) 'Round ${o.kotRound}'],
      flex: const [1, 1],
    );
    d.text(DateFormat('dd-MM-yyyy hh:mm a').format(o.timestamp));
    if ((o.waiterName ?? '').isNotEmpty) d.text('Staff: ${o.waiterName}');
    d.divider();

    for (final item in o.items) {
      d.text(
        '${isVoid ? '-' : ''}${item.qty} x ${item.name}',
        size: ReceiptTextSize.tall,
        bold: true,
      );
      for (final a in item.addOns) {
        d.text('   + $a');
      }
      if ((item.notes ?? '').isNotEmpty) {
        d.text('   >> ${item.notes!.toUpperCase()}', bold: true);
      }
    }
    d.divider();
    if (isVoid && (o.reason ?? '').isNotEmpty) {
      d.text('REASON: ${o.reason}', bold: true);
      d.divider();
    }
    if ((o.specialNotes ?? '').isNotEmpty) {
      d.text('NOTE: ${o.specialNotes!.toUpperCase()}', bold: true);
      d.divider();
    }
    final count = o.items.fold<int>(0, (s, i) => s + i.qty);
    d.text('Items: $count', align: ReceiptAlign.right);
    return d;
  }

  /// Customer bill from a finalized [Bill]: business details, items, the
  /// full tax breakdown and the total. Only fields that are set are
  /// printed.
  static ReceiptDocument taxBill(Bill b, {bool duplicate = false}) {
    final d = ReceiptDocument();
    String amt(Money m) => m.format(symbol: false);
    const itemFlex = [5, 1, 3, 3];

    if (duplicate) {
      d.text('*** DUPLICATE ***', align: ReceiptAlign.center, bold: true);
    }
    final h = b.header;
    d.text(
      h.name,
      align: ReceiptAlign.center,
      size: ReceiptTextSize.tall,
      bold: true,
    );
    d.text(h.address, align: ReceiptAlign.center);
    if (h.phone.isNotEmpty) {
      d.text('Ph: ${h.phone}', align: ReceiptAlign.center);
    }
    if (h.gstin.isNotEmpty) {
      d.text('GSTIN: ${h.gstin}', align: ReceiptAlign.center);
    }
    if (h.fssai.isNotEmpty) {
      d.text('FSSAI: ${h.fssai}', align: ReceiptAlign.center);
    }
    d.divider();
    d.text('Bill No: ${b.billNumber}', bold: true);
    d.text(DateFormat('dd-MM-yyyy hh:mm a').format(b.createdAt));
    d.text(
      [
        'Order #${b.orderNo}',
        b.orderTypeLabel,
        if (b.tableLabel.isNotEmpty) 'Table ${b.tableLabel}',
      ].join(' | '),
    );
    if (b.customerName.isNotEmpty) d.text('Customer: ${b.customerName}');
    if (b.customerPhone.isNotEmpty) d.text('Phone: ${b.customerPhone}');
    if (b.staffName.isNotEmpty) d.text('Staff: ${b.staffName}');
    d.divider();

    d.columns(['Item', 'Qty', 'Rate', 'Amount'], flex: itemFlex, bold: true);
    for (final l in b.lines) {
      d.columns([
        l.displayName,
        '${l.qty}',
        amt(l.unitPrice),
        amt(l.gross),
      ], flex: itemFlex);
      if (l.addonsText.isNotEmpty) d.text('  + ${l.addonsText}');
    }
    d.divider();

    void row(String label, Money m) =>
        d.columns([label, amt(m)], flex: const [3, 1]);
    row('Subtotal (${b.itemCount} items)', b.itemsTotal);
    if (!b.discount.isZero) {
      row(b.discountLabel.isEmpty ? 'Discount' : b.discountLabel, -b.discount);
    }
    if (!b.serviceCharge.isZero) {
      row('Service charge ${formatBp(b.serviceChargeBp)}', b.serviceCharge);
    }
    var hasInclusive = false;
    for (final t in b.taxes) {
      if (t.tax.isZero) continue;
      hasInclusive |= t.inclusive;
      final on = t.base == TaxBase.serviceCharge
          ? ' on service chg'
          : ' on ${amt(t.taxable)}';
      final pre = t.inclusive ? 'Incl. ' : '';
      switch (t.splitMode) {
        case TaxSplitMode.cgstSgst:
          final half = t.rateBp.isEven
              ? formatBp(t.rateBp ~/ 2)
              : '${formatBp(t.rateBp)}/2';
          row('${pre}CGST $half$on', t.cgst);
          row('${pre}SGST $half$on', t.sgst);
        case TaxSplitMode.igst:
          row('${pre}IGST ${formatBp(t.rateBp)}$on', t.igst);
        case TaxSplitMode.none:
          row('${pre}Tax ${formatBp(t.rateBp)}$on', t.other);
      }
    }
    if (!b.roundOff.isZero) {
      d.columns(
        ['Round off', '${b.roundOff.isNegative ? '' : '+'}${amt(b.roundOff)}'],
        flex: const [3, 1],
      );
    }
    d.divider('=');
    d.columns(
      ['TOTAL', b.grandTotal.format()],
      flex: const [1, 1],
      bold: true,
      size: ReceiptTextSize.tall,
    );
    d.divider('=');
    if (b.payments.isNotEmpty) {
      _paymentLines(d, b);
      d.divider();
    }
    if (hasInclusive) {
      d.text('"Incl." tax is already in the item prices.');
    }
    if (b.upiQr.isNotEmpty) {
      d.feed();
      d.text(
        'Scan to pay ${b.balance.format()} by UPI',
        align: ReceiptAlign.center,
        bold: true,
      );
      d.qr(b.upiQr);
      d.text(
        'Please show the payment to our staff.',
        align: ReceiptAlign.center,
      );
    }
    if (h.footer.isNotEmpty) {
      d.feed();
      d.text(h.footer, align: ReceiptAlign.center);
    }
    return d;
  }

  static void _paymentLines(ReceiptDocument d, Bill b) {
    String amt(Money m) => m.format(symbol: false);
    for (final p in b.payments) {
      d.columns([p.label, amt(p.amount)], flex: const [3, 1]);
      if (p.reference.isNotEmpty) d.text('  Ref: ${p.reference}');
    }
    d.columns(['Total paid', amt(b.paid)], flex: const [3, 1], bold: true);
    if (b.balance.paise > 0) {
      d.columns(
        ['BALANCE DUE', b.balance.format()],
        flex: const [1, 1],
        bold: true,
      );
    } else {
      d.text('Paid in full', align: ReceiptAlign.center, bold: true);
    }
  }

  /// Receipt for one payment or reversal: what was collected now, what was
  /// paid before and what is still due. UPI/card are marked as recorded by
  /// staff, because the app cannot see the bank.
  static ReceiptDocument paymentReceipt(
    Map<String, dynamic> json, {
    bool duplicate = false,
  }) {
    final b = Bill.fromJson(json);
    final r = (json['receipt'] as Map?)?.cast<String, dynamic>() ?? const {};
    Money m(String k) => Money((r[k] as num?)?.toInt() ?? 0);
    String amt(Money x) => x.format(symbol: false);
    final d = ReceiptDocument();
    if (duplicate) {
      d.text('*** DUPLICATE ***', align: ReceiptAlign.center, bold: true);
    }
    d.text(
      b.header.name,
      align: ReceiptAlign.center,
      size: ReceiptTextSize.tall,
      bold: true,
    );
    if (b.header.phone.isNotEmpty) {
      d.text('Ph: ${b.header.phone}', align: ReceiptAlign.center);
    }
    d.text(
      r['label'] as String? ?? 'PAYMENT RECEIPT',
      align: ReceiptAlign.center,
      bold: true,
    );
    d.divider();
    d.text('Bill No: ${b.billNumber}', bold: true);
    final at = DateTime.tryParse(r['at'] as String? ?? '');
    if (at != null) d.text(DateFormat('dd-MM-yyyy hh:mm a').format(at));
    d.text(
      [
        'Order #${b.orderNo}',
        if (b.tableLabel.isNotEmpty) 'Table ${b.tableLabel}',
      ].join(' | '),
    );
    if (b.customerName.isNotEmpty) d.text('Customer: ${b.customerName}');
    d.divider();
    d.columns(['Bill total', amt(b.grandTotal)], flex: const [3, 1]);
    d.columns(
      [
        'This ${r['method'] ?? ''} ${m('amount').isNegative ? 'reversal' : 'payment'}',
        amt(m('amount')),
      ],
      flex: const [3, 1],
      bold: true,
    );
    if (r['tendered'] != null) {
      d.columns(['Cash received', amt(m('tendered'))], flex: const [3, 1]);
      d.columns(['Change', amt(m('change'))], flex: const [3, 1]);
    }
    final ref = r['reference'] as String? ?? '';
    if (ref.isNotEmpty) d.text('Ref: $ref');
    final reason = r['reason'] as String? ?? '';
    if (reason.isNotEmpty) d.text('Reason: $reason');
    if (r['staffConfirmed'] == true) {
      d.text('Recorded by staff (not bank-verified).');
    }
    d.divider();
    d.columns(['Total paid', amt(b.paid)], flex: const [3, 1]);
    if (b.balance.paise > 0) {
      d.columns(
        ['BALANCE DUE', b.balance.format()],
        flex: const [1, 1],
        bold: true,
      );
    } else {
      d.text('Paid in full', align: ReceiptAlign.center, bold: true);
    }
    if (b.header.footer.isNotEmpty) {
      d.feed();
      d.text(b.header.footer, align: ReceiptAlign.center);
    }
    return d;
  }

  /// A plain bill from the values in [o] (used by the POS-integration
  /// payload). Bills made in the app use [taxBill].
  static ReceiptDocument bill(PosOrder o) {
    final d = ReceiptDocument();
    if (o.isReprint) {
      d.text('*** DUPLICATE ***', align: ReceiptAlign.center, bold: true);
    }
    d.text(
      o.restaurantName,
      align: ReceiptAlign.center,
      size: ReceiptTextSize.tall,
      bold: true,
    );
    d.divider();
    d.columns([
      '${o.type} #${o.billNo}',
      DateFormat('dd-MM-yy hh:mm a').format(o.timestamp),
    ]);
    if ((o.tableNumber ?? '').isNotEmpty) d.text('Table: ${o.tableNumber}');
    if ((o.customerName ?? '').isNotEmpty) {
      d.text('Customer: ${o.customerName}');
    }
    if ((o.customerPhone ?? '').isNotEmpty) d.text('Phone: ${o.customerPhone}');
    d.divider();
    d.columns(['Item', 'Qty', 'Amount'], flex: const [4, 1, 2], bold: true);
    for (final i in o.items) {
      d.columns(
        [i.name, '${i.qty}', (i.price * i.qty).toStringAsFixed(2)],
        flex: const [4, 1, 2],
      );
      for (final a in i.addOns) {
        d.text('  + $a');
      }
    }
    d.divider();
    void money(String label, double v, {bool bold = false}) => d.columns(
      [label, v.toStringAsFixed(2)],
      flex: const [3, 2],
      bold: bold,
    );
    if (o.subtotal > 0) money('Subtotal', o.subtotal);
    if (o.discount > 0) money('Discount', -o.discount);
    if (o.cgst > 0) money('CGST', o.cgst);
    if (o.sgst > 0) money('SGST', o.sgst);
    if (o.tax > 0 && o.cgst == 0 && o.sgst == 0) money('Tax', o.tax);
    if (o.total > 0) {
      d.divider();
      d.columns(
        ['TOTAL', '₹ ${o.total.toStringAsFixed(2)}'],
        flex: const [1, 1],
        bold: true,
        size: ReceiptTextSize.tall,
      );
    }
    if (o.paymentMethod.isNotEmpty) d.text('Payment: ${o.paymentMethod}');
    if (o.paymentStatus.isNotEmpty) {
      d.text(o.paymentStatus, align: ReceiptAlign.center, bold: true);
    }
    return d;
  }

  /// Printer self-test: exercises text sizes, symbols, Hindi and emoji so
  /// staff can judge print quality. Clearly labelled as a test.
  static ReceiptDocument testPage(PosOrder o, PrinterDevice device) {
    final d = ReceiptDocument();
    d.text(
      'PRINTER TEST',
      align: ReceiptAlign.center,
      size: ReceiptTextSize.large,
      bold: true,
    );
    d.text(device.name, align: ReceiptAlign.center);
    d.text(
      '${device.connectionType.name.toUpperCase()} · ${device.paperWidth.label} · '
      '${device.effectiveDots} dots · ${device.effectiveCharsPerLine} chars',
      align: ReceiptAlign.center,
    );
    d.text(
      DateFormat('dd-MM-yyyy hh:mm a').format(DateTime.now()),
      align: ReceiptAlign.center,
    );
    d.divider();
    d.text('1234567890' * 5);
    d.text('Normal text');
    d.text('Bold text', bold: true);
    d.text('Tall text', size: ReceiptTextSize.tall);
    d.text('Large', size: ReceiptTextSize.large);
    d.divider();
    d.columns(
      ['Paneer Tikka (Full) with a long name', '2', '520.00'],
      flex: const [4, 1, 2],
    );
    d.columns(['Price', '₹ 1,234.50']);
    d.text('Symbols: ₹ ✓ ★ → • ©');
    d.text('Hindi: नमस्ते, धन्यवाद');
    d.text('Emoji: 😊 🌶️ 🍔 ☕');
    d.divider();
    d.text(
      'In Fast mode, ₹ prints as "Rs." and Hindi/emoji as "?". Use '
      'Compatibility or Full image mode to print them.',
    );
    d.qr('PRINTER-TEST ${device.id}');
    return d;
  }
}
