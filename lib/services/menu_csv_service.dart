import 'package:csv/csv.dart';

import '../core/util/ids.dart';
import '../core/util/money.dart';
import '../data/db/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../domain/menu/menu_models.dart';

/// Column names used for export and accepted on import (case-insensitive).
class MenuCsvColumns {
  static const id = 'id';
  static const category = 'category';
  static const subcategory = 'subcategory';
  static const name = 'name';
  static const price = 'price';
  static const sku = 'sku';
  static const tax = 'tax';
  static const foodType = 'food_type';
  static const active = 'active';
  static const dineIn = 'dine_in';
  static const takeaway = 'takeaway';
  static const favorite = 'favorite';
  static const station = 'station';
  static const prepMinutes = 'prep_minutes';
  static const description = 'description';

  static const all = [
    id,
    category,
    subcategory,
    name,
    price,
    sku,
    tax,
    foodType,
    active,
    dineIn,
    takeaway,
    favorite,
    station,
    prepMinutes,
    description,
  ];

  static const required = [category, name];
}

enum CsvRowAction { create, update, unchanged, error }

class CsvImportRow {
  /// 1-based line number in the file (the header is line 1).
  final int line;
  final String displayName;
  final CsvRowAction action;
  final MenuItem? item;
  final List<String> messages;

  const CsvImportRow({
    required this.line,
    required this.displayName,
    required this.action,
    this.item,
    this.messages = const [],
  });
}

class NewCategory {
  final String id;
  final String name;
  final String? parentId;

  /// "Starters" or "Starters › Veg" for display.
  final String path;

  const NewCategory(this.id, this.name, this.parentId, this.path);
}

/// What an import would do. Nothing is written until [MenuCsvService.apply].
class CsvImportPlan {
  final List<CsvImportRow> rows;
  final List<NewCategory> newCategories;

  /// Problems with the file as a whole (missing columns, empty file).
  final List<String> fileErrors;

  const CsvImportPlan({
    required this.rows,
    required this.newCategories,
    this.fileErrors = const [],
  });

  int count(CsvRowAction a) => rows.where((r) => r.action == a).length;
  bool get hasErrors => fileErrors.isNotEmpty || count(CsvRowAction.error) > 0;
  bool get hasWork =>
      count(CsvRowAction.create) + count(CsvRowAction.update) > 0;
  bool get canApply => !hasErrors && hasWork;
}

class CsvImportResult {
  final int created;
  final int updated;
  final int categoriesCreated;

  const CsvImportResult(this.created, this.updated, this.categoriesCreated);
}

/// Menu item CSV export and import.
///
/// Import rules:
/// - A row matches an existing item by `id`, then by `sku`, then by
///   category + name. Matched rows update; others create.
/// - On update, a blank cell keeps the current value.
/// - Missing categories/subcategories are created. Tax and station names
///   must already exist (a typo would otherwise silently change billing).
/// - Any error blocks the whole import; the file must be fixed first.
/// - The import runs in one transaction: all rows are saved or none.
/// - Variants and add-ons are not part of the CSV; set them in the app.
class MenuCsvService {
  static String _norm(String s) => s.trim().toLowerCase();

  // ------------------------------------------------------------------ export

  static String export(MenuSnapshot snap) {
    final rows = <List<String>>[MenuCsvColumns.all];
    final items = [...snap.items]
      ..sort((a, b) {
        final c = snap
            .categoryPath(a.categoryId)
            .compareTo(snap.categoryPath(b.categoryId));
        return c != 0 ? c : a.sortOrder.compareTo(b.sortOrder);
      });
    for (final i in items) {
      final cat = snap.categoryById[i.categoryId];
      final parent = cat?.parentId == null
          ? null
          : snap.categoryById[cat!.parentId];
      rows.add([
        i.id,
        parent?.name ?? cat?.name ?? '',
        parent == null ? '' : cat!.name,
        i.name,
        i.basePrice.format(symbol: false).replaceAll(',', ''),
        i.sku ?? '',
        i.taxProfileId == null
            ? ''
            : (snap.taxById[i.taxProfileId]?.name ?? ''),
        _foodTypeOut(i.foodType),
        _bool(i.isActive),
        _bool(i.availableDineIn),
        _bool(i.availableTakeaway),
        _bool(i.isFavorite),
        i.stationId == null ? '' : (snap.stationById[i.stationId]?.name ?? ''),
        i.prepMinutes?.toString() ?? '',
        i.description,
      ]);
    }
    // '\n' line endings, UTF-8 BOM so Excel shows ₹ and Hindi correctly.
    return '﻿${Csv(lineDelimiter: '\n').encode(rows)}';
  }

