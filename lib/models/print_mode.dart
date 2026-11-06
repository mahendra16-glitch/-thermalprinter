enum PrintMode {
  fastMode,
  compatibilityMode,
  fullImageMode,
}

extension PrintModeX on PrintMode {
  String get title {
    switch (this) {
      case PrintMode.fastMode:
        return 'Fast Mode';
      case PrintMode.compatibilityMode:
        return 'Compatibility Mode';
      case PrintMode.fullImageMode:
        return 'Full Image Mode';
    }
  }

  String get description {
    switch (this) {
      case PrintMode.fastMode:
        return 'Prints using ESC/POS text whenever possible for maximum speed and crispness.';
      case PrintMode.compatibilityMode:
        return 'Automatically renders unsupported Unicode, Hindi & emojis as inline images.';
      case PrintMode.fullImageMode:
        return 'Renders complete receipt as an image before printing. 100% font/emoji compatibility.';
    }
  }
}
