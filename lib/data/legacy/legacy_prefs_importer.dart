import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../models/print_history_item.dart';
import '../../models/print_job.dart';
import '../../models/print_mode.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import '../repositories/audit_repository.dart';
import '../repositories/print_job_repository.dart';
import '../repositories/printer_repository.dart';
import '../repositories/settings_repository.dart';

class LegacyImportException implements Exception {
  final String message;
  LegacyImportException(this.message);

  @override
  String toString() => 'Could not import saved printer data: $message';
}

class LegacyImportResult {
  final bool alreadyDone;
  final int printers;
  final int jobs;
  final int interruptedJobs;
  final int historyItems;

  const LegacyImportResult({
    this.alreadyDone = false,
    this.printers = 0,
    this.jobs = 0,
    this.interruptedJobs = 0,
    this.historyItems = 0,
  });
}

/// One-time copy of the pre-database `SharedPreferences` data (printers,
/// print mode, queue, history) into the database.
///
/// Safety rules:
/// - Everything is written in one transaction; on any error nothing is
///   written and the import is retried on the next launch.
/// - Malformed legacy JSON aborts the import instead of being skipped, so
///   no printer is silently dropped.
/// - The legacy keys are never modified or deleted.
/// - Printer ids are preserved.
class LegacyPrefsImporter {
  final AppDatabase _db;
  final SharedPreferences _prefs;

  LegacyPrefsImporter(this._db, this._prefs);

  Future<LegacyImportResult> run() async {
    final audit = AuditRepository(_db);
    final settings = SettingsRepository(_db, audit);

    if (await settings.getRaw(SettingsRepository.keyLegacyImportV1) != null) {
      return const LegacyImportResult(alreadyDone: true);
    }

    final printers = _decodeList(
      AppConstants.keySavedPrinters,
      PrinterDevice.fromJson,
    );
    final jobs = _decodeList(AppConstants.keyPrintQueue, PrintJob.fromJson);
    final history = _decodeList(
      AppConstants.keyPrintHistory,
      PrintHistoryItem.fromJson,
    );
    final modeName = _prefs.getString(AppConstants.keyPrintMode);
    final mode = PrintMode.values.where((m) => m.name == modeName).firstOrNull;

    var interrupted = 0;

    await _db.transaction(() async {
      final now = Clock.nowMs();
      final seenPrinterIds = <String>{};
      for (var i = 0; i < printers.length; i++) {
        final p = printers[i];
        if (!seenPrinterIds.add(p.id)) {
          throw LegacyImportException('duplicate printer id ${p.id}');
        }
        await _db
            .into(_db.printerProfiles)
            .insert(
              PrinterRepository.toCompanion(
                p,
                createdAt: now + i,
                updatedAt: now,
                sortOrder: i,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      final seenJobIds = <String>{};
      for (final legacy in jobs) {
        // Legacy ids were millisecond timestamps and could collide.
        final j = seenJobIds.add(legacy.id)
            ? legacy
            : PrintJob(
                id: newId(),
                orderId: legacy.orderId,
                printType: legacy.printType,
                targetRole: legacy.targetRole,
                targetPrinterId: legacy.targetPrinterId,
                posOrderJson: legacy.posOrderJson,
                createdAt: legacy.createdAt,
                status: legacy.status,
                retryCount: legacy.retryCount,
                errorMessage: legacy.errorMessage,
                processedAt: legacy.processedAt,
              );
        seenJobIds.add(j.id);
        if (j.status == PrintJobStatus.printing) {
          j.status = PrintJobStatus.failed;
          j.errorMessage = PrintJobRepository.interruptedMessage;
          interrupted++;
        }
        await _db
            .into(_db.printJobs)
            .insert(PrintJobRepository.jobToCompanion(j));
      }

      final seenHistoryIds = <String>{};
      for (final h in history) {
        final item = seenHistoryIds.add(h.id)
            ? h
            : PrintHistoryItem(
                id: newId(),
                timestamp: h.timestamp,
                printerName: h.printerName,
                connectionType: h.connectionType,
                orderId: h.orderId,
                printType: h.printType,
                isSuccess: h.isSuccess,
                errorMessage: h.errorMessage,
              );
        seenHistoryIds.add(item.id);
        await _db
            .into(_db.printHistory)
            .insert(PrintJobRepository.historyToCompanion(item));
      }

      if (mode != null) {
        await settings.setRaw(
          SettingsRepository.keyPrintMode,
          mode.name,
          audit: false,
        );
      }

      // The old app silently sent jobs for an unassigned role to the first
      // printer. Keep that behaviour for existing users, but as an explicit,
      // visible setting they can change.
      if (printers.isNotEmpty) {
        await settings.setRaw(
          SettingsRepository.keyFallbackPrinterId,
          printers.first.id,
          audit: false,
        );
      }

      final summary = {
        'printers': printers.length,
        'jobs': jobs.length,
        'interruptedJobs': interrupted,
        'historyItems': history.length,
        'printMode': mode?.name,
      };
      await audit.record(
        action: 'legacy_import.completed',
        entity: 'shared_preferences',
        details: summary,
      );
      await settings.setRaw(
        SettingsRepository.keyLegacyImportV1,
        jsonEncode({'at': now, ...summary}),
        audit: false,
      );
    });

    return LegacyImportResult(
      printers: printers.length,
      jobs: jobs.length,
      interruptedJobs: interrupted,
      historyItems: history.length,
    );
  }

  List<T> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('expected a JSON list');
      }
      return decoded
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw LegacyImportException('"$key" is unreadable ($e)');
    }
  }
}
