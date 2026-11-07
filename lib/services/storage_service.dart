import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/security/pin_hasher.dart';
import '../data/db/app_database.dart';
import '../data/legacy/legacy_prefs_importer.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/business_profile_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/kitchen_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/print_job_repository.dart';
import '../data/repositories/printer_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/table_repository.dart';
import 'backup_service.dart';
import '../domain/staff/staff_session.dart';
import '../models/print_history_item.dart';
import '../models/print_mode.dart';
import '../models/printer_device.dart';

/// App-wide access to local data. Backed by the SQLite database
/// ([AppDatabase]); the method names are kept from the earlier
/// SharedPreferences version so existing screens did not change.
class StorageService {
  static StorageService? _instance;
  static Future<StorageService>? _opening;

  final AppDatabase db;

  /// Who is signed in (see [StaffRepository]).
  final StaffSession session = StaffSession();
  late final AuditRepository audit = AuditRepository(db, session);
  late final SettingsRepository settings = SettingsRepository(db, audit);
  late final StaffRepository staff = StaffRepository(
    db,
    audit,
    settings,
    hasher: _pinHasher,
  );
  final PinHasher? _pinHasher;
  late final PrinterRepository printers = PrinterRepository(db, audit);
  late final PrintJobRepository printJobs = PrintJobRepository(db);
  late final BusinessProfileRepository businessProfile =
      BusinessProfileRepository(db, audit);
  late final MenuRepository menu = MenuRepository(db, audit);
  late final TableRepository tables = TableRepository(db, audit);
  late final OrderRepository orders = OrderRepository(db, audit, settings);
  late final InventoryRepository inventory = InventoryRepository(
    db,
    audit,
    settings,
    orders,
  );
  late final KitchenRepository kitchen = KitchenRepository(
    db,
    audit,
    printJobs,
    inventory: inventory,
  );
  late final BillRepository bills = BillRepository(
    db,
    audit,
    settings,
    orders,
    businessProfile,
    printJobs,
    inventory: inventory,
  );
  late final ShiftRepository shifts = ShiftRepository(
    db,
    audit,
    orders,
    businessProfile,
    printJobs,
  );
  late final PaymentRepository payments = PaymentRepository(
    db,
    audit,
    orders,
    bills,
    businessProfile,
    printJobs,
  );
  late final ReportRepository reports = ReportRepository(
    db,
    audit,
    businessProfile,
    shifts,
    printJobs,
  );

  /// Set when the one-time import of pre-database data failed. The legacy
  /// data is untouched and the import is retried on the next launch.
  String? legacyImportError;

  /// Set when a restore was applied (or failed) at this start-up.
  RestoreOutcome? restoreOutcome;

  StorageService._(this.db, [this._pinHasher]);

  /// Uses [db] directly (tests). Does not run the legacy import.
  @visibleForTesting
  /// PINs are hashed with a light [PinHasher] on the calling isolate so
  /// widget tests stay fast and do not wait on isolates.
  factory StorageService.forTesting(AppDatabase db, {PinHasher? pinHasher}) {
    final s = StorageService._(
      db,
      pinHasher ?? const PinHasher(iterations: 1000, useIsolate: false),
    );
    _instance = s;
    return s;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    _opening = null;
  }

  /// The opened instance, or null before [getInstance] has finished.
  static StorageService? get maybeInstance => _instance;

  static Future<StorageService> getInstance() {
    final existing = _instance;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open();
  }

  static Future<StorageService> _open() async {
    // A restore chosen on the Backup screen is applied here, before the
    // database is opened (see BackupService.applyPendingRestore).
    RestoreOutcome? restore;
    try {
      restore = await BackupService.applyPendingRestore(
        dbPath: await posDatabasePath(),
        backupDir: await BackupService.defaultBackupDirectory(),
        maxVersion: AppDatabase.currentSchemaVersion,
      );
    } catch (e) {
      restore = RestoreOutcome(
        false,
        'The restore was not done ($e). Your current data is unchanged.',
      );
    }
    final s = StorageService._(await openPosDatabase());
    s.restoreOutcome = restore;
    if (restore != null) {
      await s.audit.record(
        action: restore.ok ? 'backup.restored' : 'backup.restore_failed',
        entity: 'database',
        details: {'message': restore.message, ...restore.details},
      );
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await LegacyPrefsImporter(s.db, prefs).run();
    } catch (e) {
      s.legacyImportError = e.toString();
      debugPrint('Legacy import failed: $e');
    }
    await s.staff.init();
    _instance = s;
    return s;
  }

  // --- Saved Printers ---

  Future<List<PrinterDevice>> getSavedPrinters() => printers.getAll();

  Future<void> savePrinter(PrinterDevice printer) => printers.save(printer);

  Future<void> deletePrinter(String printerId) async {
    await db.transaction(() async {
      await printers.delete(printerId);
      if (await settings.getFallbackPrinterId() == printerId) {
        await settings.setFallbackPrinterId(null);
      }
    });
  }

  /// The printer for [role]; otherwise the configured fallback printer;
  /// otherwise null (the caller must report that no printer is assigned).
  Future<PrinterDevice?> getPrinterForRole(PrinterRole role) async {
    final direct = await printers.getFirstForRole(role);
    if (direct != null) return direct;
    // "KOT" and "Kitchen" printers both take kitchen tickets.
    if (role == PrinterRole.kot || role == PrinterRole.kitchen) {
      final other = await printers.getFirstForRole(
        role == PrinterRole.kot ? PrinterRole.kitchen : PrinterRole.kot,
      );
      if (other != null) return other;
    }
    final fallbackId = await settings.getFallbackPrinterId();
    if (fallbackId == null) return null;
    return printers.getById(fallbackId);
  }

  // --- Print Mode ---

  Future<PrintMode> getPrintMode() => settings.getPrintMode();

  Future<void> setPrintMode(PrintMode mode) => settings.setPrintMode(mode);

  // --- Print History ---

  Future<List<PrintHistoryItem>> getHistory({int? limit}) =>
      printJobs.getHistory(limit: limit);

  Future<void> addHistoryItem(PrintHistoryItem item, {String? jobId}) =>
      printJobs.addHistory(item, jobId: jobId);

  Future<void> clearHistory() async {
    await db.transaction(() async {
      await printJobs.clearHistory();
      await audit.record(
        action: 'print_history.cleared',
        entity: 'print_history',
      );
    });
  }
}
