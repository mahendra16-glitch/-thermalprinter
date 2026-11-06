class AppConstants {
  static const String appName = 'Thermal POS Printer';
  static const String appVersion = '1.0.0';

  // Paper dots
  static const int dots58mm = 384; // 58mm thermal paper width in dots
  static const int dots80mm = 576; // 80mm thermal paper width in dots

  // Default character counts per line (Font A / Standard)
  static const int chars58mm = 32;
  static const int chars80mm = 48;

  // Network default port
  static const int defaultNetworkPort = 9100;

  // Socket timeout
  static const Duration socketTimeout = Duration(seconds: 5);

  // Storage Keys
  static const String keySavedPrinters = 'saved_printers_v1';
  static const String keyPrintHistory = 'print_history_v1';
  static const String keyPrintQueue = 'print_queue_v1';
  static const String keyPrintMode = 'default_print_mode_v1';
  static const String keyPrinterRouting = 'printer_routing_v1';
  static const String keyAutoReconnect = 'auto_reconnect_v1';

  // Special unicode characters supported by hybrid engine
  static const List<String> specialSymbols = [
    '₹', '✓', '★', '♥', '→', '•', '°', '©', '™'
  ];
}
