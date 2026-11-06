import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/orders/table_models.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';

/// Dining areas and tables. Like the menu, nothing is hard-deleted.
class TableRepository {
  final AppDatabase _db;
  final AuditRepository _audit;

  TableRepository(this._db, this._audit);

  static String _norm(String s) => s.trim().toLowerCase();

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.diningAreas, _db.restaurantTables]),
  );

  // ------------------------------------------------------------------ areas

  Future<List<DiningArea>> listAreas() async {
    final rows =
        await (_db.select(_db.diningAreas)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows
        .map((r) => DiningArea(id: r.id, name: r.name, isActive: r.isActive))
        .toList();
  }

  Future<void> saveArea(DiningArea a) {
    return _db.transaction(() async {
      final name = a.name.trim();
      if (name.isEmpty) throw ValidationException('Area name is required.');
      final others = (await listAreas()).where((o) => o.id != a.id);
      if (others.any((o) => _norm(o.name) == _norm(name))) {
        throw ValidationException('An area named "$name" already exists.');
      }
      final existing = await (_db.select(
        _db.diningAreas,
      )..where((t) => t.id.equals(a.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.diningAreas)
          .insertOnConflictUpdate(
            DiningAreasCompanion.insert(
              id: a.id,
              name: name,
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(existing?.sortOrder ?? await _nextAreaSort()),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null ? 'area.created' : 'area.updated',
        entity: 'dining_areas',
        entityId: a.id,
        details: {'from': existing?.name, 'to': name},
      );
    });
  }

  Future<void> setAreaActive(String id, bool active) {
    return _db.transaction(() async {
      if (!active) {
        final busy = await _activeOrderCount(
          areaTables: await _tableIdsInArea(id),
        );
        if (busy > 0) {
          throw ValidationException(
            'This area has $busy running order(s). Close or move them first.',
          );
        }
      }
      await (_db.update(_db.diningAreas)..where((t) => t.id.equals(id))).write(
        DiningAreasCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'area.activated' : 'area.deactivated',
        entity: 'dining_areas',
        entityId: id,
      );
    });
  }

  Future<void> reorderAreas(List<String> ids) => _db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.diningAreas)..where((t) => t.id.equals(ids[i])))
          .write(DiningAreasCompanion(sortOrder: Value(i)));
    }
  });

  Future<int> _nextAreaSort() async {
    final max = _db.diningAreas.sortOrder.max();
    final r = await (_db.selectOnly(
      _db.diningAreas,
    )..addColumns([max])).getSingle();
    return (r.read(max) ?? -1) + 1;
  }

  // ----------------------------------------------------------------- tables

  Future<List<RestaurantTable>> listTables() async {
    final rows =
        await (_db.select(_db.restaurantTables)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows
        .map(
          (r) => RestaurantTable(
            id: r.id,
            areaId: r.areaId,
            label: r.label,
            seats: r.seats,
            isActive: r.isActive,
            sortOrder: r.sortOrder,
          ),
        )
        .toList();
  }

  Future<RestaurantTable?> getTable(String id) async =>
      (await listTables()).where((t) => t.id == id).firstOrNull;

  Future<void> saveTable(RestaurantTable t) {
    return _db.transaction(() async {
      final label = t.label.trim();
      if (label.isEmpty) throw ValidationException('Table name is required.');
      if (t.seats != null && (t.seats! < 1 || t.seats! > 100)) {
        throw ValidationException('Seats must be 1 to 100.');
      }
      final area = await (_db.select(
        _db.diningAreas,
      )..where((a) => a.id.equals(t.areaId))).getSingleOrNull();
      if (area == null) throw ValidationException('Choose an area.');
      final others = (await listTables()).where((o) => o.id != t.id);
      if (others.any(
        (o) => o.areaId == t.areaId && _norm(o.label) == _norm(label),
      )) {
        throw ValidationException(
          'Table "$label" already exists in ${area.name}.',
        );
      }
      final existing = await (_db.select(
        _db.restaurantTables,
      )..where((r) => r.id.equals(t.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.restaurantTables)
          .insertOnConflictUpdate(
            RestaurantTablesCompanion.insert(
              id: t.id,
              areaId: t.areaId,
              label: label,
              seats: Value(t.seats),
              isActive: Value(existing?.isActive ?? true),
              sortOrder: Value(existing?.sortOrder ?? await _nextTableSort()),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: existing == null ? 'table.created' : 'table.updated',
        entity: 'restaurant_tables',
        entityId: t.id,
        details: {'label': label, 'areaId': t.areaId, 'seats': t.seats},
      );
    });
  }

  /// Creates tables named `<prefix><n>` for n in [from]..[to], skipping
  /// names that already exist in the area. Returns how many were created.
  Future<int> addTables({
    required String areaId,
    required String prefix,
    required int from,
    required int to,
    int? seats,
  }) async {
    if (from < 0 || to < from || to - from >= 200) {
      throw ValidationException('Enter a range of up to 200 tables.');
    }
    return _db.transaction(() async {
      final existing = (await listTables())
          .where((t) => t.areaId == areaId)
          .map((t) => _norm(t.label))
          .toSet();
      var created = 0;
      for (var n = from; n <= to; n++) {
        final label = '${prefix.trim()}$n';
        if (existing.contains(_norm(label))) continue;
        await saveTable(
          RestaurantTable(
            id: newId(),
            areaId: areaId,
            label: label,
            seats: seats,
          ),
        );
        created++;
      }
      return created;
    });
  }

  Future<void> setTableActive(String id, bool active) {
    return _db.transaction(() async {
      if (!active && await _activeOrderCount(areaTables: [id]) > 0) {
        throw ValidationException(
          'This table has a running order. Close or move it first.',
        );
      }
      await (_db.update(
        _db.restaurantTables,
      )..where((t) => t.id.equals(id))).write(
        RestaurantTablesCompanion(
          isActive: Value(active),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'table.activated' : 'table.deactivated',
        entity: 'restaurant_tables',
        entityId: id,
      );
    });
  }

  Future<void> reorderTables(List<String> ids) => _db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.restaurantTables)
            ..where((t) => t.id.equals(ids[i])))
          .write(RestaurantTablesCompanion(sortOrder: Value(i)));
    }
  });

  Future<int> _nextTableSort() async {
    final max = _db.restaurantTables.sortOrder.max();
    final r = await (_db.selectOnly(
      _db.restaurantTables,
    )..addColumns([max])).getSingle();
    return (r.read(max) ?? -1) + 1;
  }

  Future<List<String>> _tableIdsInArea(String areaId) async {
    final rows = await (_db.select(
      _db.restaurantTables,
    )..where((t) => t.areaId.equals(areaId))).get();
    return rows.map((r) => r.id).toList();
  }

  Future<int> _activeOrderCount({required List<String> areaTables}) async {
    if (areaTables.isEmpty) return 0;
    final rows =
        await (_db.select(_db.orders)..where(
              (o) =>
                  o.tableId.isIn(areaTables) &
                  o.status.isIn([OrderStatus.open.name, OrderStatus.held.name]),
            ))
            .get();
    return rows.length;
  }
}
