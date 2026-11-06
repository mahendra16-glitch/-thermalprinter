import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../core/util/money.dart';
import '../domain/reports/report_models.dart';
import '../domain/shifts/shift_models.dart';

/// CSV files for a [SalesReport]. Amounts are rupees with two decimals and
/// no grouping (e.g. `1234.50`) so spreadsheets read them as numbers.
class ReportCsv {
  ReportCsv._();

  static final _time = DateFormat('yyyy-MM-dd HH:mm');

  /// File name -> CSV text (UTF-8 with BOM so Excel shows ₹ and Hindi).
  static Map<String, String> files(SalesReport r) {
    final tag = r.period.isSingleDay
        ? r.period.from
        : '${r.period.from}_to_${r.period.to}';
    return {
      'summary-$tag.csv': _encode(summary(r)),
      'bills-$tag.csv': _encode(bills(r)),
      'items-$tag.csv': _encode(items(r)),
      'payments-$tag.csv': _encode(payments(r)),
      'tax-$tag.csv': _encode(tax(r)),
      'voids-$tag.csv': _encode(voids(r)),
      'expenses-$tag.csv': _encode(expenses(r)),
      'dues-$tag.csv': _encode(dues(r)),
    };
  }

  static String _encode(List<List<Object?>> rows) =>
      '﻿${Csv(lineDelimiter: '\n').encode(rows)}';

  static String _amt(Money m) {
    final sign = m.isNegative ? '-' : '';
    final a = m.paise.abs();
    return '$sign${a ~/ 100}.${(a % 100).toString().padLeft(2, '0')}';
  }

  /// Text typed by staff. A leading = + - @ would run as a formula in a
  /// spreadsheet, so such cells get a leading apostrophe.
  static String _txt(String s) =>
      RegExp(r'^[=+\-@\t\r]').hasMatch(s) ? "'$s" : s;

  static List<List<Object?>> summary(SalesReport r) {
    final t = r.totals;
    final rows = <List<Object?>>[
      ['section', 'item', 'value'],
      ['period', 'from', r.period.from],
      ['period', 'to', r.period.to],
      ['period', 'generated', _time.format(r.generatedAt)],
      ['sales', 'bills', t.bills],
      ['sales', 'items_sold', t.itemQty],
      ['sales', 'gross_item_sales', _amt(t.grossSales)],
      ['sales', 'discounts', _amt(t.discount)],
      ['sales', 'service_charge', _amt(t.serviceCharge)],
      ['sales', 'net_sales_before_tax', _amt(t.netSales)],
      ['sales', 'tax_added', _amt(t.exclusiveTax)],
      ['sales', 'tax_included_in_prices', _amt(t.inclusiveTax)],
      ['sales', 'total_tax', _amt(t.totalTax)],
      ['sales', 'round_off', _amt(t.roundOff)],
      ['sales', 'total_billed', _amt(t.billed)],
      ['sales', 'average_bill', _amt(t.averageBill)],
      ['period_bills', 'paid_so_far', _amt(r.paidOnPeriodBills)],
      ['period_bills', 'still_to_collect', _amt(r.outstandingOnPeriodBills)],
      ['period_bills', 'paid_in_parts', r.splitPaidBills],
      ['period_bills', 'part_paid', r.partPaidBills],
      ['period_bills', 'unpaid', r.unpaidBills],
    ];
    for (final c in r.collections) {
      rows.add(['collected', '${c.method}_received', _amt(c.received)]);
      rows.add(['collected', '${c.method}_refunded', _amt(c.reversed)]);
      rows.add(['collected', '${c.method}_net', _amt(c.net)]);
    }
    rows.addAll([
      ['collected', 'net_collected', _amt(r.collected)],
      ['collected', 'for_bills_of_period', _amt(r.collectedForPeriodBills)],
      ['collected', 'for_bills_of_other_dates', _amt(r.collectedForOtherBills)],
      ['collected', 'cash_with_no_shift_open', _amt(r.cashOutsideShifts)],
      ['voids', 'voided_bills', r.voidedBills.length],
      ['voids', 'voided_bills_value', _amt(r.voidedBillsTotal)],
      ['voids', 'cancelled_orders', r.cancelledCount],
      ['voids', 'items_voided', r.itemVoids.fold<int>(0, (s, v) => s + v.qty)],
      ['voids', 'reversals', r.reversals.length],
      ['voids', 'reversed_amount', _amt(r.refunds)],
      ['expenses', 'total', _amt(r.expensesTotal)],
      for (final e in r.expensesBySource.entries)
        ['expenses', e.key, _amt(e.value)],
      ['dues', 'bills_owing', r.dues.length],
      ['dues', 'total_owed', _amt(r.duesTotal)],
      for (final g in r.byOrderType) ['order_type', g.label, _amt(g.billed)],
      for (final g in r.byStaff) ['staff', _txt(g.label), _amt(g.billed)],
      for (final g in r.byTable) ['table', _txt(g.label), _amt(g.billed)],
      for (final c in r.categories) ['category', _txt(c.name), _amt(c.net)],
      ['check', 'problems_found', r.issues.length],
      for (final i in r.issues) ['check', _txt(i.ref), _txt(i.message)],
    ]);
    return rows;
  }

