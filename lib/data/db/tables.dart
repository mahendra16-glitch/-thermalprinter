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

// ---------------------------------------------------------------------------
// Schema v2: menu
// ---------------------------------------------------------------------------
// Nothing in the menu is ever hard-deleted: rows are deactivated, so past
// orders that point at them stay readable. Order lines (v3) will copy the
// name, price and tax at the time of sale.

/// A GST (or other) rate that can be attached to menu items.
@DataClassName('TaxProfileRow')
class TaxProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Rate in basis points: 5% = 500.
  IntColumn get rateBp => integer()();

  /// True when menu prices already include this tax.
  BoolColumn get isInclusive => boolean().withDefault(const Constant(false))();

  /// `TaxSplitMode.name`: none | cgstSgst | igst.
  TextColumn get splitMode => text().withDefault(const Constant('none'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where an item is prepared (Kitchen, Bar, …). Printer routing per station
/// is added with the KOT module.
@DataClassName('KitchenStationRow')
class KitchenStations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuCategoryRow')
@TableIndex(name: 'idx_menu_categories_parent', columns: {#parentId})
class MenuCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Set for a subcategory. Only one level of nesting is allowed.
  TextColumn get parentId => text().nullable().references(
    MenuCategories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MenuItemRow')
@TableIndex(name: 'idx_menu_items_category', columns: {#categoryId})
@TableIndex(name: 'idx_menu_items_sku', columns: {#sku})
class MenuItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId =>
      text().references(MenuCategories, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Short code, unique among items when set (checked in the repository).
  TextColumn get sku => text().nullable()();
  IntColumn get basePricePaise => integer()();

  /// Null means the item is not taxed.
  TextColumn get taxProfileId => text().nullable().references(
    TaxProfiles,
    #id,
    onDelete: KeyAction.restrict,
  )();

  /// `FoodType.name`: veg | nonVeg | egg | other.
  TextColumn get foodType => text().withDefault(const Constant('veg'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get availableDineIn =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get availableTakeaway =>
      boolean().withDefault(const Constant(true))();
  TextColumn get stationId => text().nullable().references(
    KitchenStations,
    #id,
    onDelete: KeyAction.restrict,
  )();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get prepMinutes => integer().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A reusable group of choices: a variant group (e.g. Size, pick exactly
/// one) or an add-on group (e.g. Extra toppings, pick up to 3).
@DataClassName('OptionGroupRow')
class OptionGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// `OptionGroupKind.name`: variant | addon.
  TextColumn get kind => text()();

  /// 0 = optional. 1 or more = that many choices are required.
  IntColumn get minSelect => integer().withDefault(const Constant(0))();

  /// 1 = single-select. Must be >= max(1, minSelect).
  IntColumn get maxSelect => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OptionChoiceRow')
@TableIndex(name: 'idx_option_choices_group', columns: {#groupId})
class OptionChoices extends Table {
  TextColumn get id => text()();
  TextColumn get groupId =>
      text().references(OptionGroups, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();

  /// Added to the item's base price when chosen (may be 0).
  IntColumn get priceDeltaPaise => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Which option groups an item offers, in display order.
@DataClassName('ItemOptionGroupRow')
class ItemOptionGroups extends Table {
  TextColumn get itemId =>
      text().references(MenuItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get groupId =>
      text().references(OptionGroups, #id, onDelete: KeyAction.restrict)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {itemId, groupId};
}
