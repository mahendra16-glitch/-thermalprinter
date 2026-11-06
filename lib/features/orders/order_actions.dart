import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/orders/order_models.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import 'item_options_sheet.dart';
import 'kitchen_actions.dart';
import 'order_launcher.dart';

Future<OrderRepository> _orders() async =>
    (await StorageService.getInstance()).orders;

/// Edit quantity / instructions of a line, or remove it.
Future<void> editLine(BuildContext context, OrderLine line) async {
  final notes = TextEditingController(text: line.notes);
  var qty = line.qty;
  final minQty = line.sentQty.clamp(1, 999);
  final sent = line.sentQty > 0;
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (sent)
              Text(
                '${line.sentQty} already sent to the kitchen.',
                style: const TextStyle(color: Color(0xFFB45309)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Quantity'),
                const Spacer(),
                QtyStepper(
                  qty: qty,
                  min: minQty,
                  onChanged: (q) => setLocal(() => qty = q),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!sent) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final n in quickNotes)
                    ActionChip(
                      label: Text(n),
                      onPressed: () => setLocal(() {
                        final parts = notes.text
                            .split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                        parts.contains(n) ? parts.remove(n) : parts.add(n);
                        notes.text = parts.join(', ');
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Kitchen instructions',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (line.voidableQty > 0)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, 'void'),
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Void sent'),
                  ),
                if (!sent)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, 'remove'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  final repo = await _orders();
  if (!context.mounted) return;
  if (result == 'void') {
    await voidSentItems(context, line);
    return;
  }
  if (result == 'remove') {
    await runMenuAction(context, () => repo.removeLine(line.id));
  } else {
    await runMenuAction(context, () async {
      if (qty != line.qty) await repo.setLineQty(line.id, qty);
      if (!sent && notes.text.trim() != line.notes) {
        await repo.setLineNotes(line.id, notes.text);
      }
    });
  }
}

Future<void> editOrderDetails(BuildContext context, Order o) async {
  final name = TextEditingController(text: o.customerName);
  final phone = TextEditingController(text: o.customerPhone);
  final guests = TextEditingController(text: o.guests?.toString() ?? '');
  final notes = TextEditingController(text: o.notes);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Customer & notes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: guests,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Guests'),
            ),
            TextField(
              controller: notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Order note'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final repo = await _orders();
            if (!ctx.mounted) return;
            final ok = await runMenuAction(
              ctx,
              () => repo.updateDetails(
                o.id,
                customerName: name.text,
                customerPhone: phone.text,
                guests: int.tryParse(guests.text),
                notes: notes.text,
              ),
            );
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> editDiscount(BuildContext context, OrderDetail d) async {
  var kind = d.order.discount.isNone
      ? DiscountKind.percent
      : d.order.discount.kind;
  final value = TextEditingController(
    text: d.order.discount.isNone
        ? ''
        : kind == DiscountKind.percent
        ? formatBp(d.order.discount.value).replaceAll('%', '')
        : Money(d.order.discount.value)
              .format(symbol: false)
              .replaceAll(',', ''),
  );
  final reason = TextEditingController(text: d.order.discount.reason);
  String? error;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final parsed = kind == DiscountKind.percent
            ? parsePercentToBp(value.text)
            : Money.parse(value.text)?.paise;
        final preview = parsed == null
            ? null
            : OrderTotals.discountAmount(
                d.totals.itemsTotal,
                OrderDiscount(kind: kind, value: parsed),
              );
        return AlertDialog(
          title: const Text('Discount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<DiscountKind>(
                segments: const [
                  ButtonSegment(value: DiscountKind.percent, label: Text('%')),
                  ButtonSegment(value: DiscountKind.amount, label: Text('₹')),
                ],
                selected: {kind},
                onSelectionChanged: (s) => setLocal(() => kind = s.first),
              ),
              TextField(
                controller: value,
                autofocus: true,
                onChanged: (_) => setLocal(() => error = null),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: kind == DiscountKind.percent
                      ? 'Percent off'
                      : 'Amount off (₹)',
                  errorText: error,
                  helperText: preview == null
                      ? null
                      : 'Takes ${preview.format()} off '
                            '${d.totals.itemsTotal.format()}',
                ),
              ),
              TextField(
                controller: reason,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason (required)',
                  hintText: 'e.g. Regular customer, complaint',
                ),
              ),
            ],
          ),
          actions: [
            if (!d.order.discount.isNone)
              TextButton(
                onPressed: () async {
                  final repo = await _orders();
                  if (!ctx.mounted) return;
                  final ok = await runMenuAction(
                    ctx,
                    () => repo.setDiscount(d.order.id, OrderDiscount.none),
                  );
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (parsed == null) {
                  setLocal(() => error = 'Enter a valid number');
                  return;
                }
                final repo = await _orders();
                if (!ctx.mounted) return;
                final ok = await runMenuAction(
                  ctx,
                  () => repo.setDiscount(
                    d.order.id,
                    OrderDiscount(
                      kind: kind,
                      value: parsed,
                      reason: reason.text,
                    ),
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    ),
  );
}

enum OrderMenuAction {
  details,
  kitchen,
  moveTable,
  merge,
  split,
  cancel,
  timeline,
}

List<PopupMenuEntry<OrderMenuAction>> orderMenuItems(OrderDetail d) => [
  const PopupMenuItem(
    value: OrderMenuAction.details,
    child: Text('Customer & notes'),
  ),
  const PopupMenuItem(
    value: OrderMenuAction.kitchen,
    child: Text('Kitchen tickets (KOT)'),
  ),
  if (d.order.type == OrderType.dineIn)
    const PopupMenuItem(
      value: OrderMenuAction.moveTable,
      child: Text('Move to another table'),
    ),
  const PopupMenuItem(
    value: OrderMenuAction.merge,
    child: Text('Merge into another order'),
  ),
  if (d.lines.length > 1)
    const PopupMenuItem(
      value: OrderMenuAction.split,
      child: Text('Split items to a new order'),
    ),
  const PopupMenuItem(value: OrderMenuAction.timeline, child: Text('Timeline')),
  const PopupMenuDivider(),
  const PopupMenuItem(
    value: OrderMenuAction.cancel,
    child: Text('Cancel order', style: TextStyle(color: Colors.red)),
  ),
];

Future<void> runOrderMenuAction(
  BuildContext context,
  OrderMenuAction action,
  OrderDetail d,
) async {
  switch (action) {
    case OrderMenuAction.details:
      await editOrderDetails(context, d.order);
    case OrderMenuAction.kitchen:
      await showKitchenTickets(context, d.order);
    case OrderMenuAction.moveTable:
      await _moveTable(context, d.order);
    case OrderMenuAction.merge:
      await _merge(context, d.order);
    case OrderMenuAction.split:
      await _split(context, d);
    case OrderMenuAction.cancel:
      await _cancel(context, d);
    case OrderMenuAction.timeline:
      await showOrderTimeline(context, d.order);
  }
}

Future<void> _moveTable(BuildContext context, Order o) async {
  final table = await pickTable(
    context,
    title: 'Move order #${o.orderNo} to',
    excludeTableId: o.tableId,
  );
  if (table == null || !context.mounted) return;
  final repo = await _orders();
  try {
    await repo.moveToTable(o.id, table.id);
  } on TableBusyException {
    if (!context.mounted) return;
    final share = await _confirm(
      context,
      '${table.label} is in use',
      'It already has a running order. Put this order on the same table '
          'anyway (both stay separate)?',
      'Share table',
    );
    if (share && context.mounted) {
      await runMenuAction(
        context,
        () => repo.moveToTable(o.id, table.id, allowSharedTable: true),
      );
    }
    return;
  } on ValidationException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Moved to ${table.label}')));
  }
}

Future<void> _merge(BuildContext context, Order o) async {
  final storage = await StorageService.getInstance();
  final tables = {for (final t in await storage.tables.listTables()) t.id: t};
  final others = (await storage.orders.listActive())
      .where((s) => s.order.id != o.id)
      .toList();
  if (!context.mounted) return;
  if (others.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('There is no other running order.')),
    );
    return;
  }
  final target = await showModalBottomSheet<OrderSummary>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(
              'Merge order #${o.orderNo} into…',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'All its items move to the chosen order; this order is closed.',
            ),
          ),
          for (final s in others)
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(
                'Order #${s.order.orderNo} · '
                '${s.order.tableId == null ? s.order.type.label : tables[s.order.tableId]?.label ?? 'Table'}',
              ),
              subtitle: Text(
                '${s.totals.itemCount} item(s) · '
                '${s.totals.afterDiscount.format()}',
              ),
              onTap: () => Navigator.pop(ctx, s),
            ),
        ],
      ),
    ),
  );
  if (target == null || !context.mounted) return;
  final ok = await _confirm(
    context,
    'Merge orders?',
    'Move every item from #${o.orderNo} into #${target.order.orderNo}. '
        'Order #${o.orderNo} will be closed as merged.',
    'Merge',
  );
  if (!ok || !context.mounted) return;
  final done = await runMenuAction(
    context,
    () => storage.orders.mergeInto(o.id, target.order.id),
  );
  if (done && context.mounted) {
    Navigator.of(context).pop();
    await openOrder(context, target.order.id);
  }
}

