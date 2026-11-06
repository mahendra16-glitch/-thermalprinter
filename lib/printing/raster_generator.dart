import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../core/constants/escpos_commands.dart';

class RasterGenerator {
  /// Converts a text string (including Hindi, Emojis, Symbols) into a monochrome
  /// ESC/POS raster byte stream for thermal printers.
  static Future<List<int>> textToRasterBytes({
    required String text,
    required int targetWidthDots, // 384 for 58mm, 576 for 80mm
    double fontSize = 22.0,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.left,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw solid white background
    final Paint bgPaint = Paint()..color = Colors.white;

    final TextSpan span = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.3,
      ),
    );

    final TextPainter tp = TextPainter(
      text: span,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );

    tp.layout(maxWidth: targetWidthDots.toDouble());

    final double height = tp.height + 8.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, targetWidthDots.toDouble(), height),
      bgPaint,
    );

    tp.paint(canvas, const Offset(0, 4));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image uiImage = await picture.toImage(
      targetWidthDots,
      height.ceil(),
    );

    return imageToEscPosRaster(uiImage);
  }

  /// Converts a Flutter [ui.Image] to monochrome ESC/POS raster command (`GS v 0`).
  static Future<List<int>> imageToEscPosRaster(ui.Image uiImage) async {
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return [];

    final int width = uiImage.width;
    final int height = uiImage.height;

    // Convert RGBA byte data to image.Image
    final img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: byteData.buffer,
    );

    return convertImageToRasterEscPos(image);
  }

  /// Converts an [img.Image] to 1-bit monochrome and returns ESC/POS raster command bytes.
  static List<int> convertImageToRasterEscPos(
    img.Image srcImage, {
    int threshold = 160,
  }) {
    final int width = srcImage.width;
    final int height = srcImage.height;

    // Width must be aligned to multiples of 8 bits (1 byte)
    final int widthInBytes = (width + 7) ~/ 8;

    final List<int> bytes = [];

    // Add ESC/POS GS v 0 raster header
    bytes.addAll(EscPosCommands.rasterHeader(
      widthInBytes: widthInBytes,
      heightInPixels: height,
      mode: 0,
    ));

    for (int y = 0; y < height; y++) {
      for (int xByte = 0; xByte < widthInBytes; xByte++) {
        int byteVal = 0;
        for (int bit = 0; bit < 8; bit++) {
          final int x = xByte * 8 + bit;
          if (x < width) {
            final pixel = srcImage.getPixel(x, y);
            // Calculate luminance (grayscale)
            final double luminance =
                0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

            // Thresholding: luminance < threshold means black pixel (bit = 1)
            if (luminance < threshold) {
              byteVal |= (0x80 >> bit);
            }
          }
        }
        bytes.add(byteVal);
      }
    }

    return bytes;
  }
}
