import 'package:intl/intl.dart';

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

  /// A plain bill from the values in [o] (used by the POS-integration
  /// payload). The full GST bill is built by the billing module.
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
