import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/util/clock.dart';
import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single local database. It is the source of truth for all POS data.
///
/// Schema history (bump [schemaVersion] and add a step in [migration] for
/// every change; never edit a released step):
/// - v1: migration_log, app_settings, business_profiles, printer_profiles,
///   print_jobs, print_history, audit_log.
/// - v2: tax_profiles, kitchen_stations, menu_categories, menu_items,
///   option_groups, option_choices, item_option_groups.
@DriftDatabase(
  tables: [
    MigrationLog,
    AppSettings,
    BusinessProfiles,
    PrinterProfiles,
    PrintJobs,
    PrintHistory,
    AuditLog,
    TaxProfiles,
    KitchenStations,
    MenuCategories,
    MenuItems,
    OptionGroups,
    OptionChoices,
    ItemOptionGroups,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const String fileName = 'pos.db';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedV1();
      await _logMigration(1, 'initial schema');
      await _logMigration(2, 'menu tables (fresh install)');
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.taxProfiles);
        await m.createTable(schema.kitchenStations);
        await m.createTable(schema.menuCategories);
        await m.createTable(schema.menuItems);
        await m.createTable(schema.optionGroups);
        await m.createTable(schema.optionChoices);
        await m.createTable(schema.itemOptionGroups);
        await m.createIndex(schema.idxMenuCategoriesParent);
        await m.createIndex(schema.idxMenuItemsCategory);
        await m.createIndex(schema.idxMenuItemsSku);
        await m.createIndex(schema.idxOptionChoicesGroup);
        await _logMigration(2, 'menu tables');
      },
    ),
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
