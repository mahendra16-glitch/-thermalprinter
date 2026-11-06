import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/printing/raster_generator.dart';

/// RGBA buffer [width]x[height]; [ink] decides which pixels are black.
Uint8List rgba(
  int width,
  int height,
  bool Function(int x, int y) ink, {
  bool Function(int x, int y)? transparent,
}) {
  final bytes = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final v = ink(x, y) ? 0 : 255;
      bytes[i] = v;
      bytes[i + 1] = v;
      bytes[i + 2] = v;
      bytes[i + 3] = (transparent?.call(x, y) ?? false) ? 0 : 255;
    }
  }
  return bytes;
}

void main() {
  const header = [0x1D, 0x76, 0x30, 0x00];

  test('GS v 0 header carries width in bytes and height in dots', () {
    final out = RasterGenerator.rgbaToEscPosRaster(
      rgba(16, 3, (x, y) => false),
      width: 16,
      height: 3,
    );
    expect(out.sublist(0, 8), [...header, 2, 0, 3, 0]);
    expect(out.length, 8 + 2 * 3);
  });

  test('RGBA pixels map 1:1 to bits, black = 1, MSB = leftmost (D3)', () {
    // Row 0: left half black. Row 1: right half black. Row 2: x == 0 only.
    final out = RasterGenerator.rgbaToEscPosRaster(
      rgba(16, 3, (x, y) {
        if (y == 0) return x < 8;
        if (y == 1) return x >= 8;
        return x == 0;
      }),
      width: 16,
      height: 3,
    );
    expect(out.sublist(8), [0xFF, 0x00, 0x00, 0xFF, 0x80, 0x00]);
  });

  test('width that is not a multiple of 8 is padded with white', () {
    final out = RasterGenerator.rgbaToEscPosRaster(
      rgba(10, 1, (x, y) => true),
      width: 10,
      height: 1,
    );
    expect(out.sublist(0, 8), [...header, 2, 0, 1, 0]);
    expect(out.sublist(8), [0xFF, 0xC0]);
  });

  test('transparent pixels print as paper, not ink', () {
    final out = RasterGenerator.rgbaToEscPosRaster(
      rgba(8, 1, (x, y) => true, transparent: (x, y) => x >= 4),
      width: 8,
      height: 1,
    );
    expect(out.sublist(8), [0xF0]);
  });
}
