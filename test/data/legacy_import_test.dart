import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermalprinter/core/constants/app_constants.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/legacy/legacy_prefs_importer.dart';
import 'package:thermalprinter/data/repositories/print_job_repository.dart';
import 'package:thermalprinter/models/print_job.dart';
import 'package:thermalprinter/models/print_mode.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

/// Values exactly as the pre-database app wrote them.
Map<String, Object> legacyPrefs() {
  final printers = [
    {
      'id': 'PRINTER-1700000000000',
      'name': 'Counter BT',
      'connectionType': 'bluetooth',
      'paperWidth': 'mm58',
      'role': 'bill',
      'macAddress': '00:11:22:33:44:55',
      'vendorId': null,
      'productId': null,
      'deviceName': null,
      'ipAddress': '192.168.1.12',
      'port': 9100,
      'isConnected': true,
      'lastConnected': '2026-10-01T10:00:00.000',
      'lastError': null,
    },
    {
      'id': 'PRINTER-1700000000999',
      'name': 'Kitchen LAN',
      'connectionType': 'network',
      'paperWidth': 'mm80',
      'role': 'kitchen',
      'ipAddress': '192.168.1.50',
      'port': 9100,
    },
  ];
  final order = {'orderId': '1024', 'type': 'KOT', 'items': []};
  final queue = [
    {
      'id': 'JOB-1',
      'orderId': '1024',
      'printType': 'KOT',
      'targetRole': 'kitchen',
      'posOrderJson': order,
      'createdAt': '2026-10-01T10:00:00.000',
      'status': 'printing',
      'retryCount': 0,
    },
    {
      'id': 'JOB-1', // legacy ids were timestamps and could collide
      'orderId': '1025',
      'printType': 'BILL',
      'targetRole': 'bill',
      'posOrderJson': {'orderId': '1025', 'items': []},
      'createdAt': '2026-10-01T10:00:01.000',
      'status': 'pending',
      'retryCount': 0,
    },
  ];
  final history = [
    {
      'id': 'HIST-1',
      'timestamp': '2026-10-01T09:00:00.000',
      'printerName': 'Counter BT',
      'connectionType': 'bluetooth',
      'orderId': '1000',
      'printType': 'BILL',
      'isSuccess': true,
    },
    {
      'id': 'HIST-1',
      'timestamp': '2026-10-01T09:00:00.000',
      'printerName': 'Counter BT',
      'connectionType': 'bluetooth',
      'orderId': '1001',
      'printType': 'BILL',
      'isSuccess': false,
      'errorMessage': 'paper out',
    },
  ];
  return {
    AppConstants.keySavedPrinters: jsonEncode(printers),
    AppConstants.keyPrintQueue: jsonEncode(queue),
    AppConstants.keyPrintHistory: jsonEncode(history),
    AppConstants.keyPrintMode: 'fullImageMode',
  };
}

void main() {
  late AppDatabase db;
  late StorageService storage;

  setUp(() {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('imports printers with their ids, order and fields', () async {
    final prefs = await prefsWith(legacyPrefs());
    final result = await LegacyPrefsImporter(db, prefs).run();

    expect(result.printers, 2);
    final printers = await storage.getSavedPrinters();
    expect(printers.map((p) => p.id), [
      'PRINTER-1700000000000',
      'PRINTER-1700000000999',
    ]);
    final bt = printers.first;
    expect(bt.name, 'Counter BT');
    expect(bt.connectionType, ConnectionType.bluetooth);
    expect(bt.paperWidth, PaperWidth.mm58);
    expect(bt.macAddress, '00:11:22:33:44:55');
    expect(bt.isConnected, isFalse, reason: 'runtime state is not imported');
    expect(printers[1].role, PrinterRole.kitchen);
    expect(printers[1].ipAddress, '192.168.1.50');
  });

  test('imports print mode and keeps old role fallback explicitly', () async {
    await LegacyPrefsImporter(db, await prefsWith(legacyPrefs())).run();

    expect(await storage.getPrintMode(), PrintMode.fullImageMode);
    expect(
      await storage.settings.getFallbackPrinterId(),
      'PRINTER-1700000000000',
    );
    // A role with no printer resolves to the fallback, as the old app did.
    final bar = await storage.getPrinterForRole(PrinterRole.bar);
    expect(bar?.id, 'PRINTER-1700000000000');
  });

  test(
    'queue: interrupted job becomes failed, id collisions resolved',
    () async {
      final result = await LegacyPrefsImporter(
        db,
        await prefsWith(legacyPrefs()),
      ).run();

      expect(result.jobs, 2);
      expect(result.interruptedJobs, 1);
      final jobs = await storage.printJobs.getAllJobs();
      expect(jobs, hasLength(2));
      expect(jobs.map((j) => j.id).toSet(), hasLength(2));

      final kot = jobs.firstWhere((j) => j.orderId == '1024');
      expect(kot.status, PrintJobStatus.failed);
      expect(kot.errorMessage, PrintJobRepository.interruptedMessage);
      expect(kot.posOrderJson?['type'], 'KOT');

      final bill = jobs.firstWhere((j) => j.orderId == '1025');
      expect(bill.status, PrintJobStatus.pending);
    },
  );

  test('history: all entries kept even with duplicate ids', () async {
    await LegacyPrefsImporter(db, await prefsWith(legacyPrefs())).run();
    final history = await storage.getHistory();
    expect(history, hasLength(2));
    expect(history.where((h) => h.errorMessage == 'paper out'), hasLength(1));
  });

  test('legacy keys are left untouched', () async {
    final values = legacyPrefs();
    final prefs = await prefsWith(values);
    await LegacyPrefsImporter(db, prefs).run();
    for (final e in values.entries) {
      expect(prefs.get(e.key), e.value, reason: e.key);
    }
  });

  test('runs only once', () async {
    final prefs = await prefsWith(legacyPrefs());
    await LegacyPrefsImporter(db, prefs).run();
    final again = await LegacyPrefsImporter(db, prefs).run();
    expect(again.alreadyDone, isTrue);
    expect(await storage.getSavedPrinters(), hasLength(2));
  });

  test('corrupt legacy data aborts without writing anything', () async {
    final values = legacyPrefs()..[AppConstants.keyPrintHistory] = '{not json';
    final prefs = await prefsWith(values);

    await expectLater(
      LegacyPrefsImporter(db, prefs).run(),
      throwsA(isA<LegacyImportException>()),
    );
    expect(await storage.getSavedPrinters(), isEmpty);
    expect(await storage.printJobs.getAllJobs(), isEmpty);
    // Not marked done, so it is retried on next launch.
    final retry = await LegacyPrefsImporter(
      db,
      await prefsWith(legacyPrefs()),
    ).run();
    expect(retry.alreadyDone, isFalse);
    expect(retry.printers, 2);
  });

  test('fresh install: nothing to import, no fallback set', () async {
    final result = await LegacyPrefsImporter(db, await prefsWith({})).run();
    expect(result.printers, 0);
    expect(await storage.settings.getFallbackPrinterId(), isNull);
    expect(await storage.getPrinterForRole(PrinterRole.bill), isNull);
  });
}
