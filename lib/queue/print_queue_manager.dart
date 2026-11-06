import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/util/ids.dart';
import '../data/repositories/print_job_repository.dart';
import '../models/pos_order.dart';
import '../models/print_history_item.dart';
import '../models/print_job.dart';
import '../models/print_mode.dart';
import '../models/printer_device.dart';
import '../printing/smart_print_engine.dart';
import '../services/storage_service.dart';

/// Sends one order to one printer. Throws on failure.
typedef PrintExecutor = Future<void> Function(
  PosOrder order,
  PrinterDevice device,
  PrintMode printMode,
);

Future<void> _defaultExecutor(
  PosOrder order,
  PrinterDevice device,
  PrintMode printMode,
) => SmartPrintEngine.printOrder(
  order: order,
  device: device,
  printMode: printMode,
);

/// Persistent print queue.
///
/// Every state change is written to the database *before* the next step:
/// a job is stored before it is processed and marked `printing` before any
/// bytes are sent. A job found in `printing` at start-up is marked failed
/// (not resent) because it may already have printed.
class PrintQueueManager {
  static PrintQueueManager? _instance;
  static Future<PrintQueueManager>? _opening;

  final StorageService _storage;
  final PrintExecutor _executor;

  final List<PrintJob> _queue = [];
  bool _isProcessing = false;
  final StreamController<List<PrintJob>> _queueController =
      StreamController<List<PrintJob>>.broadcast();

  PrintQueueManager._(this._storage, this._executor);

  PrintJobRepository get _jobs => _storage.printJobs;

  static Future<PrintQueueManager> getInstance() {
    final existing = _instance;
    if (existing != null) return Future.value(existing);
    return _opening ??= () async {
      final storage = await StorageService.getInstance();
      final manager = PrintQueueManager._(storage, _defaultExecutor);
      await manager._loadQueue();
      _instance = manager;
      unawaited(manager.processNext());
      return manager;
    }();
  }

  /// Creates a manager with a fake [executor] and loads the stored queue.
  /// Does not start processing; call [processNext].
  @visibleForTesting
  static Future<PrintQueueManager> createForTesting(
    StorageService storage,
    PrintExecutor executor,
  ) async {
    final manager = PrintQueueManager._(storage, executor);
    await manager._loadQueue();
    return manager;
  }

  Stream<List<PrintJob>> get queueStream => _queueController.stream;
  List<PrintJob> get currentQueue => List.unmodifiable(_queue);

  Future<void> _loadQueue() async {
    await _jobs.failInterruptedJobs();
    _queue
      ..clear()
      ..addAll(await _jobs.getAllJobs());
    _emit();
  }

  void _emit() {
    if (!_queueController.isClosed) {
      _queueController.add(List.unmodifiable(_queue));
    }
  }

  /// Adds a print job for [order] and returns its id.
  ///
  /// If a job for the same document (same print type and order id) is
  /// already pending or printing, that job's id is returned instead, so a
  /// double tap cannot queue two copies. A KOT and a BILL for the same order
  /// are different documents and are both queued.
  Future<String> addOrderToQueue(
    PosOrder order, {
    String? targetPrinterId,
  }) async {
    final key = PrintJobRepository.sourceKeyFor(order.type, order.orderId);
    for (final j in _queue) {
      final active =
          j.status == PrintJobStatus.pending ||
          j.status == PrintJobStatus.printing;
      if (active &&
          PrintJobRepository.sourceKeyFor(j.printType, j.orderId) == key) {
        return j.id;
      }
    }

    final job = PrintJob(
      id: newId(),
      orderId: order.orderId,
      printType: order.type,
      targetRole: order.printerRole,
      targetPrinterId: targetPrinterId,
      posOrderJson: order.toJson(),
      status: PrintJobStatus.pending,
    );

    await _jobs.upsertJob(job); // persisted before anything else happens
    _queue.add(job);
    _emit();

    unawaited(processNext());
    return job.id;
  }

