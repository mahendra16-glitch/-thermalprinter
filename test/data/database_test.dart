import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('v1 schema is created and logged', () async {
    final log = await db.select(db.migrationLog).get();
    expect(log.map((r) => r.version), [1]);
    expect(db.schemaVersion, 1);
  });

  test('business profile row is seeded empty (no demo data)', () async {
    final rows = await db.select(db.businessProfiles).get();
    expect(rows, hasLength(1));
    expect(rows.single.name, '');
    expect(rows.single.gstin, '');
  });

  test('foreign keys are enforced', () async {
    final r = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(r.data.values.first, 1);
  });
}
