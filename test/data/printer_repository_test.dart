import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

PrinterDevice printer(String id, PrinterRole role, {String? name}) =>
    PrinterDevice(
      id: id,
      name: name ?? id,
      connectionType: ConnectionType.network,
      role: role,
      ipAddress: '10.0.0.1',
    );

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

  test('save then update keeps id, position and creation time', () async {
    await storage.savePrinter(printer('a', PrinterRole.bill));
    await storage.savePrinter(printer('b', PrinterRole.kitchen));
    final before = await db.select(db.printerProfiles).get();

    await storage.savePrinter(printer('a', PrinterRole.bill, name: 'Renamed'));

    final list = await storage.getSavedPrinters();
    expect(list.map((p) => p.id), ['a', 'b']);
    expect(list.first.name, 'Renamed');
    final after = await db.select(db.printerProfiles).get();
    expect(
      after.firstWhere((r) => r.id == 'a').createdAt,
      before.firstWhere((r) => r.id == 'a').createdAt,
    );
  });

  test('role lookup: direct match, then fallback, else null', () async {
    await storage.savePrinter(printer('bill1', PrinterRole.bill));
    await storage.savePrinter(printer('kit1', PrinterRole.kitchen));

    expect((await storage.getPrinterForRole(PrinterRole.kitchen))?.id, 'kit1');
    // No silent "first printer" fallback any more.
    expect(await storage.getPrinterForRole(PrinterRole.bar), isNull);

    await storage.settings.setFallbackPrinterId('bill1');
    expect((await storage.getPrinterForRole(PrinterRole.bar))?.id, 'bill1');
  });

  test('deleting the fallback printer clears the fallback', () async {
    await storage.savePrinter(printer('bill1', PrinterRole.bill));
    await storage.settings.setFallbackPrinterId('bill1');

    await storage.deletePrinter('bill1');

    expect(await storage.getSavedPrinters(), isEmpty);
    expect(await storage.settings.getFallbackPrinterId(), isNull);
  });

  test('configuration changes are audited', () async {
    await storage.savePrinter(printer('a', PrinterRole.bill));
    await storage.savePrinter(printer('a', PrinterRole.kitchen));
    await storage.deletePrinter('a');

    final actions = (await storage.audit.recent())
        .map((r) => r.action)
        .toList()
        .reversed
        .toList();
    expect(actions, ['printer.created', 'printer.updated', 'printer.deleted']);
  });
}
