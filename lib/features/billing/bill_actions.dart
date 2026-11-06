import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../data/repositories/bill_repository.dart';
import '../../domain/billing/bill_calculator.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/billing/billing_settings.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../models/print_job.dart';
import '../../queue/print_queue_manager.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import '../payments/payment_actions.dart';

/// One printed row of a bill breakdown.
class BreakdownRow {
  final String label;
  final Money amount;
  final bool bold;

  /// Shown for information only (inclusive tax): not added to the total.
  final bool info;

  const BreakdownRow(
    this.label,
    this.amount, {
    this.bold = false,
    this.info = false,
  });
}

/// The same rows the printed bill shows, for preview and bill screens.
List<BreakdownRow> breakdownRows({
  required int itemCount,
  required Money itemsTotal,
  required Money discount,
  required String discountLabel,
  required Money serviceCharge,
  required int serviceChargeBp,
  required List<BillTax> taxes,
  required Money roundOff,
  required Money grandTotal,
}) {
  final rows = <BreakdownRow>[
    BreakdownRow('Items ($itemCount)', itemsTotal),
    if (!discount.isZero)
      BreakdownRow(
        discountLabel.isEmpty ? 'Discount' : discountLabel,
        -discount,
      ),
    if (!serviceCharge.isZero)
      BreakdownRow(
        'Service charge ${formatBp(serviceChargeBp)}',
        serviceCharge,
      ),
  ];
  for (final t in taxes) {
    if (t.tax.isZero) continue;
    final on = t.base == TaxBase.serviceCharge
        ? ' on service charge'
        : ' on ${t.taxable.format()}';
    final pre = t.inclusive ? 'Incl. ' : '';
    switch (t.splitMode) {
      case TaxSplitMode.cgstSgst:
        final half = t.rateBp.isEven
            ? formatBp(t.rateBp ~/ 2)
            : '${formatBp(t.rateBp)}/2';
        rows.add(
          BreakdownRow('${pre}CGST $half$on', t.cgst, info: t.inclusive),
        );
        rows.add(
          BreakdownRow('${pre}SGST $half$on', t.sgst, info: t.inclusive),
        );
      case TaxSplitMode.igst:
        rows.add(
          BreakdownRow(
            '${pre}IGST ${formatBp(t.rateBp)}$on',
            t.igst,
            info: t.inclusive,
          ),
        );
      case TaxSplitMode.none:
        rows.add(
          BreakdownRow(
            '${pre}Tax ${formatBp(t.rateBp)}$on',
            t.other,
            info: t.inclusive,
          ),
        );
    }
  }
  if (!roundOff.isZero) rows.add(BreakdownRow('Round off', roundOff));
  rows.add(BreakdownRow('Total', grandTotal, bold: true));
  return rows;
}

List<BreakdownRow> rowsForBill(Bill b) => breakdownRows(
  itemCount: b.itemCount,
  itemsTotal: b.itemsTotal,
  discount: b.discount,
  discountLabel: b.discountLabel,
  serviceCharge: b.serviceCharge,
  serviceChargeBp: b.serviceChargeBp,
  taxes: b.taxes,
  roundOff: b.roundOff,
  grandTotal: b.grandTotal,
);

List<BreakdownRow> rowsForDraft(BillDraft d) {
  final o = d.order.order;
  final c = d.calc;
  return breakdownRows(
    itemCount: c.itemCount,
    itemsTotal: c.itemsTotal,
    discount: c.discount,
    discountLabel: c.discount.isZero
        ? ''
        : 'Discount (${o.discount.label}'
              '${o.discount.reason.isEmpty ? '' : ' · ${o.discount.reason}'})',
    serviceCharge: c.serviceCharge,
    serviceChargeBp: c.serviceChargeBp,
    taxes: c.taxes.map(BillTax.of).toList(),
    roundOff: c.roundOff,
    grandTotal: c.grandTotal,
  );
}

class BreakdownView extends StatelessWidget {
  final List<BreakdownRow> rows;

