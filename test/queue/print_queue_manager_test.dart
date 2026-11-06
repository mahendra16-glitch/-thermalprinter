import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/print_job_repository.dart';
import 'package:thermalprinter/models/pos_order.dart';
import 'package:thermalprinter/models/print_job.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/queue/print_queue_manager.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

PosOrder order(String id, String type, {PrinterRole role = PrinterRole.bill}) =>
    PosOrder(
      orderId: id,
      type: type,
      printerRole: role,
      items: [PosOrderItem(name: 'Tea', qty: 1, price: 20)],
    );

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late AppDatabase db;
  late StorageService storage;
  late List<String> printed;
  late List<PrintJobStatus?> statusSeenByPrinter;
  Object? failWith;

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    printed = [];
    statusSeenByPrinter = [];
    failWith = null;
    await storage.savePrinter(
      PrinterDevice(
        id: 'bill',
        name: 'Bill',
        connectionType: ConnectionType.network,
        role: PrinterRole.bill,
      ),
    );
    await storage.savePrinter(
      PrinterDevice(
        id: 'kot',
        name: 'Kitchen',
        connectionType: ConnectionType.network,
        role: PrinterRole.kot,
      ),
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<PrintQueueManager> manager() {
    return PrintQueueManager.createForTesting(storage, (o, device, mode) async {
      // What the database says while the bytes are "being sent".
      final stored = await storage.printJobs.getAllJobs();
      statusSeenByPrinter.add(
        stored
            .where((j) => j.orderId == o.orderId && j.printType == o.type)
            .firstOrNull
            ?.status,
      );
      if (failWith != null) throw failWith!;
      printed.add('${o.type}:${o.orderId}@${device.id}');
    });
  }

  Future<void> settle(PrintQueueManager m) async {
    // Jobs are processed asynchronously; wait until none are pending.
    for (var i = 0; i < 100; i++) {
      await m.processNext();
      final busy = m.currentQueue.any(
        (j) =>
            j.status == PrintJobStatus.pending ||
            j.status == PrintJobStatus.printing,
      );
      if (!busy) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    fail('queue did not settle');
  }

  test('a BILL and a KOT for the same order are both queued (D4)', () async {
    final m = await manager();
    final kotId = await m.addOrderToQueue(
      order('1024', 'KOT', role: PrinterRole.kot),
    );
    final billId = await m.addOrderToQueue(order('1024', 'BILL'));
    expect(kotId, isNot(billId));
    await settle(m);
    expect(printed, containsAll(['KOT:1024@kot', 'BILL:1024@bill']));
  });

  test('the same document is not queued twice while active', () async {
    final gate = Completer<void>();
    final m = await PrintQueueManager.createForTesting(storage, (
      o,
      d,
      _,
    ) async {
      await gate.future;
      printed.add(o.orderId);
    });
    final first = await m.addOrderToQueue(order('7', 'BILL'));
    final second = await m.addOrderToQueue(order('7', 'BILL'));
    expect(second, first);
    expect(m.currentQueue, hasLength(1));
    gate.complete();
    await settle(m);
    expect(printed, ['7']);
  });

  test('job ids are UUIDs (D5)', () async {
    final m = await manager();
    final id = await m.addOrderToQueue(order('1', 'BILL'));
    expect(id, matches(_uuid));
    await settle(m);
  });

  test('job is stored, and marked printing, before bytes are sent', () async {
    final m = await manager();
    await m.addOrderToQueue(order('5', 'BILL'));
    await settle(m);
    expect(statusSeenByPrinter, [PrintJobStatus.printing]);
    final stored = await storage.printJobs.getAllJobs();
    expect(stored.single.status, PrintJobStatus.printed);
    expect(stored.single.processedAt, isNotNull);
  });

  test('failure is persisted with the error and logged', () async {
    failWith = Exception('Connection to 10.0.0.9:9100 timed out.');
    final m = await manager();
    await m.addOrderToQueue(order('9', 'BILL'));
    await settle(m);

    final job = (await storage.printJobs.getAllJobs()).single;
    expect(job.status, PrintJobStatus.failed);
    expect(job.errorMessage, 'Connection to 10.0.0.9:9100 timed out.');
    expect(job.retryCount, 1);
    final history = await storage.getHistory();
    expect(history.single.isSuccess, isFalse);
    expect(history.single.printerName, 'Bill');
  });

  test('manual retry re-sends a failed job', () async {
    failWith = Exception('offline');
    final m = await manager();
    final id = await m.addOrderToQueue(order('3', 'BILL'));
    await settle(m);
    failWith = null;
    await m.retryJob(id);
    await settle(m);
    expect(printed, ['BILL:3@bill']);
    expect(
      (await storage.printJobs.getAllJobs()).single.status,
      PrintJobStatus.printed,
    );
  });

  test('job interrupted mid-print is failed on restart, not resent', () async {
    final stuck = PrintJob(
      id: 'stuck',
      orderId: '42',
      printType: 'BILL',
      posOrderJson: order('42', 'BILL').toJson(),
      status: PrintJobStatus.printing,
    );
    await storage.printJobs.upsertJob(stuck);

    final m = await manager();
    await settle(m);

    expect(printed, isEmpty);
    final job = m.currentQueue.single;
    expect(job.status, PrintJobStatus.failed);
    expect(job.errorMessage, PrintJobRepository.interruptedMessage);
  });

  test('pending jobs survive a restart and are printed', () async {
    await storage.printJobs.upsertJob(
      PrintJob(
        id: 'p1',
        orderId: '77',
        printType: 'BILL',
        posOrderJson: order('77', 'BILL').toJson(),
      ),
    );
    final m = await manager();
    await settle(m);
    expect(printed, ['BILL:77@bill']);
  });

  test(
    'no printer for the role and no fallback: clear failure (D13)',
    () async {
      final m = await manager();
      await m.addOrderToQueue(order('8', 'BAR', role: PrinterRole.bar));
      await settle(m);
      expect(printed, isEmpty);
      final job = m.currentQueue.single;
      expect(job.status, PrintJobStatus.failed);
      expect(job.errorMessage, contains('No printer is assigned'));
    },
  );

  test('no printer for the role: uses the configured fallback', () async {
    await storage.settings.setFallbackPrinterId('bill');
    final m = await manager();
    await m.addOrderToQueue(order('8', 'BAR', role: PrinterRole.bar));
    await settle(m);
    expect(printed, ['BAR:8@bill']);
  });

  test('clearCompleted removes printed and failed jobs from storage', () async {
    final m = await manager();
    await m.addOrderToQueue(order('1', 'BILL'));
    await m.addOrderToQueue(order('2', 'BAR', role: PrinterRole.bar));
    await settle(m);
    await m.clearCompleted();
    expect(m.currentQueue, isEmpty);
    expect(await storage.printJobs.getAllJobs(), isEmpty);
  });
}