  static List<List<Object?>> bills(SalesReport r) => [
    [
      'bill_no',
      'business_date',
      'time',
      'order_no',
      'type',
      'table',
      'customer',
      'phone',
      'staff',
      'items_total',
      'discount',
      'discount_label',
      'service_charge',
      'tax',
      'round_off',
      'total',
      'paid',
      'balance',
      'status',
      'void_reason',
    ],
    for (final b in r.bills)
      [
        _txt(b.billNumber),
        b.businessDate,
        _time.format(b.createdAt),
        b.orderNo,
        b.orderType,
        _txt(b.tableLabel),
        _txt(b.customerName),
        _txt(b.customerPhone),
        _txt(b.staffName),
        _amt(b.itemsTotal),
        _amt(b.discount),
        _txt(b.discountLabel),
        _amt(b.serviceCharge),
        _amt(b.tax),
        _amt(b.roundOff),
        _amt(b.total),
        _amt(b.paid),
        _amt(b.balance),
        b.state.label,
        _txt(b.voidReason),
      ],
  ];

  static List<List<Object?>> items(SalesReport r) => [
    ['item', 'category', 'qty', 'gross', 'discount', 'net'],
    for (final i in r.items)
      [
        _txt(i.name),
        _txt(i.category),
        i.qty,
        _amt(i.gross),
        _amt(i.discount),
        _amt(i.net),
      ],
  ];

  static List<List<Object?>> payments(SalesReport r) => [
    [
      'time',
      'business_date',
      'bill_no',
      'order_no',
      'kind',
      'method',
      'amount',
      'signed_amount',
      'cash_received',
      'change',
      'reference',
      'confirmation',
      'reason',
      'staff',
      'in_shift',
    ],
    for (final p in r.ledger)
      [
        _time.format(p.at),
        p.businessDate,
        _txt(p.billNumber),
        p.orderNo,
        p.reversal ? 'reversal' : 'payment',
        _txt(p.method),
        _amt(p.amount),
        _amt(p.signedAmount),
        p.tendered == null ? '' : _amt(p.tendered!),
        p.change == null ? '' : _amt(p.change!),
        _txt(p.reference),
        p.confirmation,
        _txt(p.reason),
        _txt(p.staffName),
        p.inShift ? 'yes' : 'no',
      ],
  ];

  static List<List<Object?>> tax(SalesReport r) => [
    [
      'on',
      'rate',
      'pricing',
      'split',
      'taxable',
      'cgst',
      'sgst',
      'igst',
      'other',
      'total_tax',
    ],
    for (final x in r.taxes)
      [
        x.base == 'serviceCharge' ? 'service charge' : 'items',
        x.rateLabel,
        x.inclusive ? 'inclusive' : 'exclusive',
        x.splitMode,
        _amt(x.taxable),
        _amt(x.cgst),
        _amt(x.sgst),
        _amt(x.igst),
        _amt(x.other),
        _amt(x.tax),
      ],
  ];

  static List<List<Object?>> voids(SalesReport r) => [
    ['kind', 'time', 'ref', 'detail', 'qty', 'amount', 'reason', 'staff'],
    for (final b in r.voidedBills)
      [
        'voided bill',
        b.voidedAt == null ? '' : _time.format(b.voidedAt!),
        _txt(b.billNumber),
        'Order #${b.orderNo}',
        '',
        _amt(b.total),
        _txt(b.voidReason),
        _txt(b.staffName),
      ],
    for (final c in r.cancelledOrders)
      [
        c.merged ? 'merged order' : 'cancelled order',
        c.at == null ? '' : _time.format(c.at!),
        'Order #${c.orderNo}',
        c.orderType,
        '',
        _amt(c.value),
        _txt(c.reason),
        _txt(c.staffName),
      ],
    for (final v in r.itemVoids)
      [
        'item voided',
        _time.format(v.at),
        'Order #${v.orderNo}',
        _txt(v.itemName),
        v.qty,
        '',
        _txt(v.reason),
        '',
      ],
    for (final x in r.reversals)
      [
        'payment reversed',
        _time.format(x.at),
        _txt(x.billNumber),
        _txt(x.method),
        '',
        _amt(x.amount),
        _txt(x.reason),
        _txt(x.staffName),
      ],
    for (final d in r.discounts)
      [
        'discount',
        '',
        _txt(d.billNumber),
        _txt(d.label),
        '',
        _amt(d.amount),
        _txt(d.reason),
        _txt(d.staffName),
      ],
  ];

  static List<List<Object?>> expenses(SalesReport r) => [
    [
      'time',
      'business_date',
      'category',
      'paid_from',
      'amount',
      'note',
      'staff',
      'cancelled',
      'cancel_reason',
    ],
    for (final e in r.expenses)
      [
        _time.format(e.createdAt),
        e.businessDate,
        _txt(e.category),
        e.paidFrom.label,
        _amt(e.amount),
        _txt(e.note),
        _txt(e.staffName),
        e.isVoided ? 'yes' : 'no',
        _txt(e.voidReason),
      ],
  ];

  static List<List<Object?>> dues(SalesReport r) => [
    [
      'bill_no',
      'business_date',
      'order_no',
      'customer',
      'phone',
      'note',
      'total',
      'paid',
      'balance',
    ],
    for (final d in r.dues)
      [
        _txt(d.billNumber),
        d.businessDate,
        d.orderNo,
        _txt(d.customerName),
        _txt(d.customerPhone),
        _txt(d.note),
        _amt(d.total),
        _amt(d.paid),
        _amt(d.balance),
      ],
  ];
}
