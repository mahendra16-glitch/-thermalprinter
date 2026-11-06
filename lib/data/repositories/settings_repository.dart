import '../../core/util/clock.dart';
import '../../models/print_mode.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';

/// Typed access to the `app_settings` key/value table.
class SettingsRepository {
  final AppDatabase _db;
  final AuditRepository _audit;

  SettingsRepository(this._db, this._audit);

  static const String keyPrintMode = 'print_mode';
  static const String keyFallbackPrinterId = 'fallback_printer_id';
  static const String keyLegacyImportV1 = 'legacy_prefs_import_v1';

  Future<String?> getRaw(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Writes a value. Pass null to delete the key.
  Future<void> setRaw(String key, String? value, {bool audit = true}) {
    return _db.transaction(() async {
      final before = await getRaw(key);
      if (value == null) {
        await (_db.delete(
          _db.appSettings,
        )..where((t) => t.key.equals(key))).go();
      } else {
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: Clock.nowMs(),
              ),
            );
      }
      if (audit && before != value) {
        await _audit.record(
          action: 'setting.changed',
          entity: 'app_settings',
          entityId: key,
          details: {'from': before, 'to': value},
        );
      }
    });
  }

  Future<PrintMode> getPrintMode() async {
    final raw = await getRaw(keyPrintMode);
    return PrintMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => PrintMode.compatibilityMode,
    );
  }

  Future<void> setPrintMode(PrintMode mode) => setRaw(keyPrintMode, mode.name);

  /// Printer used when no printer is assigned to a job's role. Null means
  /// "no fallback": such jobs fail with a clear message instead.
  Future<String?> getFallbackPrinterId() => getRaw(keyFallbackPrinterId);

  Future<void> setFallbackPrinterId(String? printerId) =>
      setRaw(keyFallbackPrinterId, printerId);

  /// Watches the value of a single key.
  Stream<String?> watchRaw(String key) {
    return (_db.select(_db.appSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }
}
