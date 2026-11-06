import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/money.dart';
import '../db/app_database.dart';
import '../../domain/menu/menu_models.dart';
import 'audit_repository.dart';

/// A menu rule was broken; [message] is shown to staff as-is.
class MenuValidationException extends ValidationException {
  MenuValidationException(super.message);
}

/// Everything needed to show or order from the menu, loaded at once.
/// Menus are small (hundreds of rows), so screens filter in memory.
class MenuSnapshot {
  final List<MenuCategory> categories;
  final List<MenuItem> items;
  final List<OptionGroup> optionGroups;
  final List<TaxProfile> taxProfiles;
  final List<KitchenStation> stations;

  MenuSnapshot({
    required this.categories,
    required this.items,
    required this.optionGroups,
    required this.taxProfiles,
    required this.stations,
  });

  late final Map<String, MenuCategory> categoryById = {
    for (final c in categories) c.id: c,
  };
  late final Map<String, OptionGroup> groupById = {
    for (final g in optionGroups) g.id: g,
  };
  late final Map<String, TaxProfile> taxById = {
    for (final t in taxProfiles) t.id: t,
  };
  late final Map<String, KitchenStation> stationById = {
    for (final s in stations) s.id: s,
  };

  List<MenuCategory> get topLevelCategories =>
      categories.where((c) => c.parentId == null).toList();

  List<MenuCategory> subcategoriesOf(String parentId) =>
      categories.where((c) => c.parentId == parentId).toList();

  /// "Starters › Veg" for a subcategory, "Starters" otherwise.
  String categoryPath(String categoryId) {
    final c = categoryById[categoryId];
    if (c == null) return '?';
    final parent = c.parentId == null ? null : categoryById[c.parentId];
    return parent == null ? c.name : '${parent.name} › ${c.name}';
  }

  /// True when the item and its whole category chain are active.
  bool isOrderable(MenuItem item) {
    if (!item.isActive) return false;
    final c = categoryById[item.categoryId];
    if (c == null || !c.isActive) return false;
    final parent = c.parentId == null ? null : categoryById[c.parentId];
    return parent == null || parent.isActive;
  }
}

/// Menu persistence. Nothing is hard-deleted: rows are deactivated so past
/// orders stay readable. Every change writes an audit entry in the same
/// transaction.
class MenuRepository {
  final AppDatabase _db;
  final AuditRepository _audit;

  MenuRepository(this._db, this._audit);

  static String _norm(String s) => s.trim().toLowerCase();

  // ---------------------------------------------------------------- loading

  Future<MenuSnapshot> loadSnapshot() async {
    return _db.transaction(() async {
      return MenuSnapshot(
        categories: await listCategories(),
        items: await listItems(),
        optionGroups: await listOptionGroups(),
        taxProfiles: await listTaxProfiles(),
        stations: await listStations(),
      );
    });
  }

