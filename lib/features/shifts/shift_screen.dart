import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/shifts/shift_models.dart';
import '../../queue/print_queue_manager.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import '../staff/permission_guard.dart';
import '../../domain/staff/staff_models.dart';

const _grey = Color(0xFF64748B);
const _red = Color(0xFFDC2626);
const _green = Color(0xFF16A34A);

final _moneyInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
const _moneyKeyboard = TextInputType.numberWithOptions(decimal: true);

/// The cash drawer: open a shift, record cash in/out and expenses, see the
/// expected cash, and close with a count.
class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageService>(
      future: StorageService.getInstance(),
      builder: (ctx, s) {
        final storage = s.data;
        if (storage == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<void>(
          stream: storage.shifts.watchChanges(),
          builder: (ctx, _) => FutureBuilder<_ShiftData>(
            future: _ShiftData.load(storage),
            builder: (ctx, snap) {
              final d = snap.data;
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Shift & cash'),
                  actions: [
                    IconButton(
                      tooltip: 'Past shifts',
                      icon: const Icon(Icons.history_rounded),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PastShiftsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: d == null
                    ? null
                    : FloatingActionButton.extended(
                        heroTag: 'expense',
                        onPressed: () => addExpense(context, d.shift != null),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Expense'),
                      ),
                body: d == null
                    ? const Center(child: CircularProgressIndicator())
                    : d.shift == null
                    ? _NoShift(data: d)
                    : _OpenShift(data: d),
              );
            },
          ),
        );
      },
    );
  }
}

class _ShiftData {
  final CashShift? shift;
  final ShiftSummary? summary;
  final List<CashMovement> movements;
  final List<Expense> shiftExpenses;
  final List<Expense> todayOtherExpenses;
  final Money cashOutside;

  const _ShiftData({
    this.shift,
    this.summary,
    this.movements = const [],
    this.shiftExpenses = const [],
    this.todayOtherExpenses = const [],
    this.cashOutside = Money.zero,
  });

  static Future<_ShiftData> load(StorageService s) async {
    final shift = await s.shifts.currentShift();
    final date = await s.orders.currentBusinessDate();
    final today = await s.shifts.expensesForDate(date);
    return _ShiftData(
      shift: shift,
      summary: shift == null ? null : await s.shifts.summary(shift.id),
      movements: shift == null
          ? const []
          : await s.shifts.movementsFor(shift.id),
      shiftExpenses: shift == null
          ? const []
          : await s.shifts.expensesForShift(shift.id),
      todayOtherExpenses: today.where((e) => e.shiftId == null).toList(),
      cashOutside: await s.shifts.cashOutsideShifts(date),
    );
  }
}

class _NoShift extends StatelessWidget {
  final _ShiftData data;

  const _NoShift({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const MessageState(
          icon: Icons.point_of_sale_rounded,
          title: 'No shift open',
          message:
              'Open a shift with the cash in the drawer. Orders and payments '
              'still work without one, but cash is only counted in a shift.',
        ),
        Center(
          child: FilledButton.icon(
            onPressed: () => openShift(context),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Open shift'),
          ),
        ),
        if (!data.cashOutside.isZero)
          Card(
            color: const Color(0xFFFEF3C7),
            margin: const EdgeInsets.only(top: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${data.cashOutside.format()} in cash was recorded today '
                'while no shift was open. It is not in any drawer count.',
                style: const TextStyle(color: Color(0xFF92400E)),
              ),
            ),
          ),
        if (data.todayOtherExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ExpenseList(
            title: 'Today\'s expenses outside a shift',
            items: data.todayOtherExpenses,
          ),
        ],
      ],
    );
  }
}

class _OpenShift extends StatelessWidget {
  final _ShiftData data;

  const _OpenShift({required this.data});