  static String _bool(bool b) => b ? 'yes' : 'no';

  static String _foodTypeOut(FoodType t) => switch (t) {
    FoodType.veg => 'veg',
    FoodType.nonVeg => 'non-veg',
    FoodType.egg => 'egg',
    FoodType.other => 'other',
  };

  // ------------------------------------------------------------------ import

  static List<List<String>> parse(String text) {
    var s = text;
    if (s.startsWith('﻿')) s = s.substring(1);
    final rows = Csv(dynamicTyping: false).decode(s);
    return rows
        .map((r) => r.map((c) => c?.toString() ?? '').toList())
        .where((r) => r.any((c) => c.trim().isNotEmpty))
        .toList();
  }

  static CsvImportPlan plan(String text, MenuSnapshot snap) {
    final List<List<String>> rows;
    try {
      rows = parse(text);
    } catch (e) {
      return CsvImportPlan(
        rows: const [],
        newCategories: const [],
        fileErrors: ['The file could not be read as CSV ($e).'],
      );
    }
    if (rows.isEmpty) {
      return const CsvImportPlan(
        rows: [],
        newCategories: [],
        fileErrors: ['The file is empty.'],
      );
    }

    final header = rows.first.map(_norm).toList();
    final col = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      if (MenuCsvColumns.all.contains(header[i])) col[header[i]] = i;
    }
    final missing = MenuCsvColumns.required.where((c) => !col.containsKey(c));
    if (missing.isNotEmpty) {
      return CsvImportPlan(
        rows: const [],
        newCategories: const [],
        fileErrors: [
          'Missing column(s): ${missing.join(', ')}. The first row must be '
              'a header such as: ${MenuCsvColumns.all.join(',')}',
        ],
      );
    }

    String cell(List<String> r, String name) {
      final i = col[name];
      return (i == null || i >= r.length) ? '' : r[i].trim();
    }

    // Category resolution, creating new ones as needed (shared across rows).
    final newCats = <NewCategory>[];
    String? findCategory(String name, String? parentId) {
      for (final c in snap.categories) {
        if (c.parentId == parentId && _norm(c.name) == _norm(name)) {
          return c.id;
        }
      }
      for (final c in newCats) {
        if (c.parentId == parentId && _norm(c.name) == _norm(name)) {
          return c.id;
        }
      }
      return null;
    }

    String resolveCategory(String top, String sub) {
      var topId = findCategory(top, null);
      if (topId == null) {
        topId = newId();
        newCats.add(NewCategory(topId, top, null, top));
      }
      if (sub.isEmpty) return topId;
      var subId = findCategory(sub, topId);
      if (subId == null) {
        subId = newId();
        newCats.add(NewCategory(subId, sub, topId, '$top › $sub'));
      }
      return subId;
    }

    final byId = {for (final i in snap.items) i.id: i};
    final seenSku = <String, int>{};
    final seenName = <String, int>{};
    final out = <CsvImportRow>[];

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final line = r + 1;
      final errors = <String>[];
      final name = cell(row, MenuCsvColumns.name);
      final top = cell(row, MenuCsvColumns.category);
      final sub = cell(row, MenuCsvColumns.subcategory);
      final display = name.isEmpty ? '(no name)' : name;

      if (name.isEmpty) errors.add('Name is empty.');
      if (top.isEmpty) errors.add('Category is empty.');
      if (errors.isNotEmpty) {
        out.add(
          CsvImportRow(
            line: line,
            displayName: display,
            action: CsvRowAction.error,
            messages: errors,
          ),
        );
        continue;
      }

      // Find an existing match before creating categories for it.
      final rawId = cell(row, MenuCsvColumns.id);
      final sku = cell(row, MenuCsvColumns.sku);
      MenuItem? existing = rawId.isEmpty ? null : byId[rawId];
      if (existing == null && sku.isNotEmpty) {
        existing = snap.items
            .where((i) => i.sku != null && _norm(i.sku!) == _norm(sku))
            .firstOrNull;
      }
      final existingTopId = findCategory(top, null);
      final existingCatId = existingTopId == null
          ? null
          : (sub.isEmpty ? existingTopId : findCategory(sub, existingTopId));
      if (existing == null && existingCatId != null) {
        existing = snap.items
            .where(
              (i) =>
                  i.categoryId == existingCatId && _norm(i.name) == _norm(name),
            )
            .firstOrNull;
      }
      if (rawId.isNotEmpty && byId[rawId] == null) {
        errors.add('id "$rawId" does not match any item. Clear it to create.');
      }

