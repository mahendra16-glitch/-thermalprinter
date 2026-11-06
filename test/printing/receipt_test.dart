import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/domain/billing/bill_calculator.dart';
import 'package:thermalprinter/domain/billing/bill_models.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/models/print_mode.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/printing/raster_generator.dart';
import 'package:thermalprinter/printing/receipt_document.dart';
import 'package:thermalprinter/printing/receipt_layouts.dart';
import 'package:thermalprinter/printing/receipt_renderer.dart';
import 'package:thermalprinter/printing/smart_print_engine.dart';

final device58 = PrinterDevice(
  id: 'p',
  name: 'Counter',
  connectionType: ConnectionType.network,
  paperWidth: PaperWidth.mm58,
);

/// Printable text in the bytes (control codes stripped), for assertions.
String textOf(List<int> bytes) => latin1.decode(
  bytes.map((b) => b < 32 && b != 10 || b > 126 ? 32 : b).toList(),
);

void main() {
  group('text helpers', () {
    test('wrapText breaks on words and splits long words', () {
      expect(wrapText('Paneer Butter Masala', 10), [
        'Paneer',
        'Butter',
        'Masala',
      ]);
      expect(wrapText('ABCDEFGHIJKL', 5), ['ABCDE', 'FGHIJ', 'KL']);
      expect(wrapText('a\nb', 10), ['a', 'b']);
    });

    test('columns keep amounts whole and wrap the name', () {
      final lines = layoutColumns(
        ['Paneer Tikka (Full) Extra Large', '2', '520.00'],
        32,
        flex: const [4, 1, 2],
      );
      expect(lines.first.length, 32);
      expect(lines.first.endsWith('520.00'), isTrue);
      expect(lines.join(' '), contains('Large'));
    });

    test('printer text never throws and spells out symbols (D2)', () {
      expect(toPrinterAscii('₹ 120 – “ok” ✓'), 'Rs. 120 - "ok" v');
      expect(toPrinterAscii('नमस्ते'), '??????');
      expect(() => encodePrinterText('😊🌶️'), returnsNormally);
      expect(needsRaster('Tea'), isFalse);
      expect(needsRaster('₹20'), isTrue);
    });
  });

  group('layouts', () {
    final kot = PosOrder(
      orderId: '12',
      type: 'KOT',
      tableNumber: 'T4',
      stationName: 'Bar',
      kotRound: 2,
      items: [
        PosOrderItem(
          name: 'Pizza (Large)',
          qty: 2,
          notes: 'less spicy',
          addOns: ['Extra cheese'],
        ),
      ],
    );

    test('KOT has what the kitchen needs and no test content (D1)', () async {
      final bytes = await SmartPrintEngine.generateOrderBytes(
        order: kot,
        device: device58,
        printMode: PrintMode.fastMode,
      );
      final t = textOf(bytes);
      expect(t, contains('KOT'));
      expect(t, contains('BAR'));
      expect(t, contains('TABLE T4'));
      expect(t, contains('Order #12'));
      expect(t, contains('Round 2'));
      expect(t, contains('2 x Pizza (Large)'));
      expect(t, contains('+ Extra cheese'));
      expect(t, contains('>> LESS SPICY'));
      expect(t, isNot(contains('Emoji')));
      expect(t, isNot(contains('Printer Status')));
      expect(t, isNot(contains('REPRINT')));
    });

    test('void and reprint KOTs are clearly marked', () async {
      final v = PosOrder.fromJson({
        ...kot.toJson(),
        'kotKind': 'VOID',
        'reason': 'Wrong item',
      }).asReprint();
      final t = textOf(
        await SmartPrintEngine.generateOrderBytes(
          order: v,
          device: device58,
          printMode: PrintMode.fastMode,
        ),
      );
      expect(t, contains('REPRINT'));
      expect(t, contains('VOID / CANCEL'));
      expect(t, contains('-2 x Pizza'));
      expect(t, contains('REASON: Wrong item'));
    });

    test('bill prints only provided fields; no fake PAID or GSTIN', () async {
      final bill = PosOrder(
        orderId: '7',
        type: 'BILL',
        items: [PosOrderItem(name: 'Tea', qty: 2, price: 20)],
        total: 40,
      );
      final t = textOf(
        await SmartPrintEngine.generateOrderBytes(
          order: bill,
          device: device58,
          printMode: PrintMode.fastMode,
        ),
      );
      expect(t, contains('Tea'));
      expect(t, contains('40.00'));
      expect(t, contains('Rs. 40.00'), reason: '₹ spelled out in fast mode');
      expect(t, isNot(contains('PAID')));
      expect(t, isNot(contains('GSTIN')));
      expect(t, isNot(contains('MYGENIE')));
      expect(t, isNot(contains('UPI')));
    });

    final taxBill = Bill(
      id: 'b1',
      orderId: 'o1',
      billNumber: 'FY26/7',
      businessDate: '2026-11-06',
      status: BillStatus.finalized,
      orderNo: 12,
      orderTypeLabel: 'Dine-in',
      tableLabel: 'T4',
      customerName: 'Asha',
      header: const BillHeader(
        name: 'Spice Route',
        address: 'MG Road, Pune',
        gstin: '27AAAAA0000A1Z5',
        footer: 'Thank you!',
      ),
      lines: const [
        BillLine(
          name: 'Dal Makhani',
          qty: 2,
          unitPrice: Money(25000),
          gross: Money(50000),
          taxRateBp: 500,
        ),
        BillLine(
          name: 'Lassi',
          addonsText: 'Extra malai',
          qty: 1,
          unitPrice: Money(10500),
          gross: Money(10500),
          taxRateBp: 500,
          taxInclusive: true,
        ),
      ],
      taxes: const [
        BillTax(
          base: TaxBase.items,
          rateBp: 500,
          inclusive: false,
          splitMode: TaxSplitMode.cgstSgst,
          taxable: Money(45000),
          cgst: Money(1125),
          sgst: Money(1125),
        ),
        BillTax(
          base: TaxBase.items,
          rateBp: 500,
          inclusive: true,
          splitMode: TaxSplitMode.cgstSgst,
          taxable: Money(9450),
          cgst: Money(236),
          sgst: Money(236),
        ),
      ],
      itemsTotal: const Money(60500),
      discount: const Money(6050),
      discountLabel: 'Discount 10% (Regular)',
      serviceCharge: Money.zero,
      roundOff: const Money(-0),
      grandTotal: const Money(56700),
      createdAt: DateTime(2026, 11, 6, 20, 15),
    );

    Future<String> printBill(PosOrder o, PrinterDevice d) async => textOf(
      await SmartPrintEngine.generateOrderBytes(
        order: o,
        device: d,
        printMode: PrintMode.fastMode,
      ),
    );

    PosOrder billJob(Bill b) => PosOrder(
      orderId: '12',
      billNo: b.billNumber,
      type: 'BILL',
      items: const [],
      bill: b.toJson(),
    );

    test('tax bill shows header, items and the full tax breakdown', () async {
      for (final d in [
        device58,
        device58.copyWith(paperWidth: PaperWidth.mm80),
      ]) {
        final t = await printBill(billJob(taxBill), d);
        expect(t, contains('Spice Route'));
        expect(t, contains('GSTIN: 27AAAAA0000A1Z5'));
        expect(t, contains('Bill No: FY26/7'));
        expect(t, contains('Table T4'));
        expect(t, contains('Customer: Asha'));
        expect(t, contains('Dal Makhani'));
        expect(t, contains('500.00'));
        expect(t, contains('+ Extra malai'));
        expect(t, contains('Discount 10% (Regular)'));
        expect(t, contains('-60.50'));
        expect(t, contains('CGST 2.5% on 450.00'));
        expect(t, contains('SGST 2.5% on 450.00'));
        expect(t, contains('11.25'));
        expect(t, contains('Incl. CGST 2.5% on 94.50'));
        expect(t, contains('Rs.567.00'));
        expect(t, contains('Thank you!'));
        expect(t, isNot(contains('DUPLICATE')));
        expect(t, isNot(contains('PAID')));
        expect(t, isNot(contains('Round off')));
      }
    });

    test(
      'a reprinted bill says DUPLICATE; empty profile fields are skipped',
      () async {
        final bare = Bill.fromJson({
          ...taxBill.toJson(),
          'header': const BillHeader(name: 'Cafe').toJson(),
          'roundOff': 30,
        });
        final t = await printBill(billJob(bare).asReprint(), device58);
        expect(t, contains('DUPLICATE'));
        expect(t, contains('Round off'));
        expect(t, contains('+0.30'));
        expect(t, isNot(contains('GSTIN')));
        expect(t, isNot(contains('FSSAI')));
        expect(t, isNot(contains('Ph:')));
      },
    );

    test('bill survives the print-job JSON round trip', () {
      final back = Bill.fromJson(
        PosOrder.fromJson(billJob(taxBill).toJson()).bill!,
      );
      expect(back.grandTotal, taxBill.grandTotal);
      expect(back.taxes.last.inclusive, isTrue);
      expect(back.lines.first.displayName, 'Dal Makhani');
      expect(back.createdAt, taxBill.createdAt);
    });

    test('feed and cut follow the printer settings', () async {
      final noCut = device58.copyWith(autoCut: false, feedLines: 5);
      final bytes = await SmartPrintEngine.generateOrderBytes(
        order: kot,
        device: noCut,
        printMode: PrintMode.fastMode,
      );
      final s = bytes.join(',');
      expect(s, contains('27,100,5')); // ESC d 5
      expect(s, isNot(contains('29,86,1'))); // no GS V 1
    });
  });

  group('raster', () {
    testWidgets('compatibility mode rasters only complex lines', (t) async {
      final doc = ReceiptDocument()
        ..text('Plain line')
        ..text('Hindi: नमस्ते');
      final bytes = await t.runAsync(
        () =>
            ReceiptRenderer(const RenderOptions(dots: 384, charsPerLine: 32))
                .render(doc),
      );
      final s = bytes!.join(',');
      expect(textOf(bytes), contains('Plain line'));
      expect(s, contains('29,118,48,0,48,0')); // GS v 0, 48 bytes wide
    });

    test('tall images are sent in bands (D14)', () {
      const h = 300;
      final rgba = List<int>.filled(16 * h * 4, 255);
      final out = RasterGenerator.rgbaToEscPosRaster(
        Uint8List.fromList(rgba),
        width: 16,
        height: h,
      );
      var headers = 0;
      for (var i = 0; i + 3 < out.length; i++) {
        if (out[i] == 0x1D && out[i + 1] == 0x76 && out[i + 2] == 0x30) {
          headers++;
        }
      }
      expect(headers, 3); // 128 + 128 + 44 rows
      expect(out.length, 3 * 8 + 2 * h);
    });
  });

  test('printer test page is labelled as a test', () {
    final doc = ReceiptLayouts.testPage(
      PosOrder(orderId: 'x', type: 'PRINTER_TEST', items: const []),
      device58,
    );
    final first = doc.blocks.first as TextBlock;
    expect(first.text, 'PRINTER TEST');
  });
}