  @override
  Widget build(BuildContext context) {
    final shift = data.shift!;
    final s = data.summary!;
    Widget row(String label, Money m, {bool bold = false, Color? color}) =>
        Padding(
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
                  color: color,
                ),
              ),
            ],
          ),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          'Shift open since '
          '${DateFormat('dd MMM, hh:mm a').format(shift.openedAt)} · '
          '${shift.openedBy}',
          style: const TextStyle(color: _grey),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                row('Opening cash', s.openingCash),
                row('+ Cash sales', s.cashSales),
                if (!s.cashRefunds.isZero) row('− Cash refunds', s.cashRefunds),
                if (!s.cashAdded.isZero) row('+ Cash added', s.cashAdded),
                if (!s.cashTakenOut.isZero)
                  row('− Cash taken out', s.cashTakenOut),
                if (!s.cashExpenses.isZero)
                  row('− Cash expenses', s.cashExpenses),
                const Divider(),
                row('Expected in drawer', s.expectedCash, bold: true),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Other collections (not in the drawer)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (s.nonCash.isEmpty)
                  const Text('None yet', style: TextStyle(color: _grey)),
                for (final e in s.nonCash.entries) row(e.key, e.value),
                const Divider(),
                row('Net collected (all methods)', s.netCollected, bold: true),
                Text(
                  '${s.billCount} bill(s) · ${s.paymentCount} payment(s). '
                  'UPI and card are as recorded by staff.',
                  style: const TextStyle(fontSize: 12, color: _grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => cashMovement(context, CashMovementKind.addition),
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Add cash'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  cashMovement(context, CashMovementKind.withdrawal),
              icon: const Icon(Icons.outbox_rounded),
              label: const Text('Take out cash'),
            ),
            OutlinedButton.icon(
              onPressed: () => _printReport(context, shift.id),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print running report'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (!await allow(context, Permission.manageShift) ||
                    !context.mounted) {
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CloseShiftScreen(shift: shift, summary: s),
                  ),
                );
              },
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Close shift'),
            ),
          ],
        ),
        if (data.movements.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Cash added / taken out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final m in data.movements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                m.kind == CashMovementKind.addition
                    ? Icons.add_rounded
                    : Icons.remove_rounded,
              ),
              title: Text(
                '${m.kind.label} · ${m.amount.format()}',
                style: TextStyle(
                  decoration: m.isVoided ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                [
                  DateFormat('hh:mm a').format(m.createdAt),
                  m.reason,
                  if (m.isVoided) 'Cancelled: ${m.voidReason}',
                ].join(' · '),
              ),
              trailing: m.isVoided
                  ? null
                  : IconButton(
                      tooltip: 'Cancel entry',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _cancel(
                        context,
                        (s, reason) => s.shifts.voidMovement(m.id, reason),
                        permission: Permission.manageShift,
                      ),
                    ),
            ),
        ],
        const SizedBox(height: 16),
        _ExpenseList(title: 'Expenses this shift', items: data.shiftExpenses),
        if (data.todayOtherExpenses.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ExpenseList(
            title: 'Today\'s expenses outside a shift',
            items: data.todayOtherExpenses,
          ),
        ],
      ],
    );
  }

  Future<void> _printReport(BuildContext context, String id) async {
    final storage = await StorageService.getInstance();
    if (!context.mounted) return;
    final ok = await runMenuAction(
      context,
      () => storage.shifts.printReport(id),
      success: 'Running shift report sent to the bill printer.',
    );
    if (ok) await (await PrintQueueManager.getInstance()).syncFromStorage();
  }
}

class _ExpenseList extends StatelessWidget {
  final String title;
  final List<Expense> items;

