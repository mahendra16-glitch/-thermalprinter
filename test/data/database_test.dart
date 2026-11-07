import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test(
    'fresh install creates the latest schema and logs every version',
    () async {
      final log = await db.select(db.migrationLog).get();
      expect(log.map((r) => r.version), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(db.schemaVersion, 9);
      expect(await db.select(db.stockItems).get(), isEmpty);
      expect(await db.select(db.staffUsers).get(), isEmpty);
      final perms = await db.select(db.rolePermissions).get();
      expect(perms.where((p) => p.role == 'owner'), isEmpty);
      expect(
        perms.where((p) => p.role == 'waiter').map((p) => p.permission),
        unorderedEquals(['viewMenu', 'takeOrders']),
      );
    },
  );

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