      final categoryId = resolveCategory(top, sub);

      // Duplicates inside the file.
      if (sku.isNotEmpty) {
        final prev = seenSku[_norm(sku)];
        if (prev != null) {
          errors.add('SKU "$sku" is also on line $prev.');
        } else {
          seenSku[_norm(sku)] = line;
        }
      }
      final nameKey = '$categoryId|${_norm(name)}';
      final prevName = seenName[nameKey];
      if (prevName != null) {
        errors.add('Same name and category as line $prevName.');
      } else {
        seenName[nameKey] = line;
      }

      // Field parsing (blank = keep current / default).
      Money? price;
      final priceText = cell(row, MenuCsvColumns.price);
      if (priceText.isNotEmpty) {
        price = Money.parse(priceText);
        if (price == null || price.isNegative) {
          errors.add('Price "$priceText" is not a valid amount.');
        }
      } else if (existing == null) {
        errors.add('Price is required for a new item.');
      }

      String? taxId;
      var keepTax = true;
      final taxText = cell(row, MenuCsvColumns.tax);
      if (col.containsKey(MenuCsvColumns.tax)) {
        if (taxText.isEmpty) {
          keepTax = existing != null;
        } else if (_norm(taxText) == 'none' || _norm(taxText) == 'no tax') {
          keepTax = false;
        } else {
          keepTax = false;
          final t = snap.taxProfiles
              .where((t) => _norm(t.name) == _norm(taxText))
              .firstOrNull;
          if (t == null) {
            errors.add('Tax "$taxText" does not exist. Create it first.');
          } else {
            taxId = t.id;
          }
        }
      }

      String? stationId;
      var keepStation = true;
      final stationText = cell(row, MenuCsvColumns.station);
      if (stationText.isNotEmpty) {
        keepStation = false;
        final s = snap.stations
            .where((s) => _norm(s.name) == _norm(stationText))
            .firstOrNull;
        if (s == null) {
          errors.add('Station "$stationText" does not exist. Create it first.');
        } else {
          stationId = s.id;
        }
      } else if (existing == null) {
        keepStation = false;
      }

      FoodType? foodType;
      final ftText = _norm(cell(row, MenuCsvColumns.foodType));
      if (ftText.isNotEmpty) {
        foodType = switch (ftText.replaceAll(RegExp(r'[\s_-]'), '')) {
          'veg' || 'v' || 'vegetarian' => FoodType.veg,
          'nonveg' || 'nv' || 'nonvegetarian' => FoodType.nonVeg,
          'egg' || 'eggetarian' => FoodType.egg,
          'other' => FoodType.other,
          _ => null,
        };
        if (foodType == null) {
          errors.add('Food type "$ftText" must be veg, non-veg, egg or other.');
        }
      }

      bool? boolCell(String column) {
        final v = _norm(cell(row, column));
        if (v.isEmpty) return null;
        if (const ['yes', 'y', 'true', '1'].contains(v)) return true;
        if (const ['no', 'n', 'false', '0'].contains(v)) return false;
        errors.add('$column "$v" must be yes or no.');
        return null;
      }

      final active = boolCell(MenuCsvColumns.active);
      final dineIn = boolCell(MenuCsvColumns.dineIn);
      final takeaway = boolCell(MenuCsvColumns.takeaway);
      final favorite = boolCell(MenuCsvColumns.favorite);

      int? prep;
      final prepText = cell(row, MenuCsvColumns.prepMinutes);
      if (prepText.isNotEmpty) {
        prep = int.tryParse(prepText);
        if (prep == null || prep < 0 || prep > 600) {
          errors.add('prep_minutes "$prepText" must be 0 to 600.');
          prep = null;
        }
      }
      final description = cell(row, MenuCsvColumns.description);

      if (errors.isNotEmpty) {
        out.add(
          CsvImportRow(
            line: line,
            displayName: display,
            action: CsvRowAction.error,
            messages: errors,
          ),
        );
        continue;
      }

      final base =
          existing ??
          MenuItem(
            id: newId(),
            categoryId: categoryId,
            name: name,
            basePrice: price!,
          );
      final item = base.copyWith(
        categoryId: categoryId,
        name: name,
        basePrice: price,
        sku: sku.isEmpty ? null : sku,
        taxProfileId: taxId,
        clearTax: !keepTax && taxId == null,
        stationId: stationId,
        clearStation: !keepStation && stationId == null,
        foodType: foodType,
        isActive: active,
        availableDineIn: dineIn,
        availableTakeaway: takeaway,
        isFavorite: favorite,
        prepMinutes: prep,
        description: description.isEmpty ? null : description,
      );

