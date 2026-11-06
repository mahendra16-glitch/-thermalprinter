import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/printer_device.dart';
import '../models/print_mode.dart';
import '../models/pos_order.dart';
import '../printers/printer_adapter.dart';
import 'escpos_builder.dart';
import 'hybrid_text_parser.dart';
import 'raster_generator.dart';

class SmartPrintEngine {
  /// Processes a [PosOrder] into byte commands according to [printMode] and sends
  /// them to the [device] via [PrinterAdapter].
  static Future<void> printOrder({
    required PosOrder order,
    required PrinterDevice device,
    required PrintMode printMode,
  }) async {
    final adapter = PrinterAdapter.forDevice(device);

    try {
      final List<int> bytes = await generateOrderBytes(
        order: order,
        device: device,
        printMode: printMode,
      );

      await adapter.sendRawBytes(bytes);
    } finally {
      await adapter.disconnect();
    }
  }

  /// Generates the raw byte payload for a [PosOrder] based on [printMode]
  static Future<List<int>> generateOrderBytes({
    required PosOrder order,
    required PrinterDevice device,
    required PrintMode printMode,
  }) async {
    if (printMode == PrintMode.fullImageMode) {
      return _generateFullImageBytes(order, device);
    } else if (printMode == PrintMode.compatibilityMode) {
      return _generateCompatibilityBytes(order, device);
    } else {
      return _generateFastModeBytes(order, device);
    }
  }

  // --- Fast Mode (ESC/POS native text) ---

  static Future<List<int>> _generateFastModeBytes(
    PosOrder order,
    PrinterDevice device,
  ) async {
    final builder = EscPosBuilder(paperWidth: device.paperWidth);
    final DateFormat formatter = DateFormat('dd-MMM-yyyy hh:mm a');

    // Header
    builder.text(order.restaurantName, align: 1, bold: true, heightMultiplier: 1);
    builder.text('--------------------------------', align: 1);
    builder.text('${order.type} #${order.orderId}', align: 1, bold: true);
    if (order.tableNumber != null) {
      builder.text('Table: ${order.tableNumber}', align: 1);
    }
    builder.text(formatter.format(order.timestamp), align: 1);
    builder.divider();

    // Table Header
    builder.row(['Item', 'Qty', 'Price'], flex: [3, 1, 2]);
    builder.divider();

    // Items
    for (final item in order.items) {
      builder.row([
        item.name,
        '${item.qty}',
        '₹${(item.price * item.qty).toStringAsFixed(2)}',
      ], flex: [3, 1, 2]);
    }
    builder.divider();

    // Totals
    builder.row(['Total:', '', '₹${order.total.toStringAsFixed(2)}'], flex: [2, 1, 2]);
    builder.text(order.paymentStatus, align: 1, bold: true);
    builder.divider();

    // Special & Emoji test lines
    builder.text('Special: ✓ ★ ♥ → © ™', align: 1);
    builder.text('Emoji: 😊 ❤️ 🔥 🌶️ 🍔 ☕', align: 1);
    builder.text('Hindi: नमस्ते / धन्यवाद 🙏', align: 1);
    builder.divider();

    // QR & Barcode
    await builder.qrCode(order.orderId);
    builder.text('--------------------------------', align: 1);
    builder.text('Connection: ${device.connectionType.name.toUpperCase()}', align: 1);
    builder.text('Printer Status: OK', align: 1);
    builder.divider();

    builder.cut();
    return builder.getBytes();
  }

  // --- Compatibility Mode (Hybrid text + inline raster for complex symbols) ---

