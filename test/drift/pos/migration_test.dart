// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 -> v8 keeps existing printers, jobs and settings', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO migration_log (version, applied_at, notes) "
      "VALUES (1, 1000, 'initial schema')",
    );
    raw.execute(
      "INSERT INTO printer_profiles (id, name, connection_type, paper_width, "
      "role, ip_address, port, sort_order, created_at, updated_at) VALUES "
      "('PRINTER-1', 'Counter', 'network', 'mm80', 'bill', '10.0.0.5', 9100, "
      "0, 1000, 1000)",
    );
    raw.execute(
      "INSERT INTO print_jobs (id, order_id, print_type, target_role, "
      "source_key, status, retry_count, created_at, updated_at) VALUES "
      "('job-1', '1024', 'KOT', 'kot', 'KOT:1024', 'pending', 0, 1000, 1000)",
    );
    raw.execute(
      "INSERT INTO app_settings (key, value, updated_at) VALUES "
      "('fallback_printer_id', 'PRINTER-1', 1000)",
    );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);

    final printers = await db.select(db.printerProfiles).get();
    expect(printers.single.id, 'PRINTER-1');
    expect(printers.single.ipAddress, '10.0.0.5');
    expect(printers.single.printableDots, isNull);
    expect(printers.single.autoCut, isTrue);
    final jobs = await db.select(db.printJobs).get();
    expect(jobs.single.sourceKey, 'KOT:1024');
    final setting = await db.select(db.appSettings).getSingle();
    expect(setting.value, 'PRINTER-1');
    final log = await db.select(db.migrationLog).get();
    expect(log.map((r) => r.version), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(await db.select(db.menuItems).get(), isEmpty);
    expect(await db.select(db.orders).get(), isEmpty);
    expect(await db.select(db.bills).get(), isEmpty);
    expect(await db.select(db.payments).get(), isEmpty);
    expect(await db.select(db.cashShifts).get(), isEmpty);
    expect(await db.select(db.staffUsers).get(), isEmpty);
    expect(await db.select(db.rolePermissions).get(), isNotEmpty);
    await db.close();
  });

  test('v7 -> v8 keeps payments, shifts and expenses; no staff ids', () async {
    final schema = await verifier.schemaAt(7);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO cash_shifts (id, status, business_date, opening_cash_paise, "
      "opened_by, opened_at, client_request_id) VALUES "
      "('shift-1', 'open', '2026-11-01', 50000, 'Asha', 1000, 'req-s')",
    );
    raw.execute(
      "INSERT INTO expenses (id, shift_id, category, amount_paise, paid_from, "
      "staff_name, business_date, created_at, client_request_id) VALUES "
      "('exp-1', 'shift-1', 'Milk', 4000, 'cash', 'Asha', '2026-11-01', 2000, "
      "'req-e')",
    );
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 8);
    final shift = await db.select(db.cashShifts).getSingle();
    expect(shift.openedBy, 'Asha');
    expect(shift.openedById, isNull);
    final exp = await db.select(db.expenses).getSingle();
    expect(exp.amountPaise, 4000);
    expect(exp.staffName, 'Asha');
    expect(exp.staffId, isNull);
    final perms = await db.select(db.rolePermissions).get();
    expect(
      perms.where((p) => p.role == 'cashier').map((p) => p.permission),
      containsAll(['recordPayment', 'finalizeBill', 'manageShift']),
    );
    expect(
      perms.where(
        (p) => p.role == 'cashier' && p.permission == 'reversePayment',
      ),
      isEmpty,
    );
    final log = await db.select(db.migrationLog).get();
    expect(log.map((r) => r.version), contains(8));
    await db.close();
  });
}
