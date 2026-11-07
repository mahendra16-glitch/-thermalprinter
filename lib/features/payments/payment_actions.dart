import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../queue/print_queue_manager.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import '../staff/permission_guard.dart';
import '../../domain/staff/staff_models.dart';

const _grey = Color(0xFF64748B);
const _red = Color(0xFFDC2626);

/// Opens the payment screen for a bill. Returns true when a payment was
/// recorded.
Future<bool> collectPayment(BuildContext context, String billId) async {
  if (!await allow(context, Permission.recordPayment) || !context.mounted) {
    return false;
  }
  final storage = await StorageService.getInstance();
  final bill = await storage.bills.getBill(billId);
  if (bill == null) return false;
  final summary = await storage.payments.summaryFor(billId);
  final upi = await storage.payments.upiLinkFor(billId);
  final shiftOpen = await storage.shifts.currentShift() != null;
  if (!context.mounted) return false;
  if (summary.balance.paise <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This bill is already fully paid.')),
    );
    return false;
  }
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaymentScreen(
        bill: bill,
        summary: summary,
        upiLink: upi,
        shiftOpen: shiftOpen,
      ),
    ),
  );
  return ok ?? false;
}

class PaymentScreen extends StatefulWidget {
  final Bill bill;
  final BillPaymentSummary summary;
  final String? upiLink;

  /// Without an open shift, cash is recorded but not in any drawer count.
  final bool shiftOpen;