  /// Manual retry for a failed job.
  Future<void> retryJob(String jobId) async {
    final job = _find(jobId);
    if (job == null || job.status != PrintJobStatus.failed) return;
    job.status = PrintJobStatus.pending;
    job.errorMessage = null;
    await _jobs.updateJobState(job);
    _emit();
    unawaited(processNext());
  }

  /// Deletes a job that is not currently printing.
  Future<void> removeJob(String jobId) async {
    final job = _find(jobId);
    if (job == null || job.status == PrintJobStatus.printing) return;
    await _jobs.deleteJob(jobId);
    _queue.remove(job);
    _emit();
  }

  /// Clears printed and failed jobs.
  Future<void> clearCompleted() async {
    const statuses = [PrintJobStatus.printed, PrintJobStatus.failed];
    await _jobs.deleteJobsWithStatus(statuses);
    _queue.removeWhere((j) => statuses.contains(j.status));
    _emit();
  }

  PrintJob? _find(String id) {
    for (final j in _queue) {
      if (j.id == id) return j;
    }
    return null;
  }

  /// Processes pending jobs one at a time until none are left.
  Future<void> processNext() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      while (true) {
        PrintJob? job;
        for (final j in _queue) {
          if (j.status == PrintJobStatus.pending) {
            job = j;
            break;
          }
        }
        if (job == null) break;
        await _process(job);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _process(PrintJob job) async {
    final payload = job.posOrderJson;
    if (payload == null) {
      await _fail(job, 'Job has no printable content.', null);
      return;
    }

    final device = await _resolvePrinter(job);
    if (device == null) {
      await _fail(
        job,
        'No printer is assigned to the ${job.targetRole.label} role and no '
        'fallback printer is set (Settings > Fallback printer).',
        null,
      );
      return;
    }

    job.status = PrintJobStatus.printing;
    await _jobs.updateJobState(job); // persisted before bytes are sent
    _emit();

    try {
      final order = PosOrder.fromJson(payload);
      final mode = await _storage.getPrintMode();
      await _executor(order, device, mode);

      // "Printed" means the transport accepted every byte. It cannot prove
      // that paper came out unless the printer reports status.
      job.status = PrintJobStatus.printed;
      job.processedAt = DateTime.now();
      job.errorMessage = null;
      await _jobs.updateJobState(job);
      _emit();
      await _recordHistory(job, device, true);
    } catch (e) {
      await _fail(job, e.toString().replaceAll('Exception: ', ''), device);
    }
    await _saveDeviceStatus(device);
  }

  Future<PrinterDevice?> _resolvePrinter(PrintJob job) async {
    final targetId = job.targetPrinterId;
    if (targetId != null) {
      final target = await _storage.printers.getById(targetId);
      if (target != null) return target;
    }
    return _storage.getPrinterForRole(job.targetRole);
  }

  Future<void> _fail(
    PrintJob job,
    String message,
    PrinterDevice? device,
  ) async {
    job.status = PrintJobStatus.failed;
    job.errorMessage = message;
    job.retryCount++;
    await _jobs.updateJobState(job);
    _emit();
    await _recordHistory(job, device, false);
  }

  Future<void> _saveDeviceStatus(PrinterDevice device) async {
    try {
      await _storage.printers.updateStatus(device);
    } catch (e) {
      debugPrint('Could not save printer status: $e');
    }
  }

  Future<void> _recordHistory(
    PrintJob job,
    PrinterDevice? device,
    bool isSuccess,
  ) async {
    await _storage.addHistoryItem(
      PrintHistoryItem(
        id: newId(),
        timestamp: DateTime.now(),
        printerName: device?.name ?? 'No Printer',
        connectionType: device?.connectionType ?? ConnectionType.network,
        orderId: job.orderId,
        printType: job.printType,
        isSuccess: isSuccess,
        errorMessage: job.errorMessage,
      ),
      jobId: job.id,
    );
  }

  @visibleForTesting
  Future<void> dispose() => _queueController.close();
}
