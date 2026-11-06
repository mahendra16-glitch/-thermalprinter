import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../models/pos_order.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'bill_repository.dart';
import 'business_profile_repository.dart';
import 'order_repository.dart';
import 'print_job_repository.dart';

class PaymentRequest {
  final String billId;
  final PaymentMethod method;

  /// Amount applied to the bill (never more than the balance).
  final Money amount;

  /// Cash handed over; the difference is change. Cash only.
  final Money? tendered;
  final String reference;

  /// Name for [PaymentMethod.other], e.g. "Zomato".
  final String methodName;

  /// Staff checked the money arrived (UPI app, card slip …). Required for
  /// every method except cash.
  final bool staffConfirmed;

  /// One id per "record payment" action; repeating it records nothing new.
  final String clientRequestId;

  const PaymentRequest({
    required this.billId,
    required this.method,
    required this.amount,
    this.tendered,
    this.reference = '',
    this.methodName = '',
    this.staffConfirmed = false,
    required this.clientRequestId,
  });
}

/// A billed order with money still owed.
class DueOrder {
  final Order order;
  final Bill bill;
  final BillPaymentSummary summary;

  const DueOrder(this.order, this.bill, this.summary);
}

/// Ledger entries of a bill, oldest first.
Future<List<LedgerEntry>> loadLedger(AppDatabase db, String billId) async {
  final rows =
      await (db.select(db.payments)
            ..where((p) => p.billId.equals(billId))
            ..orderBy([
              (p) => OrderingTerm.asc(p.createdAt),
              (p) => OrderingTerm.asc(p.rowId),
            ]))
          .get();
  return rows.map(ledgerEntryFromRow).toList();
}

/// Payment lines as printed on a bill.
List<BillPaymentLine> printedPaymentLines(List<LedgerEntry> entries) => [
  for (final e in entries)
    BillPaymentLine(
      '${e.isReversal ? 'Reversed' : 'Paid'} ${e.methodLabel}'
      '${e.method.needsStaffConfirmation && !e.isReversal ? ' (staff-confirmed)' : ''}',
      e.signedAmount,
      reference: e.reference,
    ),
];

LedgerEntry ledgerEntryFromRow(PaymentRow r) => LedgerEntry(
  id: r.id,
  billId: r.billId,
  orderId: r.orderId,
  kind: r.kind == PaymentKind.reversal.name
      ? PaymentKind.reversal
      : PaymentKind.payment,
  method: PaymentMethodX.parse(r.method),
  methodName: r.methodName,
  amount: Money(r.amountPaise),
  tendered: r.tenderedPaise == null ? null : Money(r.tenderedPaise!),
  change: r.changePaise == null ? null : Money(r.changePaise!),
  reference: r.reference,
  confirmation: r.confirmation,
  reversesPaymentId: r.reversesPaymentId,
  reason: r.reason,
  staffName: r.staffName,
  businessDate: r.businessDate,
  createdAt: Clock.toLocal(r.createdAt),
);

