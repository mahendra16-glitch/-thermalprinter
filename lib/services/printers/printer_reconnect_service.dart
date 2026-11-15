import 'dart:async';
import 'dart:io';
import '../../models/printer_device.dart';
import '../storage_service.dart';
import 'printer_connection_manager.dart';
import 'printer_status_service.dart';

class PrinterReconnectService {
  static final PrinterReconnectService _instance =
      PrinterReconnectService._internal();
  factory PrinterReconnectService() => _instance;
  PrinterReconnectService._internal();

  Timer? _reconnectTimer;
  bool _isDaemonRunning = false;
  final PrinterConnectionManager _connectionManager = PrinterConnectionManager();
  final PrinterStatusService _statusService = PrinterStatusService();

  /// Starts the background auto-reconnection daemon for offline Wi-Fi & Bluetooth printers
  void startAutoReconnectDaemon() {
    if (_isDaemonRunning) return;
    _isDaemonRunning = true;

    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _checkAndReconnectPrinters();
    });
  }

  void stopAutoReconnectDaemon() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isDaemonRunning = false;
  }

  Future<void> _checkAndReconnectPrinters() async {
    try {
      final storage = await StorageService.getInstance();
      final savedPrinters = await storage.getSavedPrinters();

      for (final device in savedPrinters) {
        final currentStatus = _statusService.getStatus(device.id);

        if (currentStatus == PrinterConnectionStatus.disconnected ||
            currentStatus == PrinterConnectionStatus.connectionFailed) {
          
          if (device.connectionType == ConnectionType.network) {
            final ip = device.ipAddress;
            if (ip == null || ip.isEmpty) continue;

            // Ping socket quickly before full connect
            final isAvailable = await _pingTcpSocket(ip, device.port);
            if (isAvailable) {
              await _connectionManager.connectPrinter(device);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> _pingTcpSocket(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 2),
      );
      await socket.close();
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