  const BreakdownView(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    final anyInfo = rows.any((r) => r.info);
    return Column(
      children: [
        for (final r in rows) ...[
          if (r.bold) const Divider(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontWeight: r.bold ? FontWeight.bold : null,
                      fontSize: r.bold ? 18 : 14,
                      color: r.info ? const Color(0xFF64748B) : null,
                    ),
                  ),
                ),
                Text(
                  r.info ? '(${r.amount.format()})' : r.amount.format(),
                  style: TextStyle(
                    fontWeight: r.bold ? FontWeight.bold : null,
                    fontSize: r.bold ? 18 : 14,
                    color: r.info ? const Color(0xFF64748B) : null,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (anyInfo)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Amounts in brackets are already included in the item prices.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }
}

/// Shows the bill preview and, when staff confirm, finalizes the bill.
/// Returns the new bill id, or null if nothing was saved.
Future<String?> generateBill(BuildContext context, String orderId) async {
  final storage = await StorageService.getInstance();
  final BillDraft draft;
  try {
    draft = await storage.bills.preview(orderId);
  } on ValidationException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return null;
  }
  if (!context.mounted) return null;
  if (draft.calc.lines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('There is nothing to bill on this order.')),
    );
    return null;
  }

  // One id for this bill action: tapping twice cannot make two bills.
  final requestId = newId();
  final choice = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PreviewSheet(draft: draft),
  );
  if (choice == null || !context.mounted) return null;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final id = await storage.bills.finalize(
      orderId,
      clientRequestId: requestId,
      expectedTotal: draft.calc.grandTotal,
      allowUnsent: draft.unsentUnits > 0,
      print: choice,
    );
    if (choice) {
      await (await PrintQueueManager.getInstance()).syncFromStorage();
    }
    final bill = await storage.bills.getBill(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Bill ${bill?.billNumber ?? ''} saved · '
          '${draft.calc.grandTotal.format()}'
          '${choice ? '. Sent to the bill printer.' : '.'}',
        ),
      ),
    );
    return id;
  } on ValidationException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not save the bill: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
  return null;
}

class _PreviewSheet extends StatelessWidget {
  final BillDraft draft;

  const _PreviewSheet({required this.draft});