  /// Emits whenever any menu table changes.
  Stream<void> watchChanges() {
    return _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.menuCategories,
        _db.menuItems,
        _db.optionGroups,
        _db.optionChoices,
        _db.itemOptionGroups,
        _db.taxProfiles,
        _db.kitchenStations,
      ]),
    );
  }

  // ----------------------------------------------------------- tax profiles

  Future<List<TaxProfile>> listTaxProfiles() async {
    final rows =
        await (_db.select(_db.taxProfiles)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows
        .map(
          (r) => TaxProfile(
            id: r.id,
            name: r.name,
            rateBp: r.rateBp,
            isInclusive: r.isInclusive,
            splitMode: TaxSplitModeX.parse(r.splitMode),
            isActive: r.isActive,
          ),
        )
        .toList();
  }

  Future<void> saveTaxProfile(TaxProfile t) {
    return _db.transaction(() async {
      final name = t.name.trim();
      if (name.isEmpty) throw MenuValidationException('Tax name is required.');
      if (t.rateBp < 0 || t.rateBp > 10000) {
        throw MenuValidationException('Tax rate must be between 0% and 100%.');
      }
      final others = (await listTaxProfiles()).where((o) => o.id != t.id);
      if (others.any((o) => _norm(o.name) == _norm(name))) {
        throw MenuValidationException('A tax named "$name" already exists.');
      }
      final existing = await (_db.select(
        _db.taxProfiles,
      )..where((r) => r.id.equals(t.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.taxProfiles)
          .insertOnConflictUpdate(
            TaxProfilesCompanion.insert(
              id: t.id,
              name: name,
              rateBp: t.rateBp,
              isInclusive: Value(t.isInclusive),
              splitMode: Value(t.splitMode.name),
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(
                existing?.sortOrder ?? await _nextSort(_db.taxProfiles),
              ),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null
            ? 'tax_profile.created'
            : 'tax_profile.updated',
        entity: 'tax_profiles',
        entityId: t.id,
        details: {
          if (existing != null)
            'from': {
              'name': existing.name,
              'rateBp': existing.rateBp,
              'inclusive': existing.isInclusive,
              'split': existing.splitMode,
            },
          'to': {
            'name': name,
            'rateBp': t.rateBp,
            'inclusive': t.isInclusive,
            'split': t.splitMode.name,
          },
        },
      );
    });
  }

  Future<void> setTaxProfileActive(String id, bool active) {
    return _db.transaction(() async {
      if (!active) {
        final count = await _countActiveItemsWhere(
          (i) => i.taxProfileId.equals(id),
        );
        if (count > 0) {
          throw MenuValidationException(
            '$count active item(s) use this tax. Change their tax first.',
          );
        }
      }
      await (_db.update(_db.taxProfiles)..where((t) => t.id.equals(id))).write(
        TaxProfilesCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'tax_profile.activated' : 'tax_profile.deactivated',
        entity: 'tax_profiles',
        entityId: id,
      );
    });
  }

  // --------------------------------------------------------------- stations

  Future<List<KitchenStation>> listStations() async {
    final rows =
        await (_db.select(_db.kitchenStations)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows
        .map(
          (r) => KitchenStation(id: r.id, name: r.name, isActive: r.isActive),
        )
        .toList();
  }

  Future<void> saveStation(KitchenStation s) {
    return _db.transaction(() async {
      final name = s.name.trim();
      if (name.isEmpty) {
        throw MenuValidationException('Station name is required.');
      }
      final others = (await listStations()).where((o) => o.id != s.id);
      if (others.any((o) => _norm(o.name) == _norm(name))) {
        throw MenuValidationException(
          'A station named "$name" already exists.',
        );
      }
      final existing = await (_db.select(
        _db.kitchenStations,
      )..where((r) => r.id.equals(s.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.kitchenStations)
          .insertOnConflictUpdate(
            KitchenStationsCompanion.insert(
              id: s.id,
              name: name,
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(
                existing?.sortOrder ?? await _nextSort(_db.kitchenStations),
              ),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null ? 'station.created' : 'station.updated',
        entity: 'kitchen_stations',
        entityId: s.id,
        details: {'from': existing?.name, 'to': name},
      );
    });
  }

  Future<void> setStationActive(String id, bool active) {
    return _db.transaction(() async {
      await (_db.update(
        _db.kitchenStations,
      )..where((t) => t.id.equals(id))).write(
        KitchenStationsCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'station.activated' : 'station.deactivated',
        entity: 'kitchen_stations',
        entityId: id,
      );
    });
  }

  // ------------------------------------------------------------- categories

  Future<List<MenuCategory>> listCategories() async {
    final rows =
        await (_db.select(_db.menuCategories)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows
        .map(
          (r) => MenuCategory(
            id: r.id,
            name: r.name,
            parentId: r.parentId,
            isActive: r.isActive,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }

  Future<void> saveCategory(MenuCategory c) {
    return _db.transaction(() async {
      final name = c.name.trim();
      if (name.isEmpty) {
        throw MenuValidationException('Category name is required.');
      }
      final all = await listCategories();
      final byId = {for (final x in all) x.id: x};
      final parentId = c.parentId;
      if (parentId != null) {
        final parent = byId[parentId];
        if (parentId == c.id) {
          throw MenuValidationException('A category cannot be its own parent.');
        }
        if (parent == null) {
          throw MenuValidationException('Parent category not found.');
        }
        if (parent.parentId != null) {
          throw MenuValidationException(
            'Subcategories cannot have subcategories of their own.',
          );
        }
        if (all.any((x) => x.parentId == c.id)) {
          throw MenuValidationException(
            '"$name" has subcategories, so it cannot become a subcategory.',
          );
        }
      }
      final siblings = all.where((x) => x.id != c.id && x.parentId == parentId);
      if (siblings.any((x) => _norm(x.name) == _norm(name))) {
        throw MenuValidationException(
          'A category named "$name" already exists here.',
        );
      }
      final existing = byId[c.id];
      final existingRow = await (_db.select(
        _db.menuCategories,
      )..where((r) => r.id.equals(c.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.menuCategories)
          .insertOnConflictUpdate(
            MenuCategoriesCompanion.insert(
              id: c.id,
              name: name,
              parentId: Value(parentId),
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(
                existing?.sortOrder ?? await _nextSort(_db.menuCategories),
              ),
              createdAt: existingRow?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null ? 'category.created' : 'category.updated',
        entity: 'menu_categories',
        entityId: c.id,
        details: {
          'from': existing == null
              ? null
              : {'name': existing.name, 'parentId': existing.parentId},
          'to': {'name': name, 'parentId': parentId},
        },
      );
    });
  }

  Future<void> setCategoryActive(String id, bool active) {
    return _db.transaction(() async {
      await (_db.update(
        _db.menuCategories,
      )..where((t) => t.id.equals(id))).write(
        MenuCategoriesCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'category.activated' : 'category.deactivated',
        entity: 'menu_categories',
        entityId: id,
      );
    });
  }

  /// Stores [orderedIds] as the new display order (0, 1, 2, …).
  Future<void> reorderCategories(List<String> orderedIds) =>
      _reorder(_db.menuCategories, orderedIds, 'categories.reordered');

  // ------------------------------------------------------------------ items

  Future<List<MenuItem>> listItems() async {
    final rows =
        await (_db.select(_db.menuItems)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    final links = await (_db.select(
      _db.itemOptionGroups,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    final groupsByItem = <String, List<String>>{};
    for (final l in links) {
      groupsByItem.putIfAbsent(l.itemId, () => []).add(l.groupId);
    }
    return rows
        .map((r) => _itemFromRow(r, groupsByItem[r.id] ?? const []))
        .toList();
  }

  Future<MenuItem?> getItem(String id) async {
    final items = await listItems();
    return items.where((i) => i.id == id).firstOrNull;
  }

  /// Checks [item] against the menu rules without saving it.
  Future<void> validateItem(MenuItem item) async {
    final name = item.name.trim();
    if (name.isEmpty) throw MenuValidationException('Item name is required.');
    if (item.basePrice.isNegative) {
      throw MenuValidationException('Price cannot be negative.');
    }
    if (item.prepMinutes != null &&
        (item.prepMinutes! < 0 || item.prepMinutes! > 600)) {
      throw MenuValidationException('Preparation time must be 0 to 600 min.');
    }
    final category = await (_db.select(
      _db.menuCategories,
    )..where((t) => t.id.equals(item.categoryId))).getSingleOrNull();
    if (category == null) {
      throw MenuValidationException('Choose a category.');
    }
    if (item.taxProfileId != null) {
      final tax = await (_db.select(
        _db.taxProfiles,
      )..where((t) => t.id.equals(item.taxProfileId!))).getSingleOrNull();
      if (tax == null) throw MenuValidationException('Tax not found.');
    }
    if (item.stationId != null) {
      final st = await (_db.select(
        _db.kitchenStations,
      )..where((t) => t.id.equals(item.stationId!))).getSingleOrNull();
      if (st == null) throw MenuValidationException('Station not found.');
    }
    if (item.optionGroupIds.toSet().length != item.optionGroupIds.length) {
      throw MenuValidationException('An option group is attached twice.');
    }
    for (final gid in item.optionGroupIds) {
      final g = await (_db.select(
        _db.optionGroups,
      )..where((t) => t.id.equals(gid))).getSingleOrNull();
      if (g == null) throw MenuValidationException('Option group not found.');
    }

    final others = (await (_db.select(
      _db.menuItems,
    )..where((t) => t.id.equals(item.id).not())).get());
    final sku = item.sku?.trim();
    if (sku != null && sku.isNotEmpty) {
      final clash = others.where(
        (o) => o.sku != null && _norm(o.sku!) == _norm(sku),
      );
      if (clash.isNotEmpty) {
        throw MenuValidationException(
          'SKU "$sku" is already used by "${clash.first.name}".',
        );
      }
    }
    final sameName = others.where(
      (o) =>
          o.isActive &&
          o.categoryId == item.categoryId &&
          _norm(o.name) == _norm(name),
    );
    if (item.isActive && sameName.isNotEmpty) {
      throw MenuValidationException(
        'An active item named "$name" already exists in this category.',
      );
    }
  }

  Future<void> saveItem(MenuItem item) {
    return _db.transaction(() async {
      await validateItem(item);
      final existingRow = await (_db.select(
        _db.menuItems,
      )..where((t) => t.id.equals(item.id))).getSingleOrNull();
      final now = Clock.nowMs();
      final sku = item.sku?.trim();
      int sortOrder = item.sortOrder;
      if (existingRow == null) {
        sortOrder = await _nextSort(_db.menuItems);
      } else if (existingRow.categoryId == item.categoryId) {
        sortOrder = existingRow.sortOrder;
      } else {
        sortOrder = await _nextSort(_db.menuItems);
      }
      await _db
          .into(_db.menuItems)
          .insertOnConflictUpdate(
            MenuItemsCompanion.insert(
              id: item.id,
              categoryId: item.categoryId,
              name: item.name.trim(),
              description: Value(item.description.trim()),
              sku: Value(sku == null || sku.isEmpty ? null : sku),
              basePricePaise: item.basePrice.paise,
              taxProfileId: Value(item.taxProfileId),
              foodType: Value(item.foodType.name),
              isActive: Value(item.isActive),
              availableDineIn: Value(item.availableDineIn),
              availableTakeaway: Value(item.availableTakeaway),
              stationId: Value(item.stationId),
              isFavorite: Value(item.isFavorite),
              prepMinutes: Value(item.prepMinutes),
              imagePath: Value(existingRow?.imagePath),
              sortOrder: Value(sortOrder),
              createdAt: existingRow?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await (_db.delete(
        _db.itemOptionGroups,
      )..where((t) => t.itemId.equals(item.id))).go();
      for (var i = 0; i < item.optionGroupIds.length; i++) {
        await _db
            .into(_db.itemOptionGroups)
            .insert(
              ItemOptionGroupsCompanion.insert(
                itemId: item.id,
                groupId: item.optionGroupIds[i],
                sortOrder: Value(i),
              ),
            );
      }
      await _audit.record(
        action: existingRow == null ? 'menu_item.created' : 'menu_item.updated',
        entity: 'menu_items',
        entityId: item.id,
        details: {
          'from': existingRow == null
              ? null
              : {
                  'name': existingRow.name,
                  'pricePaise': existingRow.basePricePaise,
                  'taxProfileId': existingRow.taxProfileId,
                  'categoryId': existingRow.categoryId,
                  'active': existingRow.isActive,
                },
          'to': {
            'name': item.name.trim(),
            'pricePaise': item.basePrice.paise,
            'taxProfileId': item.taxProfileId,
            'categoryId': item.categoryId,
            'active': item.isActive,
          },
        },
      );
    });
  }

  Future<void> setItemActive(String id, bool active) {
    return _db.transaction(() async {
      if (active) {
        final item = await getItem(id);
        if (item == null) return;
        // Re-activating must not create a duplicate active name.
        await validateItem(item.copyWith(isActive: true));
      }
      await (_db.update(_db.menuItems)..where((t) => t.id.equals(id))).write(
        MenuItemsCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'menu_item.activated' : 'menu_item.deactivated',
        entity: 'menu_items',
        entityId: id,
      );
    });
  }

  Future<void> setItemFavorite(String id, bool favorite) {
    return (_db.update(_db.menuItems)..where((t) => t.id.equals(id))).write(
      MenuItemsCompanion(
        isFavorite: Value(favorite),
        updatedAt: Value(Clock.nowMs()),
      ),
    );
  }

  Future<void> reorderItems(List<String> orderedIds) =>
      _reorder(_db.menuItems, orderedIds, 'menu_items.reordered');

  MenuItem _itemFromRow(MenuItemRow r, List<String> groupIds) {
    return MenuItem(
      id: r.id,
      categoryId: r.categoryId,
      name: r.name,
      description: r.description,
      sku: r.sku,
      basePrice: Money(r.basePricePaise),
      taxProfileId: r.taxProfileId,
      foodType: FoodTypeX.parse(r.foodType),
      isActive: r.isActive,
      availableDineIn: r.availableDineIn,
      availableTakeaway: r.availableTakeaway,
      stationId: r.stationId,
      isFavorite: r.isFavorite,
      prepMinutes: r.prepMinutes,
      sortOrder: r.sortOrder,
      optionGroupIds: groupIds,
    );
  }

  // ---------------------------------------------------------- option groups

  Future<List<OptionGroup>> listOptionGroups() async {
    final groups =
        await (_db.select(_db.optionGroups)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    final choices =
        await (_db.select(_db.optionChoices)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    final byGroup = <String, List<OptionChoice>>{};
    for (final c in choices) {
      byGroup
          .putIfAbsent(c.groupId, () => [])
          .add(
            OptionChoice(
              id: c.id,
              groupId: c.groupId,
              name: c.name,
              priceDelta: Money(c.priceDeltaPaise),
              isActive: c.isActive,
            ),
          );
    }
    return groups
        .map(
          (g) => OptionGroup(
            id: g.id,
            name: g.name,
            kind: OptionGroupKindX.parse(g.kind),
            minSelect: g.minSelect,
            maxSelect: g.maxSelect,
            isActive: g.isActive,
            choices: byGroup[g.id] ?? const [],
          ),
        )
        .toList();
  }

  /// Saves the group's name, kind and rules (not its choices).
  Future<void> saveOptionGroup(OptionGroup g) {
    return _db.transaction(() async {
      final name = g.name.trim();
      if (name.isEmpty) {
        throw MenuValidationException('Group name is required.');
      }
      if (g.minSelect < 0) {
        throw MenuValidationException('Minimum cannot be negative.');
      }
      if (g.maxSelect < 1) {
        throw MenuValidationException('Maximum must be at least 1.');
      }
      if (g.maxSelect < g.minSelect) {
        throw MenuValidationException('Maximum cannot be less than minimum.');
      }
      final existing = await (_db.select(
        _db.optionGroups,
      )..where((t) => t.id.equals(g.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.optionGroups)
          .insertOnConflictUpdate(
            OptionGroupsCompanion.insert(
              id: g.id,
              name: name,
              kind: g.kind.name,
              minSelect: Value(g.minSelect),
              maxSelect: Value(g.maxSelect),
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(
                existing?.sortOrder ?? await _nextSort(_db.optionGroups),
              ),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null
            ? 'option_group.created'
            : 'option_group.updated',
        entity: 'option_groups',
        entityId: g.id,
        details: {
          'name': name,
          'kind': g.kind.name,
          'min': g.minSelect,
          'max': g.maxSelect,
        },
      );
    });
  }

  Future<void> setOptionGroupActive(String id, bool active) {
    return _db.transaction(() async {
      await (_db.update(_db.optionGroups)..where((t) => t.id.equals(id))).write(
        OptionGroupsCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'option_group.activated' : 'option_group.deactivated',
        entity: 'option_groups',
        entityId: id,
      );
    });
  }

  Future<void> saveOptionChoice(OptionChoice c) {
    return _db.transaction(() async {
      final name = c.name.trim();
      if (name.isEmpty) {
        throw MenuValidationException('Choice name is required.');
      }
      final group = await (_db.select(
        _db.optionGroups,
      )..where((t) => t.id.equals(c.groupId))).getSingleOrNull();
      if (group == null) throw MenuValidationException('Group not found.');
      final siblings =
          await (_db.select(_db.optionChoices)..where(
                (t) => t.groupId.equals(c.groupId) & t.id.equals(c.id).not(),
              ))
              .get();
      if (siblings.any((s) => _norm(s.name) == _norm(name))) {
        throw MenuValidationException(
          '"$name" already exists in ${group.name}.',
        );
      }
      final existing = await (_db.select(
        _db.optionChoices,
      )..where((t) => t.id.equals(c.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.optionChoices)
          .insertOnConflictUpdate(
            OptionChoicesCompanion.insert(
              id: c.id,
              groupId: c.groupId,
              name: name,
              priceDeltaPaise: Value(c.priceDelta.paise),
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(
                existing?.sortOrder ?? await _nextSort(_db.optionChoices),
              ),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null
            ? 'option_choice.created'
            : 'option_choice.updated',
        entity: 'option_choices',
        entityId: c.id,
        details: {
          'groupId': c.groupId,
          'from': existing == null
              ? null
              : {'name': existing.name, 'pricePaise': existing.priceDeltaPaise},
          'to': {'name': name, 'pricePaise': c.priceDelta.paise},
        },
      );
    });
  }

  Future<void> setOptionChoiceActive(String id, bool active) {
    return _db.transaction(() async {
      await (_db.update(
        _db.optionChoices,
      )..where((t) => t.id.equals(id))).write(
        OptionChoicesCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active
            ? 'option_choice.activated'
            : 'option_choice.deactivated',
        entity: 'option_choices',
        entityId: id,
      );
    });
  }

  Future<void> reorderOptionChoices(List<String> orderedIds) =>
      _reorder(_db.optionChoices, orderedIds, 'option_choices.reordered');

  // ---------------------------------------------------------------- helpers

  Future<int> _countActiveItemsWhere(
    Expression<bool> Function($MenuItemsTable t) filter,
  ) async {
    final count = _db.menuItems.id.count();
    final q = _db.selectOnly(_db.menuItems)
      ..addColumns([count])
      ..where(filter(_db.menuItems) & _db.menuItems.isActive.equals(true));
    return (await q.getSingle()).read(count) ?? 0;
  }

  Future<int> _nextSort(TableInfo table) async {
    final col = table.columnsByName['sort_order']! as GeneratedColumn<int>;
    final max = col.max();
    final row = await (_db.selectOnly(table)..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Future<void> _reorder(
    TableInfo table,
    List<String> orderedIds,
    String action,
  ) {
    return _db.transaction(() async {
      final now = Clock.nowMs();
      for (var i = 0; i < orderedIds.length; i++) {
        await _db.customUpdate(
          'UPDATE ${table.actualTableName} SET sort_order = ?, updated_at = ? '
          'WHERE id = ?',
          variables: [
            Variable.withInt(i),
            Variable.withInt(now),
            Variable.withString(orderedIds[i]),
          ],
          updates: {table},
        );
      }
      await _audit.record(
        action: action,
        entity: table.actualTableName,
        details: {'count': orderedIds.length},
      );
    });
  }
}
