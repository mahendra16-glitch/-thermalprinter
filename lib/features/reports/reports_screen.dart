import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/util/money.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/reports/report_models.dart';
import '../../domain/shifts/shift_models.dart';
import '../../queue/print_queue_manager.dart';
import '../../services/report_csv.dart';
import '../../services/storage_service.dart';
import '../billing/bill_actions.dart';
import '../menu/menu_widgets.dart';
import '../payments/dues_screen.dart';

enum _Preset { today, yesterday, last7, thisMonth, custom }

/// Sales, collections, items, tax, voids, expenses, dues and shifts for a
/// range of business dates. Everything comes from the local database.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  StorageService? _storage;
  _Preset _preset = _Preset.today;
  ReportPeriod? _period;
  SalesReport? _report;
  Object? _error;
  bool _loading = false;
  bool _stale = false;
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final s = await StorageService.getInstance();
    _storage = s;
    _changes = s.reports.watchChanges().listen((_) {
      if (mounted && _report != null && !_loading) {
        setState(() => _stale = true);
      }
    });
    await _choose(_Preset.today);
  }

  Future<void> _choose(_Preset preset, {ReportPeriod? custom}) async {
    final s = _storage;
    if (s == null) return;
    final today = await s.orders.currentBusinessDate();
    final period = switch (preset) {
      _Preset.today => ReportPeriod.day(today),
      _Preset.yesterday => ReportPeriod.day(ReportPeriod.shift(today, -1)),
      _Preset.last7 => ReportPeriod(ReportPeriod.shift(today, -6), today),
      _Preset.thisMonth => ReportPeriod('${today.substring(0, 8)}01', today),
      _Preset.custom => custom!,
    };
    setState(() {
      _preset = preset;
      _period = period;
    });
    await _load();
  }

  Future<void> _load() async {
    final s = _storage;
    final period = _period;
    if (s == null || period == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await s.reports.build(period);
      if (!mounted) return;
      setState(() {
        _report = r;
        _stale = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCustom() async {
    final s = _storage;
    if (s == null) return;
    final today = DateTime.parse(await s.orders.currentBusinessDate());
    if (!mounted) return;
    final current = _period;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: DateTime.parse(current.from),
              end: DateTime.parse(current.to),
            ),
      helpText: 'Business dates',
    );
    if (range == null) return;
    await _choose(
      _Preset.custom,
      custom: ReportPeriod(
        ReportPeriod.dateString(range.start),
        ReportPeriod.dateString(range.end),
      ),
    );
  }

  Future<void> _print() async {
    final s = _storage;
    final period = _period;
    if (s == null || period == null) return;
    var items = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Print report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Business date: ${period.label}'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: items,
                onChanged: (v) => setLocal(() => items = v ?? false),
                title: const Text('Include item-wise sales'),
                subtitle: const Text('Can be long'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Print'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await s.reports.printSummary(period, includeItems: items);
      await (await PrintQueueManager.getInstance()).syncFromStorage();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Report added to the print queue. Check Settings › Print queue '
            'if it does not come out.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not print: $e')));
    }
  }

  Future<void> _export() async {
    final s = _storage;
    final r = _report;
    if (s == null || r == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final out = Directory(
        p.join(dir.path, 'reports-${DateTime.now().millisecondsSinceEpoch}'),
      );
      await out.create(recursive: true);
      final files = <XFile>[];
      final csv = ReportCsv.files(r);
      for (final e in csv.entries) {
        final f = File(p.join(out.path, e.key));
        await f.writeAsBytes(utf8.encode(e.value));
        files.add(XFile(f.path, mimeType: 'text/csv'));
      }
      await s.reports.recordExport(r.period, csv.keys.toList());
      await SharePlus.instance.share(
        ShareParams(files: files, subject: 'Report ${r.period.label}'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Print summary',
              onPressed: r == null ? null : _print,
              icon: const Icon(Icons.print_outlined),
            ),
            IconButton(
              tooltip: 'Export CSV',
              onPressed: r == null ? null : _export,
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Items'),
              Tab(text: 'Payments'),
              Tab(text: 'Bills'),
              Tab(text: 'Tax'),
              Tab(text: 'Voids'),
              Tab(text: 'Expenses'),
              Tab(text: 'Dues'),
              Tab(text: 'Shifts'),
            ],
          ),
        ),
        body: Column(
          children: [
            _periodBar(),
            if (_stale)
              MaterialBanner(
                content: const Text('New sales or payments since this report.'),
                actions: [
                  TextButton(onPressed: _load, child: const Text('Refresh')),
                ],
              ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _body(r)),
          ],
        ),
      ),
    );
  }

  Widget _periodBar() {
    final period = _period;
    Widget chip(String label, _Preset p) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: _preset == p,
        onSelected: _loading
            ? null
            : (_) => p == _Preset.custom ? _pickCustom() : _choose(p),
      ),
    );
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  chip('Today', _Preset.today),
                  chip('Yesterday', _Preset.yesterday),
                  chip('Last 7 days', _Preset.last7),
                  chip('This month', _Preset.thisMonth),
                  chip('Dates…', _Preset.custom),
                ],
              ),
            ),
            if (period != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Business date: ${_dateLabel(period)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _dateLabel(ReportPeriod p) {
    final f = DateFormat('d MMM yyyy');
    final a = f.format(DateTime.parse(p.from));
    return p.isSingleDay ? a : '$a – ${f.format(DateTime.parse(p.to))}';
  }

  Widget _body(SalesReport? r) {
    if (_error != null) {
      return MessageState(
        icon: Icons.error_outline_rounded,
        title: 'Could not build the report',
        message: '$_error',
        action: FilledButton(onPressed: _load, child: const Text('Try again')),
      );
    }
    if (r == null) return const Center(child: CircularProgressIndicator());
    return TabBarView(
      children: [
        _SummaryTab(r),
        _ItemsTab(r),
        _PaymentsTab(r),
        _BillsTab(r),
        _TaxTab(r),
        _VoidsTab(r),
        _ExpensesTab(r),
        _DuesTab(r),
        _ShiftsTab(r, storage: _storage!),
      ],
    );
  }
}

// --------------------------------------------------------------- widgets

final _time = DateFormat('dd MMM, hh:mm a');

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? note;

  const _Section(this.title, this.children, {this.note});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(note!, style: const TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final String? sub;

  const _Row(this.label, this.value, {this.bold = false, this.sub});

  _Row.money(String label, Money m, {bool bold = false, String? sub})
    : this(label, m.format(), bold: bold, sub: sub);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (sub != null && sub!.isNotEmpty)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}

Widget _empty(String title, [String? message]) => MessageState(
  icon: Icons.insert_chart_outlined_rounded,
  title: title,
  message: message,
);

// ------------------------------------------------------------------- tabs

class _SummaryTab extends StatelessWidget {
  final SalesReport r;

  const _SummaryTab(this.r);

  @override
  Widget build(BuildContext context) {
    final data = ReportRepository.printData(r);
    final sections = (data['sections'] as List).cast<Map<String, Object?>>();
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _IssuesCard(r.issues),
        for (final s in sections)
          _Section(s['title'] as String, [
            for (final row in (s['rows'] as List).cast<Map<String, Object?>>())
              _Row(
                row['l'] as String,
                row['v'] is int
                    ? Money(row['v'] as int).format()
                    : row['s'] as String? ?? '',
                bold: row['b'] == true,
              ),
          ]),
        if (r.byStaff.isNotEmpty)
          _Section('BY STAFF', [
            for (final g in r.byStaff)
              _Row.money('${g.label} (${g.bills} bills)', g.billed),
          ], note: 'Staff name typed on the order.'),
        if (r.byTable.isNotEmpty)
          _Section('BY TABLE (dine-in)', [
            for (final g in r.byTable)
              _Row.money('${g.label} (${g.bills} bills)', g.billed),
          ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Sales are bills of these business dates (voided bills left out). '
            'Money collected is what was received on these dates, which can '
            'include payments for earlier bills. UPI and card are '
            'staff-confirmed, not bank-verified.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _IssuesCard extends StatelessWidget {
  final List<ReconcileIssue> issues;

  const _IssuesCard(this.issues);

  @override
  Widget build(BuildContext context) {
    final ok = issues.isEmpty;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      color: ok ? Colors.green.shade50 : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          ok ? Icons.verified_outlined : Icons.report_problem_outlined,
          color: ok ? Colors.green.shade800 : Colors.red.shade800,
        ),
        title: Text(
          ok
              ? 'Checked against the payment ledger'
              : '${issues.length} problem(s) found in the data',
        ),
        subtitle: Text(
          ok
              ? 'Every bill adds up, and paid / due states match payments.'
              : issues.take(20).join('\n'),
        ),
      ),
    );
  }
}

class _ItemsTab extends StatefulWidget {
  final SalesReport r;

  const _ItemsTab(this.r);

  @override
  State<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<_ItemsTab> {
  bool _categories = false;

  @override
  Widget build(BuildContext context) {
    final rows = _categories ? widget.r.categories : widget.r.items;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Items')),
              ButtonSegment(value: true, label: Text('Categories')),
            ],
            selected: {_categories},
            onSelectionChanged: (v) => setState(() => _categories = v.first),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? _empty('No items sold')
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final x = rows[i];
                    return ListTile(
                      dense: true,
                      title: Text(x.name),
                      subtitle: Text(
                        [
                          if (!_categories) x.category,
                          'Qty ${x.qty}',
                          if (!x.discount.isZero)
                            '${x.gross.format()} − ${x.discount.format()} discount',
                        ].join(' · '),
                      ),
                      trailing: Text(
                        x.net.format(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final SalesReport r;

  const _PaymentsTab(this.r);

  @override
  Widget build(BuildContext context) {
    if (r.ledger.isEmpty) {
      return _empty('No payments on these dates');
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Section('BY METHOD', [
          for (final c in r.collections)
            _Row.money(
              c.method,
              c.net,
              bold: true,
              sub: [
                '${c.payments} payment(s) ${c.received.format()}',
                if (c.reversals > 0)
                  '${c.reversals} reversed ${c.reversed.format()}',
              ].join(' · '),
            ),
          const Divider(),
          _Row.money('Net collected', r.collected, bold: true),
          _Row.money('For bills of these dates', r.collectedForPeriodBills),
          _Row.money('For bills of other dates', r.collectedForOtherBills),
          if (!r.cashOutsideShifts.isZero)
            _Row.money(
              'Cash taken with no shift open',
              r.cashOutsideShifts,
              sub: 'Not in any drawer count',
            ),
        ], note: 'By the date the money was received.'),
        _Section('LEDGER', [
          for (final e in r.ledger)
            _Row.money(
              '${e.reversal ? 'Reversed' : 'Paid'} ${e.method} · '
              'Bill ${e.billNumber}',
              e.signedAmount,
              sub: [
                _time.format(e.at),
                if (e.reference.isNotEmpty) 'Ref ${e.reference}',
                if (e.reason.isNotEmpty) e.reason,
                if (e.staffName.isNotEmpty) e.staffName,
              ].join(' · '),
            ),
        ]),
      ],
    );
  }
}

class _BillsTab extends StatelessWidget {
  final SalesReport r;

  const _BillsTab(this.r);

  @override
  Widget build(BuildContext context) {
    if (r.bills.isEmpty) return _empty('No bills on these dates');
    final bills = r.bills.reversed.toList();
    return ListView.separated(
      itemCount: bills.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final b = bills[i];
        final color = switch (b.state) {
          BillPayState.paid => Colors.green.shade800,
          BillPayState.partlyPaid => Colors.orange.shade800,
          BillPayState.unpaid => Colors.red.shade800,
          BillPayState.voided => Colors.grey,
        };
        return ListTile(
          onTap: () => showBill(context, b.billId),
          title: Text(
            [
              'Bill ${b.billNumber}',
              'Order #${b.orderNo}',
              b.orderType,
              if (b.tableLabel.isNotEmpty) b.tableLabel,
            ].join(' · '),
            style: TextStyle(
              decoration: b.voided ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            [
              _time.format(b.createdAt),
              if (b.customerName.isNotEmpty) b.customerName,
              if (b.voided && b.voidReason.isNotEmpty) 'Void: ${b.voidReason}',
              if (b.state == BillPayState.partlyPaid)
                '${b.balance.format()} left',
            ].join(' · '),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                b.total.format(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(b.state.label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        );
      },
    );
  }
}

class _TaxTab extends StatelessWidget {
  final SalesReport r;

  const _TaxTab(this.r);

  @override
  Widget build(BuildContext context) {
    if (r.taxes.isEmpty) return _empty('No tax charged on these dates');
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final x in r.taxes)
          _Section(x.label, [
            _Row.money('Taxable value', x.taxable),
            if (!x.cgst.isZero) _Row.money('CGST', x.cgst),
            if (!x.sgst.isZero) _Row.money('SGST', x.sgst),
            if (!x.igst.isZero) _Row.money('IGST', x.igst),
            if (!x.other.isZero) _Row.money('Tax', x.other),
            _Row.money('Total tax', x.tax, bold: true),
          ]),
        _Section('TOTAL', [
          _Row.money('Tax added to bills', r.totals.exclusiveTax),
          _Row.money('Tax included in prices', r.totals.inclusiveTax),
          _Row.money('Total tax', r.totals.totalTax, bold: true),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Totals of the tax printed on finalized bills, as calculated by '
            'the app. Check with your accountant before filing returns.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _VoidsTab extends StatelessWidget {
  final SalesReport r;

  const _VoidsTab(this.r);

  @override
  Widget build(BuildContext context) {
    final cancelled = r.cancelledOrders.where((c) => !c.merged).toList();
    final merged = r.cancelledOrders.where((c) => c.merged).toList();
    if (r.voidedBills.isEmpty &&
        r.cancelledOrders.isEmpty &&
        r.itemVoids.isEmpty &&
        r.reversals.isEmpty &&
        r.discounts.isEmpty) {
      return _empty('No voids, refunds or discounts');
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (r.voidedBills.isNotEmpty)
          _Section('VOIDED BILLS', [
            for (final b in r.voidedBills)
              _Row.money(
                'Bill ${b.billNumber} · Order #${b.orderNo}',
                b.total,
                sub: [
                  if (b.voidedAt != null) _time.format(b.voidedAt!),
                  b.voidReason,
                ].join(' · '),
              ),
          ], note: 'The order was reopened; a new bill replaces it.'),
        if (r.reversals.isNotEmpty)
          _Section('REFUNDS / REVERSED PAYMENTS', [
            for (final x in r.reversals)
              _Row.money(
                '${x.method} · Bill ${x.billNumber}',
                x.amount,
                sub: [
                  _time.format(x.at),
                  x.reason,
                  x.staffName,
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
          ]),
        if (cancelled.isNotEmpty)
          _Section('CANCELLED ORDERS', [
            for (final c in cancelled)
              _Row.money(
                'Order #${c.orderNo} · ${c.orderType}',
                c.value,
                sub: c.reason,
              ),
          ], note: 'Value of the items on the order when cancelled.'),
        if (r.itemVoids.isNotEmpty)
          _Section('ITEMS VOIDED AFTER KOT', [
            for (final v in r.itemVoids)
              _Row(
                '${v.itemName} · Order #${v.orderNo}',
                '× ${v.qty}',
                sub: [
                  _time.format(v.at),
                  v.reason,
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
          ]),
        if (r.discounts.isNotEmpty)
          _Section('DISCOUNTS', [
            for (final d in r.discounts)
              _Row.money(
                'Bill ${d.billNumber} · ${d.label}',
                d.amount,
                sub: [
                  'on ${d.itemsTotal.format()}',
                  d.reason,
                  d.staffName,
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
            const Divider(),
            _Row.money('Total discounts', r.discountsTotal, bold: true),
          ]),
        if (merged.isNotEmpty)
          _Section('MERGED ORDERS', [
            for (final c in merged)
              _Row('Order #${c.orderNo}', '', sub: c.reason),
          ], note: 'Moved into another order, not lost sales.'),
      ],
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final SalesReport r;

  const _ExpensesTab(this.r);

  @override
  Widget build(BuildContext context) {
    if (r.expenses.isEmpty) return _empty('No expenses on these dates');
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Section('BY CATEGORY', [
          for (final e in r.expensesByCategory.entries)
            _Row.money(e.key, e.value),
          const Divider(),
          _Row.money('Total', r.expensesTotal, bold: true),
        ]),
        _Section('PAID FROM', [
          for (final e in r.expensesBySource.entries)
            _Row.money(e.key, e.value),
        ]),
        _Section('ALL EXPENSES', [
          for (final e in r.expenses)
            Opacity(
              opacity: e.isVoided ? 0.5 : 1,
              child: _Row.money(
                '${e.category}${e.isVoided ? ' (cancelled)' : ''}',
                e.amount,
                sub: [
                  _time.format(e.createdAt),
                  e.paidFrom.label,
                  e.note,
                  e.staffName,
                  if (e.isVoided) 'Cancelled: ${e.voidReason}',
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
            ),
        ]),
      ],
    );
  }
}

class _DuesTab extends StatelessWidget {
  final SalesReport r;

  const _DuesTab(this.r);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Section(
          'MONEY OWED (all dates)',
          [
            _Row.money('${r.dues.length} bill(s)', r.duesTotal, bold: true),
            for (final d in r.dues)
              _Row.money(
                'Bill ${d.billNumber} · '
                '${[d.customerName, d.customerPhone].where((s) => s.isNotEmpty).join(' ')}',
                d.balance,
                sub: [
                  d.businessDate,
                  'of ${d.total.format()}',
                  d.note,
                ].where((s) => s.isNotEmpty).join(' · '),
              ),
          ],
          note:
              'As of ${_time.format(r.generatedAt)}, whatever the dates '
              'chosen above.',
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const DuesScreen())),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Open Dues & payments'),
          ),
        ),
      ],
    );
  }
}

class _ShiftsTab extends StatelessWidget {
  final SalesReport r;
  final StorageService storage;

  const _ShiftsTab(this.r, {required this.storage});

  Future<void> _print(BuildContext context, CashShift s) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await storage.shifts.printReport(s.id);
      await (await PrintQueueManager.getInstance()).syncFromStorage();
      messenger.showSnackBar(
        const SnackBar(content: Text('Shift report added to the print queue.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not print: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (r.shifts.isEmpty) return _empty('No shifts on these dates');
    return ListView.separated(
      itemCount: r.shifts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final s = r.shifts[i];
        final v = s.variance;
        final result = s.isOpen
            ? 'Open'
            : v == null || v.isZero
            ? 'Matched'
            : v.isNegative
            ? 'Short ${(-v).format()}'
            : 'Over ${v.format()}';
        return ListTile(
          title: Text(
            '${_time.format(s.openedAt)} · ${s.openedBy}'
            '${s.closedAt == null ? '' : ' → ${_time.format(s.closedAt!)}'}',
          ),
          subtitle: Text(
            [
              'Opening ${s.openingCash.format()}',
              if (s.expectedCash != null)
                'Expected ${s.expectedCash!.format()}',
              if (s.countedCash != null) 'Counted ${s.countedCash!.format()}',
              if (s.varianceReason.isNotEmpty) s.varianceReason,
            ].join(' · '),
          ),
          trailing: Text(
            result,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: s.isOpen || v == null || v.isZero
                  ? null
                  : Colors.red.shade800,
            ),
          ),
          onTap: () => _print(context, s),
        );
      },
    );
  }
}
