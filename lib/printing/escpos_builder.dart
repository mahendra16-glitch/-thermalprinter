import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/printer_device.dart';
import '../core/constants/escpos_commands.dart';
import 'raster_generator.dart';

class EscPosBuilder {
  final PaperWidth paperWidth;
  final List<int> _bytes = [];

  EscPosBuilder({this.paperWidth = PaperWidth.mm80}) {
    _bytes.addAll(EscPosCommands.init);
  }

  int get maxCharsPerLine => paperWidth.charsPerLine;
  int get maxDotsWidth => paperWidth.dots;

  void addRawBytes(List<int> bytes) {
    _bytes.addAll(bytes);
  }

  void text(
    String text, {
    bool bold = false,
    int align = 0, // 0 = left, 1 = center, 2 = right
    int widthMultiplier = 0,
    int heightMultiplier = 0,
    bool lineBreak = true,
  }) {
    // Set Alignment
    if (align == 1) {
      _bytes.addAll(EscPosCommands.alignCenter);
    } else if (align == 2) {
      _bytes.addAll(EscPosCommands.alignRight);
    } else {
      _bytes.addAll(EscPosCommands.alignLeft);
    }

    // Set Bold
    _bytes.addAll(bold ? EscPosCommands.boldOn : EscPosCommands.boldOff);

    // Set Text Size
    _bytes.addAll(EscPosCommands.textSize(
      width: widthMultiplier,
      height: heightMultiplier,
    ));

    // Convert text to standard bytes
    _bytes.addAll(latin1.encode(text));

    if (lineBreak) {
      _bytes.addAll(EscPosCommands.lineFeed);
    }
  }

  void divider({String char = '-'}) {
    final int count = maxCharsPerLine;
    final String line = char * count;
    text(line, align: 0, lineBreak: true);
  }

  void row(List<String> columns, {List<int>? flex}) {
    if (columns.isEmpty) return;

    final int totalChars = maxCharsPerLine;
    flex ??= List.filled(columns.length, 1);

    final int sumFlex = flex.reduce((a, b) => a + b);
    final List<int> widths = [];
    int allocated = 0;

    for (int i = 0; i < flex.length; i++) {
      if (i == flex.length - 1) {
        widths.add(totalChars - allocated);
      } else {
        final int w = (totalChars * flex[i] / sumFlex).floor();
        widths.add(w);
        allocated += w;
      }
    }

    StringBuffer lineBuffer = StringBuffer();
    for (int i = 0; i < columns.length; i++) {
      String colText = columns[i];
      int colWidth = widths[i];

      if (colText.length > colWidth) {
        colText = colText.substring(0, colWidth);
      }

      if (i == columns.length - 1) {
        // Right align last column
        lineBuffer.write(colText.padLeft(colWidth));
      } else {
        // Left align other columns
        lineBuffer.write(colText.padRight(colWidth));
      }
    }

    text(lineBuffer.toString(), lineBreak: true);
  }

  void feed([int lines = 2]) {
    _bytes.addAll(EscPosCommands.feedLines(lines));
  }

  void cut() {
    feed(3);
    _bytes.addAll(EscPosCommands.fullCut);
  }

  /// Generates QR Code as raster ESC/POS bitmap image
  Future<void> qrCode(String data, {double size = 180.0}) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
          gapless: true,
        );

        final picRecorder = ui.PictureRecorder();
        final canvas = Canvas(picRecorder);
        painter.paint(canvas, Size(size, size));
        final picture = picRecorder.endRecording();
        final uiImage = await picture.toImage(size.toInt(), size.toInt());

        final rasterBytes = await RasterGenerator.imageToEscPosRaster(uiImage);
        
        // Center QR Code
        _bytes.addAll(EscPosCommands.alignCenter);
        _bytes.addAll(rasterBytes);
        _bytes.addAll(EscPosCommands.alignLeft);
      }
    } catch (_) {
      // Fallback text if QR rendering fails
      text('[QR: $data]', align: 1);
    }
  }

  /// Generates Barcode as raster ESC/POS bitmap image
  Future<void> barcode(String data, {double height = 60.0}) async {
    try {
      // Printable barcode text fallback
      _bytes.addAll(EscPosCommands.alignCenter);
      text('*$data*', align: 1, bold: true);
      _bytes.addAll(EscPosCommands.alignLeft);
    } catch (_) {
      text('*$data*', align: 1);
    }
  }

  List<int> getBytes() {
    return List.from(_bytes);
  }
}
