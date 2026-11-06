import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/menu_repository.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/services/menu_csv_service.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late MenuRepository menu;

  setUp(() async {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    menu = storage.menu;
    await menu.saveTaxProfile(
      const TaxProfile(id: 'gst5', name: 'GST 5%', rateBp: 500),
    );
    await menu.saveStation(const KitchenStation(id: 'bar', name: 'Bar'));
    await menu.saveCategory(
      const MenuCategory(id: 'starters', name: 'Starters'),
    );
    await menu.saveItem(
      const MenuItem(
        id: 'tikka',
        categoryId: 'starters',
        name: 'Paneer Tikka',
        sku: 'PT',
        basePrice: Money(18000),
        taxProfileId: 'gst5',
      ),
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<CsvImportPlan> planFor(String csv) async =>
      MenuCsvService.plan(csv, await menu.loadSnapshot());

  Future<CsvImportResult> apply(CsvImportPlan plan) =>
      MenuCsvService.apply(db, menu, storage.audit, plan);

  test('creates items and missing categories, updates matches', () async {
    final plan = await planFor(
      'category,subcategory,name,price,sku,tax,food_type,station\n'
      'Starters,,Paneer Tikka,200,,,,\n'
      'Drinks,Cold,Lassi,"1,20.50",LS,GST 5%,veg,Bar\n'
      'Main Course,,Chicken Curry,320,CC,,non-veg,\n',
    );

    expect(
      plan.hasErrors,
      isFalse,
      reason: plan.rows.map((r) => r.messages).join(),
    );
    expect(plan.count(CsvRowAction.update), 1);
    expect(plan.count(CsvRowAction.create), 2);
    expect(plan.newCategories.map((c) => c.path), [
      'Drinks',
      'Drinks › Cold',
      'Main Course',
    ]);
    final update = plan.rows.firstWhere((r) => r.action == CsvRowAction.update);
    expect(update.messages, ['price: ₹180.00 → ₹200.00']);

    final result = await apply(plan);
    expect(result.created, 2);
    expect(result.updated, 1);

    final snap = await menu.loadSnapshot();
    final lassi = snap.items.firstWhere((i) => i.name == 'Lassi');
    expect(lassi.basePrice, const Money(12050));
    expect(snap.categoryPath(lassi.categoryId), 'Drinks › Cold');
    expect(lassi.taxProfileId, 'gst5');
    expect(lassi.stationId, 'bar');
    final tikka = snap.items.firstWhere((i) => i.id == 'tikka');
    expect(tikka.basePrice, const Money(20000));
    expect(tikka.taxProfileId, 'gst5', reason: 'blank tax cell keeps the tax');
    expect(tikka.sku, 'PT', reason: 'blank sku cell keeps the sku');
    final curry = snap.items.firstWhere((i) => i.name == 'Chicken Curry');
    expect(curry.foodType, FoodType.nonVeg);
    expect(curry.taxProfileId, isNull);
  });

  test('matches by sku even when the name changed', () async {
    final plan = await planFor(
      'category,name,sku\nStarters,Paneer Tikka Dry,pt\n',
    );
    expect(plan.rows.single.action, CsvRowAction.update);
    expect(
      plan.rows.single.messages,
      contains('name: Paneer Tikka → Paneer Tikka Dry'),
    );
  });

  test('export then import is a no-op', () async {
    final csv = MenuCsvService.export(await menu.loadSnapshot());
    expect(csv.startsWith('﻿'), isTrue);
    final plan = await planFor(csv);
    expect(plan.hasErrors, isFalse);
    expect(plan.rows.single.action, CsvRowAction.unchanged);
    expect(plan.canApply, isFalse);
  });

  test('errors are reported per line and block the import', () async {
    final plan = await planFor(
      'category,name,price,sku,tax,food_type,active,station\n'
      ',No Category,10,,,,,\n'
      'Drinks,Soda,abc,,,,,\n'
      'Drinks,Tea,10,T1,GST 12%,,,\n'
      'Drinks,Coffee,10,T1,,,,\n'
      'Drinks,Juice,10,,,fruit,,\n'
      'Drinks,Shake,10,,,,maybe,\n'
      'Drinks,Mocktail,10,,,,,Kitchen\n'
      'Drinks,New Thing,,,,,,\n',
    );
    final byLine = {for (final r in plan.rows) r.line: r};
    expect(byLine[2]!.messages.join(), contains('Category is empty'));
    expect(byLine[3]!.messages.join(), contains('not a valid amount'));
    expect(
      byLine[4]!.messages.join(),
      contains('Tax "GST 12%" does not exist'),
    );
    expect(byLine[5]!.messages.join(), contains('SKU "T1" is also on line 4'));
    expect(byLine[6]!.messages.join(), contains('Food type'));
    expect(byLine[7]!.messages.join(), contains('yes or no'));
    expect(byLine[8]!.messages.join(), contains('Station "Kitchen"'));
    expect(byLine[9]!.messages.join(), contains('Price is required'));
    expect(plan.canApply, isFalse);
    await expectLater(apply(plan), throwsA(isA<MenuValidationException>()));
  });

  test('duplicate name in the same category within the file', () async {
    final plan = await planFor(
      'category,name,price\nDrinks,Tea,10\nDrinks,tea,12\n',
    );
    expect(plan.rows.last.messages.join(), contains('as line 2'));
  });

  test('missing required columns', () async {
    final plan = await planFor('title,price\nTea,10\n');
    expect(
      plan.fileErrors.single,
      contains('Missing column(s): category, name'),
    );
  });

  test('semicolon-separated Excel files are detected', () async {
    final plan = await planFor('category;name;price\nDrinks;Tea;10\n');
    expect(plan.hasErrors, isFalse);
    expect(plan.count(CsvRowAction.create), 1);
  });

  test('a failure while saving rolls back the whole import', () async {
    final plan = await planFor(
      'category,name,price,sku\nNew Cat,First,10,A1\nNew Cat,Second,10,B2\n',
    );
    expect(plan.canApply, isTrue);

    // Someone else takes SKU B2 after the preview was made.
    await menu.saveItem(
      const MenuItem(
        id: 'other',
        categoryId: 'starters',
        name: 'Other',
        sku: 'B2',
        basePrice: Money(100),
      ),
    );

    await expectLater(
      apply(plan),
      throwsA(
        isA<MenuValidationException>().having(
          (e) => e.message,
          'message',
          contains('Line 3'),
        ),
      ),
    );
    final snap = await menu.loadSnapshot();
    expect(snap.items.where((i) => i.name == 'First'), isEmpty);
    expect(snap.categories.where((c) => c.name == 'New Cat'), isEmpty);
  });

  test('unknown id is an error rather than a silent create', () async {
    final plan = await planFor('id,category,name,price\nnope,Drinks,Tea,10\n');
    expect(plan.rows.single.action, CsvRowAction.error);
  });
}
