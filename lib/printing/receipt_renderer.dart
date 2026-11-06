import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/constants/escpos_commands.dart';
import '../models/print_mode.dart';
import '../models/printer_device.dart';
import 'escpos_builder.dart';
import 'raster_generator.dart';
import 'receipt_document.dart';

/// Printer geometry and behaviour used when rendering.
class RenderOptions {
  final int dots;
  final int charsPerLine;
  final int threshold;
  final int feedLines;
  final bool cut;
  final PrintMode mode;

  const RenderOptions({
    required this.dots,
    required this.charsPerLine,
    this.threshold = 160,
    this.feedLines = 3,
    this.cut = true,
    this.mode = PrintMode.compatibilityMode,
  });

  factory RenderOptions.forDevice(PrinterDevice d, PrintMode mode) =>
      RenderOptions(
        dots: d.effectiveDots,
        charsPerLine: d.effectiveCharsPerLine,
        threshold: d.effectiveThreshold,
        feedLines: d.effectiveFeedLines,
        cut: d.autoCut,
        mode: mode,
      );
}

/// One output line after layout.
class _Line {
  final String text;
  final ReceiptAlign align;
  final ReceiptTextSize size;
  final bool bold;

  const _Line(this.text, this.align, this.size, this.bold);
}

/// Turns a [ReceiptDocument] into printer bytes.
///
/// - Fast mode: ESC/POS text only; unsupported characters are spelled out
///   or replaced (`₹` -> `Rs.`), never sent as corrupted bytes.
/// - Compatibility mode: text, except lines with Hindi, emoji or symbols,
///   which are drawn as images.
/// - Full image mode: the whole receipt is drawn as one image (sent in
///   bands).
class ReceiptRenderer {
  final RenderOptions o;

  ReceiptRenderer(this.o);

  /// Lines for every text-like block, wrapped to the line width.
  List<Object> _layout(ReceiptDocument doc) {
    final out = <Object>[];
    for (final b in doc.blocks) {
      switch (b) {
        case TextBlock():
          final width = o.charsPerLine ~/ b.size.widthFactor;
          for (final l in wrapText(b.text, width)) {
            out.add(_Line(l, b.align, b.size, b.bold));
          }
        case ColumnsBlock():
          final width = o.charsPerLine ~/ b.size.widthFactor;
          for (final l in layoutColumns(b.cols, width, flex: b.flex)) {
            out.add(_Line(l, ReceiptAlign.left, b.size, b.bold));
          }
        case DividerBlock():
          out.add(
            _Line(
              b.char * o.charsPerLine,
              ReceiptAlign.left,
              ReceiptTextSize.normal,
              false,
            ),
          );
        case FeedBlock():
          for (var i = 0; i < b.lines; i++) {
            out.add(
              const _Line('', ReceiptAlign.left, ReceiptTextSize.normal, false),
            );
          }
        case QrBlock():
          out.add(b);
      }
    }
    return out;
  }

  Future<List<int>> render(ReceiptDocument doc) async {
    final lines = _layout(doc);
    final bytes = <int>[...EscPosCommands.init];

    if (o.mode == PrintMode.fullImageMode) {
      final textLines = <_Line>[];
      Future<void> flush() async {
        if (textLines.isEmpty) return;
        bytes.addAll(await _rasterLines(textLines));
        textLines.clear();
      }

      for (final l in lines) {
        if (l is _Line) {
          textLines.add(l);
        } else if (l is QrBlock) {
          await flush();
          bytes.addAll(await _qr(l.data));
        }
      }
      await flush();
    } else {
      for (final l in lines) {
        if (l is QrBlock) {
          bytes.addAll(await _qr(l.data));
        } else if (l is _Line) {
          if (o.mode == PrintMode.compatibilityMode && needsRaster(l.text)) {
            bytes.addAll(await _rasterLines([l]));
          } else {
            bytes.addAll(_textLine(l));
          }
        }
      }
    }

    bytes.addAll(EscPosCommands.alignLeft);
    bytes.addAll(EscPosCommands.textSize());
    if (o.feedLines > 0) bytes.addAll(EscPosCommands.feedLines(o.feedLines));
    if (o.cut) bytes.addAll(EscPosCommands.partialCut);
    return bytes;
  }

  List<int> _textLine(_Line l) {
    return [
      ...switch (l.align) {
        ReceiptAlign.left => EscPosCommands.alignLeft,
        ReceiptAlign.center => EscPosCommands.alignCenter,
        ReceiptAlign.right => EscPosCommands.alignRight,
      },
      ...(l.bold ? EscPosCommands.boldOn : EscPosCommands.boldOff),
      ...EscPosCommands.textSize(
        width: l.size.widthFactor - 1,
        height: l.size.heightFactor - 1,
      ),
      ...encodePrinterText(l.text),
      ...EscPosCommands.lineFeed,
    ];
  }

  /// Draws [lines] in a monospaced font so columns stay aligned, and returns
  /// banded raster commands.
  Future<List<int>> _rasterLines(List<_Line> lines) async {
    final width = o.dots.toDouble();
    // A monospace glyph is ~0.6 em wide: size the font so charsPerLine fit.
    final baseFont = width / (o.charsPerLine * 0.6);
    final painters = <TextPainter>[];
    var height = 4.0;
    for (final l in lines) {
      final tp = TextPainter(
        text: TextSpan(
          text: l.text.isEmpty ? ' ' : l.text,
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'monospace',
            fontSize: baseFont * l.size.heightFactor,
            fontWeight: l.bold ? FontWeight.bold : FontWeight.w500,
            height: 1.15,
          ),
        ),
        textAlign: switch (l.align) {
          ReceiptAlign.left => TextAlign.left,
          ReceiptAlign.center => TextAlign.center,
          ReceiptAlign.right => TextAlign.right,
        },
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      )..layout(minWidth: width, maxWidth: width);
      painters.add(tp);
      height += tp.height;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    var y = 2.0;
    for (var i = 0; i < painters.length; i++) {
      // Large lines are wrapped to half the characters and drawn at twice
      // the font size, so they fill the same width.
      painters[i].paint(canvas, Offset(0, y));
      y += painters[i].height;
    }
    final image = await recorder.endRecording().toImage(o.dots, height.ceil());
    final bytes = await RasterGenerator.imageToEscPosRaster(
      image,
      threshold: o.threshold,
    );
    image.dispose();
    return [...EscPosCommands.alignLeft, ...bytes];
  }

  Future<List<int>> _qr(String data) async {
    final b = EscPosBuilder(paperWidth: PaperWidth.mm58);
    await b.qrCode(data);
    // Drop the builder's own init command; keep the QR raster.
    return b.getBytes().sublist(EscPosCommands.init.length);
  }
}
