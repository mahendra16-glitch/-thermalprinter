import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/util/clock.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single local database. It is the source of truth for all POS data.
///
/// Schema history (bump [schemaVersion] and add a step in [migration] for
/// every change; never edit a released step):
/// - v1: migration_log, app_settings, business_profiles, printer_profiles,
///   print_jobs, print_history, audit_log.
@DriftDatabase(
  tables: [
    MigrationLog,
    AppSettings,
    BusinessProfiles,
    PrinterProfiles,
    PrintJobs,
    PrintHistory,
    AuditLog,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const String fileName = 'pos.db';

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedV1();
      await _logMigration(1, 'initial schema');
    },
    onUpgrade: (m, from, to) async {
      // Future steps go here, e.g.:
      // if (from < 2) { await m.createTable(menuItems); await _logMigration(2, '...'); }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedV1() async {
    await into(businessProfiles).insert(
      BusinessProfilesCompanion.insert(
        id: const Value(1),
        updatedAt: Clock.nowMs(),
      ),
    );
  }

  Future<void> _logMigration(int version, String notes) async {
    await into(migrationLog).insertOnConflictUpdate(
      MigrationLogCompanion.insert(
        version: Value(version),
        appliedAt: Clock.nowMs(),
        notes: Value(notes),
      ),
    );
  }
}

/// Absolute path of the on-device database file.
Future<String> posDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, AppDatabase.fileName);
}

/// Opens the on-device database on a background isolate.
Future<AppDatabase> openPosDatabase() async {
  final file = File(await posDatabasePath());
  return AppDatabase(NativeDatabase.createInBackground(file));
}
