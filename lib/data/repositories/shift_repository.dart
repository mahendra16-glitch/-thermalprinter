import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/payments/payment_models.dart';
import '../../domain/shifts/shift_models.dart';
import '../../models/pos_order.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'business_profile_repository.dart';
import 'order_repository.dart';
import 'print_job_repository.dart';

/// Cash drawer shifts, cash added / taken out, and expenses.
///
/// One shift is open at a time. Cash payments and reversals are linked to
/// the shift open when they are recorded (see `PaymentRepository`); they
/// are never blocked when no shift is open. Cash expenses and cash
/// movements need an open shift, because they come out of the drawer.
///
/// Movements and expenses are cancelled with a reason (kept on record),
/// and only while their shift is open. A closed shift never changes.
class ShiftRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final OrderRepository _orders;
  final BusinessProfileRepository _profile;
  final PrintJobRepository _jobs;

  ShiftRepository(
    this._db,
    this._audit,
    this._orders,
    this._profile,
    this._jobs,
  );

  static const int maxAmountPaise = 100000000; // ₹10,00,000

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.cashShifts,
      _db.cashMovements,
      _db.expenses,
      _db.payments,
    ]),
  );

  // ------------------------------------------------------------------ read

  Future<CashShift?> currentShift() async {
    final r = await (_db.select(
      _db.cashShifts,
    )..where((s) => s.status.equals(ShiftStatus.open.name))).getSingleOrNull();
    return r == null ? null : _shift(r);
  }

  Future<CashShift?> getShift(String id) async {
    final r = await (_db.select(
      _db.cashShifts,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return r == null ? null : _shift(r);
  }

  /// Most recent shifts first.
  Future<List<CashShift>> recentShifts({int limit = 30}) async {
    final rows =
        await (_db.select(_db.cashShifts)
              ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
              ..limit(limit))
            .get();
    return rows.map(_shift).toList();
  }

  Future<List<CashMovement>> movementsFor(String shiftId) async {
    final rows =
        await (_db.select(_db.cashMovements)
              ..where((m) => m.shiftId.equals(shiftId))
              ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
            .get();
    return rows.map(_movement).toList();
  }

  Future<List<Expense>> expensesForShift(String shiftId) async {
    final rows =
        await (_db.select(_db.expenses)
              ..where((e) => e.shiftId.equals(shiftId))
              ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
            .get();
    return rows.map(_expense).toList();
  }

  Future<List<Expense>> expensesForDate(String businessDate) async {
    final rows =
        await (_db.select(_db.expenses)
              ..where((e) => e.businessDate.equals(businessDate))
              ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
            .get();
    return rows.map(_expense).toList();
  }

  /// Expenses (including cancelled ones) for business dates [from]…[to].
  Future<List<Expense>> expensesBetween(String from, String to) async {
    final rows =
        await (_db.select(_db.expenses)
              ..where((e) => e.businessDate.isBetweenValues(from, to))
              ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
            .get();
    return rows.map(_expense).toList();
  }

  /// Shifts opened on business dates [from]…[to], oldest first.
  Future<List<CashShift>> shiftsBetween(String from, String to) async {
    final rows =
        await (_db.select(_db.cashShifts)
              ..where((s) => s.businessDate.isBetweenValues(from, to))
              ..orderBy([(s) => OrderingTerm.asc(s.openedAt)]))
            .get();
    return rows.map(_shift).toList();
  }

  /// Categories used before, then the defaults, without duplicates.
  Future<List<String>> expenseCategories() async {
    final rows = await (_db.selectOnly(
      _db.expenses,
      distinct: true,
    )..addColumns([_db.expenses.category])).get();
    final used = rows.map((r) => r.read(_db.expenses.category)!).toList();
    final seen = <String>{};
    return [
      for (final c in [...defaultExpenseCategories, ...used])
        if (seen.add(c.toLowerCase())) c,
    ];
  }

  /// Cash payments recorded on [businessDate] while no shift was open.
  Future<Money> cashOutsideShifts(String businessDate) async {
    final rows =
        await (_db.select(_db.payments)..where(
              (p) =>
                  p.businessDate.equals(businessDate) &
                  p.shiftId.isNull() &
                  p.method.equals(PaymentMethod.cash.name),
            ))
            .get();
    return Money(
      rows.fold(
        0,
        (s, p) =>
            s +
            (p.kind == PaymentKind.reversal.name
                ? -p.amountPaise
                : p.amountPaise),
      ),
    );
  }

  /// Totals for a shift, calculated from its entries.
  Future<ShiftSummary> summary(String shiftId) async {
    final s = await _requireShift(shiftId);
    final pays = await (_db.select(
      _db.payments,
    )..where((p) => p.shiftId.equals(shiftId))).get();
    var cashSales = 0, cashRefunds = 0;
    final nonCash = <String, Money>{};
    final bills = <String>{};
    for (final p in pays) {
      final reversal = p.kind == PaymentKind.reversal.name;
      if (p.method == PaymentMethod.cash.name) {
        if (reversal) {
          cashRefunds += p.amountPaise;
        } else {
          cashSales += p.amountPaise;
        }
      } else {
        final method = PaymentMethodX.parse(p.method);
        final label = method == PaymentMethod.other && p.methodName.isNotEmpty
            ? p.methodName
            : method.label;
        nonCash[label] =
            (nonCash[label] ?? Money.zero) +
            Money(reversal ? -p.amountPaise : p.amountPaise);
      }
      if (!reversal) bills.add(p.billId);
    }
    var added = 0, takenOut = 0;
    for (final m in await movementsFor(shiftId)) {
      if (m.isVoided) continue;
      if (m.kind == CashMovementKind.addition) {
        added += m.amount.paise;
      } else {
        takenOut += m.amount.paise;
      }
    }
    var cashExp = 0, otherExp = 0;
    for (final e in await expensesForShift(shiftId)) {
      if (e.isVoided) continue;
      if (e.paidFrom == ExpenseSource.cash) {
        cashExp += e.amount.paise;
      } else {
        otherExp += e.amount.paise;
      }
    }
    return ShiftSummary(
      openingCash: Money(s.openingCashPaise),
      cashSales: Money(cashSales),
      cashRefunds: Money(cashRefunds),
      cashAdded: Money(added),
      cashTakenOut: Money(takenOut),
      cashExpenses: Money(cashExp),
      nonCash: nonCash,
      otherExpenses: Money(otherExp),
      paymentCount: pays
          .where((p) => p.kind != PaymentKind.reversal.name)
          .length,
      billCount: bills.length,
    );
  }

  // ------------------------------------------------------------------ open

  Future<String> open({
    required Money openingCash,
    required String staffName,
    String note = '',
    required String clientRequestId,
  }) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.cashShifts)
                ..where((s) => s.clientRequestId.equals(clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;
      if (await currentShift() != null) {
        throw ValidationException(
          'A shift is already open. Close it before opening a new one.',
        );
      }
      _checkAmount(openingCash, allowZero: true);
      final staff = _requireStaff(staffName);
      final id = newId();
      final now = Clock.nowMs();
      final date = await _orders.currentBusinessDate();
      await _db
          .into(_db.cashShifts)
          .insert(
            CashShiftsCompanion.insert(
              id: id,
              status: ShiftStatus.open.name,
              businessDate: date,
              openingCashPaise: openingCash.paise,
              openedBy: staff,
              openedById: Value(_audit.session.staffId),
              openNote: Value(note.trim()),
              openedAt: now,
              clientRequestId: clientRequestId,
            ),
          );
      await _audit.record(
        action: 'shift.opened',
        entity: 'cash_shifts',
        entityId: id,
        details: {
          'openingCashPaise': openingCash.paise,
          'by': staff,
          'businessDate': date,
          'note': note.trim(),
        },
      );
      return id;
    });
  }

  // ------------------------------------------------------------- movements

  Future<String> addMovement({
    required CashMovementKind kind,
    required Money amount,
    required String reason,
    String staffName = '',
    required String clientRequestId,
  }) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.cashMovements)
                ..where((m) => m.clientRequestId.equals(clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;
      final shift = await _requireOpenShift();
      _checkAmount(amount);
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason.');
      }
      if (kind == CashMovementKind.withdrawal) {
        final expected = (await summary(shift.id)).expectedCash;
        if (amount > expected) {
          throw ValidationException(
            'Only ${expected.format()} should be in the drawer.',
          );
        }
      }
      final id = newId();
      await _db
          .into(_db.cashMovements)
          .insert(
            CashMovementsCompanion.insert(
              id: id,
              shiftId: shift.id,
              kind: kind.name,
              amountPaise: amount.paise,
              reason: reason.trim(),
              staffName: Value(_name(staffName)),
              staffId: Value(_audit.session.staffId),
              createdAt: Clock.nowMs(),
              clientRequestId: clientRequestId,
            ),
          );
      await _audit.record(
        action: 'cash.${kind.name}',
        entity: 'cash_movements',
        entityId: id,
        details: {
          'shiftId': shift.id,
          'amountPaise': amount.paise,
          'reason': reason.trim(),
          'by': _name(staffName),
        },
      );
      return id;
    });
  }

  Future<void> voidMovement(String id, String reason) {
    return _db.transaction(() async {
      final m = await (_db.select(
        _db.cashMovements,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (m == null) throw ValidationException('Entry not found.');
      if (m.voidedAt != null) return;
      await _requireShiftOpen(m.shiftId);
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for cancelling.');
      }
      await (_db.update(
        _db.cashMovements,
      )..where((r) => r.id.equals(id))).write(
        CashMovementsCompanion(
          voidedAt: Value(Clock.nowMs()),
          voidReason: Value(reason.trim()),
        ),
      );
      await _audit.record(
        action: 'cash.movement_cancelled',
        entity: 'cash_movements',
        entityId: id,
        details: {
          'kind': m.kind,
          'amountPaise': m.amountPaise,
          'reason': reason.trim(),
        },
      );
    });
  }

  // -------------------------------------------------------------- expenses

  Future<String> recordExpense({
    required String category,
    required Money amount,
    required ExpenseSource paidFrom,
    String note = '',
    String staffName = '',
    required String clientRequestId,
  }) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.expenses)
                ..where((e) => e.clientRequestId.equals(clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;
      _checkAmount(amount);
      final cat = category.trim();
      if (cat.isEmpty) throw ValidationException('Choose a category.');
      if (cat.length > 40) {
        throw ValidationException('Category must be at most 40 characters.');
      }
      final shift = await currentShift();
      if (paidFrom == ExpenseSource.cash) {
        if (shift == null) {
          throw ValidationException(
            'Open a shift to pay an expense from the cash drawer.',
          );
        }
        final expected = (await summary(shift.id)).expectedCash;
        if (amount > expected) {
          throw ValidationException(
            'Only ${expected.format()} should be in the drawer.',
          );
        }
      }
      final id = newId();
      final date = await _orders.currentBusinessDate();
      await _db
          .into(_db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: id,
              shiftId: Value(shift?.id),
              category: cat,
              amountPaise: amount.paise,
              paidFrom: paidFrom.name,
              note: Value(note.trim()),
              staffName: Value(_name(staffName)),
              staffId: Value(_audit.session.staffId),
              businessDate: date,
              createdAt: Clock.nowMs(),
              clientRequestId: clientRequestId,
            ),
          );
      await _audit.record(
        action: 'expense.recorded',
        entity: 'expenses',
        entityId: id,
        details: {
          'category': cat,
          'amountPaise': amount.paise,
          'paidFrom': paidFrom.name,
          'shiftId': shift?.id,
          'note': note.trim(),
          'by': _name(staffName),
        },
      );
      return id;
    });
  }

  Future<void> voidExpense(String id, String reason) {
    return _db.transaction(() async {
      final e = await (_db.select(
        _db.expenses,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (e == null) throw ValidationException('Expense not found.');
      if (e.voidedAt != null) return;
      if (e.shiftId != null) await _requireShiftOpen(e.shiftId!);
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for cancelling.');
      }
      await (_db.update(_db.expenses)..where((r) => r.id.equals(id))).write(
        ExpensesCompanion(
          voidedAt: Value(Clock.nowMs()),
          voidReason: Value(reason.trim()),
        ),
      );
      await _audit.record(
        action: 'expense.cancelled',
        entity: 'expenses',
        entityId: id,
        details: {
          'category': e.category,
          'amountPaise': e.amountPaise,
          'reason': reason.trim(),
        },
      );
    });
  }

  // ----------------------------------------------------------------- close

  /// Closes the shift with the counted cash. A difference from the
  /// expected cash needs a reason. Returns the variance (+ over, − short).
  Future<Money> close(
    String shiftId, {
    required Money countedCash,
    required String staffName,
    String varianceReason = '',
    String note = '',
    Map<int, int>? denominations,
    bool print = true,
  }) {
    return _db.transaction(() async {
      final s = await _requireShift(shiftId);
      if (s.status != ShiftStatus.open.name) {
        throw ValidationException('This shift is already closed.');
      }
      _checkAmount(countedCash, allowZero: true);
      final staff = _requireStaff(staffName);
      final sum = await summary(shiftId);
      final variance = countedCash - sum.expectedCash;
      if (!variance.isZero && varianceReason.trim().isEmpty) {
        throw ValidationException(
          'The drawer is ${variance.isNegative ? 'short' : 'over'} by '
          '${Money(variance.paise.abs()).format()}. Enter a reason.',
        );
      }
      final now = Clock.nowMs();
      await (_db.update(
        _db.cashShifts,
      )..where((r) => r.id.equals(shiftId))).write(
        CashShiftsCompanion(
          status: Value(ShiftStatus.closed.name),
          closedAt: Value(now),
          closedBy: Value(staff),
          closedById: Value(_audit.session.staffId),
          countedCashPaise: Value(countedCash.paise),
          expectedCashPaise: Value(sum.expectedCash.paise),
          variancePaise: Value(variance.paise),
          varianceReason: Value(varianceReason.trim()),
          denominationsJson: Value(
            denominations == null
                ? null
                : jsonEncode({
                    for (final e in denominations.entries)
                      if (e.value > 0) '${e.key}': e.value,
                  }),
          ),
          summaryJson: Value(jsonEncode(sum.toJson())),
          closeNote: Value(note.trim()),
        ),
      );
      await _audit.record(
        action: 'shift.closed',
        entity: 'cash_shifts',
        entityId: shiftId,
        details: {
          'by': staff,
          'countedPaise': countedCash.paise,
          'expectedPaise': sum.expectedCash.paise,
          'variancePaise': variance.paise,
          'varianceReason': varianceReason.trim(),
        },
      );
      if (print) await _queueReport(shiftId);
      return variance;
    });
  }

  /// Prints the shift report (open: a running "X" report; closed: the
  /// closing report).
  Future<void> printReport(String shiftId) => _db.transaction(() async {
    await _queueReport(shiftId);
    await _audit.record(
      action: 'shift.report_printed',
      entity: 'cash_shifts',
      entityId: shiftId,
    );
  });

  /// The data printed on the shift report.
  Future<Map<String, Object?>> reportData(String shiftId) async {
    final s = (await getShift(shiftId))!;
    final row = await _requireShift(shiftId);
    final sum = s.isOpen || row.summaryJson == null
        ? await summary(shiftId)
        : ShiftSummary.fromJson(
            jsonDecode(row.summaryJson!) as Map<String, dynamic>,
          );
    final profile = await _profile.get();
    final movements = await movementsFor(shiftId);
    final expenses = await expensesForShift(shiftId);
    return {
      'business': profile.name,
      'open': s.isOpen,
      'businessDate': s.businessDate,
      'openedAt': s.openedAt.toIso8601String(),
      'openedBy': s.openedBy,
      'closedAt': s.closedAt?.toIso8601String(),
      'closedBy': s.closedBy,
      'summary': sum.toJson(),
      'counted': s.countedCash?.paise,
      'variance': s.variance?.paise,
      'varianceReason': s.varianceReason,
      'closeNote': s.closeNote,
      'denominations': row.denominationsJson == null
          ? null
          : jsonDecode(row.denominationsJson!),
      'movements': [
        for (final m in movements.where((m) => !m.isVoided))
          {
            'label': m.kind.label,
            'amount': m.kind == CashMovementKind.addition
                ? m.amount.paise
                : -m.amount.paise,
            'reason': m.reason,
          },
      ],
      'expenses': [
        for (final e in expenses.where((e) => !e.isVoided))
          {
            'category': e.category,
            'paidFrom': e.paidFrom.label,
            'amount': e.amount.paise,
            'note': e.note,
          },
      ],
    };
  }

  Future<void> _queueReport(String shiftId) async {
    final data = await reportData(shiftId);
    final pos = PosOrder(
      orderId: 'SHIFT',
      type: 'SHIFT_REPORT',
      printerRole: PrinterRole.bill,
      restaurantName: data['business'] as String? ?? '',
      items: const [],
      report: data,
    );
    await _jobs.upsertJob(
      PrintJob(
        id: newId(),
        orderId: 'SHIFT',
        printType: 'SHIFT_REPORT',
        targetRole: PrinterRole.bill,
        posOrderJson: pos.toJson(),
        sourceKey: 'SHIFT:$shiftId:${newId()}',
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  void _checkAmount(Money m, {bool allowZero = false}) {
    if (m.isNegative || (!allowZero && m.isZero)) {
      throw ValidationException('Enter an amount above ₹0.');
    }
    if (m.paise > maxAmountPaise) {
      throw ValidationException('That amount is too large.');
    }
  }

  /// The signed-in staff member's name, or (with staff login off) the
  /// name typed on the form.
  String _name(String typed) {
    final signed = _audit.session.staffName;
    return signed.isNotEmpty ? signed : typed.trim();
  }

  String _requireStaff(String name) {
    final n = _name(name);
    if (n.isEmpty) throw ValidationException('Enter your name.');
    return n;
  }

  Future<CashShift> _requireOpenShift() async {
    final s = await currentShift();
    if (s == null) {
      throw ValidationException('Open a shift first (Shift › Open shift).');
    }
    return s;
  }

  Future<void> _requireShiftOpen(String shiftId) async {
    final s = await _requireShift(shiftId);
    if (s.status != ShiftStatus.open.name) {
      throw ValidationException(
        'That shift is closed; its entries cannot change.',
      );
    }
  }

  Future<CashShiftRow> _requireShift(String id) async {
    final s = await (_db.select(
      _db.cashShifts,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (s == null) throw ValidationException('Shift not found.');
    return s;
  }

  static CashShift _shift(CashShiftRow r) => CashShift(
    id: r.id,
    status: r.status == ShiftStatus.closed.name
        ? ShiftStatus.closed
        : ShiftStatus.open,
    businessDate: r.businessDate,
    openingCash: Money(r.openingCashPaise),
    openedBy: r.openedBy,
    openNote: r.openNote,
    openedAt: Clock.toLocal(r.openedAt),
    closedAt: r.closedAt == null ? null : Clock.toLocal(r.closedAt!),
    closedBy: r.closedBy,
    countedCash: r.countedCashPaise == null ? null : Money(r.countedCashPaise!),
    expectedCash: r.expectedCashPaise == null
        ? null
        : Money(r.expectedCashPaise!),
    variance: r.variancePaise == null ? null : Money(r.variancePaise!),
    varianceReason: r.varianceReason,
    closeNote: r.closeNote,
  );

  static CashMovement _movement(CashMovementRow r) => CashMovement(
    id: r.id,
    shiftId: r.shiftId,
    kind: CashMovementKindX.parse(r.kind),
    amount: Money(r.amountPaise),
    reason: r.reason,
    staffName: r.staffName,
    createdAt: Clock.toLocal(r.createdAt),
    voidedAt: r.voidedAt == null ? null : Clock.toLocal(r.voidedAt!),
    voidReason: r.voidReason,
  );

  static Expense _expense(ExpenseRow r) => Expense(
    id: r.id,
    shiftId: r.shiftId,
    category: r.category,
    amount: Money(r.amountPaise),
    paidFrom: ExpenseSourceX.parse(r.paidFrom),
    note: r.note,
    staffName: r.staffName,
    businessDate: r.businessDate,
    createdAt: Clock.toLocal(r.createdAt),
    voidedAt: r.voidedAt == null ? null : Clock.toLocal(r.voidedAt!),
    voidReason: r.voidReason,
  );
}