      if (existing == null) {
        out.add(
          CsvImportRow(
            line: line,
            displayName: display,
            action: CsvRowAction.create,
            item: item,
            messages: ['New item, ${item.basePrice.format()}'],
          ),
        );
      } else {
        final changes = _diff(existing, item, snap, newCats);
        out.add(
          CsvImportRow(
            line: line,
            displayName: display,
            action: changes.isEmpty
                ? CsvRowAction.unchanged
                : CsvRowAction.update,
            item: item,
            messages: changes,
          ),
        );
      }
    }

    // Only keep categories that a non-error row actually uses.
    final used = <String>{};
    for (final r in out.where((r) => r.item != null)) {
      used.add(r.item!.categoryId);
      final nc = newCats.where((c) => c.id == r.item!.categoryId).firstOrNull;
      if (nc?.parentId != null) used.add(nc!.parentId!);
    }
    return CsvImportPlan(
      rows: out,
      newCategories: newCats.where((c) => used.contains(c.id)).toList(),
    );
  }

  static List<String> _diff(
    MenuItem a,
    MenuItem b,
    MenuSnapshot snap,
    List<NewCategory> newCats,
  ) {
    String cat(String id) =>
        newCats.where((c) => c.id == id).firstOrNull?.path ??
        snap.categoryPath(id);
    String tax(String? id) =>
        id == null ? 'no tax' : (snap.taxById[id]?.name ?? '?');
    String station(String? id) =>
        id == null ? 'default' : (snap.stationById[id]?.name ?? '?');
    String yn(bool v) => v ? 'yes' : 'no';
    final c = <String>[];
    void add(String label, String from, String to) {
      if (from != to) c.add('$label: $from → $to');
    }

    add('name', a.name, b.name);
    add('category', cat(a.categoryId), cat(b.categoryId));
    add('price', a.basePrice.format(), b.basePrice.format());
    add('sku', a.sku ?? '', b.sku ?? '');
    add('tax', tax(a.taxProfileId), tax(b.taxProfileId));
    add('food type', a.foodType.label, b.foodType.label);
    add('active', yn(a.isActive), yn(b.isActive));
    add('dine-in', yn(a.availableDineIn), yn(b.availableDineIn));
    add('takeaway', yn(a.availableTakeaway), yn(b.availableTakeaway));
    add('favourite', yn(a.isFavorite), yn(b.isFavorite));
    add('station', station(a.stationId), station(b.stationId));
    add('prep', '${a.prepMinutes ?? ''}', '${b.prepMinutes ?? ''}');
    add('description', a.description, b.description);
    return c;
  }

  /// Writes the plan in one transaction. Any failure rolls everything back.
  static Future<CsvImportResult> apply(
    AppDatabase db,
    MenuRepository menu,
    AuditRepository audit,
    CsvImportPlan plan,
  ) async {
    if (!plan.canApply) {
      throw MenuValidationException(
        plan.hasErrors
            ? 'Fix the errors in the file before importing.'
            : 'Nothing to import.',
      );
    }
    return db.transaction(() async {
      // Parents before children.
      final ordered = [
        ...plan.newCategories.where((c) => c.parentId == null),
        ...plan.newCategories.where((c) => c.parentId != null),
      ];
      for (final c in ordered) {
        await menu.saveCategory(
          MenuCategory(id: c.id, name: c.name, parentId: c.parentId),
        );
      }
      var created = 0;
      var updated = 0;
      for (final r in plan.rows) {
        if (r.action == CsvRowAction.create) {
          await _save(menu, r);
          created++;
        } else if (r.action == CsvRowAction.update) {
          await _save(menu, r);
          updated++;
        }
      }
      await audit.record(
        action: 'menu.csv_imported',
        entity: 'menu_items',
        details: {
          'created': created,
          'updated': updated,
          'categoriesCreated': ordered.length,
        },
      );
      return CsvImportResult(created, updated, ordered.length);
    });
  }

  static Future<void> _save(MenuRepository menu, CsvImportRow r) async {
    try {
      await menu.saveItem(r.item!);
    } on MenuValidationException catch (e) {
      throw MenuValidationException('Line ${r.line} (${r.displayName}): $e');
    }
  }
}
