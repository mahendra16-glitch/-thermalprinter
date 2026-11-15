import 'dart:async';
import '../../models/printer_device.dart';
import '../../models/pos_order.dart';
import '../../queue/print_queue_manager.dart';
import '../../printing/smart_print_engine.dart';
import '../../services/storage_service.dart';
import 'printer_connection_manager.dart';
import 'printer_status_service.dart';
import 'printer_reconnect_service.dart';

class PrinterManagerService {
  static final PrinterManagerService _instance =
      PrinterManagerService._internal();
  factory PrinterManagerService() => _instance;
  PrinterManagerService._internal();

  final PrinterConnectionManager connectionManager = PrinterConnectionManager();
  final PrinterStatusService statusService = PrinterStatusService();
  final PrinterReconnectService reconnectService = PrinterReconnectService();

  /// Initializes background reconnection daemon and queue manager
  Future<void> initialize() async {
    reconnectService.startAutoReconnectDaemon();
    await PrintQueueManager.getInstance();
  }

  /// Sends a POS order to the queue for job execution
  Future<String> sendOrderToQueue(PosOrder order) async {
    final queueManager = await PrintQueueManager.getInstance();
    return await queueManager.addOrderToQueue(order);
  }

  /// Directly prints an order onto a specific printer device
  Future<void> printOrderDirect({
    required PosOrder order,
    required PrinterDevice device,
  }) async {
    final storage = await StorageService.getInstance();
    final printMode = await storage.getPrintMode();

    await SmartPrintEngine.printOrder(
      order: order,
      device: device,
      printMode: printMode,
    );
  }
}