  const _ExpenseList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items
        .where((e) => !e.isVoided)
        .fold(Money.zero, (s, e) => s + e.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(total.format()),
          ],
        ),
        if (items.isEmpty) const Text('None', style: TextStyle(color: _grey)),
        for (final e in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.receipt_outlined),
            title: Text(
              '${e.category} · ${e.amount.format()}',
              style: TextStyle(
                decoration: e.isVoided ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              [
                DateFormat('hh:mm a').format(e.createdAt),
                e.paidFrom.label,
                if (e.note.isNotEmpty) e.note,
                if (e.staffName.isNotEmpty) e.staffName,
                if (e.isVoided) 'Cancelled: ${e.voidReason}',
              ].join(' · '),
            ),
            trailing: e.isVoided
                ? null
                : IconButton(
                    tooltip: 'Cancel expense',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => _cancel(
                      context,
                      (s, reason) => s.shifts.voidExpense(e.id, reason),
                      permission: Permission.recordExpense,
                    ),
                  ),
          ),
      ],
    );
  }
}

/// The signed-in staff member's name ('' with staff login off). Name
/// fields are filled with it and cannot be changed.
String _signedName() => StorageService.maybeInstance?.session.staffName ?? '';

Future<void> _cancel(
  BuildContext context,
  Future<void> Function(StorageService, String reason) action, {
  required Permission permission,
}) async {
  if (!await allow(context, permission) || !context.mounted) return;
  final reason = TextEditingController();
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel this entry?'),
      content: TextField(
        controller: reason,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Reason (required)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancel entry'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  await runMenuAction(
    context,
    () => action(storage, reason.text),
    success: 'Entry cancelled (kept on record).',
  );
}

/// Asks for the opening cash and the staff name, then opens a shift.
Future<void> openShift(BuildContext context) async {
  if (!await allow(context, Permission.manageShift) || !context.mounted) return;
  final cash = TextEditingController();
  final name = TextEditingController(text: _signedName());
  final note = TextEditingController();
  final requestId = newId();
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Open shift'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: cash,
            autofocus: true,
            keyboardType: _moneyKeyboard,
            inputFormatters: _moneyInput,
            decoration: const InputDecoration(
              labelText: 'Cash in the drawer now',
              prefixText: '₹ ',
            ),
          ),
          TextField(
            controller: name,
            readOnly: _signedName().isNotEmpty,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
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
          child: const Text('Open shift'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final amount = cash.text.trim().isEmpty ? Money.zero : Money.parse(cash.text);
  if (amount == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening cash is not a valid amount.')),
    );
    return;
  }
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  await runMenuAction(
    context,
    () => storage.shifts.open(
      openingCash: amount,
      staffName: name.text,
      note: note.text,
      clientRequestId: requestId,
    ),
    success: 'Shift opened with ${amount.format()}.',
  );
}

/// Records cash added to or taken out of the drawer.
Future<void> cashMovement(BuildContext context, CashMovementKind kind) async {
  if (!await allow(context, Permission.manageShift) || !context.mounted) return;
  final amount = TextEditingController();
  final reason = TextEditingController();
  final name = TextEditingController(text: _signedName());
  final requestId = newId();
  final add = kind == CashMovementKind.addition;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(add ? 'Add cash to the drawer' : 'Take cash out'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: _moneyKeyboard,
            inputFormatters: _moneyInput,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
            ),
          ),
          TextField(
            controller: reason,
            decoration: InputDecoration(
              labelText: 'Reason (required)',
              hintText: add
                  ? 'e.g. extra change from owner'
                  : 'e.g. bank deposit',
            ),
          ),
          TextField(
            controller: name,
            readOnly: _signedName().isNotEmpty,
            decoration: const InputDecoration(labelText: 'Your name'),
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
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;
  final m = Money.parse(amount.text);
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  await runMenuAction(context, () async {
    if (m == null) throw ValidationException('Enter a valid amount.');
    await storage.shifts.addMovement(
      kind: kind,
      amount: m,
      reason: reason.text,
      staffName: name.text,
      clientRequestId: requestId,
    );
  }, success: add ? 'Cash added.' : 'Cash taken out.');
}

