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

  // v4: print settings. Null means "use the default for the paper width".
  /// Printable width in dots (often 384 for 58mm, 576 for 80mm; some
  /// 80mm printers use 512).
  IntColumn get printableDots => integer().nullable()();

  /// Characters per line in text mode (32 / 42 / 48 …).
  IntColumn get charsPerLine => integer().nullable()();

  /// Luminance below which a raster pixel prints black (80–220).
  IntColumn get rasterThreshold => integer().nullable()();

  /// Blank lines fed before cutting (0–10).
  IntColumn get feedLines => integer().nullable()();

  /// Whether to send the cut command.
  BoolColumn get autoCut => boolean().withDefault(const Constant(true))();
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

// ---------------------------------------------------------------------------
// Schema v3: dining areas, tables, orders
// ---------------------------------------------------------------------------

@DataClassName('DiningAreaRow')
class DiningAreas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RestaurantTableRow')
@TableIndex(name: 'idx_restaurant_tables_area', columns: {#areaId})
class RestaurantTables extends Table {
  TextColumn get id => text()();
  TextColumn get areaId =>
      text().references(DiningAreas, #id, onDelete: KeyAction.restrict)();
  TextColumn get label => text()();
  IntColumn get seats => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A customer order. Orders are never deleted: cancelled orders keep their
/// lines and reason.
@DataClassName('OrderRow')
@TableIndex(name: 'idx_orders_status', columns: {#status})
@TableIndex(name: 'idx_orders_business_date', columns: {#businessDate})
@TableIndex(name: 'idx_orders_table', columns: {#tableId})
@TableIndex(
  name: 'idx_orders_day_number',
  columns: {#businessDate, #orderNo},
  unique: true,
)
class Orders extends Table {
  TextColumn get id => text()();

  /// Human number, sequential per business day (1, 2, 3, …).
  IntColumn get orderNo => integer()();

  /// Local business date `yyyy-MM-dd` (see the business-day start setting).
  TextColumn get businessDate => text()();

  /// `OrderType.name`: dineIn | takeaway | delivery.
  TextColumn get orderType => text()();
  TextColumn get tableId => text().nullable().references(
    RestaurantTables,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  TextColumn get customerPhone => text().withDefault(const Constant(''))();
  IntColumn get guests => integer().nullable()();
  TextColumn get staffId => text().nullable()();
  TextColumn get staffName => text().withDefault(const Constant(''))();

  /// `OrderStatus.name`.
  TextColumn get status => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// `DiscountKind.name`: none | percent | amount.
  TextColumn get discountKind => text().withDefault(const Constant('none'))();

  /// Basis points for percent, paise for amount.
  IntColumn get discountValue => integer().withDefault(const Constant(0))();
  TextColumn get discountReason => text().withDefault(const Constant(''))();
  TextColumn get cancelReason => text().withDefault(const Constant(''))();

  /// v6: why a billed order was closed with money still due.
  TextColumn get dueNote => text().withDefault(const Constant(''))();

  /// Set by the device that created the order; a repeated create with the
  /// same id returns the existing order instead of making a duplicate.
  TextColumn get clientRequestId => text().unique()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get closedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One item on an order. Name, price, options and tax are copied from the
/// menu when the line is added, so menu edits never change past orders.
@DataClassName('OrderLineRow')
@TableIndex(name: 'idx_order_lines_order', columns: {#orderId})
class OrderLines extends Table {
  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.restrict)();

  /// Reference only; the snapshot columns below are what is billed.
  TextColumn get menuItemId => text().nullable().references(
    MenuItems,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get itemName => text()();
  TextColumn get variantText => text().withDefault(const Constant(''))();
  IntColumn get basePricePaise => integer()();

  /// Base price plus all chosen options, for one unit.
  IntColumn get unitPricePaise => integer()();
  TextColumn get taxProfileId => text().nullable()();
  IntColumn get taxRateBp => integer().withDefault(const Constant(0))();
  BoolColumn get taxInclusive => boolean().withDefault(const Constant(false))();
  TextColumn get taxSplitMode => text().withDefault(const Constant('none'))();
  TextColumn get stationId => text().nullable()();
  IntColumn get qty => integer()();

  /// Units already sent to the kitchen (KOT module). Quantity can never go
  /// below this; sent units must be voided instead.
  IntColumn get sentQty => integer().withDefault(const Constant(0))();
  IntColumn get voidedQty => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderLineOptionRow')
@TableIndex(name: 'idx_order_line_options_line', columns: {#lineId})
class OrderLineOptions extends Table {
  TextColumn get id => text()();
  TextColumn get lineId =>
      text().references(OrderLines, #id, onDelete: KeyAction.cascade)();
  TextColumn get groupId => text()();
  TextColumn get groupName => text()();

  /// `OptionGroupKind.name`.
  TextColumn get kind => text()();
  TextColumn get choiceId => text()();
  TextColumn get name => text()();
  IntColumn get priceDeltaPaise => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Schema v4: kitchen tickets (KOT) and station routing
// ---------------------------------------------------------------------------

/// Which printers receive KOTs for a station. `stationId` is
/// [StationPrinters.defaultStation] for items that have no station.
@DataClassName('StationPrinterRow')
class StationPrinters extends Table {
  static const String defaultStation = '__default__';

  TextColumn get stationId => text()();
  TextColumn get printerId => text()();

  @override
  Set<Column> get primaryKey => {stationId, printerId};
}

/// One kitchen ticket: the units of an order sent to one station at one
/// time ("round"), or a void of units already sent.
@DataClassName('KitchenTicketRow')
@TableIndex(name: 'idx_kitchen_tickets_order', columns: {#orderId})
class KitchenTickets extends Table {
  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.restrict)();

  /// Station id, or [StationPrinters.defaultStation].
  TextColumn get stationId => text()();
  TextColumn get stationName => text()();

  /// 1 for the first send of an order, 2 for the next, … (per order).
  IntColumn get roundNo => integer()();

  /// `KitchenTicketKind.name`: send | voided.
  TextColumn get kind => text()();
  TextColumn get reason => text().withDefault(const Constant(''))();

  /// Ties the ticket to the staff action that created it, so a retried
  /// action cannot create it twice.
  TextColumn get clientRequestId => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KitchenTicketLineRow')
@TableIndex(name: 'idx_kitchen_ticket_lines_ticket', columns: {#ticketId})
class KitchenTicketLines extends Table {
  TextColumn get id => text()();
  TextColumn get ticketId =>
      text().references(KitchenTickets, #id, onDelete: KeyAction.restrict)();
  TextColumn get orderLineId =>
      text().references(OrderLines, #id, onDelete: KeyAction.restrict)();
  IntColumn get qty => integer()();

  /// Printed text, copied at send time.
  TextColumn get itemName => text()();
  TextColumn get addonsText => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Schema v5: bills
// ---------------------------------------------------------------------------
// A bill is finalized once and never edited. Correcting it means voiding it
// (with a reason) and generating a new bill with a new number. Payment
// status is derived from the payment ledger (Phase 6), not stored here.

@DataClassName('BillRow')
@TableIndex(name: 'idx_bills_order', columns: {#orderId})
@TableIndex(name: 'idx_bills_business_date', columns: {#businessDate})
@TableIndex(
  name: 'idx_bills_prefix_seq',
  columns: {#billPrefix, #billSeq},
  unique: true,
)
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.restrict)();

  /// Bill number = prefix + sequence. Each prefix has its own sequence.
  TextColumn get billPrefix => text().withDefault(const Constant(''))();
  IntColumn get billSeq => integer()();
  TextColumn get billNumber => text().unique()();
  TextColumn get businessDate => text()();

  /// `BillStatus.name`: finalized | voided.
  TextColumn get status => text()();

  // Copies of order details at billing time.
  IntColumn get orderNo => integer()();
  TextColumn get orderType => text()();
  TextColumn get tableLabel => text().withDefault(const Constant(''))();
  TextColumn get customerName => text().withDefault(const Constant(''))();
  TextColumn get customerPhone => text().withDefault(const Constant(''))();
  TextColumn get staffName => text().withDefault(const Constant(''))();

  /// `BillHeader` JSON: business name, address, GSTIN… at billing time.
  TextColumn get headerJson => text()();

  IntColumn get itemsTotalPaise => integer()();
  IntColumn get discountPaise => integer()();
  TextColumn get discountLabel => text().withDefault(const Constant(''))();
  IntColumn get serviceChargePaise => integer()();
  IntColumn get serviceChargeBp => integer().withDefault(const Constant(0))();

  /// All tax, inclusive and exclusive.
  IntColumn get taxPaise => integer()();
  IntColumn get roundOffPaise => integer()();
  IntColumn get grandTotalPaise => integer()();

  /// `RoundingMode.name` used for this bill.
  TextColumn get rounding => text()();

  /// `BillingSettings` JSON used for this bill.
  TextColumn get settingsJson => text()();
  TextColumn get clientRequestId => text().unique()();
  IntColumn get createdAt => integer()();
  IntColumn get voidedAt => integer().nullable()();
  TextColumn get voidReason => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillLineRow')
@TableIndex(name: 'idx_bill_lines_bill', columns: {#billId})
class BillLines extends Table {
  TextColumn get id => text()();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.restrict)();
  TextColumn get orderLineId =>
      text().references(OrderLines, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get variantText => text().withDefault(const Constant(''))();
  TextColumn get addonsText => text().withDefault(const Constant(''))();
  IntColumn get qty => integer()();
  IntColumn get unitPricePaise => integer()();
  IntColumn get grossPaise => integer()();

  /// This line's share of the order discount.
  IntColumn get discountPaise => integer()();
  IntColumn get taxRateBp => integer()();
  BoolColumn get taxInclusive => boolean()();
  TextColumn get taxSplitMode => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tax per rate group on a bill (the printed tax breakdown).
@DataClassName('BillTaxRow')
@TableIndex(name: 'idx_bill_taxes_bill', columns: {#billId})
class BillTaxes extends Table {
  TextColumn get id => text()();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.restrict)();

  /// `TaxBase.name`: items | serviceCharge.
  TextColumn get base => text()();
  IntColumn get rateBp => integer()();
  BoolColumn get inclusive => boolean()();
  TextColumn get splitMode => text()();
  IntColumn get taxablePaise => integer()();
  IntColumn get cgstPaise => integer().withDefault(const Constant(0))();
  IntColumn get sgstPaise => integer().withDefault(const Constant(0))();
  IntColumn get igstPaise => integer().withDefault(const Constant(0))();
  IntColumn get otherPaise => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Schema v6: payment ledger
// ---------------------------------------------------------------------------
// Ledger entries are never updated or deleted. A mistaken or refunded
// payment is undone by a separate `reversal` entry pointing at it. What a
// bill has received is always the sum of its entries.

@DataClassName('PaymentRow')
@TableIndex(name: 'idx_payments_bill', columns: {#billId})
@TableIndex(name: 'idx_payments_order', columns: {#orderId})
@TableIndex(name: 'idx_payments_business_date', columns: {#businessDate})
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.restrict)();
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.restrict)();

  /// `PaymentKind.name`: payment | reversal.
  TextColumn get kind => text()();

  /// `PaymentMethod.name`: cash | upi | card | other.
  TextColumn get method => text()();

  /// Name of an "other" method (e.g. "Swiggy"), otherwise empty.
  TextColumn get methodName => text().withDefault(const Constant(''))();

  /// Always positive. A reversal subtracts this amount.
  IntColumn get amountPaise => integer()();

  /// Cash handed over and change returned (cash payments only).
  IntColumn get tenderedPaise => integer().nullable()();
  IntColumn get changePaise => integer().nullable()();

  /// UPI transaction id, card slip number, …
  TextColumn get reference => text().withDefault(const Constant(''))();

  /// How the money was confirmed. UPI/card/other are always
  /// `staffConfirmed`: the app cannot see the bank.
  TextColumn get confirmation => text().withDefault(const Constant(''))();

  /// For a reversal: the payment it undoes (one reversal per payment).
  TextColumn get reversesPaymentId => text().nullable().unique().references(
    Payments,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get staffName => text().withDefault(const Constant(''))();

  /// Business date the money moved (for shift and day totals).
  TextColumn get businessDate => text()();
  TextColumn get clientRequestId => text().unique()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
