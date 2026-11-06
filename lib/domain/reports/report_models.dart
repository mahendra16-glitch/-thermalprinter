import '../../core/util/money.dart';
import '../shifts/shift_models.dart';

/// Business dates `from` … `to` (inclusive), as `yyyy-MM-dd`.
class ReportPeriod {
  final String from;
  final String to;

  const ReportPeriod(this.from, this.to);

  const ReportPeriod.day(String date) : from = date, to = date;

  bool get isSingleDay => from == to;

  bool contains(String businessDate) =>
      businessDate.compareTo(from) >= 0 && businessDate.compareTo(to) <= 0;

  String get label => isSingleDay ? from : '$from to $to';

  /// The day before / days back from a `yyyy-MM-dd` date.
  static String shift(String date, int days) {
    final d = DateTime.parse(date).add(Duration(days: days));
    return dateString(d);
  }

  static String dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Totals of finalized bills (voided bills are never included).
///
/// Identity of every bill, and so of the totals:
/// `itemsTotal − discount + serviceCharge + exclusiveTax + roundOff = billed`.
/// Inclusive tax is already inside [itemsTotal].
class SalesTotals {
  final int bills;
  final int itemQty;
  final Money itemsTotal;
  final Money discount;
  final Money serviceCharge;
  final Money exclusiveTax;
  final Money inclusiveTax;
  final Money roundOff;
  final Money billed;

  const SalesTotals({
    this.bills = 0,
    this.itemQty = 0,
    this.itemsTotal = Money.zero,
    this.discount = Money.zero,
    this.serviceCharge = Money.zero,
    this.exclusiveTax = Money.zero,
    this.inclusiveTax = Money.zero,
    this.roundOff = Money.zero,
    this.billed = Money.zero,
  });

  /// Item sales before discount, as charged (includes inclusive tax).
  Money get grossSales => itemsTotal;

  Money get totalTax => exclusiveTax + inclusiveTax;

  /// Sales after discount, plus service charge, without any tax or
  /// rounding: what the restaurant earned before tax.
  Money get netSales => billed - roundOff - totalTax;

  /// Average bill (rounded to the paisa).
  Money get averageBill => bills == 0
      ? Money.zero
      : Money((billed.paise * 2 + bills) ~/ (bills * 2));
}

/// Item or category sales from bill lines.
class ItemSalesRow {
  final String name;
  final String category;
  final int qty;
  final Money gross;
  final Money discount;

  const ItemSalesRow({
    required this.name,
    required this.category,
    required this.qty,
    required this.gross,
    required this.discount,
  });

  Money get net => gross - discount;
}

/// A group of bills (by staff, order type or table).
class BillGroupRow {
  final String label;
  final int bills;
  final Money billed;

  const BillGroupRow(this.label, this.bills, this.billed);
}

/// Tax charged at one rate and pricing (items or service charge).
class TaxSummaryRow {
  final String base;
  final int rateBp;
  final bool inclusive;
  final String splitMode;
  final Money taxable;
  final Money cgst;
  final Money sgst;
  final Money igst;
  final Money other;

  const TaxSummaryRow({
    required this.base,
    required this.rateBp,
    required this.inclusive,
    required this.splitMode,
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.other,
  });

  Money get tax => cgst + sgst + igst + other;

  String get rateLabel {
    final pct = rateBp % 100 == 0 ? '${rateBp ~/ 100}' : '${rateBp / 100}';
    return '$pct%';
  }

  String get label {
    final what = base == 'serviceCharge' ? 'Service charge' : 'Items';
    final split = switch (splitMode) {
      'cgstSgst' => 'CGST+SGST',
      'igst' => 'IGST',
      _ => 'Tax',
    };
    return '$what $split $rateLabel${inclusive ? ' incl.' : ''}';
  }
}

/// Money collected with one method, by the date the money moved.
class CollectionRow {
  final String method;
  final int payments;
  final Money received;
  final int reversals;
  final Money reversed;

  const CollectionRow({
    required this.method,
    required this.payments,
    required this.received,
    required this.reversals,
    required this.reversed,
  });