/// Records an expense. Cash expenses need an open shift.
Future<void> addExpense(BuildContext context, bool shiftOpen) async {
  if (!await allow(context, Permission.recordExpense) || !context.mounted) {
    return;
  }
  final storage = await StorageService.getInstance();
  final categories = await storage.shifts.expenseCategories();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _ExpenseForm(categories: categories, shiftOpen: shiftOpen),
    ),
  );
}

class _ExpenseForm extends StatefulWidget {
  final List<String> categories;
  final bool shiftOpen;

  const _ExpenseForm({required this.categories, required this.shiftOpen});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _requestId = newId();
  final _category = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _name = TextEditingController(text: _signedName());
  late ExpenseSource _from = widget.shiftOpen
      ? ExpenseSource.cash
      : ExpenseSource.upi;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _note.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final m = Money.parse(_amount.text);
    if (m == null || m.paise <= 0) {
      setState(() => _error = 'Enter the amount.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final storage = await StorageService.getInstance();
    try {
      await storage.shifts.recordExpense(
        category: _category.text,
        amount: m,
        paidFrom: _from,
        note: _note.text,
        staffName: _name.text,
        clientRequestId: _requestId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense of ${m.format()} saved.')),
      );
      Navigator.of(context).pop();
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add expense',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in widget.categories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category.text == c,
                  onSelected: (_) => setState(() => _category.text = c),
                ),
            ],
          ),
          TextField(
            controller: _category,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: _amount,
            keyboardType: _moneyKeyboard,
            inputFormatters: _moneyInput,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 12),
          const Text('Paid from'),
          Wrap(
            spacing: 6,
            children: [
              for (final s in ExpenseSource.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _from == s,
                  onSelected: (_) => setState(() => _from = s),
                ),
            ],
          ),
          if (_from == ExpenseSource.cash && !widget.shiftOpen)
            const Text(
              'Open a shift to pay from the cash drawer.',
              style: TextStyle(color: _red),
            ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (supplier, bill no …)',
            ),
          ),
          TextField(
            controller: _name,
            readOnly: _signedName().isNotEmpty,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: _red)),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save expense'),
          ),
        ],
      ),
    );
  }
}

/// Count the drawer and close the shift.
class CloseShiftScreen extends StatefulWidget {
  final CashShift shift;
  final ShiftSummary summary;

  const CloseShiftScreen({
    super.key,
    required this.shift,
    required this.summary,
  });

