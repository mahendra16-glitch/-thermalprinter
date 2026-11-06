import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/menu_repository.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
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
    await menu.saveCategory(
      const MenuCategory(id: 'starters', name: 'Starters'),
    );
    await menu.saveCategory(const MenuCategory(id: 'drinks', name: 'Drinks'));
    await menu.saveTaxProfile(
      const TaxProfile(id: 'gst5', name: 'GST 5%', rateBp: 500),
    );
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  MenuItem item(
    String id,
    String name, {
    String category = 'starters',
    int price = 10000,
    String? sku,
  }) => MenuItem(
    id: id,
    categoryId: category,
    name: name,
    basePrice: Money(price),
    sku: sku,
    taxProfileId: 'gst5',
  );

  Matcher rejects(String text) => throwsA(
    isA<MenuValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  group('categories', () {
    test('subcategory under a top-level category', () async {
      await menu.saveCategory(
        const MenuCategory(id: 'veg', name: 'Veg', parentId: 'starters'),
      );
      final snap = await menu.loadSnapshot();
      expect(snap.subcategoriesOf('starters').single.name, 'Veg');
      expect(snap.categoryPath('veg'), 'Starters › Veg');
    });

    test('only one level of nesting', () async {
      await menu.saveCategory(
        const MenuCategory(id: 'veg', name: 'Veg', parentId: 'starters'),
      );
      await expectLater(
        menu.saveCategory(
          const MenuCategory(id: 'x', name: 'X', parentId: 'veg'),
        ),
        rejects('cannot have subcategories'),
      );
      await expectLater(
        menu.saveCategory(
          const MenuCategory(
            id: 'starters',
            name: 'Starters',
            parentId: 'drinks',
          ),
        ),
        rejects('has subcategories'),
      );
    });

    test('duplicate names are rejected case-insensitively', () async {
      await expectLater(
        menu.saveCategory(const MenuCategory(id: 'dup', name: ' starters ')),
        rejects('already exists'),
      );
    });

    test('reorder persists', () async {
      await menu.reorderCategories(['drinks', 'starters']);
      final names = (await menu.listCategories()).map((c) => c.name);
      expect(names, ['Drinks', 'Starters']);
    });
  });

  group('items', () {
    test('create, edit and read back', () async {
      await menu.saveItem(item('i1', 'Paneer Tikka', sku: 'PT1'));
      await menu.saveItem(
        (await menu.getItem('i1'))!.copyWith(
          basePrice: const Money(22050),
          foodType: FoodType.veg,
          availableTakeaway: false,
          prepMinutes: 15,
        ),
      );
      final i = (await menu.getItem('i1'))!;
      expect(i.basePrice, const Money(22050));
      expect(i.sku, 'PT1');
      expect(i.availableTakeaway, isFalse);
      expect(i.prepMinutes, 15);
    });

    test('validation', () async {
      await menu.saveItem(item('i1', 'Paneer Tikka', sku: 'PT1'));
      await expectLater(menu.saveItem(item('i2', '  ')), rejects('name'));
      await expectLater(
        menu.saveItem(item('i2', 'Soup', price: -1)),
        rejects('negative'),
      );
      await expectLater(
        menu.saveItem(item('i2', 'Soup', sku: 'pt1')),
        rejects('SKU "pt1" is already used'),
      );
      await expectLater(
        menu.saveItem(item('i2', 'paneer tikka')),
        rejects('already exists in this category'),
      );
      await expectLater(
        menu.saveItem(item('i2', 'Soup', category: 'missing')),
        rejects('category'),
      );
      // Same name in another category is fine.
      await menu.saveItem(item('i3', 'Paneer Tikka', category: 'drinks'));
    });

    test(
      'deactivate instead of delete; reactivation checks duplicates',
      () async {
        await menu.saveItem(item('old', 'Lassi', category: 'drinks'));
        await menu.setItemActive('old', false);
        // A replacement with the same name is allowed while the old is off.
        await menu.saveItem(item('new', 'Lassi', category: 'drinks'));
        await expectLater(
          menu.setItemActive('old', true),
          rejects('already exists'),
        );
        final all = await menu.listItems();
        expect(all, hasLength(2), reason: 'nothing is hard-deleted');
      },
    );

    test('inactive category makes its items not orderable', () async {
      await menu.saveItem(item('i1', 'Soup'));
      await menu.setCategoryActive('starters', false);
      final snap = await menu.loadSnapshot();
      expect(snap.isOrderable(snap.items.single), isFalse);
    });

    test('foreign keys stop orphan items', () async {
      await expectLater(
        db
            .into(db.menuItems)
            .insert(
              MenuItemsCompanion.insert(
                id: 'x',
                categoryId: 'nope',
                name: 'x',
                basePricePaise: 1,
                createdAt: 0,
                updatedAt: 0,
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('option groups', () {
    test('groups, choices and attachment order', () async {
      await menu.saveOptionGroup(
        const OptionGroup(
          id: 'size',
          name: 'Size',
          kind: OptionGroupKind.variant,
          minSelect: 1,
        ),
      );
      await menu.saveOptionGroup(
        const OptionGroup(
          id: 'extras',
          name: 'Extras',
          kind: OptionGroupKind.addon,
          maxSelect: 3,
        ),
      );
      await menu.saveOptionChoice(
        const OptionChoice(id: 'half', groupId: 'size', name: 'Half'),
      );
      await menu.saveOptionChoice(
        const OptionChoice(
          id: 'full',
          groupId: 'size',
          name: 'Full',
          priceDelta: Money(8000),
        ),
      );
      await menu.saveItem(
        item('i1', 'Tikka').copyWith(optionGroupIds: ['extras', 'size']),
      );

      final snap = await menu.loadSnapshot();
      expect(snap.items.single.optionGroupIds, ['extras', 'size']);
      final sizeGroup = snap.groupById['size']!;
      expect(sizeGroup.choices.map((c) => c.name), ['Half', 'Full']);
      expect(sizeGroup.choices.last.priceDelta, const Money(8000));

      await menu.reorderOptionChoices(['full', 'half']);
      final again = (await menu.loadSnapshot()).groupById['size']!;
      expect(again.choices.map((c) => c.name), ['Full', 'Half']);
    });

    test('rule validation', () async {
      await expectLater(
        menu.saveOptionGroup(
          const OptionGroup(
            id: 'g',
            name: 'G',
            kind: OptionGroupKind.addon,
            minSelect: 3,
            maxSelect: 2,
          ),
        ),
        rejects('Maximum cannot be less'),
      );
      await expectLater(
        menu.saveOptionGroup(
          const OptionGroup(
            id: 'g',
            name: 'G',
            kind: OptionGroupKind.addon,
            maxSelect: 0,
          ),
        ),
        rejects('at least 1'),
      );
    });

    test('duplicate choice names in a group are rejected', () async {
      await menu.saveOptionGroup(
        const OptionGroup(id: 'g', name: 'G', kind: OptionGroupKind.addon),
      );
      await menu.saveOptionChoice(
        const OptionChoice(id: 'a', groupId: 'g', name: 'Cheese'),
      );
      await expectLater(
        menu.saveOptionChoice(
          const OptionChoice(id: 'b', groupId: 'g', name: 'cheese'),
        ),
        rejects('already exists'),
      );
    });
  });

  group('tax profiles', () {
    test('cannot deactivate a tax used by active items', () async {
      await menu.saveItem(item('i1', 'Soup'));
      await expectLater(
        menu.setTaxProfileActive('gst5', false),
        rejects('1 active item(s) use this tax'),
      );
      await menu.setItemActive('i1', false);
      await menu.setTaxProfileActive('gst5', false);
      expect((await menu.listTaxProfiles()).single.isActive, isFalse);
    });

    test('rate bounds and names', () async {
      await expectLater(
        menu.saveTaxProfile(
          const TaxProfile(id: 't', name: 'Bad', rateBp: 10001),
        ),
        rejects('between 0% and 100%'),
      );
      await expectLater(
        menu.saveTaxProfile(
          const TaxProfile(id: 't', name: 'gst 5%', rateBp: 500),
        ),
        rejects('already exists'),
      );
    });
  });

  test('menu changes are audited', () async {
    await menu.saveItem(item('i1', 'Soup'));
    await menu.saveItem(
      (await menu.getItem('i1'))!.copyWith(basePrice: const Money(12000)),
    );
    await menu.setItemActive('i1', false);
    final actions = (await storage.audit.recent()).map((a) => a.action);
    expect(actions.take(3), [
      'menu_item.deactivated',
      'menu_item.updated',
      'menu_item.created',
    ]);
  });
}