  @override
  Widget build(BuildContext context) {
    final c = draft.calc;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (ctx, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Bill preview · Order #${draft.order.order.orderNo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check the bill. Once saved it cannot be edited; to correct '
                  'it you must void it.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                if (draft.unsentUnits > 0)
                  Card(
                    color: const Color(0xFFFEF3C7),
                    margin: const EdgeInsets.only(top: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${draft.unsentUnits} item(s) were never sent to the '
                        'kitchen. They will be billed anyway.',
                        style: const TextStyle(color: Color(0xFF92400E)),
                      ),
                    ),
                  ),
                const Divider(height: 24),
                for (final l in c.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            [
                              l.variantText.isEmpty
                                  ? l.name
                                  : '${l.name} (${l.variantText})',
                              if (l.addons.isNotEmpty)
                                '+ ${l.addons.join(', ')}',
                            ].join('\n'),
                          ),
                        ),
                        Text('${l.qty} × ${l.unitPrice.format()}  '),
                        SizedBox(
                          width: 90,
                          child: Text(
                            l.gross.format(),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                BreakdownView(rowsForDraft(draft)),
                const SizedBox(height: 12),
                Text(
                  'Rounding: ${draft.settings.rounding.label}. Tax and '
                  'service charge come from Settings › Billing & tax and the '
                  'tax set on each item.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Save without printing'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Save & print'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bill details with its print status, reprint and void.
Future<void> showBill(BuildContext context, String billId) async {
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (ctx, scroll) => StreamBuilder<void>(
        stream: storage.payments.watchChanges(),
        builder: (ctx, _) =>
            FutureBuilder<(Bill?, List<PrintJob>, BillPaymentSummary?)>(
              future: _loadBill(storage, billId),
              builder: (ctx, snap) {
                final data = snap.data;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final (bill, jobs, pay) = data;
                if (bill == null) {
                  return const MessageState(
                    icon: Icons.error_outline_rounded,
                    title: 'Bill not found',
                  );
                }
                return _BillView(
                  bill: bill,
                  jobs: jobs,
                  pay: pay,
                  scroll: scroll,
                );
              },
            ),
      ),
    ),
  );
}

Future<(Bill?, List<PrintJob>, BillPaymentSummary?)> _loadBill(
  StorageService storage,
  String billId,
) async {
  final bill = await storage.bills.getBill(billId);
  return (
    bill,
    await storage.bills.printJobsFor(billId),
    bill == null ? null : await storage.payments.summaryFor(billId),
  );
}

class _BillView extends StatelessWidget {
  final Bill bill;
  final List<PrintJob> jobs;
  final BillPaymentSummary? pay;
  final ScrollController scroll;

  const _BillView({
    required this.bill,
    required this.jobs,
    required this.pay,
    required this.scroll,
  });

  (String, Color, String?) get _printState {
    final live = jobs.where((j) => j.status != PrintJobStatus.cancelled);
    if (live.isEmpty) {
      return ('Not printed', const Color(0xFF64748B), null);
    }
    final last = live.last;
    return switch (last.status) {
      PrintJobStatus.printed => ('Printed', const Color(0xFF16A34A), null),
      PrintJobStatus.failed => (
        'Print failed',
        const Color(0xFFDC2626),
        last.errorMessage,
      ),
      _ => ('Printing…', const Color(0xFF2563EB), null),
    };
  }

  @override
  Widget build(BuildContext context) {
    final b = bill;
    final (label, color, error) = _printState;
    final failed = jobs
        .where((j) => j.status == PrintJobStatus.failed)
        .map((j) => j.id)
        .toList();
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bill ${b.billNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (b.isVoided)
              const SmallBadge('VOIDED', color: Color(0xFFDC2626))
            else
              SmallBadge(label, color: color),
          ],
        ),
        Text(
          [
            'Order #${b.orderNo}',
            b.orderTypeLabel,
            if (b.tableLabel.isNotEmpty) 'Table ${b.tableLabel}',
            DateFormat('dd MMM yyyy, hh:mm a').format(b.createdAt),
          ].join(' · '),
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        if (b.isVoided)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Voided${b.voidedAt == null ? '' : ' ${DateFormat('dd MMM, hh:mm a').format(b.voidedAt!)}'}'
              ': ${b.voidReason}',
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        if (!b.isVoided && error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        if (!b.isVoided)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '"Printed" means the printer accepted the data; check the bill '
              'actually came out.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
        const Divider(height: 24),
        for (final l in b.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    [
                      l.displayName,
                      if (l.addonsText.isNotEmpty) '+ ${l.addonsText}',
                    ].join('\n'),
                  ),
                ),
                Text('${l.qty} × ${l.unitPrice.format()}  '),
                SizedBox(
                  width: 90,
                  child: Text(l.gross.format(), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        BreakdownView(rowsForBill(b)),
        if (pay != null && !b.isVoided) ...[
          const Divider(height: 24),
          PaymentHistory(pay!),
        ],
        const SizedBox(height: 16),
        if (!b.isVoided)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (failed.isNotEmpty)
                FilledButton.tonal(
                  onPressed: () async {
                    final q = await PrintQueueManager.getInstance();
                    for (final id in failed) {
                      await q.retryJob(id);
                    }
                  },
                  child: const Text('Retry print'),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18),
                label: Text(jobs.isEmpty ? 'Print' : 'Reprint (duplicate)'),
                onPressed: () => _reprint(context),
              ),
              if (pay != null && pay!.balance.paise > 0)
                FilledButton.icon(
                  icon: const Icon(Icons.payments_rounded, size: 18),
                  label: Text('Collect ${pay!.balance.format()}'),
                  onPressed: () => collectPayment(context, b.id),
                ),
              if (pay == null || pay!.paid.isZero)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Void bill'),
                  onPressed: () => voidBill(context, b),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _reprint(BuildContext context) async {
    final storage = await StorageService.getInstance();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    var duplicate = false;
    final ok = await runMenuAction(
      context,
      () async => duplicate = await storage.bills.reprint(bill.id),
    );
    if (!ok) return;
    await (await PrintQueueManager.getInstance()).syncFromStorage();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          duplicate
              ? 'Bill copy queued (marked DUPLICATE).'
              : 'Bill sent to the bill printer.',
        ),
      ),
    );
  }
}

/// Asks for a reason and voids the bill; the order opens again.
Future<bool> voidBill(BuildContext context, Bill bill) async {
  final reason = TextEditingController();
  const reasons = [
    'Wrong item billed',
    'Customer changed order',
    'Wrong discount',
    'Duplicate bill',
  ];
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Void bill ${bill.billNumber}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The bill (${bill.grandTotal.format()}) is kept and marked '
              'VOID. The order opens again so you can correct it and make a '
              'new bill with a new number.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: reason.text == r,
                    onSelected: (_) => setLocal(() => reason.text = r),
                  ),
              ],
            ),
            TextField(
              controller: reason,
              onChanged: (_) => setLocal(() {}),
              decoration: const InputDecoration(labelText: 'Reason (required)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: reason.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('Void bill'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return false;
  final storage = await StorageService.getInstance();
  if (!context.mounted) return false;
  return runMenuAction(
    context,
    () => storage.bills.voidBill(bill.id, reason.text),
    success: 'Bill ${bill.billNumber} voided. The order is open again.',
  );
}
