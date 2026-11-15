import 'dart:async';

enum PrinterConnectionStatus {
  searching,
  found,
  connecting,
  connected,
  disconnected,
  connectionFailed,
  unsupportedDevice,
}

extension PrinterConnectionStatusX on PrinterConnectionStatus {
  String get label {
    switch (this) {
      case PrinterConnectionStatus.searching:
        return 'Searching...';
      case PrinterConnectionStatus.found:
        return 'Found';
      case PrinterConnectionStatus.connecting:
        return 'Connecting...';
      case PrinterConnectionStatus.connected:
        return 'Connected 🟢';
      case PrinterConnectionStatus.disconnected:
        return 'Disconnected 🔴';
      case PrinterConnectionStatus.connectionFailed:
        return 'Connection Failed ❌';
      case PrinterConnectionStatus.unsupportedDevice:
        return 'Unsupported Device ⚠️';
    }
  }
}

class PrinterStatusService {
  static final PrinterStatusService _instance = PrinterStatusService._internal();
  factory PrinterStatusService() => _instance;
  PrinterStatusService._internal();

  final Map<String, PrinterConnectionStatus> _printerStatuses = {};
  final Map<String, String?> _lastErrors = {};

  final StreamController<Map<String, PrinterConnectionStatus>> _statusController =
      StreamController<Map<String, PrinterConnectionStatus>>.broadcast();

  Stream<Map<String, PrinterConnectionStatus>> get statusStream =>
      _statusController.stream;

  PrinterConnectionStatus getStatus(String printerId) {
    return _printerStatuses[printerId] ?? PrinterConnectionStatus.disconnected;
  }

  String? getLastError(String printerId) {
    return _lastErrors[printerId];
  }

  void updateStatus(
    String printerId,
    PrinterConnectionStatus status, {
    String? error,
  }) {
    _printerStatuses[printerId] = status;
    if (error != null) {
      _lastErrors[printerId] = error;
    } else if (status == PrinterConnectionStatus.connected) {
      _lastErrors[printerId] = null;
    }
    _statusController.add(Map.unmodifiable(_printerStatuses));
  }
}
