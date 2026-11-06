import 'package:drift/drift.dart';

// Conventions (see docs/IMPLEMENTATION_PLAN.md §6):
// - Primary keys are text UUIDs (legacy printer ids are kept as-is).
// - Timestamps are UTC epoch milliseconds (`*_at` columns).
// - Money, when it appears, is integer paise.

/// One row per applied schema version, written inside the migration.
@DataClassName('MigrationLogRow')
class MigrationLog extends Table {
  IntColumn get version => integer()();
  IntColumn get appliedAt => integer()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {version};
}

/// Typed key/value settings. Use `SettingsRepository` instead of raw access.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Single-row business profile (id is always 1). All fields start empty:
/// nothing is printed until the owner fills them in.
@DataClassName('BusinessProfileRow')
class BusinessProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get gstin => text().withDefault(const Constant(''))();
  TextColumn get fssai => text().withDefault(const Constant(''))();
  TextColumn get upiId => text().withDefault(const Constant(''))();
  TextColumn get billFooter => text().withDefault(const Constant(''))();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PrinterProfileRow')
class PrinterProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// `ConnectionType.name` (bluetooth | usb | network).
  TextColumn get connectionType => text()();

  /// `PaperWidth.name` (mm58 | mm80).
  TextColumn get paperWidth => text()();

  /// `PrinterRole.name`.
  TextColumn get role => text()();
  TextColumn get macAddress => text().nullable()();
  IntColumn get vendorId => integer().nullable()();
  IntColumn get productId => integer().nullable()();
  TextColumn get deviceName => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  IntColumn get port => integer().withDefault(const Constant(9100))();
  IntColumn get lastConnectedAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_print_jobs_status', columns: {#status})
@TableIndex(name: 'idx_print_jobs_source_key', columns: {#sourceKey})
@DataClassName('PrintJobRow')
class PrintJobs extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get printType => text()();
  TextColumn get targetRole => text()();
  TextColumn get targetPrinterId => text().nullable()();

  /// Identifies what is being printed (e.g. `KOT:1024`). Used to stop the
  /// same document being queued twice while a copy is still active.
  TextColumn get sourceKey => text()();

  /// `PosOrder.toJson()` snapshot, so the job can be re-printed exactly.
  TextColumn get payloadJson => text().nullable()();

  /// `PrintJobStatus.name`.
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get processedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per print attempt (successful or not). Printer name and type are
/// copied so the log stays readable after a printer is deleted.
@TableIndex(name: 'idx_print_history_at', columns: {#at})
@DataClassName('PrintHistoryRow')
class PrintHistory extends Table {
  TextColumn get id => text()();
  TextColumn get jobId => text().nullable()();
  IntColumn get at => integer()();
  TextColumn get printerName => text()();
  TextColumn get connectionType => text()();
  TextColumn get orderId => text()();
  TextColumn get printType => text()();
  BoolColumn get isSuccess => boolean()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_audit_log_at', columns: {#at})
@DataClassName('AuditLogRow')
class AuditLog extends Table {
  TextColumn get id => text()();
  IntColumn get at => integer()();
  TextColumn get staffId => text().nullable()();
  TextColumn get action => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get detailsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
