import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/services/backup_service.dart';
import 'package:thermalprinter/services/storage_service.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late StorageService storage;
  late BackupService backups;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_backup_test');
    db = AppDatabase(NativeDatabase(File(p.join(tmp.path, 'live.db'))));
    storage = StorageService.forTesting(db);
    backups = BackupService(
      db,
      storage.audit,
      directoryProvider: () async => Directory(p.join(tmp.path, 'backups')),
    );
  });

  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
    await tmp.delete(recursive: true);
  });

  test('backup is a verified, complete copy of the database', () async {
    await storage.savePrinter(
      PrinterDevice(
        id: 'p1',
        name: 'Counter',
        connectionType: ConnectionType.network,
      ),
    );

    final info = await backups.createBackup();

    expect(info.integrityOk, isTrue, reason: info.problem);
    expect(info.schemaVersion, db.schemaVersion);
    expect(info.fileName, startsWith(BackupService.filePrefix));

    final copy = AppDatabase(NativeDatabase(info.file));
    try {
      final printers = await copy.select(copy.printerProfiles).get();
      expect(printers.single.name, 'Counter');
    } finally {
      await copy.close();
    }

    expect(await backups.listBackups(), hasLength(1));
    final audit = await storage.audit.recent();
    expect(audit.first.action, 'backup.created');
  });

  test('two backups in the same second get distinct files', () async {
    final a = await backups.createBackup();
    final b = await backups.createBackup();
    expect(a.file.path, isNot(b.file.path));
    expect(await backups.listBackups(), hasLength(2));
  });

  test('verify flags a file that is not a database', () async {
    final junk = File(p.join(tmp.path, 'junk.db'))
      ..writeAsStringSync('not sqlite');
    final info = await backups.verify(junk);
    expect(info.integrityOk, isFalse);
    expect(info.problem, isNotNull);
  });
}