/// The payment ledger. Entries are only ever inserted: a payment is undone
/// by a reversal entry, never edited or deleted. Paid / part paid / unpaid
/// is always worked out from the entries.
///
/// The order follows the ledger: fully paid -> settled; a reversal on a
/// settled order -> due (the table stays free, the balance stays visible).
///
/// After printing a receipt, call `PrintQueueManager.syncFromStorage()`.
class PaymentRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final OrderRepository _orders;
  final BillRepository _bills;
  final BusinessProfileRepository _profile;
  final PrintJobRepository _jobs;

  PaymentRepository(
    this._db,
    this._audit,
    this._orders,
    this._bills,
    this._profile,
    this._jobs,
  );

  static const int maxReference = 50;

  // ------------------------------------------------------------------ read

  Future<BillPaymentSummary> summaryFor(String billId) async {
    final bill = await _requireBillRow(billId);
    return BillPaymentSummary(
      Money(bill.grandTotalPaise),
      await loadLedger(_db, billId),
    );
  }

  Future<LedgerEntry?> getEntry(String id) async {
    final r = await (_db.select(
      _db.payments,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return r == null ? null : ledgerEntryFromRow(r);
  }

  /// Ledger entries whose money moved on [businessDate], oldest first.
  Future<List<LedgerEntry>> entriesForDate(String businessDate) async {
    final rows =
        await (_db.select(_db.payments)
              ..where((p) => p.businessDate.equals(businessDate))
              ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
            .get();
    return rows.map(ledgerEntryFromRow).toList();
  }

  /// Billed and due orders that still owe money, oldest first.
  Future<List<DueOrder>> listDues() async {
    final rows =
        await (_db.select(_db.orders)
              ..where(
                (o) => o.status.isIn([
                  OrderStatus.billed.name,
                  OrderStatus.due.name,
                ]),
              )
              ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
            .get();
    final out = <DueOrder>[];
    for (final r in rows) {
      final bill = await _bills.currentBillFor(r.id);
      if (bill == null) continue;
      final s = BillPaymentSummary(
        bill.grandTotal,
        await loadLedger(_db, bill.id),
      );
      if (s.balance.paise <= 0) continue;
      final detail = await _orders.getDetail(r.id);
      out.add(DueOrder(detail!.order, bill, s));
    }
    return out;
  }

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.payments, _db.orders, _db.printJobs]),
  );

  // ---------------------------------------------------------------- record

  /// Records a payment and returns its id.
  Future<String> record(PaymentRequest r, {bool printReceipt = false}) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.payments)
                ..where((p) => p.clientRequestId.equals(r.clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;

      final bill = await _requireBillRow(r.billId);
      if (bill.status != BillStatus.finalized.name) {
        throw ValidationException('This bill was voided; it cannot be paid.');
      }
      final order = await _requireOrder(bill.orderId);
      final status = OrderStatusX.parse(order.status);
      if (status != OrderStatus.billed && status != OrderStatus.due) {
        throw ValidationException(
          'Order #${order.orderNo} is ${status.label.toLowerCase()}; no '
          'payment is due.',
        );
      }
      final summary = BillPaymentSummary(
        Money(bill.grandTotalPaise),
        await loadLedger(_db, bill.id),
      );
      final balance = summary.balance;
      if (balance.paise <= 0) {
        throw ValidationException('This bill is already fully paid.');
      }
      if (r.amount.paise <= 0) {
        throw ValidationException('Enter an amount above ₹0.');
      }
      if (r.amount > balance) {
        throw ValidationException(
          'The balance is ${balance.format()}. You cannot collect more than '
          'that.',
        );
      }
      final reference = r.reference.trim();
      if (reference.length > maxReference) {
        throw ValidationException(
          'Reference must be at most $maxReference characters.',
        );
      }
      final methodName = r.methodName.trim();
      if (r.method == PaymentMethod.other && methodName.isEmpty) {
        throw ValidationException('Enter the name of the payment method.');
      }
      if (r.method.needsStaffConfirmation && !r.staffConfirmed) {
        throw ValidationException(
          'Confirm that you checked the ${r.method.label} payment arrived '
          'before recording it.',
        );
      }
      Money? change;
      if (r.method == PaymentMethod.cash && r.tendered != null) {
        if (r.tendered! < r.amount) {
          throw ValidationException(
            'Cash received (${r.tendered!.format()}) is less than the amount '
            '(${r.amount.format()}).',
          );
        }
        change = r.tendered! - r.amount;
      } else if (r.tendered != null) {
        throw ValidationException('Cash received applies to cash only.');
      }

      final id = newId();
      final now = Clock.nowMs();
      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: id,
              billId: bill.id,
              orderId: bill.orderId,
              kind: PaymentKind.payment.name,
              method: r.method.name,
              methodName: Value(
                r.method == PaymentMethod.other ? methodName : '',
              ),
              amountPaise: r.amount.paise,
              tenderedPaise: Value(r.tendered?.paise),
              changePaise: Value(change?.paise),
              reference: Value(reference),
              confirmation: Value(
                r.method.needsStaffConfirmation ? staffConfirmed : '',
              ),
              shiftId: Value(await _openShiftId()),
              businessDate: await _orders.currentBusinessDate(),
              clientRequestId: r.clientRequestId,
              createdAt: now,
            ),
          );
      final newBalance = balance - r.amount;
      if (newBalance.isZero) {
        await _setOrderStatus(order.id, OrderStatus.settled, now);
      }
      final details = {
        'paymentId': id,
        'billId': bill.id,
        'billNumber': bill.billNumber,
        'method': r.method.name,
        if (methodName.isNotEmpty) 'methodName': methodName,
        'amountPaise': r.amount.paise,
        'tenderedPaise': r.tendered?.paise,
        'changePaise': change?.paise,
        'reference': reference,
        'confirmation': r.method.needsStaffConfirmation ? staffConfirmed : '',
        'balancePaise': newBalance.paise,
      };
      await _audit.record(
        action: 'order.payment_recorded',
        entity: 'orders',
        entityId: order.id,
        details: details,
      );
      await _audit.record(
        action: 'payment.recorded',
        entity: 'payments',
        entityId: id,
        details: details,
      );
      if (printReceipt) await _queueReceipt(id);
      return id;
    });
  }

  // --------------------------------------------------------------- reverse

  /// Undoes a payment (entered by mistake, or money given back) with a
  /// reason. The original entry is kept. Returns the reversal's id.
  Future<String> reverse(
    String paymentId, {
    required String reason,
    required String clientRequestId,
    bool printReceipt = false,
  }) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.payments)
                ..where((p) => p.clientRequestId.equals(clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;

      final p = await (_db.select(
        _db.payments,
      )..where((t) => t.id.equals(paymentId))).getSingleOrNull();
      if (p == null) throw ValidationException('Payment not found.');
      if (p.kind != PaymentKind.payment.name) {
        throw ValidationException('A reversal cannot be reversed.');
      }
      final already = await (_db.select(
        _db.payments,
      )..where((t) => t.reversesPaymentId.equals(paymentId))).getSingleOrNull();
      if (already != null) {
        throw ValidationException('This payment was already reversed.');
      }
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for the reversal.');
      }
      final bill = await _requireBillRow(p.billId);
      final order = await _requireOrder(p.orderId);

      final id = newId();
      final now = Clock.nowMs();
      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: id,
              billId: p.billId,
              orderId: p.orderId,
              kind: PaymentKind.reversal.name,
              method: p.method,
              methodName: Value(p.methodName),
              amountPaise: p.amountPaise,
              reference: Value(p.reference),
              reversesPaymentId: Value(paymentId),
              reason: Value(reason.trim()),
              shiftId: Value(await _openShiftId()),
              businessDate: await _orders.currentBusinessDate(),
              clientRequestId: clientRequestId,
              createdAt: now,
            ),
          );
      final summary = BillPaymentSummary(
        Money(bill.grandTotalPaise),
        await loadLedger(_db, bill.id),
      );
      if (order.status == OrderStatus.settled.name &&
          summary.balance.paise > 0) {
        await _setOrderStatus(
          order.id,
          OrderStatus.due,
          now,
          dueNote: 'Payment reversed: ${reason.trim()}',
        );
      }
      final details = {
        'reversalId': id,
        'paymentId': paymentId,
        'billId': bill.id,
        'billNumber': bill.billNumber,
        'method': p.method,
        'amountPaise': p.amountPaise,
        'reason': reason.trim(),
        'balancePaise': summary.balance.paise,
      };
      await _audit.record(
        action: 'order.payment_reversed',
        entity: 'orders',
        entityId: order.id,
        details: details,
      );
      await _audit.record(
        action: 'payment.reversed',
        entity: 'payments',
        entityId: paymentId,
        details: details,
      );
      if (printReceipt) await _queueReceipt(id);
      return id;
    });
  }

  // ------------------------------------------------------------------- due

  /// Closes a billed order that still owes money: the table is freed and
  /// the balance stays in the dues list until paid. The order must name the
  /// customer (name or phone).
  Future<void> closeAsDue(String orderId, String note) {
    return _db.transaction(() async {
      final o = await _requireOrder(orderId);
      if (o.status != OrderStatus.billed.name) {
        throw ValidationException('Only a billed order can be moved to dues.');
      }
      if (o.customerName.trim().isEmpty && o.customerPhone.trim().isEmpty) {
        throw ValidationException(
          'Add the customer\'s name or phone first, so you know who owes it.',
        );
      }
      final bill = await _bills.currentBillFor(orderId);
      if (bill == null) throw ValidationException('No bill on this order.');
      final s = BillPaymentSummary(
        bill.grandTotal,
        await loadLedger(_db, bill.id),
      );
      if (s.balance.paise <= 0) {
        throw ValidationException('Nothing is due on this bill.');
      }
      await _setOrderStatus(
        orderId,
        OrderStatus.due,
        Clock.nowMs(),
        dueNote: note.trim(),
      );
      await _audit.record(
        action: 'order.moved_to_due',
        entity: 'orders',
        entityId: orderId,
        details: {
          'billId': bill.id,
          'billNumber': bill.billNumber,
          'balancePaise': s.balance.paise,
          'note': note.trim(),
        },
      );
    });
  }

  // ----------------------------------------------------------------- print

  /// Queues a receipt for one ledger entry (payment or reversal).
  Future<void> printReceipt(String entryId) => _db.transaction(() async {
    await _queueReceipt(entryId);
    final e = (await getEntry(entryId))!;
    await _audit.record(
      action: 'order.receipt_printed',
      entity: 'orders',
      entityId: e.orderId,
      details: {'paymentId': entryId},
    );
  });

  Future<void> _queueReceipt(String entryId) async {
    final e = await getEntry(entryId);
    if (e == null) throw ValidationException('Payment not found.');
    final bill = (await _bills.getBill(e.billId))!;
    // Ledger up to and including this entry.
    final all = await loadLedger(_db, e.billId);
    final upTo = all.sublist(0, all.indexWhere((x) => x.id == entryId) + 1);
    final printed = bill.withPrintExtras(payments: printedPaymentLines(upTo));
    final pos = PosOrder(
      orderId: '${bill.orderNo}',
      billNo: bill.billNumber,
      type: 'PAYMENT_RECEIPT',
      printerRole: PrinterRole.bill,
      restaurantName: bill.header.name,
      items: const [],
      timestamp: e.createdAt,
      bill: {
        ...printed.toJson(),
        'receipt': {
          'label': e.isReversal ? 'REFUND / REVERSAL' : 'PAYMENT RECEIPT',
          'method': e.methodLabel,
          'staffConfirmed': e.confirmation == staffConfirmed,
          'amount': e.signedAmount.paise,
          'tendered': e.tendered?.paise,
          'change': e.change?.paise,
          'reference': e.reference,
          'reason': e.reason,
          'at': e.createdAt.toIso8601String(),
        },
      },
    );
    await _jobs.upsertJob(
      PrintJob(
        id: newId(),
        orderId: '${bill.orderNo}',
        printType: 'PAYMENT_RECEIPT',
        targetRole: PrinterRole.bill,
        posOrderJson: pos.toJson(),
        sourceKey: 'RECEIPT:$entryId:${newId()}',
      ),
    );
  }

  /// UPI link for the bill's balance, or null without a UPI ID.
  Future<String?> upiLinkFor(String billId) async {
    final profile = await _profile.get();
    if (profile.upiId.trim().isEmpty) return null;
    final bill = (await _bills.getBill(billId))!;
    final s = await summaryFor(billId);
    if (s.balance.paise <= 0) return null;
    return upiPayLink(
      upiId: profile.upiId,
      payeeName: profile.name,
      amount: s.balance,
      note: 'Bill ${bill.billNumber}',
    );
  }

  // ---------------------------------------------------------------- helpers

  /// The cash shift open now, if any. Payments are never blocked by it.
  Future<String?> _openShiftId() async =>
      (await (_db.select(_db.cashShifts)
                ..where((s) => s.status.equals('open'))
                ..limit(1))
              .getSingleOrNull())
          ?.id;

  Future<void> _setOrderStatus(
    String orderId,
    OrderStatus status,
    int now, {
    String? dueNote,
  }) => (_db.update(_db.orders)..where((o) => o.id.equals(orderId))).write(
    OrdersCompanion(
      status: Value(status.name),
      closedAt: Value(
        status == OrderStatus.settled || status == OrderStatus.due ? now : null,
      ),
      dueNote: dueNote == null ? const Value.absent() : Value(dueNote),
      updatedAt: Value(now),
    ),
  );

  Future<BillRow> _requireBillRow(String id) async {
    final b = await (_db.select(
      _db.bills,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (b == null) throw ValidationException('Bill not found.');
    return b;
  }

  Future<OrderRow> _requireOrder(String id) async {
    final o = await (_db.select(
      _db.orders,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (o == null) throw ValidationException('Order not found.');
    return o;
  }
}
