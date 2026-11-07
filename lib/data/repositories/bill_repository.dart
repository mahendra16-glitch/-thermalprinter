import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/billing/bill_calculator.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/billing/billing_settings.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../models/pos_order.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'inventory_repository.dart';
import 'business_profile_repository.dart';
import 'order_repository.dart';
import 'payment_repository.dart';
import 'print_job_repository.dart';
import 'settings_repository.dart';

/// Some items were never sent to the kitchen.
class UnsentItemsException extends ValidationException {
  final int units;
  UnsentItemsException(this.units)
    : super('$units item(s) were not sent to the kitchen.');
}

/// A bill preview: what would be billed now, with the settings in force.
class BillDraft {
  final OrderDetail order;
  final BillCalculation calc;
  final BillingSettings settings;
  final int unsentUnits;

  const BillDraft(this.order, this.calc, this.settings, this.unsentUnits);
}

/// Bills. A bill is finalized once in a transaction (bill, lines, tax
/// breakdown, order status, audit and print job together) and is never
/// edited afterwards. To correct a bill, void it with a reason: the order
/// opens again and the next bill gets a new number.
///
/// After [finalize] with `print: true`, or [reprint], call
/// `PrintQueueManager.syncFromStorage()` so the job starts printing.
class BillRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final SettingsRepository _settings;
  final OrderRepository _orders;
  final BusinessProfileRepository _profile;
  final PrintJobRepository _jobs;

  BillRepository(
    this._db,
    this._audit,
    this._settings,
    this._orders,
    this._profile,
    this._jobs, {
    this.inventory,
  });

  /// Takes and returns stock with bills (v9). Null in tests that don't
  /// need it.
  final InventoryRepository? inventory;

  static const String keySettings = 'billing_settings';
  static final _prefixPattern = RegExp(r'^[A-Za-z0-9/\-]{0,10}$');

  // ---------------------------------------------------------------- settings

  Future<BillingSettings> getSettings() async {
    final raw = await _settings.getRaw(keySettings);
    if (raw == null) return BillingSettings.defaults;
    try {
      return BillingSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return BillingSettings.defaults;
    }
  }

  /// Saves billing settings. Only new bills use them; finalized bills keep
  /// the settings they were made with. The change is audited.
  Future<void> saveSettings(BillingSettings s) async {
    if (s.serviceChargeBp < 0 || s.serviceChargeBp > 5000) {
      throw ValidationException('Service charge must be 0% to 50%.');
    }
    if (s.serviceChargeTaxBp < 0 || s.serviceChargeTaxBp > 5000) {
      throw ValidationException('Service charge tax must be 0% to 50%.');
    }
    if (s.serviceChargeBp > 0 && s.serviceChargeOrderTypes.isEmpty) {
      throw ValidationException(
        'Choose at least one order type for the service charge.',
      );
    }
    final prefix = s.billNumberPrefix.trim();
    if (!_prefixPattern.hasMatch(prefix)) {
      throw ValidationException(
        'Bill number prefix: up to 10 letters, digits, "/" or "-".',
      );
    }
    await _settings.setRaw(
      keySettings,
      jsonEncode(s.copyWith(billNumberPrefix: prefix).toJson()),
    );
  }

  // ------------------------------------------------------------------ draft

  /// Calculates the bill for an open order without saving anything.
  Future<BillDraft> preview(String orderId) async {
    final d = await _orders.getDetail(orderId);
    if (d == null) throw ValidationException('Order not found.');
    final settings = await getSettings();
    return BillDraft(
      d,
      calculateBill(
        lines: d.lines,
        discount: d.order.discount,
        orderType: d.order.type,
        settings: settings,
      ),
      settings,
      d.lines.fold(0, (s, l) => s + l.unsentQty),
    );
  }

  // --------------------------------------------------------------- finalize

  /// Finalizes the bill for [orderId] and returns the bill id.
  ///
  /// - Calling again with the same [clientRequestId] returns the same bill.
  /// - [expectedTotal] is the total staff saw in the preview; if the order
  ///   or settings changed since, nothing is saved and an error explains
  ///   why.
  /// - Items never sent to the kitchen block the bill unless
  ///   [allowUnsent] is set (staff confirmed).
  Future<String> finalize(
    String orderId, {
    required String clientRequestId,
    Money? expectedTotal,
    bool allowUnsent = false,
    bool print = true,
  }) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.bills)
                ..where((b) => b.clientRequestId.equals(clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;

      final draft = await preview(orderId);
      final o = draft.order.order;
      if (!o.status.isActive) {
        throw ValidationException(
          'Order #${o.orderNo} is ${o.status.label.toLowerCase()}; it cannot '
          'be billed.',
        );
      }
      final calc = draft.calc;
      if (calc.lines.isEmpty) {
        throw ValidationException('There is nothing to bill on this order.');
      }
      if (draft.unsentUnits > 0 && !allowUnsent) {
        throw UnsentItemsException(draft.unsentUnits);
      }
      if (expectedTotal != null && expectedTotal != calc.grandTotal) {
        throw ValidationException(
          'The bill changed to ${calc.grandTotal.format()} (was '
          '${expectedTotal.format()}). Check it and try again.',
        );
      }

      final settings = draft.settings;
      final prefix = settings.billNumberPrefix;
      final maxSeq = _db.bills.billSeq.max();
      final seqRow =
          await (_db.selectOnly(_db.bills)
                ..addColumns([maxSeq])
                ..where(_db.bills.billPrefix.equals(prefix)))
              .getSingle();
      final seq = (seqRow.read(maxSeq) ?? 0) + 1;
      final number = '$prefix$seq';

      final profile = await _profile.get();
      final header = BillHeader(
        name: profile.name.trim(),
        address: profile.address.trim(),
        phone: profile.phone.trim(),
        gstin: profile.gstin.trim(),
        fssai: profile.fssai.trim(),
        footer: profile.billFooter.trim(),
      );
      final table = o.tableId == null
          ? null
          : await (_db.select(
              _db.restaurantTables,
            )..where((t) => t.id.equals(o.tableId!))).getSingleOrNull();

      final billId = newId();
      final now = Clock.nowMs();
      await _db
          .into(_db.bills)
          .insert(
            BillsCompanion.insert(
              id: billId,
              orderId: orderId,
              billPrefix: Value(prefix),
              billSeq: seq,
              billNumber: number,
              businessDate: o.businessDate,
              status: BillStatus.finalized.name,
              orderNo: o.orderNo,
              orderType: o.type.name,
              tableLabel: Value(table?.label ?? ''),
              customerName: Value(o.customerName),
              customerPhone: Value(o.customerPhone),
              staffName: Value(o.staffName),
              headerJson: jsonEncode(header.toJson()),
              itemsTotalPaise: calc.itemsTotal.paise,
              discountPaise: calc.discount.paise,
              discountLabel: Value(_discountLabel(o.discount, calc.discount)),
              serviceChargePaise: calc.serviceCharge.paise,
              serviceChargeBp: Value(calc.serviceChargeBp),
              taxPaise: calc.totalTax.paise,
              roundOffPaise: calc.roundOff.paise,
              grandTotalPaise: calc.grandTotal.paise,
              rounding: calc.rounding.name,
              settingsJson: jsonEncode(settings.toJson()),
              clientRequestId: clientRequestId,
              createdAt: now,
            ),
          );
      for (var i = 0; i < calc.lines.length; i++) {
        final l = calc.lines[i];
        await _db
            .into(_db.billLines)
            .insert(
              BillLinesCompanion.insert(
                id: newId(),
                billId: billId,
                orderLineId: l.orderLineId,
                name: l.name,
                variantText: Value(l.variantText),
                addonsText: Value(l.addons.join(', ')),
                qty: l.qty,
                unitPricePaise: l.unitPrice.paise,
                grossPaise: l.gross.paise,
                discountPaise: l.discount.paise,
                taxRateBp: l.taxRateBp,
                taxInclusive: l.taxInclusive,
                taxSplitMode: l.taxSplitMode.name,
                sortOrder: Value(i),
              ),
            );
      }
      for (var i = 0; i < calc.taxes.length; i++) {
        final t = calc.taxes[i];
        await _db
            .into(_db.billTaxes)
            .insert(
              BillTaxesCompanion.insert(
                id: newId(),
                billId: billId,
                base: t.base.name,
                rateBp: t.rateBp,
                inclusive: t.inclusive,
                splitMode: t.splitMode.name,
                taxablePaise: t.taxable.paise,
                cgstPaise: Value(t.cgst.paise),
                sgstPaise: Value(t.sgst.paise),
                igstPaise: Value(t.igst.paise),
                otherPaise: Value(t.other.paise),
                sortOrder: Value(i),
              ),
            );
      }
      // A ₹0 bill (e.g. 100% discount) has nothing to collect.
      final settled = calc.grandTotal.isZero;
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(
            settled ? OrderStatus.settled.name : OrderStatus.billed.name,
          ),
          closedAt: settled ? Value(now) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      final details = {
        'billId': billId,
        'billNumber': number,
        'grandTotalPaise': calc.grandTotal.paise,
        'taxPaise': calc.totalTax.paise,
        'discountPaise': calc.discount.paise,
        'serviceChargePaise': calc.serviceCharge.paise,
        'roundOffPaise': calc.roundOff.paise,
        'unsentUnits': draft.unsentUnits,
      };
      await _audit.record(
        action: 'order.billed',
        entity: 'orders',
        entityId: orderId,
        details: details,
      );
      await _audit.record(
        action: 'bill.finalized',
        entity: 'bills',
        entityId: billId,
        details: {...details, 'orderId': orderId, 'orderNo': o.orderNo},
      );
      await inventory?.onBillFinalized(billId);
      if (print) await _queuePrint(billId);
      return billId;
    });
  }

  // ------------------------------------------------------------------- void

  /// Voids a finalized bill and opens its order again for correction.
  /// The bill and its number are kept, marked voided.
  Future<void> voidBill(String billId, String reason) {
    return _db.transaction(() async {
      final b = await _requireBill(billId);
      if (b.status == BillStatus.voided.name) return;
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for voiding the bill.');
      }
      final order = await (_db.select(
        _db.orders,
      )..where((o) => o.id.equals(b.orderId))).getSingle();
      if (order.status != OrderStatus.billed.name &&
          order.status != OrderStatus.due.name &&
          !(order.status == OrderStatus.settled.name &&
              b.grandTotalPaise == 0)) {
        throw ValidationException(
          'Order #${order.orderNo} is '
          '${OrderStatusX.parse(order.status).label.toLowerCase()}; this bill '
          'cannot be voided.',
        );
      }
      final paid = BillPaymentSummary(
        Money(b.grandTotalPaise),
        await loadLedger(_db, billId),
      ).paid;
      if (paid.paise > 0) {
        throw ValidationException(
          '${paid.format()} has been paid on this bill. Reverse the payments '
          'first, then void the bill.',
        );
      }
      final now = Clock.nowMs();
      await (_db.update(_db.bills)..where((r) => r.id.equals(billId))).write(
        BillsCompanion(
          status: Value(BillStatus.voided.name),
          voidedAt: Value(now),
          voidReason: Value(reason.trim()),
        ),
      );
      await (_db.update(
        _db.orders,
      )..where((r) => r.id.equals(b.orderId))).write(
        OrdersCompanion(
          status: Value(OrderStatus.open.name),
          closedAt: const Value(null),
          dueNote: const Value(''),
          updatedAt: Value(now),
        ),
      );
      final details = {
        'billId': billId,
        'billNumber': b.billNumber,
        'grandTotalPaise': b.grandTotalPaise,
        'reason': reason.trim(),
      };
      await _audit.record(
        action: 'order.bill_voided',
        entity: 'orders',
        entityId: b.orderId,
        details: details,
      );
      await _audit.record(
        action: 'bill.voided',
        entity: 'bills',
        entityId: billId,
        details: details,
      );
      await inventory?.onBillVoided(billId);
    });
  }

  // ---------------------------------------------------------------- reprint

  /// Prints the bill. If it was printed (or queued) before, the copy is
  /// marked "DUPLICATE". Creates no new bill. Returns true for a duplicate.
  Future<bool> reprint(String billId) {
    return _db.transaction(() async {
      final b = await _requireBill(billId);
      if (b.status == BillStatus.voided.name) {
        throw ValidationException(
          'This bill was voided and cannot be printed.',
        );
      }
      final printedBefore = (await _jobs.jobsWithSourcePrefix('BILL:$billId'))
          .isNotEmpty;
      await _queuePrint(billId, reprint: printedBefore);
      await _audit.record(
        action: printedBefore ? 'order.bill_reprinted' : 'order.bill_printed',
        entity: 'orders',
        entityId: b.orderId,
        details: {'billId': billId, 'billNumber': b.billNumber},
      );
      return printedBefore;
    });
  }

  // ------------------------------------------------------------------ read

  Future<Bill?> getBill(String billId) async {
    final r = await (_db.select(
      _db.bills,
    )..where((b) => b.id.equals(billId))).getSingleOrNull();
    return r == null ? null : _toBill(r);
  }

  /// All bills of an order, oldest first (voided ones included).
  Future<List<Bill>> billsForOrder(String orderId) async {
    final rows =
        await (_db.select(_db.bills)
              ..where((b) => b.orderId.equals(orderId))
              ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
            .get();
    return [for (final r in rows) await _toBill(r)];
  }

  /// The finalized (not voided) bill of an order, if any.
  Future<Bill?> currentBillFor(String orderId) async {
    final r =
        await (_db.select(_db.bills)..where(
              (b) =>
                  b.orderId.equals(orderId) &
                  b.status.equals(BillStatus.finalized.name),
            ))
            .getSingleOrNull();
    return r == null ? null : _toBill(r);
  }

  /// Bills of one business day, newest first.
  Future<List<Bill>> billsForDate(String businessDate) async {
    final rows =
        await (_db.select(_db.bills)
              ..where((b) => b.businessDate.equals(businessDate))
              ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
            .get();
    return [for (final r in rows) await _toBill(r)];
  }

  /// Print jobs of a bill (first print and reprints).
  Future<List<PrintJob>> printJobsFor(String billId) async => [
    ...await _jobs.jobsWithSourcePrefix('BILL:$billId'),
    ...await _jobs.jobsWithSourcePrefix('REPRINT:BILL:$billId:'),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.bills, _db.printJobs]),
  );

  // ---------------------------------------------------------------- helpers

  Future<void> _queuePrint(String billId, {bool reprint = false}) async {
    final stored = (await getBill(billId))!;
    final ledger = await loadLedger(_db, billId);
    final summary = BillPaymentSummary(stored.grandTotal, ledger);
    final profile = await _profile.get();
    final settings = await getSettings();
    final bill = stored.withPrintExtras(
      payments: printedPaymentLines(ledger),
      upiQr:
          settings.printUpiQr &&
              profile.upiId.trim().isNotEmpty &&
              summary.balance.paise > 0
          ? upiPayLink(
              upiId: profile.upiId,
              payeeName: profile.name,
              amount: summary.balance,
              note: 'Bill ${stored.billNumber}',
            )
          : '',
    );
    final pos = PosOrder(
      orderId: '${bill.orderNo}',
      billNo: bill.billNumber,
      type: 'BILL',
      printerRole: PrinterRole.bill,
      restaurantName: bill.header.name,
      items: const [],
      timestamp: bill.createdAt,
      isReprint: reprint,
      bill: bill.toJson(),
    );
    await _jobs.upsertJob(
      PrintJob(
        id: newId(),
        orderId: '${bill.orderNo}',
        printType: 'BILL',
        targetRole: PrinterRole.bill,
        posOrderJson: pos.toJson(),
        sourceKey: reprint ? 'REPRINT:BILL:$billId:${newId()}' : 'BILL:$billId',
      ),
    );
  }

  static String _discountLabel(OrderDiscount d, Money amount) {
    if (amount.isZero) return '';
    final what = d.kind == DiscountKind.percent
        ? 'Discount ${formatBp(d.value)}'
        : 'Discount';
    return d.reason.isEmpty ? what : '$what (${d.reason})';
  }

  Future<BillRow> _requireBill(String id) async {
    final b = await (_db.select(
      _db.bills,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (b == null) throw ValidationException('Bill not found.');
    return b;
  }

  Future<Bill> _toBill(BillRow r) async {
    final lines =
        await (_db.select(_db.billLines)
              ..where((l) => l.billId.equals(r.id))
              ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
            .get();
    final taxes =
        await (_db.select(_db.billTaxes)
              ..where((t) => t.billId.equals(r.id))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    return Bill(
      id: r.id,
      orderId: r.orderId,
      billNumber: r.billNumber,
      businessDate: r.businessDate,
      status: BillStatusX.parse(r.status),
      orderNo: r.orderNo,
      orderTypeLabel: OrderTypeX.parse(r.orderType).label,
      tableLabel: r.tableLabel,
      customerName: r.customerName,
      customerPhone: r.customerPhone,
      staffName: r.staffName,
      header: BillHeader.fromJson(
        jsonDecode(r.headerJson) as Map<String, dynamic>,
      ),
      lines: [
        for (final l in lines)
          BillLine(
            name: l.name,
            variantText: l.variantText,
            addonsText: l.addonsText,
            qty: l.qty,
            unitPrice: Money(l.unitPricePaise),
            gross: Money(l.grossPaise),
            discount: Money(l.discountPaise),
            taxRateBp: l.taxRateBp,
            taxInclusive: l.taxInclusive,
          ),
      ],
      taxes: [
        for (final t in taxes)
          BillTax(
            base: t.base == TaxBase.serviceCharge.name
                ? TaxBase.serviceCharge
                : TaxBase.items,
            rateBp: t.rateBp,
            inclusive: t.inclusive,
            splitMode: TaxSplitModeX.parse(t.splitMode),
            taxable: Money(t.taxablePaise),
            cgst: Money(t.cgstPaise),
            sgst: Money(t.sgstPaise),
            igst: Money(t.igstPaise),
            other: Money(t.otherPaise),
          ),
      ],
      itemsTotal: Money(r.itemsTotalPaise),
      discount: Money(r.discountPaise),
      discountLabel: r.discountLabel,
      serviceCharge: Money(r.serviceChargePaise),
      serviceChargeBp: r.serviceChargeBp,
      roundOff: Money(r.roundOffPaise),
      grandTotal: Money(r.grandTotalPaise),
      rounding: RoundingModeX.parse(r.rounding),
      createdAt: Clock.toLocal(r.createdAt),
      voidedAt: r.voidedAt == null ? null : Clock.toLocal(r.voidedAt!),
      voidReason: r.voidReason,
    );
  }
}
