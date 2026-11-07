import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/inventory/inventory_models.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'order_repository.dart';
import 'settings_repository.dart';

/// Stock items, stock movements and recipes.
///
/// Stock on hand is the sum of an item's movements; movements are never
/// changed or deleted. Sales take stock away only for items that have a
/// recipe, at the moment set by [deductOn]. Each deduction has a unique
/// `source_key`, so a retried or reprinted KOT or bill can never take
/// stock twice.
class InventoryRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final SettingsRepository _settings;
  final OrderRepository _orders;

  InventoryRepository(this._db, this._audit, this._settings, this._orders);

  static const String keyDeductOn = 'inventory.deduct_on';

  // --- Settings ------------------------------------------------------------

  Future<DeductOn> deductOn() async =>
      DeductOnX.parse(await _settings.getRaw(keyDeductOn));

  Future<void> setDeductOn(DeductOn d) => _settings.setRaw(keyDeductOn, d.name);

  // --- Stock items ---------------------------------------------------------

  static const _itemsSql = '''
SELECT s.*,
  COALESCE((SELECT SUM(m.qty_milli) FROM stock_movements m
            WHERE m.stock_item_id = s.id), 0) AS on_hand,
  (SELECT m.cost_paise * 1000 / m.qty_milli FROM stock_movements m
     WHERE m.stock_item_id = s.id AND m.kind = 'purchase'
       AND m.cost_paise IS NOT NULL AND m.qty_milli > 0
     ORDER BY m.created_at DESC, m.rowid DESC LIMIT 1) AS last_cost
FROM stock_items s
ORDER BY s.active DESC, s.name COLLATE NOCASE
''';

  StockItem _item(QueryRow r) {
    final row = _db.stockItems.map(r.data);
    return StockItem(
      id: row.id,
      name: row.name,
      unit: StockUnitX.parse(row.unit),
      lowStockMilli: row.lowStockMilli,
      note: row.note,
      active: row.active,
      onHandMilli: r.read<int>('on_hand'),
      lastCostPerUnitPaise: r.readNullable<int>('last_cost'),
    );
  }

  Selectable<QueryRow> _itemsQuery() => _db.customSelect(
    _itemsSql,
    readsFrom: {_db.stockItems, _db.stockMovements},
  );

  Future<List<StockItem>> items() async =>
      (await _itemsQuery().get()).map(_item).toList();

  Stream<List<StockItem>> watchItems() =>
      _itemsQuery().watch().map((rows) => rows.map(_item).toList());

  Future<StockItem?> item(String id) async {
    for (final i in await items()) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Active items at or below their low-stock level.
  Stream<List<StockItem>> watchLow() =>
      watchItems().map((all) => all.where((i) => i.active && i.isLow).toList());

  Future<String> saveItem({
    String? id,
    required String name,
    required StockUnit unit,
    int? lowStockMilli,
    String note = '',
  }) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) throw ValidationException('Enter a name.');
    if (lowStockMilli != null && lowStockMilli < 0) {
      throw ValidationException('The low-stock level cannot be negative.');
    }
    return _db.transaction(() async {
      final all = await _db.select(_db.stockItems).get();
      if (all.any(
        (r) => r.id != id && r.name.toLowerCase() == clean.toLowerCase(),
      )) {
        throw ValidationException('There is already a stock item "$clean".');
      }
      final now = Clock.nowMs();
      if (id == null) {
        final newItemId = newId();
        await _db
            .into(_db.stockItems)
            .insert(
              StockItemsCompanion.insert(
                id: newItemId,
                name: clean,
                unit: unit.name,
                lowStockMilli: Value(lowStockMilli),
                note: Value(note.trim()),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _audit.record(
          action: 'stock.item_created',
          entity: 'stock_items',
          entityId: newItemId,
          details: {'name': clean, 'unit': unit.name, 'low': lowStockMilli},
        );
        return newItemId;
      }
      final before = all.where((r) => r.id == id).firstOrNull;
      if (before == null) throw ValidationException('Stock item not found.');
      if (before.unit != unit.name && await _hasMovements(id)) {
        throw ValidationException(
          'The unit cannot change once stock has been recorded. Make a new '
          'item instead.',
        );
      }
      await (_db.update(_db.stockItems)..where((t) => t.id.equals(id))).write(
        StockItemsCompanion(
          name: Value(clean),
          unit: Value(unit.name),
          lowStockMilli: Value(lowStockMilli),
          note: Value(note.trim()),
          updatedAt: Value(now),
        ),
      );
      await _audit.record(
        action: 'stock.item_updated',
        entity: 'stock_items',
        entityId: id,
        details: {
          'name': {'from': before.name, 'to': clean},
          'low': {'from': before.lowStockMilli, 'to': lowStockMilli},
        },
      );
      return id;
    });
  }

  Future<void> setItemActive(String id, bool active) async {
    await _db.transaction(() async {
      await (_db.update(_db.stockItems)..where((t) => t.id.equals(id))).write(
        StockItemsCompanion(
          active: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'stock.item_reactivated' : 'stock.item_deactivated',
        entity: 'stock_items',
        entityId: id,
      );
    });
  }

  Future<bool> _hasMovements(String itemId) async =>
      await _db.stockMovements
          .count(where: (m) => m.stockItemId.equals(itemId))
          .getSingle() >
      0;

  // --- Movements by hand ---------------------------------------------------

  /// Records opening stock, a purchase or wastage. [qtyMilli] is the
  /// amount (always positive); wastage takes it away. A retried request
  /// with the same [clientRequestId] is recorded once.
  Future<void> record({
    required String stockItemId,
    required StockMovementKind kind,
    required int qtyMilli,
    int? costPaise,
    String reason = '',
    required String clientRequestId,
  }) async {
    if (kind == StockMovementKind.sale ||
        kind == StockMovementKind.saleReturn ||
        kind == StockMovementKind.count) {
      throw ArgumentError('Use countStock for counts; sales are automatic.');
    }
    if (qtyMilli <= 0) throw ValidationException('Enter a quantity above 0.');
    if (costPaise != null && costPaise < 0) {
      throw ValidationException('The cost cannot be negative.');
    }
    if (kind == StockMovementKind.wastage && reason.trim().isEmpty) {
      throw ValidationException('Enter a reason for the wastage.');
    }
    await _db.transaction(() async {
      if (await _requestDone(clientRequestId)) return;
      final it = await _requireItem(stockItemId);
      if (kind == StockMovementKind.opening &&
          await _hasMovements(stockItemId)) {
        throw ValidationException(
          'Opening stock is only for an item with no stock recorded yet. '
          'Use a stock count to correct it.',
        );
      }
      final signed = kind == StockMovementKind.wastage ? -qtyMilli : qtyMilli;
      final id = await _insert(
        stockItemId: stockItemId,
        kind: kind,
        qtyMilli: signed,
        costPaise: kind == StockMovementKind.purchase ? costPaise : null,
        reason: reason.trim(),
        sourceKey: 'REQ:$clientRequestId',
      );
      await _audit.record(
        action: 'stock.${kind.name}',
        entity: 'stock_movements',
        entityId: id,
        details: {
          'item': it.name,
          'qtyMilli': signed,
          'costPaise': ?costPaise,
          if (reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    });
  }

  /// Sets stock on hand to what was counted, recording the difference.
  /// Returns the difference (counted − on hand before).
  Future<int> countStock({
    required String stockItemId,
    required int countedMilli,
    required String reason,
    required String clientRequestId,
  }) async {
    if (countedMilli < 0) throw ValidationException('Enter what you counted.');
    return _db.transaction(() async {
      if (await _requestDone(clientRequestId)) return 0;
      final it = await item(stockItemId);
      if (it == null) throw ValidationException('Stock item not found.');
      final diff = countedMilli - it.onHandMilli;
      if (diff == 0) return 0;
      if (reason.trim().isEmpty) {
        throw ValidationException(
          'The count is ${Qty.withUnit(diff.abs(), it.unit)} '
          '${diff < 0 ? 'less' : 'more'} than expected. Enter a reason.',
        );
      }
      final id = await _insert(
        stockItemId: stockItemId,
        kind: StockMovementKind.count,
        qtyMilli: diff,
        reason: reason.trim(),
        sourceKey: 'REQ:$clientRequestId',
      );
      await _audit.record(
        action: 'stock.count',
        entity: 'stock_movements',
        entityId: id,
        details: {
          'item': it.name,
          'expectedMilli': it.onHandMilli,
          'countedMilli': countedMilli,
          'diffMilli': diff,
          'reason': reason.trim(),
        },
      );
      return diff;
    });
  }

  Future<bool> _requestDone(String clientRequestId) async =>
      await _db.stockMovements
          .count(where: (m) => m.sourceKey.equals('REQ:$clientRequestId'))
          .getSingle() >
      0;

  Future<StockItemRow> _requireItem(String id) async {
    final r = await (_db.select(
      _db.stockItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) throw ValidationException('Stock item not found.');
    return r;
  }

  Future<String> _insert({
    required String stockItemId,
    required StockMovementKind kind,
    required int qtyMilli,
    int? costPaise,
    String reason = '',
    String? orderId,
    String? orderLineId,
    String? sourceRef,
    int? units,
    required String sourceKey,
  }) async {
    final id = newId();
    await _db
        .into(_db.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            id: id,
            stockItemId: stockItemId,
            kind: kind.name,
            qtyMilli: qtyMilli,
            costPaise: Value(costPaise),
            reason: Value(reason),
            orderId: Value(orderId),
            orderLineId: Value(orderLineId),
            sourceRef: Value(sourceRef),
            units: Value(units),
            sourceKey: Value(sourceKey),
            staffId: Value(_audit.session.staffId),
            staffName: Value(_audit.session.staffName),
            businessDate: await _orders.currentBusinessDate(),
            createdAt: Clock.nowMs(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return id;
  }

  // --- History -------------------------------------------------------------

  StockMovement _movement(StockMovementRow r) => StockMovement(
    id: r.id,
    stockItemId: r.stockItemId,
    kind: StockMovementKindX.parse(r.kind),
    qtyMilli: r.qtyMilli,
    costPaise: r.costPaise,
    reason: r.reason,
    orderId: r.orderId,
    units: r.units,
    staffName: r.staffName,
    businessDate: r.businessDate,
    createdAt: Clock.toLocal(r.createdAt),
  );

  Stream<List<StockMovement>> watchHistory(
    String stockItemId, {
    int limit = 200,
  }) =>
      (_db.select(_db.stockMovements)
            ..where((m) => m.stockItemId.equals(stockItemId))
            ..orderBy([
              (m) => OrderingTerm.desc(m.createdAt),
              (m) => OrderingTerm.desc(m.rowId),
            ])
            ..limit(limit))
          .watch()
          .map((rows) => rows.map(_movement).toList());

  /// Movements whose business date is from [from] to [to] (inclusive).
  Future<List<StockMovement>> movementsBetween(String from, String to) async {
    final rows =
        await (_db.select(_db.stockMovements)
              ..where((m) => m.businessDate.isBetweenValues(from, to))
              ..orderBy([
                (m) => OrderingTerm.asc(m.createdAt),
                (m) => OrderingTerm.asc(m.rowId),
              ]))
            .get();
    return rows.map(_movement).toList();
  }

  // --- Recipes -------------------------------------------------------------

  RecipeLine _recipe(RecipeLineRow r) => RecipeLine(
    id: r.id,
    menuItemId: r.menuItemId,
    optionChoiceId: r.optionChoiceId,
    stockItemId: r.stockItemId,
    qtyMilli: r.qtyMilli,
  );

  Stream<List<RecipeLine>> watchRecipe({String? menuItemId, String? choiceId}) {
    final q = _db.select(_db.recipeLines)
      ..where(
        (r) => menuItemId != null
            ? r.menuItemId.equals(menuItemId)
            : r.optionChoiceId.equals(choiceId!),
      );
    return q.watch().map((rows) => rows.map(_recipe).toList());
  }

  /// Menu item ids and option choice ids that have a recipe.
  Future<Set<String>> withRecipes() async {
    final rows = await _db.select(_db.recipeLines).get();
    return {for (final r in rows) r.menuItemId ?? r.optionChoiceId!};
  }

  /// Sets how much of [stockItemId] one unit of the menu item (or one
  /// chosen option) uses. 0 removes the line. Exactly one of [menuItemId]
  /// and [choiceId] must be given.
  Future<void> setRecipeLine({
    String? menuItemId,
    String? choiceId,
    required String stockItemId,
    required int qtyMilli,
  }) async {
    if ((menuItemId == null) == (choiceId == null)) {
      throw ArgumentError('Give a menu item or an option choice.');
    }
    if (qtyMilli < 0) {
      throw ValidationException('Enter a quantity of 0 or more.');
    }
    await _db.transaction(() async {
      final it = await _requireItem(stockItemId);
      final existing =
          await (_db.select(_db.recipeLines)..where(
                (r) =>
                    r.stockItemId.equals(stockItemId) &
                    (menuItemId != null
                        ? r.menuItemId.equals(menuItemId)
                        : r.optionChoiceId.equals(choiceId!)),
              ))
              .getSingleOrNull();
      final now = Clock.nowMs();
      if (qtyMilli == 0) {
        if (existing == null) return;
        await (_db.delete(
          _db.recipeLines,
        )..where((r) => r.id.equals(existing.id))).go();
      } else if (existing == null) {
        await _db
            .into(_db.recipeLines)
            .insert(
              RecipeLinesCompanion.insert(
                id: newId(),
                menuItemId: Value(menuItemId),
                optionChoiceId: Value(choiceId),
                stockItemId: stockItemId,
                qtyMilli: qtyMilli,
                updatedAt: now,
              ),
            );
      } else {
        if (existing.qtyMilli == qtyMilli) return;
        await (_db.update(
          _db.recipeLines,
        )..where((r) => r.id.equals(existing.id))).write(
          RecipeLinesCompanion(
            qtyMilli: Value(qtyMilli),
            updatedAt: Value(now),
          ),
        );
      }
      await _audit.record(
        action: 'recipe.changed',
        entity: 'recipe_lines',
        entityId: menuItemId ?? choiceId,
        details: {
          'menuItemId': ?menuItemId,
          'choiceId': ?choiceId,
          'stockItem': it.name,
          'fromMilli': existing?.qtyMilli ?? 0,
          'toMilli': qtyMilli,
        },
      );
    });
  }

  /// Stock used by one unit of an order line: the menu item's recipe plus
  /// the recipes of the chosen options. Stock item id -> thousandths.
  Future<Map<String, int>> _perUnit(OrderLineRow line) async {
    final out = <String, int>{};
    void add(Iterable<RecipeLineRow> rows) {
      for (final r in rows) {
        out[r.stockItemId] = (out[r.stockItemId] ?? 0) + r.qtyMilli;
      }
    }

    if (line.menuItemId != null) {
      add(
        await (_db.select(
          _db.recipeLines,
        )..where((r) => r.menuItemId.equals(line.menuItemId!))).get(),
      );
    }
    final choices = await (_db.select(
      _db.orderLineOptions,
    )..where((o) => o.lineId.equals(line.id))).get();
    if (choices.isNotEmpty) {
      add(
        await (_db.select(_db.recipeLines)..where(
              (r) => r.optionChoiceId.isIn(choices.map((c) => c.choiceId)),
            ))
            .get(),
      );
    }
    return out;
  }

  Future<OrderLineRow?> _line(String id) => (_db.select(
    _db.orderLines,
  )..where((l) => l.id.equals(id))).getSingleOrNull();

  // --- Sales (called inside the KOT / bill transactions) -------------------

  /// After a kitchen ticket is saved. Takes stock only when [deductOn] is
  /// [DeductOn.kot]; void tickets never take or return stock (the food
  /// may already be made: correct it with wastage or a count).
  Future<void> onKitchenTicket(String ticketId) async {
    if (await deductOn() != DeductOn.kot) return;
    final ticket = await (_db.select(
      _db.kitchenTickets,
    )..where((t) => t.id.equals(ticketId))).getSingle();
    if (ticket.kind != 'send') return;
    final lines = await (_db.select(
      _db.kitchenTicketLines,
    )..where((l) => l.ticketId.equals(ticketId))).get();
    for (final tl in lines) {
      final line = await _line(tl.orderLineId);
      if (line == null) continue;
      final per = await _perUnit(line);
      for (final e in per.entries) {
        await _insert(
          stockItemId: e.key,
          kind: StockMovementKind.sale,
          qtyMilli: -e.value * tl.qty,
          orderId: line.orderId,
          orderLineId: line.id,
          sourceRef: tl.id,
          units: tl.qty,
          sourceKey: 'KOT:${tl.id}:${e.key}',
        );
      }
    }
  }

  /// Units of [orderLineId] already taken from stock by kitchen tickets.
  Future<int> _kotUnits(String orderLineId) async {
    final rows =
        await (_db.select(_db.stockMovements)..where(
              (m) =>
                  m.orderLineId.equals(orderLineId) & m.sourceKey.like('KOT:%'),
            ))
            .get();
    final byRef = <String, int>{};
    for (final r in rows) {
      byRef[r.sourceRef ?? r.id] = r.units ?? 0;
    }
    return byRef.values.fold<int>(0, (s, u) => s + u);
  }

  /// After a bill is finalized. Unless deduction is off, takes stock for
  /// billed units not already taken by a kitchen ticket (e.g. items billed
  /// without a KOT, or everything when deducting on the bill).
  Future<void> onBillFinalized(String billId) async {
    if (await deductOn() == DeductOn.off) return;
    final bill = await (_db.select(
      _db.bills,
    )..where((b) => b.id.equals(billId))).getSingle();
    final lines = await (_db.select(
      _db.billLines,
    )..where((l) => l.billId.equals(billId))).get();
    for (final bl in lines) {
      final line = await _line(bl.orderLineId);
      if (line == null) continue;
      final units = bl.qty - await _kotUnits(line.id);
      if (units <= 0) continue;
      final per = await _perUnit(line);
      for (final e in per.entries) {
        await _insert(
          stockItemId: e.key,
          kind: StockMovementKind.sale,
          qtyMilli: -e.value * units,
          orderId: bill.orderId,
          orderLineId: line.id,
          sourceRef: bl.id,
          units: units,
          sourceKey: 'BILL:${bl.id}:${e.key}',
        );
      }
    }
  }

  /// After a bill is voided: gives back exactly what that bill took (not
  /// recalculated from today's recipe). Kitchen-ticket deductions stay.
  Future<void> onBillVoided(String billId) async {
    final lines = await (_db.select(
      _db.billLines,
    )..where((l) => l.billId.equals(billId))).get();
    for (final bl in lines) {
      final taken = await (_db.select(
        _db.stockMovements,
      )..where((m) => m.sourceKey.like('BILL:${bl.id}:%'))).get();
      for (final m in taken) {
        await _insert(
          stockItemId: m.stockItemId,
          kind: StockMovementKind.saleReturn,
          qtyMilli: -m.qtyMilli,
          orderId: m.orderId,
          orderLineId: m.orderLineId,
          sourceRef: bl.id,
          units: m.units,
          reason: 'Bill voided',
          sourceKey: 'BILLVOID:${bl.id}:${m.stockItemId}',
        );
      }
    }
  }
}
