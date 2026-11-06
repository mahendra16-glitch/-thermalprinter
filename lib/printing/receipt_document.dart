import 'dart:convert';

/// A printer-independent receipt: what to print, not how. The renderer
/// turns it into ESC/POS text, inline raster, or a full image.
class ReceiptDocument {
  final List<ReceiptBlock> blocks = [];

  void text(
    String text, {
    ReceiptAlign align = ReceiptAlign.left,
    ReceiptTextSize size = ReceiptTextSize.normal,
    bool bold = false,
  }) {
    if (text.isEmpty) return;
    blocks.add(TextBlock(text, align: align, size: size, bold: bold));
  }

  /// Left column wraps; the others are right-aligned and never truncated.
  void columns(
    List<String> cols, {
    List<int>? flex,
    bool bold = false,
    ReceiptTextSize size = ReceiptTextSize.normal,
  }) {
    blocks.add(ColumnsBlock(cols, flex: flex, bold: bold, size: size));
  }

  void divider([String char = '-']) => blocks.add(DividerBlock(char));

  void feed([int lines = 1]) => blocks.add(FeedBlock(lines));

  void qr(String data) => blocks.add(QrBlock(data));
}

enum ReceiptAlign { left, center, right }

/// `tall` doubles height only (keeps all characters per line), `large`
/// doubles both (half the characters per line).
enum ReceiptTextSize { normal, tall, large }

extension ReceiptTextSizeX on ReceiptTextSize {
  int get widthFactor => this == ReceiptTextSize.large ? 2 : 1;
  int get heightFactor => this == ReceiptTextSize.normal ? 1 : 2;
}

sealed class ReceiptBlock {
  const ReceiptBlock();
}

class TextBlock extends ReceiptBlock {
  final String text;
  final ReceiptAlign align;
  final ReceiptTextSize size;
  final bool bold;

  const TextBlock(
    this.text, {
    this.align = ReceiptAlign.left,
    this.size = ReceiptTextSize.normal,
    this.bold = false,
  });
}

class ColumnsBlock extends ReceiptBlock {
  final List<String> cols;
  final List<int>? flex;
  final bool bold;
  final ReceiptTextSize size;

  const ColumnsBlock(
    this.cols, {
    this.flex,
    this.bold = false,
    this.size = ReceiptTextSize.normal,
  });
}

class DividerBlock extends ReceiptBlock {
  final String char;
  const DividerBlock(this.char);
}

class FeedBlock extends ReceiptBlock {
  final int lines;
  const FeedBlock(this.lines);
}

class QrBlock extends ReceiptBlock {
  final String data;
  const QrBlock(this.data);
}

// ---------------------------------------------------------------- helpers

/// Word-wraps [text] to lines of at most [width] characters, breaking long
/// words. Explicit newlines are kept.
List<String> wrapText(String text, int width) {
  if (width < 1) width = 1;
  final out = <String>[];
  for (final para in text.split('\n')) {
    var line = '';
    for (final word in para.split(RegExp(r' +'))) {
      var w = word;
      while (w.length > width) {
        if (line.isNotEmpty) {
          out.add(line);
          line = '';
        }
        out.add(w.substring(0, width));
        w = w.substring(width);
      }
      if (line.isEmpty) {
        line = w;
      } else if (line.length + 1 + w.length <= width) {
        line = '$line $w';
      } else {
        out.add(line);
        line = w;
      }
    }
    out.add(line);
  }
  return out;
}

/// Lays out columns in [width] characters. Columns after the first are
/// right-aligned and keep their full text; the first column wraps onto
/// extra lines instead of being cut off.
List<String> layoutColumns(List<String> cols, int width, {List<int>? flex}) {
  if (cols.isEmpty) return const [];
  if (cols.length == 1) return wrapText(cols.first, width);
  final f = flex ?? [3, ...List.filled(cols.length - 1, 1)];
  final total = f.reduce((a, b) => a + b);
  final widths = <int>[];
  for (var i = 1; i < cols.length; i++) {
    // Right columns get their share but at least their own length + gap.
    final share = (width * f[i]) ~/ total;
    final need = cols[i].length + 1;
    widths.add(share < need ? need : share);
  }
  final rightWidth = widths.fold(0, (a, b) => a + b);
  final firstWidth = (width - rightWidth).clamp(1, width);
  final firstLines = wrapText(cols.first, firstWidth);
  final right = StringBuffer();
  for (var i = 1; i < cols.length; i++) {
    right.write(cols[i].padLeft(widths[i - 1]));
  }
  final r = right.toString();
  if (firstWidth + r.length > width) {
    // Not enough room: put the right columns on their own line.
    return [...wrapText(cols.first, width), r.trimLeft().padLeft(width)];
  }
  return [firstLines.first.padRight(firstWidth) + r, ...firstLines.skip(1)];
}

const Map<String, String> _asciiReplacements = {
  '₹': 'Rs.',
  '–': '-',
  '—': '-',
  '‘': "'",
  '’': "'",
  '“': '"',
  '”': '"',
  '•': '*',
  '…': '...',
  '×': 'x',
  '✓': 'v',
  '✔': 'v',
  '★': '*',
  '→': '->',
  '←': '<-',
  '°': 'deg',
  '©': '(c)',
  '®': '(R)',
  '™': '(TM)',
  ' ': ' ',
};

/// Text a basic ESC/POS printer can print in its default code page: ASCII,
/// with common symbols spelled out (₹ -> "Rs.") and anything else replaced
/// by "?". Never throws, unlike `latin1.encode`.
String toPrinterAscii(String s) {
  final b = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    if (rune >= 32 && rune < 127 || rune == 10) {
      b.write(ch);
    } else if (_asciiReplacements[ch] case final r?) {
      b.write(r);
    } else if (rune == 0xFE0F || rune == 0x200D) {
      // Emoji presentation selector / joiner: drop silently.
    } else {
      b.write('?');
    }
  }
  return b.toString();
}

List<int> encodePrinterText(String s) => ascii.encode(toPrinterAscii(s));

/// True if [s] has characters that plain ESC/POS text cannot show
/// faithfully (Hindi, emoji, ₹ …), so raster output is better.
bool needsRaster(String s) =>
    s.runes.any((r) => r >= 127 || (r < 32 && r != 10));