  static Future<List<int>> _generateCompatibilityBytes(
    PosOrder order,
    PrinterDevice device,
  ) async {
    final builder = EscPosBuilder(paperWidth: device.paperWidth);
    final DateFormat formatter = DateFormat('dd-MMM-yyyy hh:mm a');

    // Restaurant Name Header
    if (HybridTextParser.hasComplexContent(order.restaurantName)) {
      final raster = await RasterGenerator.textToRasterBytes(
        text: order.restaurantName,
        targetWidthDots: device.paperWidth.dots,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center,
      );
      builder.addRawBytes(raster);
    } else {
      builder.text(order.restaurantName, align: 1, bold: true, heightMultiplier: 1);
    }

    builder.text('--------------------------------', align: 1);
    builder.text('${order.type} #${order.orderId}', align: 1, bold: true);
    if (order.tableNumber != null) {
      builder.text('Table: ${order.tableNumber}', align: 1);
    }
    builder.text(formatter.format(order.timestamp), align: 1);
    builder.divider();

    // Table Header
    builder.row(['Item', 'Qty', 'Price'], flex: [3, 1, 2]);
    builder.divider();

    // Items (render individual item line as raster if it contains emojis/Hindi)
    for (final item in order.items) {
      if (HybridTextParser.hasComplexContent(item.name)) {
        final lineText =
            '${item.name}  x${item.qty}  ₹${(item.price * item.qty).toStringAsFixed(2)}';
        final raster = await RasterGenerator.textToRasterBytes(
          text: lineText,
          targetWidthDots: device.paperWidth.dots,
          fontSize: 20,
        );
        builder.addRawBytes(raster);
      } else {
        builder.row([
          item.name,
          '${item.qty}',
          '₹${(item.price * item.qty).toStringAsFixed(2)}',
        ], flex: [3, 1, 2]);
      }
    }
    builder.divider();

    // Total
    builder.row(['Total:', '', '₹${order.total.toStringAsFixed(2)}'], flex: [2, 1, 2]);

    if (HybridTextParser.hasComplexContent(order.paymentStatus)) {
      final raster = await RasterGenerator.textToRasterBytes(
        text: order.paymentStatus,
        targetWidthDots: device.paperWidth.dots,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.center,
      );
      builder.addRawBytes(raster);
    } else {
      builder.text(order.paymentStatus, align: 1, bold: true);
    }

    builder.divider();

    // Complex symbol tests - rendered cleanly via raster
    final specialRaster = await RasterGenerator.textToRasterBytes(
      text: 'Special: ✓ ★ ♥ → © ™',
      targetWidthDots: device.paperWidth.dots,
      fontSize: 20,
      textAlign: TextAlign.center,
    );
    builder.addRawBytes(specialRaster);

    final emojiRaster = await RasterGenerator.textToRasterBytes(
      text: 'Emoji: 😊 ❤️ 🔥 🌶️ 🍔 ☕',
      targetWidthDots: device.paperWidth.dots,
      fontSize: 20,
      textAlign: TextAlign.center,
    );
    builder.addRawBytes(emojiRaster);

    final hindiRaster = await RasterGenerator.textToRasterBytes(
      text: 'Hindi: नमस्ते धन्यवाद 🙏',
      targetWidthDots: device.paperWidth.dots,
      fontSize: 20,
      textAlign: TextAlign.center,
    );
    builder.addRawBytes(hindiRaster);

    builder.divider();

    await builder.qrCode(order.orderId);
    builder.text('--------------------------------', align: 1);
    builder.text('Connection: ${device.connectionType.name.toUpperCase()}', align: 1);
    builder.text('Printer Status: OK', align: 1);
    builder.divider();

    builder.cut();
    return builder.getBytes();
  }

  // --- Full Image Mode (Render complete receipt as bitmap canvas) ---

  static Future<List<int>> _generateFullImageBytes(
    PosOrder order,
    PrinterDevice device,
  ) async {
    final DateFormat formatter = DateFormat('dd-MMM-yyyy hh:mm a');
    final StringBuffer sb = StringBuffer();

    sb.writeln(order.restaurantName);
    sb.writeln('------------------------------------------');
    sb.writeln('${order.type} #${order.orderId}');
    if (order.tableNumber != null) {
      sb.writeln('Table: ${order.tableNumber}');
    }
    sb.writeln(formatter.format(order.timestamp));
    sb.writeln('------------------------------------------');

    for (final item in order.items) {
      final priceStr = '₹${(item.price * item.qty).toStringAsFixed(2)}';
      sb.writeln('${item.name}  x${item.qty}  $priceStr');
    }
    sb.writeln('------------------------------------------');
    sb.writeln('Total: ₹${order.total.toStringAsFixed(2)}');
    sb.writeln(order.paymentStatus);
    sb.writeln('------------------------------------------');
    sb.writeln('Special: ✓ ★ ♥ → © ™');
    sb.writeln('Emoji: 😊 ❤️ 🔥 🌶️ 🍔 ☕');
    sb.writeln('Hindi: नमस्ते धन्यवाद 🙏');
    sb.writeln('------------------------------------------');
    sb.writeln('Connection: ${device.connectionType.name.toUpperCase()}');
    sb.writeln('Printer Status: OK');
    sb.writeln('------------------------------------------');

    final List<int> rasterBytes = await RasterGenerator.textToRasterBytes(
      text: sb.toString(),
      targetWidthDots: device.paperWidth.dots,
      fontSize: 20,
      textAlign: TextAlign.left,
    );

    final builder = EscPosBuilder(paperWidth: device.paperWidth);
    builder.addRawBytes(rasterBytes);
    await builder.qrCode(order.orderId);
    builder.cut();

    return builder.getBytes();
  }
}
