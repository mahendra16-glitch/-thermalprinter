import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/util/clock.dart';
import '../../domain/staff/staff_models.dart';
import 'app_database.steps.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The single local database. It is the source of truth for all POS data.
///
/// Schema history (bump [schemaVersion] and add a step in [migration] for
/// every change; never edit a released step):
/// - v1: migration_log, app_settings, business_profiles, printer_profiles,
///   print_jobs, print_history, audit_log.
/// - v2: tax_profiles, kitchen_stations, menu_categories, menu_items,
///   option_groups, option_choices, item_option_groups.
/// - v3: dining_areas, restaurant_tables, orders, order_lines,
///   order_line_options.
/// - v4: printer_profiles print-setting columns; station_printers,
///   kitchen_tickets, kitchen_ticket_lines.
/// - v5: bills, bill_lines, bill_taxes.
/// - v6: payments (ledger); orders.due_note.
/// - v7: cash_shifts, cash_movements, expenses; payments.shift_id.
/// - v8: staff_users, role_permissions (seeded with the default roles);
///   staff_id on payments, cash_movements, expenses; opened_by_id and
///   closed_by_id on cash_shifts.
/// - v9: stock_items, stock_movements, recipe_lines; the manager role gets
///   the new manageInventory permission.
@DriftDatabase(
  tables: [
    MigrationLog,
    AppSettings,
    BusinessProfiles,
    PrinterProfiles,
    PrintJobs,
    PrintHistory,
    AuditLog,
    TaxProfiles,
    KitchenStations,
    MenuCategories,
    MenuItems,
    OptionGroups,
    OptionChoices,
    ItemOptionGroups,
    DiningAreas,
    RestaurantTables,
    Orders,
    OrderLines,
    OrderLineOptions,
    StationPrinters,
    KitchenTickets,
    KitchenTicketLines,
    Bills,
    BillLines,
    BillTaxes,
    Payments,
    CashShifts,
    CashMovements,
    Expenses,
    StaffUsers,
    RolePermissions,
    StockItems,
    StockMovements,
    RecipeLines,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static const String fileName = 'pos.db';

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedV1();
      await _logMigration(1, 'initial schema');
      await _logMigration(2, 'menu tables (fresh install)');
      await _logMigration(3, 'tables and orders (fresh install)');
      await _logMigration(4, 'kitchen tickets (fresh install)');
      await _logMigration(5, 'bills (fresh install)');
      await _logMigration(6, 'payments (fresh install)');
      await _logMigration(7, 'shifts and expenses (fresh install)');
      await _seedRolePermissions();
      await _logMigration(8, 'staff and permissions (fresh install)');
      await _logMigration(9, 'inventory (fresh install)');
    },
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.taxProfiles);
        await m.createTable(schema.kitchenStations);
        await m.createTable(schema.menuCategories);
        await m.createTable(schema.menuItems);
        await m.createTable(schema.optionGroups);
        await m.createTable(schema.optionChoices);
        await m.createTable(schema.itemOptionGroups);
        await m.createIndex(schema.idxMenuCategoriesParent);
        await m.createIndex(schema.idxMenuItemsCategory);
        await m.createIndex(schema.idxMenuItemsSku);
        await m.createIndex(schema.idxOptionChoicesGroup);
        await _logMigration(2, 'menu tables');
      },
      from2To3: (m, schema) async {
        await m.createTable(schema.diningAreas);
        await m.createTable(schema.restaurantTables);
        await m.createTable(schema.orders);
        await m.createTable(schema.orderLines);
        await m.createTable(schema.orderLineOptions);
        await m.createIndex(schema.idxRestaurantTablesArea);
        await m.createIndex(schema.idxOrdersStatus);
        await m.createIndex(schema.idxOrdersBusinessDate);
        await m.createIndex(schema.idxOrdersTable);
        await m.createIndex(schema.idxOrdersDayNumber);
        await m.createIndex(schema.idxOrderLinesOrder);
        await m.createIndex(schema.idxOrderLineOptionsLine);
        await _logMigration(3, 'tables and orders');
      },
      from3To4: (m, schema) async {
        final p = schema.printerProfiles;
        await m.addColumn(p, p.printableDots);
        await m.addColumn(p, p.charsPerLine);
        await m.addColumn(p, p.rasterThreshold);
        await m.addColumn(p, p.feedLines);
        await m.addColumn(p, p.autoCut);
        await m.createTable(schema.stationPrinters);
        await m.createTable(schema.kitchenTickets);
        await m.createTable(schema.kitchenTicketLines);
        await m.createIndex(schema.idxKitchenTicketsOrder);
        await m.createIndex(schema.idxKitchenTicketLinesTicket);
        await _logMigration(4, 'kitchen tickets, printer settings');
      },
      from4To5: (m, schema) async {
        await m.createTable(schema.bills);
        await m.createTable(schema.billLines);
        await m.createTable(schema.billTaxes);
        await m.createIndex(schema.idxBillsOrder);
        await m.createIndex(schema.idxBillsBusinessDate);
        await m.createIndex(schema.idxBillsPrefixSeq);
        await m.createIndex(schema.idxBillLinesBill);
        await m.createIndex(schema.idxBillTaxesBill);
        await _logMigration(5, 'bills');
      },
      from5To6: (m, schema) async {
        await m.addColumn(schema.orders, schema.orders.dueNote);
        await m.createTable(schema.payments);
        await m.createIndex(schema.idxPaymentsBill);
        await m.createIndex(schema.idxPaymentsOrder);
        await m.createIndex(schema.idxPaymentsBusinessDate);
        await _logMigration(6, 'payments');
      },
      from6To7: (m, schema) async {
        await m.addColumn(schema.payments, schema.payments.shiftId);
        await m.createTable(schema.cashShifts);
        await m.createTable(schema.cashMovements);
        await m.createTable(schema.expenses);
        await m.createIndex(schema.idxCashShiftsStatus);
        await m.createIndex(schema.idxCashMovementsShift);
        await m.createIndex(schema.idxExpensesBusinessDate);
        await m.createIndex(schema.idxExpensesShift);
        await _logMigration(7, 'shifts and expenses');
      },
      from7To8: (m, schema) async {
        await m.addColumn(schema.payments, schema.payments.staffId);
        await m.addColumn(schema.cashMovements, schema.cashMovements.staffId);
        await m.addColumn(schema.expenses, schema.expenses.staffId);
        await m.addColumn(schema.cashShifts, schema.cashShifts.openedById);
        await m.addColumn(schema.cashShifts, schema.cashShifts.closedById);
        await m.createTable(schema.staffUsers);
        await m.createTable(schema.rolePermissions);
        await _seedRolePermissions();
        await _logMigration(8, 'staff and permissions');
      },
      from8To9: (m, schema) async {
        await m.createTable(schema.stockItems);
        await m.createTable(schema.stockMovements);
        await m.createTable(schema.recipeLines);
        await m.createIndex(schema.idxStockMovementsItem);
        await m.createIndex(schema.idxStockMovementsOrderLine);
        await m.createIndex(schema.idxStockMovementsDate);
        await m.createIndex(schema.idxRecipeLinesItem);
        await m.createIndex(schema.idxRecipeLinesChoice);
        // Only the new permission: roles the owner changed stay as they are.
        await customInsert(
          'INSERT OR IGNORE INTO role_permissions (role, permission, '
          'updated_at) VALUES (?, ?, ?)',
          variables: [
            Variable.withString(StaffRole.manager.name),
            Variable.withString(Permission.manageInventory.name),
            Variable.withInt(Clock.nowMs()),
          ],
        );
        await _logMigration(9, 'inventory');
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedV1() async {
    await into(businessProfiles).insert(
      BusinessProfilesCompanion.insert(
        id: const Value(1),
        updatedAt: Clock.nowMs(),
      ),
    );
  }

  /// Default permissions for each role except the owner (who has all).
  Future<void> _seedRolePermissions() async {
    final now = Clock.nowMs();
    for (final e in defaultRolePermissions.entries) {
      for (final perm in e.value) {
        await customInsert(
          'INSERT OR IGNORE INTO role_permissions (role, permission, '
          'updated_at) VALUES (?, ?, ?)',
          variables: [
            Variable.withString(e.key.name),
            Variable.withString(perm.name),
            Variable.withInt(now),
          ],
        );
      }
    }
  }

  Future<void> _logMigration(int version, String notes) async {
    await into(migrationLog).insertOnConflictUpdate(
      MigrationLogCompanion.insert(
        version: Value(version),
        appliedAt: Clock.nowMs(),
        notes: Value(notes),
      ),
    );
  }
}

/// Absolute path of the on-device database file.
Future<String> posDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, AppDatabase.fileName);
}

/// Opens the on-device database on a background isolate.
Future<AppDatabase> openPosDatabase() async {
  final file = File(await posDatabasePath());
  return AppDatabase(NativeDatabase.createInBackground(file));
}
