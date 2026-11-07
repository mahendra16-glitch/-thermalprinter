import 'dart:typed_data';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/models/printer_device.dart';
import 'package:thermalprinter/services/backup_service.dart';
import 'package:thermalprinter/services/storage_service.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../drift/pos/generated/schema.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late StorageService storage;
  late BackupService backups;
  late String livePath;
  late Directory backupDir;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    tmp = await Directory.systemTemp.createTemp('pos_backup_test');
    livePath = p.join(tmp.path, 'live.db');
    backupDir = Directory(p.join(tmp.path, 'backups'));
    db = AppDatabase(NativeDatabase(File(livePath)));
    storage = StorageService.forTesting(db);
    backups = BackupService(
      db,
      storage.audit,
      directoryProvider: () async => backupDir,
      databasePathProvider: () async => livePath,
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

  PrinterDevice printer(String id, String name) =>
      PrinterDevice(id: id, name: name, connectionType: ConnectionType.network);

  Future<List<String>> printerNames(AppDatabase d) async =>
      (await d.select(d.printerProfiles).get()).map((r) => r.name).toList()
        ..sort();

  test('password-protected backup: sealed, listed, opens only with the '
      'password', () async {
    await storage.savePrinter(printer('p1', 'Counter'));
    expect(() => backups.createBackup(password: 'short'), throwsArgumentError);
    final info = await backups.createBackup(password: 'correct horse');
    expect(info.encrypted, isTrue);
    expect(info.fileName, endsWith('.posbak'));
    expect(info.schemaVersion, db.schemaVersion);
    final bytes = await info.file.readAsBytes();
    expect(String.fromCharCodes(bytes.take(7)), 'POSBAK1');
    expect(
      String.fromCharCodes(bytes),
      isNot(contains('Counter')),
      reason: 'contents are encrypted',
    );
    // No plain copy is left behind.
    expect((await backups.listBackups()).map((f) => f.path), [info.file.path]);

    await expectLater(
      backups.prepareRestore(info.file),
      throwsA(isA<RestoreException>()),
    );
    await expectLater(
      backups.prepareRestore(info.file, password: 'wrong password'),
      throwsA(
        isA<RestoreException>().having(
          (e) => e.message,
          'message',
          contains('Wrong password'),
        ),
      ),
    );
    final check = await backups.prepareRestore(
      info.file,
      password: 'correct horse',
    );
    expect(check.counts['printer_profiles'], 1);
    expect(check.schemaVersion, db.schemaVersion);

    // A changed byte is detected.
    final tampered = File(p.join(tmp.path, 'tampered.posbak'));
    final copy = Uint8List.fromList(bytes);
    copy[copy.length - 40] ^= 1;
    await tampered.writeAsBytes(copy);
    await expectLater(
      backups.prepareRestore(tampered, password: 'correct horse'),
      throwsA(isA<RestoreException>()),
    );
  });

  test('restore refuses junk and backups from a newer app', () async {
    final junk = File(p.join(tmp.path, 'junk.db'))
      ..writeAsStringSync('not sqlite');
    await expectLater(
      backups.prepareRestore(junk),
      throwsA(isA<RestoreException>()),
    );
    final info = await backups.createBackup();
    final newer = File(p.join(tmp.path, 'newer.db'));
    await info.file.copy(newer.path);
    final raw = sqlite.sqlite3.open(newer.path);
    raw.userVersion = 99;
    raw.close();
    await expectLater(
      backups.prepareRestore(newer),
      throwsA(
        isA<RestoreException>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        ),
      ),
    );
  });

  test('scheduled restore swaps the data at the next start, after a '
      'pre-restore backup', () async {
    await storage.savePrinter(printer('p1', 'Counter'));
    final info = await backups.createBackup();
    await storage.savePrinter(printer('p2', 'Kitchen'));

    final check = await backups.prepareRestore(info.file);
    expect(await printerNames(db), ['Counter', 'Kitchen'], reason: 'unchanged');
    await backups.scheduleRestore(check);
    expect(await backups.pendingRestore(), info.fileName);
    // Entered after scheduling: must end up in the pre-restore backup.
    await storage.savePrinter(printer('p3', 'Bar'));
    StorageService.resetForTesting();
    await db.close();

    final outcome = await BackupService.applyPendingRestore(
      dbPath: livePath,
      backupDir: backupDir,
      maxVersion: AppDatabase.currentSchemaVersion,
    );
    expect(outcome!.ok, isTrue, reason: outcome.message);
    expect(outcome.message, contains('pre-restore'));
    expect(
      await BackupService.applyPendingRestore(
        dbPath: livePath,
        backupDir: backupDir,
        maxVersion: AppDatabase.currentSchemaVersion,
      ),
      isNull,
      reason: 'nothing pending any more',
    );

    db = AppDatabase(NativeDatabase(File(livePath)));
    storage = StorageService.forTesting(db);
    expect(await printerNames(db), ['Counter']);

    final pre = (await backupDir.list().toList()).whereType<File>().firstWhere(
      (f) => f.path.contains('pre-restore'),
    );
    final preDb = AppDatabase(NativeDatabase(pre));
    try {
      expect(await printerNames(preDb), ['Bar', 'Counter', 'Kitchen']);
    } finally {
      await preDb.close();
    }
  });

  test('a damaged pending restore leaves the data unchanged', () async {
    await storage.savePrinter(printer('p1', 'Counter'));
    StorageService.resetForTesting();
    await db.close();
    File('$livePath${BackupService.pendingSuffix}').writeAsStringSync('junk');

    final outcome = await BackupService.applyPendingRestore(
      dbPath: livePath,
      backupDir: backupDir,
      maxVersion: AppDatabase.currentSchemaVersion,
    );
    expect(outcome!.ok, isFalse);
    expect(outcome.message, contains('unchanged'));
    expect(
      File('$livePath${BackupService.pendingSuffix}').existsSync(),
      isFalse,
    );
    db = AppDatabase(NativeDatabase(File(livePath)));
    storage = StorageService.forTesting(db);
    expect(await printerNames(db), ['Counter']);
  });

  test('a backup from an older version is upgraded after restore', () async {
    // A v1 database (the first released schema) with one printer.
    final verifier = SchemaVerifier(GeneratedHelper());
    final old = await verifier.schemaAt(1);
    old.rawDatabase.execute(
      "INSERT INTO printer_profiles (id, name, connection_type, paper_width, "
      "role, ip_address, port, sort_order, created_at, updated_at) VALUES "
      "('OLD', 'Old counter', 'network', 'mm58', 'bill', '10.0.0.9', 9100, 0, "
      "1000, 1000)",
    );
    final oldFile = p.join(tmp.path, 'v1.db');
    old.rawDatabase.execute('VACUUM INTO ?', [oldFile]);

    final check = await backups.prepareRestore(File(oldFile));
    expect(check.schemaVersion, 1);
    await backups.scheduleRestore(check);
    StorageService.resetForTesting();
    await db.close();
    final outcome = await BackupService.applyPendingRestore(
      dbPath: livePath,
      backupDir: backupDir,
      maxVersion: AppDatabase.currentSchemaVersion,
    );
    expect(outcome!.ok, isTrue, reason: outcome.message);

    db = AppDatabase(NativeDatabase(File(livePath)));
    storage = StorageService.forTesting(db);
    expect(await printerNames(db), ['Old counter']);
    final log = await db.select(db.migrationLog).get();
    expect(log.map((r) => r.version).last, AppDatabase.currentSchemaVersion);
    expect(await db.select(db.staffUsers).get(), isEmpty);
  });
}
