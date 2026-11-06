import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/table_repository.dart';
import 'package:thermalprinter/domain/orders/table_models.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late TableRepository tables;

  setUp(() async {
    db = openTestDatabase();
    tables = StorageService.forTesting(db).tables;
    await tables.saveArea(const DiningArea(id: 'in', name: 'Indoor'));
    await tables.saveArea(const DiningArea(id: 'out', name: 'Terrace'));
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  test('bulk add skips names that already exist', () async {
    await tables.saveTable(
      const RestaurantTable(id: 'x', areaId: 'in', label: 'T2'),
    );
    final created = await tables.addTables(
      areaId: 'in',
      prefix: 'T',
      from: 1,
      to: 5,
      seats: 4,
    );
    expect(created, 4);
    final labels = (await tables.listTables())
        .where((t) => t.areaId == 'in')
        .map((t) => t.label);
    expect(labels, ['T2', 'T1', 'T3', 'T4', 'T5']);
  });

  test('same label allowed in a different area, not in the same', () async {
    await tables.saveTable(
      const RestaurantTable(id: 'a', areaId: 'in', label: 'T1'),
    );
    await tables.saveTable(
      const RestaurantTable(id: 'b', areaId: 'out', label: 'T1'),
    );
    await expectLater(
      tables.saveTable(
        const RestaurantTable(id: 'c', areaId: 'in', label: 't1'),
      ),
      rejects('already exists in Indoor'),
    );
  });

  test('validation', () async {
    await expectLater(
      tables.saveArea(const DiningArea(id: 'z', name: 'indoor')),
      rejects('already exists'),
    );
    await expectLater(
      tables.saveTable(
        const RestaurantTable(id: 'a', areaId: 'in', label: 'T1', seats: 0),
      ),
      rejects('Seats'),
    );
    await expectLater(
      tables.addTables(areaId: 'in', prefix: 'T', from: 1, to: 500),
      rejects('up to 200'),
    );
  });
}