  @override
  State<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends State<CloseShiftScreen> {
  final Map<int, TextEditingController> _counts = {
    for (final d in denominations) d: TextEditingController(),
  };
  final _total = TextEditingController();
  final _reason = TextEditingController();
  final _name = TextEditingController(text: _signedName());
  final _note = TextEditingController();
  bool _byNotes = true;
  bool _print = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [..._counts.values, _total, _reason, _name, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<int, int> get _countMap => {
    for (final e in _counts.entries) e.key: int.tryParse(e.value.text) ?? 0,
  };

  Money? get _counted => _byNotes
      ? countDenominations(_countMap)
      : (_total.text.trim().isEmpty ? null : Money.parse(_total.text));

  Future<void> _close() async {
    final counted = _counted;
    if (counted == null) {
      setState(() => _error = 'Enter the cash you counted.');
      return;
    }
    final variance = counted - widget.summary.expectedCash;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close the shift?'),
        content: Text(
          'Counted ${counted.format()}, expected '
          '${widget.summary.expectedCash.format()}. '
          '${variance.isZero
              ? 'The drawer matches.'
              : variance.isNegative
              ? 'Short by ${(-variance).format()}.'
              : 'Over by ${variance.format()}.'}'
          '\nA closed shift cannot be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close shift'),
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
      await storage.shifts.close(
        widget.shift.id,
        countedCash: counted,
        staffName: _name.text,
        varianceReason: _reason.text,
        note: _note.text,
        denominations: _byNotes ? _countMap : null,
        print: _print,
      );
      if (_print) {
        await (await PrintQueueManager.getInstance()).syncFromStorage();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shift closed.${_print ? ' Report sent to the bill printer.' : ''}',
          ),
        ),
      );
      Navigator.of(context).pop();
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expected = widget.summary.expectedCash;
    final counted = _counted;
    final variance = counted == null ? null : counted - expected;
    return Scaffold(
      appBar: AppBar(title: const Text('Close shift')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Expected in drawer')),
              Text(
                expected.format(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Count notes')),
              ButtonSegment(value: false, label: Text('Enter total')),
            ],
            selected: {_byNotes},
            onSelectionChanged: (s) => setState(() => _byNotes = s.first),
          ),
          const SizedBox(height: 8),
          if (_byNotes)
            for (final d in denominations)
              Row(
                children: [
                  SizedBox(width: 90, child: Text('${Money(d).format()} ×')),
                  Expanded(
                    child: TextField(
                      controller: _counts[d],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '0',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      Money(d * (int.tryParse(_counts[d]!.text) ?? 0)).format(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              )
          else
            TextField(
              controller: _total,
              keyboardType: _moneyKeyboard,
              inputFormatters: _moneyInput,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Cash counted',
                prefixText: '₹ ',
              ),
            ),
          const Divider(height: 24),
          if (counted != null) ...[
            Row(
              children: [
                const Expanded(child: Text('Counted')),
                Text(
                  counted.format(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    variance!.isZero
                        ? 'Matches'
                        : variance.isNegative
                        ? 'Short'
                        : 'Over',
                  ),
                ),
                Text(
                  variance.format(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: variance.isZero ? _green : _red,
                  ),
                ),
              ],
            ),
          ],
          if (variance != null && !variance.isZero)
            TextField(
              controller: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason for the difference (required)',
              ),
            ),
          TextField(
            controller: _name,
            readOnly: _signedName().isNotEmpty,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _print,
            onChanged: (v) => setState(() => _print = v ?? false),
            title: const Text('Print the closing report'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: _red)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _close,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Close shift'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Closed shifts with their result; tap to print the report again.
class PastShiftsScreen extends StatelessWidget {
  const PastShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past shifts')),
      body: FutureBuilder<List<CashShift>>(
        future: StorageService.getInstance().then(
          (s) => s.shifts.recentShifts(),
        ),
        builder: (ctx, snap) {
          final list = snap.data;
          if (list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final closed = list.where((s) => !s.isOpen).toList();
          if (closed.isEmpty) {
            return const MessageState(
              icon: Icons.history_rounded,
              title: 'No closed shifts yet',
            );
          }
          return ListView(
            children: [
              for (final s in closed)
                ListTile(
                  title: Text(
                    '${DateFormat('dd MMM, hh:mm a').format(s.openedAt)} – '
                    '${s.closedAt == null ? '' : DateFormat('hh:mm a').format(s.closedAt!)}'
                    ' · ${s.closedBy}',
                  ),
                  subtitle: Text(
                    'Expected ${s.expectedCash?.format() ?? '-'} · counted '
                    '${s.countedCash?.format() ?? '-'}'
                    '${s.varianceReason.isEmpty ? '' : ' · ${s.varianceReason}'}',
                  ),
                  trailing: Text(
                    s.variance == null || s.variance!.isZero
                        ? 'OK'
                        : s.variance!.format(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s.variance == null || s.variance!.isZero
                          ? _green
                          : _red,
                    ),
                  ),
                  onTap: () async {
                    final storage = await StorageService.getInstance();
                    if (!context.mounted) return;
                    final ok = await runMenuAction(
                      context,
                      () => storage.shifts.printReport(s.id),
                      success: 'Shift report sent to the bill printer.',
                    );
                    if (ok) {
                      await (await PrintQueueManager.getInstance())
                          .syncFromStorage();
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