  Money get net => received - reversed;
}

enum BillPayState { paid, partlyPaid, unpaid, voided }

extension BillPayStateX on BillPayState {
  String get label => switch (this) {
    BillPayState.paid => 'Paid',
    BillPayState.partlyPaid => 'Part paid',
    BillPayState.unpaid => 'Unpaid',
    BillPayState.voided => 'Voided',
  };
}

/// One bill in the bill register.
class BillRegisterRow {
  final String billId;
  final String billNumber;
  final String businessDate;
  final DateTime createdAt;
  final int orderNo;
  final String orderType;
  final String tableLabel;
  final String customerName;
  final String customerPhone;
  final String staffName;
  final Money itemsTotal;
  final Money discount;
  final String discountLabel;
  final Money serviceCharge;
  final Money tax;
  final Money roundOff;
  final Money total;

  /// Net of reversals, all dates up to now.
  final Money paid;
  final bool voided;
  final String voidReason;
  final DateTime? voidedAt;

  /// Paid in more than one payment.
  final bool splitPaid;

  const BillRegisterRow({
    required this.billId,
    required this.billNumber,
    required this.businessDate,
    required this.createdAt,
    required this.orderNo,
    required this.orderType,
    required this.tableLabel,
    required this.customerName,
    required this.customerPhone,
    required this.staffName,
    required this.itemsTotal,
    required this.discount,
    required this.discountLabel,
    required this.serviceCharge,
    required this.tax,
    required this.roundOff,
    required this.total,
    required this.paid,
    required this.voided,
    required this.voidReason,
    required this.voidedAt,
    required this.splitPaid,
  });

  Money get balance => voided ? Money.zero : total - paid;

  BillPayState get state => voided
      ? BillPayState.voided
      : paid >= total
      ? BillPayState.paid
      : paid.paise > 0
      ? BillPayState.partlyPaid
      : BillPayState.unpaid;
}

/// A discount given on a bill.
class DiscountRow {
  final String billNumber;
  final int orderNo;
  final String label;
  final String reason;
  final String staffName;
  final Money itemsTotal;
  final Money amount;

  const DiscountRow({
    required this.billNumber,
    required this.orderNo,
    required this.label,
    required this.reason,
    required this.staffName,
    required this.itemsTotal,
    required this.amount,
  });
}

class CancelledOrderRow {
  final int orderNo;
  final String businessDate;
  final String orderType;
  final String reason;
  final String staffName;

  /// Value of the items still on the order when it was cancelled.
  final Money value;

  /// Cancelled because it was merged into another order (not a loss).
  final bool merged;
  final DateTime? at;

  const CancelledOrderRow({
    required this.orderNo,
    required this.businessDate,
    required this.orderType,
    required this.reason,
    required this.staffName,
    required this.value,
    required this.merged,
    required this.at,
  });
}

/// Items cancelled after they were sent to the kitchen.
class ItemVoidRow {
  final int orderNo;
  final String itemName;
  final int qty;
  final String reason;
  final DateTime at;

  const ItemVoidRow({
    required this.orderNo,
    required this.itemName,
    required this.qty,
    required this.reason,
    required this.at,
  });
}

/// A payment that was reversed (refund or correction).
class ReversalRow {
  final String billNumber;
  final int orderNo;
  final String method;
  final Money amount;
  final String reason;
  final String staffName;
  final DateTime at;

  const ReversalRow({
    required this.billNumber,
    required this.orderNo,
    required this.method,
    required this.amount,
    required this.reason,
    required this.staffName,
    required this.at,
  });
}

/// A ledger entry in the period, with its bill number.
class LedgerReportRow {
  final String id;
  final DateTime at;
  final String businessDate;
  final String billNumber;
  final int orderNo;
  final bool reversal;
  final String method;
  final Money amount;
  final Money? tendered;
  final Money? change;
  final String reference;
  final String confirmation;
  final String reason;
  final String staffName;
  final bool inShift;

  const LedgerReportRow({
    required this.id,
    required this.at,
    required this.businessDate,
    required this.billNumber,
    required this.orderNo,
    required this.reversal,
    required this.method,
    required this.amount,
    required this.tendered,
    required this.change,
    required this.reference,
    required this.confirmation,
    required this.reason,
    required this.staffName,
    required this.inShift,
  });

  Money get signedAmount => reversal ? -amount : amount;
}

/// Money still owed, as of when the report was made.
class DueRow {
  final String billNumber;
  final String businessDate;
  final int orderNo;
  final String customerName;
  final String customerPhone;
  final String note;
  final Money total;
  final Money paid;

  const DueRow({
    required this.billNumber,
    required this.businessDate,
    required this.orderNo,
    required this.customerName,
    required this.customerPhone,
    required this.note,
    required this.total,
    required this.paid,
  });

