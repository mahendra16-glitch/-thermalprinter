import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../models/print_history_item.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';

/// Persistence for the print queue and the print history log.
class PrintJobRepository {
  final AppDatabase _db;

  PrintJobRepository(this._db);

  /// Stored on jobs that were mid-print when the app stopped.
  static const String interruptedMessage =
      'Interrupted while printing (app closed or crashed). The printer may '
      'already have printed it. Check the printer before retrying.';

  // --- Jobs ---

  Future<List<PrintJob>> getAllJobs() async {
    final rows = await (_db.select(
      _db.printJobs,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
    return rows.map(jobFromRow).toList();
  }

  /// Inserts or replaces a job. Await this before sending any bytes.
  Future<void> upsertJob(PrintJob job) {
    return _db.into(_db.printJobs).insertOnConflictUpdate(jobToCompanion(job));
  }

  Future<void> updateJobState(PrintJob job) {
    return (_db.update(_db.printJobs)..where((t) => t.id.equals(job.id))).write(
      PrintJobsCompanion(
        status: Value(job.status.name),
        retryCount: Value(job.retryCount),
        errorMessage: Value(job.errorMessage),
        processedAt: Value(job.processedAt?.toUtc().millisecondsSinceEpoch),
        updatedAt: Value(Clock.nowMs()),
      ),
    );
  }

  Future<void> deleteJob(String id) =>
      (_db.delete(_db.printJobs)..where((t) => t.id.equals(id))).go();

  Future<void> deleteJobsWithStatus(List<PrintJobStatus> statuses) {
    final names = statuses.map((s) => s.name).toList();
    return (_db.delete(_db.printJobs)..where((t) => t.status.isIn(names))).go();
  }

  /// Marks every job left in `printing` as failed. Called once on start-up:
  /// such a job was interrupted, and re-sending it automatically could print
  /// a duplicate bill or KOT.
  Future<int> failInterruptedJobs() {
    return (_db.update(
      _db.printJobs,
    )..where((t) => t.status.equals(PrintJobStatus.printing.name))).write(
      PrintJobsCompanion(
        status: Value(PrintJobStatus.failed.name),
        errorMessage: const Value(interruptedMessage),
        updatedAt: Value(Clock.nowMs()),
      ),
    );
  }

  // --- History ---

  Future<List<PrintHistoryItem>> getHistory({int? limit}) async {
    final query = _db.select(_db.printHistory)
      ..orderBy([(t) => OrderingTerm.desc(t.at)]);
    if (limit != null) query.limit(limit);
    final rows = await query.get();
    return rows.map(historyFromRow).toList();
  }

  Future<void> addHistory(PrintHistoryItem item, {String? jobId}) {
    return _db
        .into(_db.printHistory)
        .insertOnConflictUpdate(historyToCompanion(item, jobId: jobId));
  }

  Future<void> clearHistory() => _db.delete(_db.printHistory).go();

  // --- Mapping ---

  /// What a job prints, e.g. `KOT:1024`. Two jobs with the same key must not
  /// both be active, but a BILL and a KOT for one order are different keys.
  static String sourceKeyFor(String printType, String orderId) =>
      '${printType.toUpperCase()}:$orderId';

  static PrintJob jobFromRow(PrintJobRow r) {
    return PrintJob(
      id: r.id,
      orderId: r.orderId,
      printType: r.printType,
      targetRole: PrinterRole.values.firstWhere(
        (e) => e.name == r.targetRole,
        orElse: () => PrinterRole.bill,
      ),
      targetPrinterId: r.targetPrinterId,
      posOrderJson: r.payloadJson == null
          ? null
          : jsonDecode(r.payloadJson!) as Map<String, dynamic>,
      createdAt: Clock.toLocal(r.createdAt),
      status: PrintJobStatus.values.firstWhere(
        (e) => e.name == r.status,
        orElse: () => PrintJobStatus.failed,
      ),
      retryCount: r.retryCount,
      errorMessage: r.errorMessage,
      processedAt: r.processedAt == null ? null : Clock.toLocal(r.processedAt!),
    );
  }

  static PrintJobsCompanion jobToCompanion(PrintJob j) {
    return PrintJobsCompanion.insert(
      id: j.id,
      orderId: j.orderId,
      printType: j.printType,
      targetRole: j.targetRole.name,
      targetPrinterId: Value(j.targetPrinterId),
      sourceKey: sourceKeyFor(j.printType, j.orderId),
      payloadJson: Value(
        j.posOrderJson == null ? null : jsonEncode(j.posOrderJson),
      ),
      status: j.status.name,
      retryCount: Value(j.retryCount),
      errorMessage: Value(j.errorMessage),
      createdAt: j.createdAt.toUtc().millisecondsSinceEpoch,
      updatedAt: Clock.nowMs(),
      processedAt: Value(j.processedAt?.toUtc().millisecondsSinceEpoch),
    );
  }

  static PrintHistoryItem historyFromRow(PrintHistoryRow r) {
    return PrintHistoryItem(
      id: r.id,
      timestamp: Clock.toLocal(r.at),
      printerName: r.printerName,
      connectionType: ConnectionType.values.firstWhere(
        (e) => e.name == r.connectionType,
        orElse: () => ConnectionType.network,
      ),
      orderId: r.orderId,
      printType: r.printType,
      isSuccess: r.isSuccess,
      errorMessage: r.errorMessage,
    );
  }

  static PrintHistoryCompanion historyToCompanion(
    PrintHistoryItem h, {
    String? jobId,
  }) {
    return PrintHistoryCompanion.insert(
      id: h.id,
      jobId: Value(jobId),
      at: h.timestamp.toUtc().millisecondsSinceEpoch,
      printerName: h.printerName,
      connectionType: h.connectionType.name,
      orderId: h.orderId,
      printType: h.printType,
      isSuccess: h.isSuccess,
      errorMessage: Value(h.errorMessage),
    );
  }
}
