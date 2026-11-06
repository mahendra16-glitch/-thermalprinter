class HybridTextParser {
  // RegExp matching Devanagari (Hindi) characters
  static final RegExp devanagariRegExp = RegExp(r'[\u0900-\u097F]');

  // RegExp matching Emojis
  static final RegExp emojiRegExp = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );

  // Special non-standard ASCII symbols commonly used in receipts
  static const List<String> specialSymbols = [
    '₹',
    '✓',
    '★',
    '♥',
    '→',
    '•',
    '°',
    '©',
    '™',
    '🙏',
  ];

  /// Checks if the given [text] contains characters that thermal printer hardware
  /// standard ASCII / CP437 character sets typically cannot print natively.
  static bool hasComplexContent(String text) {
    if (text.isEmpty) return false;

    // Check for Hindi / Devanagari
    if (devanagariRegExp.hasMatch(text)) return true;

    // Check for Emoji
    if (emojiRegExp.hasMatch(text)) return true;

    // Check for Special symbols
    for (final sym in specialSymbols) {
      if (text.contains(sym)) return true;
    }

    // Check for non-ASCII (> 127)
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) > 127) {
        return true;
      }
    }

    return false;
  }
}