Future<void> _split(BuildContext context, OrderDetail d) async {
  final selected = <String>{};
  var toTable = false;
  final go = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, scroll) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  const ListTile(
                    title: Text(
                      'Move items to a new order',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Whole lines move with their quantity.'),
                  ),
                  for (final l in d.lines)
                    CheckboxListTile(
                      value: selected.contains(l.id),
                      title: Text('${l.qty} × ${l.displayName}'),
                      subtitle: Text(l.lineTotal.format()),
                      onChanged: (v) => setLocal(
                        () => v == true
                            ? selected.add(l.id)
                            : selected.remove(l.id),
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('New order is dine-in on a table'),
                    subtitle: const Text('Otherwise it becomes a takeaway.'),
                    value: toTable,
                    onChanged: (v) => setLocal(() => toTable = v),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed:
                        selected.isEmpty || selected.length == d.lines.length
                        ? null
                        : () => Navigator.pop(ctx, true),
                    child: Text(
                      selected.length == d.lines.length
                          ? 'Leave at least one item'
                          : 'Move ${selected.length} item(s)',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (go != true || !context.mounted) return;
  String? tableId;
  if (toTable) {
    final t = await pickTable(context, title: 'Table for the new order');
    if (t == null) return;
    tableId = t.id;
  }
  if (!context.mounted) return;
  final repo = await _orders();
  var request = NewOrderRequest(
    clientRequestId: newId(),
    type: toTable ? OrderType.dineIn : OrderType.takeaway,
    tableId: tableId,
  );
  String? newOrderId;
  Future<void> attempt() async {
    newOrderId = await repo.splitToNewOrder(d.order.id, [...selected], request);
  }

  try {
    await attempt();
  } on TableBusyException {
    if (!context.mounted) return;
    final share = await _confirm(
      context,
      'Table is in use',
      'That table already has a running order. Start a separate order on it?',
      'Share table',
    );
    if (!share || !context.mounted) return;
    request = NewOrderRequest(
      clientRequestId: request.clientRequestId,
      type: request.type,
      tableId: tableId,
      allowSharedTable: true,
    );
    if (!await runMenuAction(context, attempt)) return;
  } on ValidationException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return;
  }
  if (newOrderId != null && context.mounted) {
    final detail = await repo.getDetail(newOrderId!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved to new order #${detail?.order.orderNo}'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => openOrder(context, newOrderId!),
        ),
      ),
    );
  }
}

