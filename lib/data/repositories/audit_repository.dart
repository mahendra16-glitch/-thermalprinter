import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../db/app_database.dart';

/// Append-only audit trail. Call [record] inside the same transaction as the
/// change it describes so the two can never disagree.
class AuditRepository {
  final AppDatabase _db;

  AuditRepository(this._db);

  Future<void> record({
    required String action,
    required String entity,
    String? entityId,
    Map<String, Object?>? details,
    String? staffId,
  }) {
    return _db
        .into(_db.auditLog)
        .insert(
          AuditLogCompanion.insert(
            id: newId(),
            at: Clock.nowMs(),
            action: action,
            entity: entity,
            entityId: Value(entityId),
            staffId: Value(staffId),
            detailsJson: Value(details == null ? null : jsonEncode(details)),
          ),
        );
  }

  Future<List<AuditLogRow>> recent({int limit = 100}) {
    return (_db.select(_db.auditLog)
          ..orderBy([
            (t) => OrderingTerm.desc(t.at),
            (t) => OrderingTerm.desc(t.rowId),
          ])
          ..limit(limit))
        .get();
  }
}
