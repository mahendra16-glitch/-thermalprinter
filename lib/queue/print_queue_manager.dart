import 'dart:async';

import '../models/print_job.dart';
import '../models/printer_device.dart';
import '../models/pos_order.dart';
import '../models/print_history_item.dart';
import '../services/storage_service.dart';
import '../printing/smart_print_engine.dart';

class PrintQueueManager {
  static PrintQueueManager? _instance;
  final StorageService _storage;

  final List<PrintJob> _queue = [];
  bool _isProcessing = false;
  final StreamController<List<PrintJob>> _queueController =
      StreamController<List<PrintJob>>.broadcast();

  PrintQueueManager._(this._storage);

  static Future<PrintQueueManager> getInstance() async {
    if (_instance == null) {
      final storage = await StorageService.getInstance();
      _instance = PrintQueueManager._(storage);
      await _instance!._loadQueue();
    }
    return _instance!;
  }

  Stream<List<PrintJob>> get queueStream => _queueController.stream;
  List<PrintJob> get currentQueue => List.unmodifiable(_queue);

  Future<void> _loadQueue() async {
    final saved = await _storage.getQueue();
    _queue.clear();
    _queue.addAll(saved);
    _notify();
    // Auto-process pending jobs on start
    processNext();
  }

  void _notify() {
    _queueController.add(List.from(_queue));
    _storage.saveQueue(_queue);
  }

  /// Adds a new POS print job to queue with duplicate prevention
  Future<String> addOrderToQueue(PosOrder order) async {
    // Prevent exact duplicate active order ID in pending/printing state
    final existing = _queue.firstWhere(
      (j) =>
          j.orderId == order.orderId &&
          (j.status == PrintJobStatus.pending ||
              j.status == PrintJobStatus.printing),
      orElse: () => PrintJob(id: '', orderId: ''),
    );

    if (existing.id.isNotEmpty) {
      return existing.id; // Return existing job ID to prevent double queueing
    }

    final jobId = 'JOB-${DateTime.now().millisecondsSinceEpoch}';
    final job = PrintJob(
      id: jobId,
      orderId: order.orderId,
      printType: order.type,
      targetRole: order.printerRole,
      posOrderJson: order.toJson(),
      status: PrintJobStatus.pending,
    );

    _queue.add(job);
    _notify();

    // Trigger queue processor
    processNext();

    return jobId;
  }

  /// Manual retry for a failed job
  Future<void> retryJob(String jobId) async {
    final index = _queue.indexWhere((j) => j.id == jobId);
    if (index >= 0) {
      _queue[index].status = PrintJobStatus.pending;
      _queue[index].errorMessage = null;
      _notify();
      processNext();
    }
  }

  /// Delete a job from the queue
  Future<void> removeJob(String jobId) async {
    _queue.removeWhere((j) => j.id == jobId);
    _notify();
  }

  /// Clear completed / failed jobs
  Future<void> clearCompleted() async {
    _queue.removeWhere(
      (j) =>
          j.status == PrintJobStatus.printed ||
          j.status == PrintJobStatus.failed,
    );
    _notify();
  }

  /// Main Queue Processing Loop
  Future<void> processNext() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pendingIndex = _queue.indexWhere(
        (j) => j.status == PrintJobStatus.pending,
      );
      if (pendingIndex < 0) {
        _isProcessing = false;
        return;
      }

      final job = _queue[pendingIndex];
      job.status = PrintJobStatus.printing;
      _notify();

      // Find target printer
      PrinterDevice? device;
      if (job.targetPrinterId != null) {
        final printers = await _storage.getSavedPrinters();
        device = printers.firstWhere(
          (p) => p.id == job.targetPrinterId,
          orElse: () => PrinterDevice(
            id: '',
            name: '',
            connectionType: ConnectionType.network,
          ),
        );
        if (device.id.isEmpty) device = null;
      }

      device ??= await _storage.getPrinterForRole(job.targetRole);

      if (device == null) {
        job.status = PrintJobStatus.failed;
        job.errorMessage =
            'No saved printer found for role ${job.targetRole.label}';
        job.retryCount++;
        _notify();
        await _recordHistory(job, 'No Printer', ConnectionType.network, false);
        _isProcessing = false;
        processNext();
        return;
      }

      final printMode = await _storage.getPrintMode();

      if (job.posOrderJson != null) {
        final order = PosOrder.fromJson(job.posOrderJson!);
        try {
          await SmartPrintEngine.printOrder(
            order: order,
            device: device,
            printMode: printMode,
          );

          job.status = PrintJobStatus.printed;
          job.processedAt = DateTime.now();
          job.errorMessage = null;
          _notify();

          await _recordHistory(job, device.name, device.connectionType, true);
        } catch (e) {
          job.status = PrintJobStatus.failed;
          job.errorMessage = e.toString().replaceAll('Exception: ', '');
          job.retryCount++;
          _notify();

          await _recordHistory(job, device.name, device.connectionType, false);
        }
      }
    } finally {
      _isProcessing = false;
    }

    // Process remaining jobs in queue
    processNext();
  }

  Future<void> _recordHistory(
    PrintJob job,
    String printerName,
    ConnectionType connType,
    bool isSuccess,
  ) async {
    final historyItem = PrintHistoryItem(
      id: 'HIST-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      printerName: printerName,
      connectionType: connType,
      orderId: job.orderId,
      printType: job.printType,
      isSuccess: isSuccess,
      errorMessage: job.errorMessage,
    );
    await _storage.addHistoryItem(historyItem);
  }
}
