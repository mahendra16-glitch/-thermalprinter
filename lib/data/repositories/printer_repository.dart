import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';

class PrinterRepository {
  final AppDatabase _db;
  final AuditRepository _audit;

  PrinterRepository(this._db, this._audit);

  Future<List<PrinterDevice>> getAll() async {
    final rows =
        await (_db.select(_db.printerProfiles)..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
            .get();
    return rows.map(fromRow).toList();
  }

  Future<PrinterDevice?> getById(String id) async {
    final row = await (_db.select(
      _db.printerProfiles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : fromRow(row);
  }

  /// First saved printer whose role is [role], or null.
  Future<PrinterDevice?> getFirstForRole(PrinterRole role) async {
    for (final p in await getAll()) {
      if (p.role == role) return p;
    }
    return null;
  }

  /// Inserts or updates a printer, keeping its id, order and creation time.
  Future<void> save(PrinterDevice printer) {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.printerProfiles,
      )..where((t) => t.id.equals(printer.id))).getSingleOrNull();
      final now = Clock.nowMs();
      await _db
          .into(_db.printerProfiles)
          .insertOnConflictUpdate(
            toCompanion(
              printer,
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
              sortOrder: existing?.sortOrder ?? await _nextSortOrder(),
            ),
          );
      await _audit.record(
        action: existing == null ? 'printer.created' : 'printer.updated',
        entity: 'printer_profiles',
        entityId: printer.id,
        details: _auditDetails(printer),
      );
    });
  }

  /// Updates only the connection-status columns. No audit entry: this is
  /// runtime state, not a configuration change.
  Future<void> updateStatus(PrinterDevice printer) {
    return (_db.update(
      _db.printerProfiles,
    )..where((t) => t.id.equals(printer.id))).write(
      PrinterProfilesCompanion(
        lastConnectedAt: Value(
          printer.lastConnected?.toUtc().millisecondsSinceEpoch,
        ),
        lastError: Value(printer.lastError),
      ),
    );
  }

  Future<void> delete(String id) {
    return _db.transaction(() async {
      final existing = await getById(id);
      if (existing == null) return;
      await (_db.delete(
        _db.printerProfiles,
      )..where((t) => t.id.equals(id))).go();
      await _audit.record(
        action: 'printer.deleted',
        entity: 'printer_profiles',
        entityId: id,
        details: _auditDetails(existing),
      );
    });
  }

  Future<int> _nextSortOrder() async {
    final max = _db.printerProfiles.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.printerProfiles,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  Map<String, Object?> _auditDetails(PrinterDevice p) => {
    'name': p.name,
    'connectionType': p.connectionType.name,
    'role': p.role.name,
    'paperWidth': p.paperWidth.name,
  };

  static PrinterDevice fromRow(PrinterProfileRow r) {
    return PrinterDevice(
      id: r.id,
      name: r.name,
      connectionType: ConnectionType.values.firstWhere(
        (e) => e.name == r.connectionType,
        orElse: () => ConnectionType.network,
      ),
      paperWidth: PaperWidth.values.firstWhere(
        (e) => e.name == r.paperWidth,
        orElse: () => PaperWidth.mm80,
      ),
      role: PrinterRole.values.firstWhere(
        (e) => e.name == r.role,
        orElse: () => PrinterRole.bill,
      ),
      macAddress: r.macAddress,
      vendorId: r.vendorId,
      productId: r.productId,
      deviceName: r.deviceName,
      ipAddress: r.ipAddress,
      port: r.port,
      lastConnected: r.lastConnectedAt == null
          ? null
          : Clock.toLocal(r.lastConnectedAt!),
      lastError: r.lastError,
    );
  }

  static PrinterProfilesCompanion toCompanion(
    PrinterDevice p, {
    required int createdAt,
    required int updatedAt,
    int sortOrder = 0,
  }) {
    return PrinterProfilesCompanion.insert(
      id: p.id,
      name: p.name,
      connectionType: p.connectionType.name,
      paperWidth: p.paperWidth.name,
      role: p.role.name,
      macAddress: Value(p.macAddress),
      vendorId: Value(p.vendorId),
      productId: Value(p.productId),
      deviceName: Value(p.deviceName),
      ipAddress: Value(p.ipAddress),
      port: Value(p.port),
      lastConnectedAt: Value(p.lastConnected?.toUtc().millisecondsSinceEpoch),
      lastError: Value(p.lastError),
      sortOrder: Value(sortOrder),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