  const PaymentScreen({
    super.key,
    required this.bill,
    required this.summary,
    this.upiLink,
    this.shiftOpen = true,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // One id for this screen: a double tap or retry records one payment.
  final String _requestId = newId();
  PaymentMethod _method = PaymentMethod.cash;
  late final _amount = TextEditingController(
    text: widget.summary.balance.format(symbol: false).replaceAll(',', ''),
  );
  final _tendered = TextEditingController();
  final _reference = TextEditingController();
  final _otherName = TextEditingController();
  bool _confirmed = false;
  bool _print = false;
  bool _busy = false;
  String? _error;

  Money get _balance => widget.summary.balance;

  @override
  void dispose() {
    _amount.dispose();
    _tendered.dispose();
    _reference.dispose();
    _otherName.dispose();
    super.dispose();
  }

  Money? get _amountValue => Money.parse(_amount.text);
  Money? get _tenderedValue =>
      _tendered.text.trim().isEmpty ? null : Money.parse(_tendered.text);

  String? _check() {
    final a = _amountValue;
    if (a == null || a.paise <= 0) return 'Enter the amount being collected.';
    if (a > _balance) {
      return 'The balance is ${_balance.format()}. Collect at most that.';
    }
    if (_method == PaymentMethod.cash && _tendered.text.trim().isNotEmpty) {
      final t = _tenderedValue;
      if (t == null) return 'Cash received is not a valid amount.';
      if (t < a) return 'Cash received is less than the amount.';
    }
    if (_method == PaymentMethod.other && _otherName.text.trim().isEmpty) {
      return 'Enter the name of the payment method.';
    }
    if (_method.needsStaffConfirmation && !_confirmed) {
      return 'Tick the box once you have checked the money arrived.';
    }
    return null;
  }

  String get _buttonLabel => switch (_method) {
    PaymentMethod.cash => 'Record cash payment',
    PaymentMethod.upi => 'Record UPI payment',
    PaymentMethod.card => 'Record card payment',
    PaymentMethod.other => 'Record payment',
  };

  String get _confirmText => switch (_method) {
    PaymentMethod.upi =>
      'I checked our UPI app or bank statement and this amount has arrived.',
    PaymentMethod.card => 'The card terminal shows this payment as approved.',
    _ => 'I checked this payment has been received.',
  };

  Future<void> _submit() async {
    final problem = _check();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final amount = _amountValue!;
    final tendered = _method == PaymentMethod.cash ? _tenderedValue : null;
    final label = _method == PaymentMethod.other
        ? _otherName.text.trim()
        : _method.label;
    final after = _balance - amount;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record ${amount.format()} by $label?'),
        content: Text(
          [
            if (tendered != null)
              'Cash received ${tendered.format()} · change '
                  '${(tendered - amount).format()}.',
            after.isZero
                ? 'The bill will be fully paid.'
                : 'Balance after this: ${after.format()}.',
            if (_method.needsStaffConfirmation)
              'Recorded as confirmed by staff (the app cannot check the bank).',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final storage = await StorageService.getInstance();
    try {
      await storage.payments.record(
        PaymentRequest(
          billId: widget.bill.id,
          method: _method,
          amount: amount,
          tendered: tendered,
          reference: _reference.text,
          methodName: _otherName.text,
          staffConfirmed: _confirmed,
          clientRequestId: _requestId,
        ),
        printReceipt: _print,
      );
      if (_print) {
        await (await PrintQueueManager.getInstance()).syncFromStorage();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            after.isZero
                ? 'Recorded ${amount.format()} ($label). Bill fully paid.'
                : 'Recorded ${amount.format()} ($label). Balance '
                      '${after.format()}.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not record the payment: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _summaryRow(String label, Money m, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ),
        Text(
          m.format(),
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : null,
            fontSize: bold ? 18 : 14,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final a = _amountValue;
    final t = _tenderedValue;
    final change = _method == PaymentMethod.cash && a != null && t != null
        ? t - a
        : null;
    final moneyKeyboard = const TextInputType.numberWithOptions(decimal: true);
    final moneyFormat = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Scaffold(
      appBar: AppBar(title: Text('Payment · Bill ${widget.bill.billNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryRow('Bill total', widget.bill.grandTotal),
          _summaryRow('Paid before', widget.summary.paid),
          _summaryRow('Balance', _balance, bold: true),
          const Divider(height: 24),
          SegmentedButton<PaymentMethod>(
            segments: [
              for (final m in PaymentMethod.values)
                ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() {
              _method = s.first;
              _confirmed = false;
              _error = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: moneyKeyboard,
                  inputFormatters: moneyFormat,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Amount collected now',
                    prefixText: '₹ ',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(
                  () => _amount.text = _balance
                      .format(symbol: false)
                      .replaceAll(',', ''),
                ),
                child: const Text('Full balance'),
              ),
            ],
          ),
          if (_method == PaymentMethod.cash) ...[
            if (!widget.shiftOpen)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No shift is open: this cash is recorded but will not be '
                  'in a drawer count. Open a shift in the Shift tab.',
                  style: TextStyle(color: Color(0xFFB45309)),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _tendered,
              keyboardType: moneyKeyboard,
              inputFormatters: moneyFormat,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Cash received (optional)',
                prefixText: '₹ ',
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final r in [100, 200, 500, 2000])
                  ActionChip(
                    label: Text('₹$r'),
                    onPressed: () => setState(() => _tendered.text = '$r'),
                  ),
              ],
            ),
            if (change != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  change.isNegative
                      ? 'Short by ${(-change).format()}'
                      : 'Change to give: ${change.format()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: change.isNegative ? _red : const Color(0xFF16A34A),
                  ),
                ),
              ),
          ],
          if (_method == PaymentMethod.upi) ...[
            const SizedBox(height: 12),
            if (widget.upiLink != null && a != null && a == _balance) ...[
              Center(
                child: QrImageView(
                  data: widget.upiLink!,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const Center(child: Text('Customer scans to pay the balance.')),
            ] else if (widget.upiLink == null)
              const Text(
                'Add your UPI ID in Settings › Business Profile to show a QR '
                'code here.',
                style: TextStyle(color: _grey),
              )
            else
              const Text(
                'The QR is for the full balance. For a part payment, the '
                'customer enters the amount in their UPI app.',
                style: TextStyle(color: _grey),
              ),
            const SizedBox(height: 8),
            const Card(
              color: Color(0xFFFEF3C7),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Showing a QR or a customer\'s screenshot does not prove '
                  'payment. Check that the money arrived in your UPI app or '
                  'bank statement before recording it.',
                  style: TextStyle(color: Color(0xFF92400E)),
                ),
              ),
            ),
          ],
          if (_method == PaymentMethod.other) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _otherName,
              decoration: const InputDecoration(
                labelText: 'Method name (e.g. Zomato, Swiggy, wallet)',
              ),
            ),
          ],
          if (_method != PaymentMethod.cash) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _reference,
              maxLength: PaymentRepository.maxReference,
              decoration: InputDecoration(
                labelText: _method == PaymentMethod.upi
                    ? 'UPI transaction ID / UTR (optional)'
                    : 'Reference (optional)',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(_confirmText),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _print,
            onChanged: (v) => setState(() => _print = v ?? false),
            title: const Text('Print a payment receipt'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: const TextStyle(color: _red)),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(_buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment history of a bill with reverse and receipt actions.
class PaymentHistory extends StatelessWidget {
  final BillPaymentSummary summary;

  const PaymentHistory(this.summary, {super.key});

  @override
  Widget build(BuildContext context) {
    final reversed = summary.reversedIds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Payments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SmallBadge(
              summary.status.label,
              color: switch (summary.status) {
                PaymentStatus.paid => const Color(0xFF16A34A),
                PaymentStatus.partlyPaid => const Color(0xFFEA580C),
                PaymentStatus.unpaid => _red,
              },
            ),
          ],
        ),
        if (summary.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No payments yet.', style: TextStyle(color: _grey)),
          ),
        for (final e in summary.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              e.isReversal
                  ? Icons.undo_rounded
                  : e.method == PaymentMethod.cash
                  ? Icons.payments_outlined
                  : Icons.qr_code_2_rounded,
              color: e.isReversal || reversed.contains(e.id) ? _red : null,
            ),
            title: Text(
              '${e.isReversal ? 'Reversed' : 'Paid'} ${e.methodLabel} · '
              '${e.amount.format()}',
              style: TextStyle(
                decoration: reversed.contains(e.id)
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              [
                DateFormat('dd MMM, hh:mm a').format(e.createdAt),
                if (e.confirmation == staffConfirmed) 'staff-confirmed',
                if (e.reference.isNotEmpty) 'Ref ${e.reference}',
                if (e.change != null && !e.change!.isZero)
                  'change ${e.change!.format()}',
                if (e.reason.isNotEmpty) e.reason,
              ].join(' · '),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (a) => a == 'receipt'
                  ? _printReceipt(context, e)
                  : reversePayment(context, e),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'receipt',
                  child: Text('Print receipt'),
                ),
                if (!e.isReversal && !reversed.contains(e.id))
                  const PopupMenuItem(
                    value: 'reverse',
                    child: Text('Refund / reverse…'),
                  ),
              ],
            ),
          ),
        const Divider(),
        Row(
          children: [
            const Expanded(child: Text('Total paid')),
            Text(summary.paid.format()),
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Balance due',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              summary.balance.format(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _printReceipt(BuildContext context, LedgerEntry e) async {
    final storage = await StorageService.getInstance();
    if (!context.mounted) return;
    final ok = await runMenuAction(
      context,
      () => storage.payments.printReceipt(e.id),
      success: 'Receipt sent to the bill printer.',
    );
    if (ok) await (await PrintQueueManager.getInstance()).syncFromStorage();
  }
}

/// Asks for a reason and reverses a payment (kept on record).
Future<bool> reversePayment(BuildContext context, LedgerEntry e) async {
  if (!await allow(context, Permission.reversePayment) || !context.mounted) {
    return false;
  }
  final reason = TextEditingController();
  final requestId = newId();
  var print = false;
  const reasons = [
    'Entered by mistake',
    'UPI not received',
    'Money returned to customer',
    'Wrong method',
  ];
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Reverse ${e.amount.format()} ${e.methodLabel}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.method == PaymentMethod.cash
                  ? 'The payment stays on record with a reversal entry. If '
                        'you give cash back, take it from the drawer.'
                  : 'The payment stays on record with a reversal entry. Any '
                        'money to return must be sent from your '
                        '${e.methodLabel} account; the app does not do that.',
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
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: print,
              onChanged: (v) => setLocal(() => print = v ?? false),
              title: const Text('Print a reversal receipt'),
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
            child: const Text('Reverse'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return false;
  final storage = await StorageService.getInstance();
  if (!context.mounted) return false;
  final ok = await runMenuAction(
    context,
    () => storage.payments.reverse(
      e.id,
      reason: reason.text,
      clientRequestId: requestId,
      printReceipt: print,
    ),
    success: 'Payment reversed. The balance is due again.',
  );
  if (ok && print) {
    await (await PrintQueueManager.getInstance()).syncFromStorage();
  }
  return ok;
}

/// Closes a billed order with money still owed. Asks for the customer if
/// the order has none.
Future<bool> moveToDues(BuildContext context, Order o, Money balance) async {
  if (!await allow(context, Permission.recordPayment) || !context.mounted) {
    return false;
  }
  final name = TextEditingController(text: o.customerName);
  final phone = TextEditingController(text: o.customerPhone);
  final note = TextEditingController();
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Move ${balance.format()} to dues?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The table is freed. The balance stays in Orders › Dues until '
              'it is paid.',
            ),
            TextField(
              controller: name,
              onChanged: (_) => setLocal(() {}),
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setLocal(() {}),
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Note (e.g. pays on Friday)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: name.text.trim().isEmpty && phone.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('Move to dues'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return false;
  final storage = await StorageService.getInstance();
  if (!context.mounted) return false;
  return runMenuAction(context, () async {
    if (name.text.trim() != o.customerName ||
        phone.text.trim() != o.customerPhone) {
      await storage.orders.updateDetails(
        o.id,
        customerName: name.text,
        customerPhone: phone.text,
        guests: o.guests,
        notes: o.notes,
      );
    }
    await storage.payments.closeAsDue(o.id, note.text);
  }, success: 'Moved to dues. The table is free.');
}