  Money get balance => total - paid;
}

/// Something in the stored data that does not add up. A clean report has
/// none.
class ReconcileIssue {
  final String ref;
  final String message;

  const ReconcileIssue(this.ref, this.message);

  @override
  String toString() => '$ref: $message';
}

/// Everything reported for a period, all from local data.
///
/// **Sales** are finalized bills whose business date is in the period.
/// **Collections** are ledger entries whose money moved in the period,
/// which can include payments for bills from other days. The two are
/// shown apart and never mixed.
class SalesReport {
  final ReportPeriod period;
  final DateTime generatedAt;
  final String business;

  final SalesTotals totals;
  final List<BillRegisterRow> bills;
  final List<ItemSalesRow> items;
  final List<ItemSalesRow> categories;
  final List<BillGroupRow> byStaff;
  final List<BillGroupRow> byOrderType;
  final List<BillGroupRow> byTable;
  final List<TaxSummaryRow> taxes;
  final List<DiscountRow> discounts;

  final List<CollectionRow> collections;
  final List<LedgerReportRow> ledger;

  /// Collected in the period for bills of the period / of other dates.
  final Money collectedForPeriodBills;
  final Money collectedForOtherBills;

  /// Cash recorded with no shift open.
  final Money cashOutsideShifts;

  final List<CancelledOrderRow> cancelledOrders;
  final List<ItemVoidRow> itemVoids;
  final List<ReversalRow> reversals;

  final List<Expense> expenses;
  final List<CashShift> shifts;

  /// All bills still owing money, any date (as of [generatedAt]).
  final List<DueRow> dues;

  final List<ReconcileIssue> issues;

  const SalesReport({
    required this.period,
    required this.generatedAt,
    required this.business,
    required this.totals,
    required this.bills,
    required this.items,
    required this.categories,
    required this.byStaff,
    required this.byOrderType,
    required this.byTable,
    required this.taxes,
    required this.discounts,
    required this.collections,
    required this.ledger,
    required this.collectedForPeriodBills,
    required this.collectedForOtherBills,
    required this.cashOutsideShifts,
    required this.cancelledOrders,
    required this.itemVoids,
    required this.reversals,
    required this.expenses,
    required this.shifts,
    required this.dues,
    required this.issues,
  });

  List<BillRegisterRow> get finalizedBills =>
      bills.where((b) => !b.voided).toList();

  List<BillRegisterRow> get voidedBills =>
      bills.where((b) => b.voided).toList();

  Money get voidedBillsTotal =>
      voidedBills.fold(Money.zero, (s, b) => s + b.total);

  /// Net money collected in the period (all methods).
  Money get collected => collections.fold(Money.zero, (s, c) => s + c.net);

  Money get refunds => collections.fold(Money.zero, (s, c) => s + c.reversed);

  Money collectedBy(String method) => collections
      .where((c) => c.method == method)
      .fold(Money.zero, (s, c) => s + c.net);

  /// For bills of the period, money received so far (any date).
  Money get paidOnPeriodBills =>
      finalizedBills.fold(Money.zero, (s, b) => s + b.paid);

  /// For bills of the period, money still owed.
  Money get outstandingOnPeriodBills =>
      finalizedBills.fold(Money.zero, (s, b) => s + b.balance);

  int get splitPaidBills => finalizedBills.where((b) => b.splitPaid).length;

  int get partPaidBills =>
      finalizedBills.where((b) => b.state == BillPayState.partlyPaid).length;

  int get unpaidBills =>
      finalizedBills.where((b) => b.state == BillPayState.unpaid).length;

  Money get duesTotal => dues.fold(Money.zero, (s, d) => s + d.balance);

  List<Expense> get liveExpenses => expenses.where((e) => !e.isVoided).toList();

  Money get expensesTotal =>
      liveExpenses.fold(Money.zero, (s, e) => s + e.amount);

  /// Expenses by category / by where the money came from.
  Map<String, Money> get expensesByCategory {
    final out = <String, Money>{};
    for (final e in liveExpenses) {
      out[e.category] = (out[e.category] ?? Money.zero) + e.amount;
    }
    return out;
  }

  Map<String, Money> get expensesBySource {
    final out = <String, Money>{};
    for (final e in liveExpenses) {
      out[e.paidFrom.label] = (out[e.paidFrom.label] ?? Money.zero) + e.amount;
    }
    return out;
  }

  Money get discountsTotal => totals.discount;

  int get cancelledCount => cancelledOrders.where((c) => !c.merged).length;
}
