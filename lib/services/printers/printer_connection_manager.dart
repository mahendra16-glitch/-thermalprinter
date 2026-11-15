import 'dart:async';
import '../../models/printer_device.dart';
import '../../printers/printer_adapter.dart';
import 'printer_status_service.dart';

class PrinterConnectionManager {
  static final PrinterConnectionManager _instance =
      PrinterConnectionManager._internal();
  factory PrinterConnectionManager() => _instance;
  PrinterConnectionManager._internal();

  final Map<String, PrinterAdapter> _activeAdapters = {};
  final PrinterStatusService _statusService = PrinterStatusService();

  /// Retrieves or creates an active connection adapter for a printer
  PrinterAdapter getAdapterForDevice(PrinterDevice device) {
    if (_activeAdapters.containsKey(device.id)) {
      return _activeAdapters[device.id]!;
    }

    final adapter = PrinterAdapter.forDevice(device);
    _activeAdapters[device.id] = adapter;
    return adapter;
  }

  /// Connects to a printer with status tracking and duplicate protection
  Future<bool> connectPrinter(PrinterDevice device) async {
    final adapter = getAdapterForDevice(device);

    if (await adapter.isConnected()) {
      _statusService.updateStatus(
        device.id,
        PrinterConnectionStatus.connected,
      );
      return true;
    }

    _statusService.updateStatus(
      device.id,
      PrinterConnectionStatus.connecting,
    );

    try {
      final success = await adapter.connect();
      if (success) {
        _statusService.updateStatus(
          device.id,
          PrinterConnectionStatus.connected,
        );
      } else {
        _statusService.updateStatus(
          device.id,
          PrinterConnectionStatus.connectionFailed,
          error: device.lastError,
        );
      }
      return success;
    } catch (e) {
      _statusService.updateStatus(
        device.id,
        PrinterConnectionStatus.connectionFailed,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Safely disconnects a printer connection
  Future<void> disconnectPrinter(String printerId) async {
    final adapter = _activeAdapters[printerId];
    if (adapter != null) {
      try {
        await adapter.disconnect();
      } catch (_) {}
      _activeAdapters.remove(printerId);
    }
    _statusService.updateStatus(
      printerId,
      PrinterConnectionStatus.disconnected,
    );
  }

  /// Sends raw ESC/POS bytes through active connection adapter
  Future<void> sendBytes(PrinterDevice device, List<int> bytes) async {
    final adapter = getAdapterForDevice(device);
    try {
      await adapter.sendRawBytes(bytes);
      _statusService.updateStatus(
        device.id,
        PrinterConnectionStatus.connected,
      );
    } catch (e) {
      _statusService.updateStatus(
        device.id,
        PrinterConnectionStatus.connectionFailed,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}
