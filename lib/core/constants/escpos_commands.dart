class EscPosCommands {
  // Initialize printer
  static const List<int> init = [0x1B, 0x40]; // ESC @

  // Line Feeds
  static const List<int> lineFeed = [0x0A]; // LF
  static List<int> feedLines(int n) => [0x1B, 0x64, n]; // ESC d n

  // Cuts
  static const List<int> fullCut = [0x1D, 0x56, 0x00]; // GS V 0
  static const List<int> partialCut = [0x1D, 0x56, 0x01]; // GS V 1
  static List<int> feedAndCut(int n) => [0x1B, 0x64, n, 0x1D, 0x56, 0x01];

  // Alignments
  static const List<int> alignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> alignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> alignRight = [0x1B, 0x61, 0x02]; // ESC a 2

  // Text Styling
  static const List<int> boldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> boldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> underlineOn = [0x1B, 0x2D, 0x01]; // ESC - 1
  static const List<int> underlineOff = [0x1B, 0x2D, 0x00]; // ESC - 0

  // Text Size: widthMultiplier (0-7), heightMultiplier (0-7)
  static List<int> textSize({int width = 0, int height = 0}) {
    final int n = ((width & 0x07) << 4) | (height & 0x07);
    return [0x1D, 0x21, n]; // GS ! n
  }

  // Line Spacing
  static const List<int> defaultLineSpacing = [0x1B, 0x32]; // ESC 2
  static List<int> setLineSpacing(int n) => [0x1B, 0x33, n]; // ESC 3 n

  // Code Page (Character Set)
  static const List<int> codePagePC437 = [0x1B, 0x74, 0x00]; // USA, Standard Europe
  static const List<int> codePageWPC1252 = [0x1B, 0x74, 0x10]; // Latin 1
  static const List<int> codePageUTF8 = [0x1C, 0x26]; // FS & (Enable UTF-8 if printer supports native UTF-8)

  // Raster Image Command (GS v 0)
  // mode: 0 = Normal, 1 = Double width, 2 = Double height, 3 = Quadruple
  static List<int> rasterHeader({
    required int widthInBytes,
    required int heightInPixels,
    int mode = 0,
  }) {
    final int xL = widthInBytes & 0xFF;
    final int xH = (widthInBytes >> 8) & 0xFF;
    final int yL = heightInPixels & 0xFF;
    final int yH = (heightInPixels >> 8) & 0xFF;

    return [0x1D, 0x76, 0x30, mode, xL, xH, yL, yH];
  }
}