Future<void> _cancel(BuildContext context, OrderDetail d) async {
  final reason = TextEditingController();
  const reasons = [
    'Customer left',
    'Ordered by mistake',
    'Duplicate order',
    'Item unavailable',
  ];
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Cancel order #${d.order.orderNo}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.lines.isEmpty
                  ? 'The order is empty.'
                  : '${d.totals.itemCount} item(s), '
                        '${d.totals.afterDiscount.format()}. The items stay '
                        'on record.',
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
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: reason.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return;
  final repo = await _orders();
  if (!context.mounted) return;
  final ok = await runMenuAction(
    context,
    () => repo.cancel(d.order.id, reason.text),
    success: 'Order #${d.order.orderNo} cancelled',
  );
  if (ok && context.mounted) Navigator.of(context).pop();
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return r == true;
}

/// Readable text for one timeline entry.
String describeOrderEvent(OrderEvent e) {
  final d = e.details;
  String money(Object? paise) => Money((paise as num?)?.toInt() ?? 0).format();
  return switch (e.action) {
    'order.created' =>
      'Order created (${OrderTypeX.parse(d['type'] as String?).label})',
    'order.item_added' =>
      d['added'] == d['qty']
          ? 'Added ${d['qty']} × ${d['name']}'
          : 'Added ${d['added']} more ${d['name']} (now ${d['qty']})',
    'order.qty_changed' => '${d['name']}: quantity ${d['from']} → ${d['to']}',
    'order.notes_changed' => '${d['name']}: instructions "${d['to']}"',
    'order.item_removed' => 'Removed ${d['qty']} × ${d['name']}',
    'order.details_changed' => 'Customer details / note changed',
    'order.discount_changed' => () {
      final to = d['to'] as Map<String, dynamic>? ?? const {};
      final kind = DiscountKindX.parse(to['kind'] as String?);
      if (kind == DiscountKind.none) return 'Discount removed';
      final v = (to['value'] as num?)?.toInt() ?? 0;
      final label = kind == DiscountKind.percent ? formatBp(v) : money(v);
      return 'Discount $label (${to['reason']})';
    }(),
    'order.held' => 'Put on hold',
    'order.resumed' => 'Resumed',
    'order.cancelled' => 'Cancelled: ${d['reason']}',
    'order.table_moved' => 'Moved to another table',
    'order.merged_in' =>
      'Merged in order #${d['fromNo']} (${d['lines']} line(s))',
    'order.merged_out' => 'Merged into order #${d['intoNo']}',
    'order.split_out' => 'Moved ${d['lines']} line(s) to order #${d['intoNo']}',
    'order.split_in' =>
      'Created from order #${d['fromNo']} (${d['lines']} line(s))',
    'order.kot_sent' =>
      'Sent to kitchen (round ${d['round']}, ${(d['lines'] as List?)?.length ?? 0} item line(s))',
    'order.items_voided' => 'Voided ${d['qty']} × ${d['name']}: ${d['reason']}',
    'order.kot_reprinted' => 'KOT reprinted (round ${d['round']})',
    _ => e.action,
  };
}

Future<void> showOrderTimeline(BuildContext context, Order o) async {
  final events = await (await _orders()).timeline(o.id);
  if (!context.mounted) return;
  final fmt = DateFormat('dd MMM, hh:mm a');
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        children: [
          ListTile(
            title: Text(
              'Order #${o.orderNo} timeline',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final e in events)
            ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 10),
              title: Text(describeOrderEvent(e)),
              subtitle: Text(fmt.format(e.at)),
            ),
        ],
      ),
    ),
  );
}
