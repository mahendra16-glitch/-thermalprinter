import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/orders/kitchen_models.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../domain/reports/report_models.dart';
import '../../models/pos_order.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'business_profile_repository.dart';
import 'payment_repository.dart';
import 'print_job_repository.dart';
import 'shift_repository.dart';

/// Reports built only from local data: bills, bill lines and taxes, the
/// payment ledger, orders, kitchen void tickets, shifts and expenses.
///
/// Nothing here writes business data. Printing a report only queues a
/// print job (and an audit row).
class ReportRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final BusinessProfileRepository _profile;
  final ShiftRepository _shifts;
  final PrintJobRepository _jobs;

  ReportRepository(
    this._db,
    this._audit,
    this._profile,
    this._shifts,
    this._jobs,
  );

  static const String uncategorised = 'Other';

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([
      _db.bills,
      _db.payments,
      _db.orders,
      _db.expenses,
      _db.cashShifts,
    ]),
  );

  /// Builds the full report for [period].
  Future<SalesReport> build(ReportPeriod period) async {
    final from = period.from;
    final to = period.to;
    final profile = await _profile.get();

    // ---------------------------------------------------------- bills
    final billRows =
        await (_db.select(_db.bills)
              ..where((b) => b.businessDate.isBetweenValues(from, to))
              ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
            .get();
    bool finalized(BillRow b) => b.status == BillStatus.finalized.name;

    // Ledger of the period's bills, any date.
    final billPayments = await (_db.select(_db.payments).join([
      innerJoin(_db.bills, _db.bills.id.equalsExp(_db.payments.billId)),
    ])..where(_db.bills.businessDate.isBetweenValues(from, to))).get();
    final entriesByBill = <String, List<PaymentRow>>{};
    for (final r in billPayments) {
      final p = r.readTable(_db.payments);
      (entriesByBill[p.billId] ??= []).add(p);
    }
    Money paidOn(String billId) => (entriesByBill[billId] ?? const []).fold(
      Money.zero,
      (s, p) => s + _signed(p),
    );

    // Orders of the period (discount reasons, statuses, cancellations).
    final orderRows = await (_db.select(
      _db.orders,
    )..where((o) => o.businessDate.isBetweenValues(from, to))).get();
    final ordersById = {for (final o in orderRows) o.id: o};

    // Tax rows of finalized bills.
    final taxJoin =
        await (_db.select(_db.billTaxes).join([
                innerJoin(
                  _db.bills,
                  _db.bills.id.equalsExp(_db.billTaxes.billId),
                ),
              ])
              ..where(
                _db.bills.businessDate.isBetweenValues(from, to) &
                    _db.bills.status.equals(BillStatus.finalized.name),
              )
              ..orderBy([OrderingTerm.asc(_db.billTaxes.sortOrder)]))
            .get();
    final taxesByBill = <String, List<BillTaxRow>>{};
    for (final r in taxJoin) {
      final t = r.readTable(_db.billTaxes);
      (taxesByBill[t.billId] ??= []).add(t);
    }

    // Lines of finalized bills, with the category of the menu item.
    final lineJoin =
        await (_db.select(_db.billLines).join([
              innerJoin(
                _db.bills,
                _db.bills.id.equalsExp(_db.billLines.billId),
              ),
              leftOuterJoin(
                _db.orderLines,
                _db.orderLines.id.equalsExp(_db.billLines.orderLineId),
              ),
              leftOuterJoin(
                _db.menuItems,
                _db.menuItems.id.equalsExp(_db.orderLines.menuItemId),
              ),
              leftOuterJoin(
                _db.menuCategories,
                _db.menuCategories.id.equalsExp(_db.menuItems.categoryId),
              ),
            ])..where(
              _db.bills.businessDate.isBetweenValues(from, to) &
                  _db.bills.status.equals(BillStatus.finalized.name),
            ))
            .get();
    final linesByBill = <String, List<BillLineRow>>{};
    final itemAgg = <String, _Agg>{};
    final catAgg = <String, _Agg>{};
    for (final r in lineJoin) {
      final l = r.readTable(_db.billLines);
      (linesByBill[l.billId] ??= []).add(l);
      final cat = r.readTableOrNull(_db.menuCategories)?.name ?? uncategorised;
      final name = l.variantText.isEmpty
          ? l.name
          : '${l.name} (${l.variantText})';
      (itemAgg['$name\u0000$cat'] ??= _Agg(name, cat)).add(l);
      (catAgg[cat] ??= _Agg(cat, cat)).add(l);
    }

    // --------------------------------------------------- totals, register
    var t = const SalesTotals();
    final register = <BillRegisterRow>[];
    final staff = <String, (int, Money)>{};
    final types = <String, (int, Money)>{};
    final tables = <String, (int, Money)>{};
    final discounts = <DiscountRow>[];
    void group(Map<String, (int, Money)> m, String k, Money v) {
      final cur = m[k] ?? (0, Money.zero);
      m[k] = (cur.$1 + 1, cur.$2 + v);
    }

    for (final b in billRows) {
      final voided = !finalized(b);
      final entries = entriesByBill[b.id] ?? const <PaymentRow>[];
      final reversed = {
        for (final p in entries)
          if (p.reversesPaymentId != null) p.reversesPaymentId!,
      };
      final livePayments = entries
          .where(
            (p) =>
                p.kind == PaymentKind.payment.name && !reversed.contains(p.id),
          )
          .length;
      final total = Money(b.grandTotalPaise);
      register.add(
        BillRegisterRow(
          billId: b.id,
          billNumber: b.billNumber,
          businessDate: b.businessDate,
          createdAt: Clock.toLocal(b.createdAt),
          orderNo: b.orderNo,
          orderType: OrderTypeX.parse(b.orderType).label,
          tableLabel: b.tableLabel,
          customerName: b.customerName,
          customerPhone: b.customerPhone,
          staffName: b.staffName,
          itemsTotal: Money(b.itemsTotalPaise),
          discount: Money(b.discountPaise),
          discountLabel: b.discountLabel,
          serviceCharge: Money(b.serviceChargePaise),
          tax: Money(b.taxPaise),
          roundOff: Money(b.roundOffPaise),
          total: total,
          paid: paidOn(b.id),
          voided: voided,
          voidReason: b.voidReason,
          voidedAt: b.voidedAt == null ? null : Clock.toLocal(b.voidedAt!),
          splitPaid: livePayments > 1,
        ),
      );
      if (voided) continue;

      final taxRows = taxesByBill[b.id] ?? const <BillTaxRow>[];
      int taxOf(BillTaxRow x) =>
          x.cgstPaise + x.sgstPaise + x.igstPaise + x.otherPaise;
      final excl = taxRows
          .where((x) => !x.inclusive)
          .fold<int>(0, (s, x) => s + taxOf(x));
      final incl = taxRows
          .where((x) => x.inclusive)
          .fold<int>(0, (s, x) => s + taxOf(x));
      final qty = (linesByBill[b.id] ?? const <BillLineRow>[]).fold<int>(
        0,
        (s, l) => s + l.qty,
      );
      t = SalesTotals(
        bills: t.bills + 1,
        itemQty: t.itemQty + qty,
        itemsTotal: t.itemsTotal + Money(b.itemsTotalPaise),
        discount: t.discount + Money(b.discountPaise),
        serviceCharge: t.serviceCharge + Money(b.serviceChargePaise),
        exclusiveTax: t.exclusiveTax + Money(excl),
        inclusiveTax: t.inclusiveTax + Money(incl),
        roundOff: t.roundOff + Money(b.roundOffPaise),
        billed: t.billed + total,
      );
      group(staff, b.staffName.trim().isEmpty ? 'Not set' : b.staffName, total);
      group(types, OrderTypeX.parse(b.orderType).label, total);
      if (b.orderType == OrderType.dineIn.name) {
        group(tables, b.tableLabel.isEmpty ? 'No table' : b.tableLabel, total);
      }
      if (b.discountPaise > 0) {
        discounts.add(
          DiscountRow(
            billNumber: b.billNumber,
            orderNo: b.orderNo,
            label: b.discountLabel,
            reason: ordersById[b.orderId]?.discountReason ?? '',
            staffName: b.staffName,
            itemsTotal: Money(b.itemsTotalPaise),
            amount: Money(b.discountPaise),
          ),
        );
      }
    }

    List<BillGroupRow> groups(Map<String, (int, Money)> m) =>
        [for (final e in m.entries) BillGroupRow(e.key, e.value.$1, e.value.$2)]
          ..sort((a, b) => b.billed.compareTo(a.billed));

    List<ItemSalesRow> aggRows(Map<String, _Agg> m) =>
        [for (final a in m.values) a.row()]
          ..sort((a, b) => b.net.compareTo(a.net));

    // ------------------------------------------------------------ taxes
    final taxAgg = <(String, int, bool, String), List<int>>{};
    for (final r in taxJoin) {
      final x = r.readTable(_db.billTaxes);
      if (x.rateBp <= 0) continue;
      final k = (x.base, x.rateBp, x.inclusive, x.splitMode);
      final a = taxAgg[k] ??= [0, 0, 0, 0, 0];
      a[0] += x.taxablePaise;
      a[1] += x.cgstPaise;
      a[2] += x.sgstPaise;
      a[3] += x.igstPaise;
      a[4] += x.otherPaise;
    }
    final taxes =
        [
          for (final e in taxAgg.entries)
            TaxSummaryRow(
              base: e.key.$1,
              rateBp: e.key.$2,
              inclusive: e.key.$3,
              splitMode: e.key.$4,
              taxable: Money(e.value[0]),
              cgst: Money(e.value[1]),
              sgst: Money(e.value[2]),
              igst: Money(e.value[3]),
              other: Money(e.value[4]),
            ),
        ]..sort((a, b) {
          final c = a.base.compareTo(b.base);
          if (c != 0) return c;
          final r = a.rateBp.compareTo(b.rateBp);
          if (r != 0) return r;
          return a.inclusive == b.inclusive ? 0 : (a.inclusive ? 1 : -1);
        });

    // ------------------------------------------------------ collections
    final periodLedger =
        await (_db.select(_db.payments).join([
                innerJoin(
                  _db.bills,
                  _db.bills.id.equalsExp(_db.payments.billId),
                ),
              ])
              ..where(_db.payments.businessDate.isBetweenValues(from, to))
              ..orderBy([
                OrderingTerm.asc(_db.payments.createdAt),
                OrderingTerm.asc(_db.payments.rowId),
              ]))
            .get();
    final collections = <String, List<int>>{};
    final ledger = <LedgerReportRow>[];
    final reversals = <ReversalRow>[];
    var forPeriodBills = Money.zero;
    var forOtherBills = Money.zero;
    var cashOutside = Money.zero;
    for (final r in periodLedger) {
      final p = r.readTable(_db.payments);
      final b = r.readTable(_db.bills);
      final e = ledgerEntryFromRow(p);
      final label = e.methodLabel;
      final a = collections[label] ??= [0, 0, 0, 0];
      if (e.isReversal) {
        a[2]++;
        a[3] += p.amountPaise;
        reversals.add(
          ReversalRow(
            billNumber: b.billNumber,
            orderNo: b.orderNo,
            method: label,
            amount: e.amount,
            reason: p.reason,
            staffName: p.staffName,
            at: e.createdAt,
          ),
        );
      } else {
        a[0]++;
        a[1] += p.amountPaise;
      }
      if (period.contains(b.businessDate)) {
        forPeriodBills += e.signedAmount;
      } else {
        forOtherBills += e.signedAmount;
      }
      if (e.method == PaymentMethod.cash && p.shiftId == null) {
        cashOutside += e.signedAmount;
      }
      ledger.add(
        LedgerReportRow(
          id: p.id,
          at: e.createdAt,
          businessDate: p.businessDate,
          billNumber: b.billNumber,
          orderNo: b.orderNo,
          reversal: e.isReversal,
          method: label,
          amount: e.amount,
          tendered: e.tendered,
          change: e.change,
          reference: p.reference,
          confirmation: p.confirmation,
          reason: p.reason,
          staffName: p.staffName,
          inShift: p.shiftId != null,
        ),
      );
    }
    const methodOrder = ['Cash', 'UPI', 'Card'];
    int rank(String m) {
      final i = methodOrder.indexOf(m);
      return i < 0 ? methodOrder.length : i;
    }

    final collectionRows =
        [
          for (final e in collections.entries)
            CollectionRow(
              method: e.key,
              payments: e.value[0],
              received: Money(e.value[1]),
              reversals: e.value[2],
              reversed: Money(e.value[3]),
            ),
        ]..sort((a, b) {
          final c = rank(a.method).compareTo(rank(b.method));
          return c != 0 ? c : a.method.compareTo(b.method);
        });

    // ------------------------------------------- cancellations, voids
    final cancelled = <CancelledOrderRow>[];
    final cancelledIds = [
      for (final o in orderRows)
        if (o.status == OrderStatus.cancelled.name) o.id,
    ];
    final cancelledLines = cancelledIds.isEmpty
        ? const <OrderLineRow>[]
        : await (_db.select(
            _db.orderLines,
          )..where((l) => l.orderId.isIn(cancelledIds))).get();
    final valueByOrder = <String, int>{};
    for (final l in cancelledLines) {
      valueByOrder[l.orderId] =
          (valueByOrder[l.orderId] ?? 0) +
          l.unitPricePaise * (l.qty - l.voidedQty);
    }
    for (final o in orderRows) {
      if (o.status != OrderStatus.cancelled.name) continue;
      cancelled.add(
        CancelledOrderRow(
          orderNo: o.orderNo,
          businessDate: o.businessDate,
          orderType: OrderTypeX.parse(o.orderType).label,
          reason: o.cancelReason,
          staffName: o.staffName,
          value: Money(valueByOrder[o.id] ?? 0),
          merged: o.cancelReason.startsWith('Merged into'),
          at: Clock.toLocal(o.closedAt ?? o.updatedAt),
        ),
      );
    }
    cancelled.sort((a, b) => a.orderNo.compareTo(b.orderNo));

    final voidJoin =
        await (_db.select(_db.kitchenTicketLines).join([
                innerJoin(
                  _db.kitchenTickets,
                  _db.kitchenTickets.id.equalsExp(
                    _db.kitchenTicketLines.ticketId,
                  ),
                ),
                innerJoin(
                  _db.orders,
                  _db.orders.id.equalsExp(_db.kitchenTickets.orderId),
                ),
              ])
              ..where(
                _db.orders.businessDate.isBetweenValues(from, to) &
                    _db.kitchenTickets.kind.equals(
                      KitchenTicketKind.voided.name,
                    ),
              )
              ..orderBy([OrderingTerm.asc(_db.kitchenTickets.createdAt)]))
            .get();
    final itemVoids = [
      for (final r in voidJoin)
        ItemVoidRow(
          orderNo: r.readTable(_db.orders).orderNo,
          itemName: r.readTable(_db.kitchenTicketLines).itemName,
          qty: r.readTable(_db.kitchenTicketLines).qty,
          reason: r.readTable(_db.kitchenTickets).reason,
          at: Clock.toLocal(r.readTable(_db.kitchenTickets).createdAt),
        ),
    ];

    // ------------------------------------------------ issues (period)
    final issues = <ReconcileIssue>[];
    for (final b in billRows) {
      final ref = 'Bill ${b.billNumber}';
      final entries = entriesByBill[b.id] ?? const <PaymentRow>[];
      final paid = paidOn(b.id);
      final byId = {for (final p in entries) p.id: p};
      for (final p in entries) {
        if (p.orderId != b.orderId) {
          issues.add(
            ReconcileIssue(ref, 'a payment belongs to a different order'),
          );
        }
        if (p.kind == PaymentKind.reversal.name) {
          final orig = byId[p.reversesPaymentId];
          if (orig == null) {
            issues.add(
              ReconcileIssue(ref, 'a reversal has no matching payment'),
            );
          } else if (orig.amountPaise != p.amountPaise ||
              orig.method != p.method) {
            issues.add(
              ReconcileIssue(
                ref,
                'a reversal does not match the payment it undoes',
              ),
            );
          }
        }
      }
      if (!finalized(b)) {
        if (!paid.isZero) {
          issues.add(
            ReconcileIssue(
              ref,
              'voided bill still has ${paid.format()} paid on it',
            ),
          );
        }
        continue;
      }
      final lines = linesByBill[b.id] ?? const <BillLineRow>[];
      final gross = lines.fold<int>(0, (s, l) => s + l.grossPaise);
      final disc = lines.fold<int>(0, (s, l) => s + l.discountPaise);
      if (gross != b.itemsTotalPaise) {
        issues.add(
          ReconcileIssue(
            ref,
            'item lines add up to ${Money(gross).format()}, bill shows '
            '${Money(b.itemsTotalPaise).format()}',
          ),
        );
      }
      if (disc != b.discountPaise) {
        issues.add(
          ReconcileIssue(ref, 'line discounts do not add up to the discount'),
        );
      }
      final taxRows = taxesByBill[b.id] ?? const <BillTaxRow>[];
      final allTax = taxRows.fold<int>(
        0,
        (s, x) => s + x.cgstPaise + x.sgstPaise + x.igstPaise + x.otherPaise,
      );
      final exclTax = taxRows
          .where((x) => !x.inclusive)
          .fold<int>(
            0,
            (s, x) =>
                s + x.cgstPaise + x.sgstPaise + x.igstPaise + x.otherPaise,
          );
      if (allTax != b.taxPaise) {
        issues.add(
          ReconcileIssue(ref, 'tax lines do not add up to the bill tax'),
        );
      }
      final expect =
          b.itemsTotalPaise -
          b.discountPaise +
          b.serviceChargePaise +
          exclTax +
          b.roundOffPaise;
      if (expect != b.grandTotalPaise) {
        issues.add(
          ReconcileIssue(
            ref,
            'total should be ${Money(expect).format()} from its parts, '
            'bill shows ${Money(b.grandTotalPaise).format()}',
          ),
        );
      }
      final total = Money(b.grandTotalPaise);
      if (paid > total) {
        issues.add(
          ReconcileIssue(
            ref,
            'paid ${paid.format()} is more than the bill ${total.format()}',
          ),
        );
      }
      final order = ordersById[b.orderId];
      if (order != null) {
        final status = OrderStatusX.parse(order.status);
        final owes = total - paid;
        final label = 'Order #${order.orderNo}';
        if (status == OrderStatus.settled && !owes.isZero) {
          issues.add(
            ReconcileIssue(
              label,
              'marked Paid but ${owes.format()} is still owed',
            ),
          );
        } else if ((status == OrderStatus.billed ||
                status == OrderStatus.due) &&
            owes.paise <= 0) {
          issues.add(ReconcileIssue(label, 'fully paid but not marked Paid'));
        } else if (status.isActive || status == OrderStatus.cancelled) {
          issues.add(
            ReconcileIssue(
              label,
              'is ${status.label.toLowerCase()} but has a finalized bill',
            ),
          );
        }
      }
    }

    // ------------------------------------------------------------ dues
    final dues = await _dues();

    return SalesReport(
      period: period,
      generatedAt: Clock.now(),
      business: profile.name,
      totals: t,
      bills: register,
      items: aggRows(itemAgg),
      categories: aggRows(catAgg),
      byStaff: groups(staff),
      byOrderType: groups(types),
      byTable: groups(tables),
      taxes: taxes,
      discounts: discounts,
      collections: collectionRows,
      ledger: ledger,
      collectedForPeriodBills: forPeriodBills,
      collectedForOtherBills: forOtherBills,
      cashOutsideShifts: cashOutside,
      cancelledOrders: cancelled,
      itemVoids: itemVoids,
      reversals: reversals,
      expenses: await _shifts.expensesBetween(from, to),
      shifts: await _shifts.shiftsBetween(from, to),
      dues: dues,
      issues: issues,
    );
  }

  /// Every bill still owing money (billed or due orders), oldest first.
  Future<List<DueRow>> _dues() async {
    final rows =
        await (_db.select(_db.bills).join([
                innerJoin(
                  _db.orders,
                  _db.orders.id.equalsExp(_db.bills.orderId),
                ),
              ])
              ..where(
                _db.bills.status.equals(BillStatus.finalized.name) &
                    _db.orders.status.isIn([
                      OrderStatus.billed.name,
                      OrderStatus.due.name,
                    ]),
              )
              ..orderBy([OrderingTerm.asc(_db.bills.createdAt)]))
            .get();
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.readTable(_db.bills).id];
    final pays = await (_db.select(
      _db.payments,
    )..where((p) => p.billId.isIn(ids))).get();
    final paid = <String, Money>{};
    for (final p in pays) {
      paid[p.billId] = (paid[p.billId] ?? Money.zero) + _signed(p);
    }
    final out = <DueRow>[];
    for (final r in rows) {
      final b = r.readTable(_db.bills);
      final o = r.readTable(_db.orders);
      final row = DueRow(
        billNumber: b.billNumber,
        businessDate: b.businessDate,
        orderNo: b.orderNo,
        customerName: o.customerName,
        customerPhone: o.customerPhone,
        note: o.dueNote,
        total: Money(b.grandTotalPaise),
        paid: paid[b.id] ?? Money.zero,
      );
      if (row.balance.paise > 0) out.add(row);
    }
    return out;
  }

  /// Queues the printed summary of [period]. Item lines are optional
  /// because they can be long.
  Future<void> printSummary(
    ReportPeriod period, {
    bool includeItems = false,
  }) async {
    final report = await build(period);
    final data = printData(report, includeItems: includeItems);
    await _db.transaction(() async {
      await _jobs.upsertJob(
        PrintJob(
          id: newId(),
          orderId: 'REPORT',
          printType: 'SALES_REPORT',
          targetRole: PrinterRole.bill,
          posOrderJson: PosOrder(
            orderId: 'REPORT',
            type: 'SALES_REPORT',
            printerRole: PrinterRole.bill,
            restaurantName: report.business,
            items: const [],
            report: data,
          ).toJson(),
          sourceKey: 'REPORT:${period.from}:${period.to}:${newId()}',
        ),
      );
      await _audit.record(
        action: 'report.printed',
        entity: 'reports',
        details: {'from': period.from, 'to': period.to, 'items': includeItems},
      );
    });
  }

  /// Records that a CSV export was made (the files are written by the UI).
  Future<void> recordExport(ReportPeriod period, List<String> files) =>
      _audit.record(
        action: 'report.csv_exported',
        entity: 'reports',
        details: {'from': period.from, 'to': period.to, 'files': files},
      );

  /// What the printed summary contains: titled sections of rows. A row is
  /// `{'l': label, 'v': paise}` or `{'l': label, 's': text}`, with an
  /// optional `'b': true` for bold.
  static Map<String, Object?> printData(
    SalesReport r, {
    bool includeItems = false,
  }) {
    Map<String, Object?> m(String l, Money v, {bool bold = false}) => {
      'l': l,
      'v': v.paise,
      if (bold) 'b': true,
    };
    Map<String, Object?> s(String l, String v) => {'l': l, 's': v};
    final t = r.totals;
    final sections = <Map<String, Object?>>[
      {
        'title': 'SALES (bills of these dates)',
        'rows': [
          s('Bills', '${t.bills}'),
          s('Items sold', '${t.itemQty}'),
          m('Gross item sales', t.grossSales),
          if (!t.discount.isZero) m('- Discounts', t.discount),
          if (!t.serviceCharge.isZero) m('+ Service charge', t.serviceCharge),
          m('Net sales (before tax)', t.netSales, bold: true),
          if (!t.exclusiveTax.isZero) m('+ Tax added', t.exclusiveTax),
          if (!t.inclusiveTax.isZero) m('Tax incl. in prices', t.inclusiveTax),
          if (!t.roundOff.isZero) m('Round off', t.roundOff),
          m('Total billed', t.billed, bold: true),
          m('Average bill', t.averageBill),
        ],
      },
      {
        'title': 'MONEY COLLECTED (by payment date)',
        'rows': [
          for (final c in r.collections) ...[
            m('${c.method} (${c.payments})', c.received),
            if (c.reversals > 0)
              m('${c.method} refunds (${c.reversals})', -c.reversed),
          ],
          if (r.collections.isEmpty) s('No payments', ''),
          m('Net collected', r.collected, bold: true),
          if (!r.collectedForOtherBills.isZero)
            m('incl. for other dates', r.collectedForOtherBills),
          if (!r.cashOutsideShifts.isZero)
            m('Cash with no shift open', r.cashOutsideShifts),
        ],
      },
      {
        'title': 'BILLS OF THESE DATES',
        'rows': [
          m('Billed', t.billed),
          m('Paid so far', r.paidOnPeriodBills),
          m('Still to collect', r.outstandingOnPeriodBills, bold: true),
          s('Paid in parts', '${r.splitPaidBills}'),
          s('Part paid / unpaid', '${r.partPaidBills} / ${r.unpaidBills}'),
        ],
      },
      if (r.taxes.isNotEmpty)
        {
          'title': 'TAX',
          'rows': [
            for (final x in r.taxes) ...[
              m(x.label, x.tax),
              m('  on', x.taxable),
            ],
            m('Total tax', t.totalTax, bold: true),
          ],
        },
      {
        'title': 'VOIDS AND CANCELLATIONS',
        'rows': [
          s('Voided bills', '${r.voidedBills.length}'),
          if (r.voidedBills.isNotEmpty) m('  value', r.voidedBillsTotal),
          s('Cancelled orders', '${r.cancelledCount}'),
          s(
            'Items voided after KOT',
            '${r.itemVoids.fold<int>(0, (a, v) => a + v.qty)}',
          ),
          s('Refunds / reversals', '${r.reversals.length}'),
          if (r.reversals.isNotEmpty) m('  amount', r.refunds),
          s('Discounted bills', '${r.discounts.length}'),
        ],
      },
      if (r.categories.isNotEmpty)
        {
          'title': 'CATEGORY SALES (after discount)',
          'rows': [
            for (final c in r.categories) m('${c.name} x${c.qty}', c.net),
          ],
        },
      if (includeItems && r.items.isNotEmpty)
        {
          'title': 'ITEM SALES (after discount)',
          'rows': [for (final i in r.items) m('${i.name} x${i.qty}', i.net)],
        },
      if (r.byOrderType.isNotEmpty)
        {
          'title': 'BY ORDER TYPE',
          'rows': [
            for (final g in r.byOrderType)
              m('${g.label} (${g.bills})', g.billed),
          ],
        },
      if (r.liveExpenses.isNotEmpty)
        {
          'title': 'EXPENSES',
          'rows': [
            for (final e in r.expensesBySource.entries) m(e.key, e.value),
            m('Total expenses', r.expensesTotal, bold: true),
          ],
        },
      {
        'title': 'DUES (all dates, now)',
        'rows': [
          s('Bills owing', '${r.dues.length}'),
          m('Total owed', r.duesTotal, bold: true),
        ],
      },
    ];
    return {
      'business': r.business,
      'title': r.period.isSingleDay ? 'DAILY REPORT' : 'SALES REPORT',
      'period': r.period.label,
      'generatedAt': r.generatedAt.toIso8601String(),
      'sections': sections,
      'issues': r.issues.length,
    };
  }

  static Money _signed(PaymentRow p) => p.kind == PaymentKind.reversal.name
      ? Money(-p.amountPaise)
      : Money(p.amountPaise);
}

class _Agg {
  final String name;
  final String category;
  int qty = 0;
  int gross = 0;
  int discount = 0;

  _Agg(this.name, this.category);

  void add(BillLineRow l) {
    qty += l.qty;
    gross += l.grossPaise;
    discount += l.discountPaise;
  }

  ItemSalesRow row() => ItemSalesRow(
    name: name,
    category: category,
    qty: qty,
    gross: Money(gross),
    discount: Money(discount),
  );
}
