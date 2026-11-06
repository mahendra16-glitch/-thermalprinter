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
  static Future<List<int>> imageToEscPosRaster(
    ui.Image uiImage, {
    int threshold = 160,
  }) async {
    final ByteData? byteData = await uiImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) return [];

    final int width = uiImage.width;
    final int height = uiImage.height;

    return rgbaToEscPosRaster(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      width: width,
      height: height,
      threshold: threshold,
    );
  }

  /// Converts raw RGBA8888 pixels (as produced by
  /// `ui.Image.toByteData(format: rawRgba)`) to an ESC/POS raster command.
  static List<int> rgbaToEscPosRaster(
    Uint8List rgba, {
    required int width,
    required int height,
    int threshold = 160,
  }) {
    // The buffer is 4 bytes per pixel. `Image.fromBytes` defaults to 3
    // channels, which shears the picture, so the channel count must be given.
    final img.Image image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    return convertImageToRasterEscPos(image, threshold: threshold);
  }

  /// Rows per GS v 0 command.
  static const int bandHeight = 128;

  /// Converts an [img.Image] to 1-bit monochrome ESC/POS raster commands,
  /// one command per band of [bandHeight] rows.
  static List<int> convertImageToRasterEscPos(
    img.Image srcImage, {
    int threshold = 160,
  }) {
    final int width = srcImage.width;
    final int height = srcImage.height;

    // Width must be aligned to multiples of 8 bits (1 byte)
    final int widthInBytes = (width + 7) ~/ 8;

    final List<int> bytes = [];
    for (int y = 0; y < height; y++) {
      // Each band of [bandHeight] rows is its own GS v 0 command, so small
      // printer buffers (common on Bluetooth models) are not overrun.
      if (y % bandHeight == 0) {
        bytes.addAll(
          EscPosCommands.rasterHeader(
            widthInBytes: widthInBytes,
            heightInPixels: (height - y) < bandHeight ? height - y : bandHeight,
            mode: 0,
          ),
        );
      }
      for (int xByte = 0; xByte < widthInBytes; xByte++) {
        int byteVal = 0;
        for (int bit = 0; bit < 8; bit++) {
          final int x = xByte * 8 + bit;
          if (x < width) {
            final pixel = srcImage.getPixel(x, y);
            // Transparent pixels (e.g. the QR painter's background) are
            // paper, not ink. Without this they read as RGB 0,0,0 = black.
            if (srcImage.hasAlpha && pixel.a < pixel.maxChannelValue / 2) {
              continue;
            }
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
