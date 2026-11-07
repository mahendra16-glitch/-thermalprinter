import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/inventory/inventory_models.dart';
import '../../domain/staff/staff_models.dart';
import '../../services/storage_service.dart';
import '../staff/permission_guard.dart';

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<void> _run(BuildContext context, Future<void> Function() f) async {
  try {
    await f();
  } catch (e) {
    if (context.mounted) _snack(context, e.toString());
  }
}

Future<bool> _canManage(BuildContext context) async =>
    await allow(context, Permission.manageInventory) && context.mounted;

/// Stock items, low-stock alerts, stock in / wastage / counts and when
/// sales take stock.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Stream<List<StockItem>> _items = StorageService.maybeInstance!.inventory
      .watchItems();
  bool _showOff = false;
  DeductOn? _deductOn;

  @override
  void initState() {
    super.initState();
    _loadDeduct();
  }

  Future<void> _loadDeduct() async {
    final d = await StorageService.maybeInstance!.inventory.deductOn();
    if (mounted) setState(() => _deductOn = d);
  }

  Future<void> _changeDeduct() async {
    if (!await _canManage(context) || !mounted) return;
    final picked = await showDialog<DeductOn>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Take stock away for sales'),
        children: [
          for (final d in DeductOn.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d),
              child: Row(
                children: [
                  Icon(
                    d == _deductOn
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(d.label)),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              'Only items with a recipe use stock. With "KOT", items billed '
              'without a KOT are taken when billed. Voiding a bill gives '
              'back what that bill took; voiding items already sent to the '
              'kitchen does not (record wastage or a count instead).',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
    if (picked == null || picked == _deductOn || !mounted) return;
    await _run(
      context,
      () => StorageService.maybeInstance!.inventory.setDeductOn(picked),
    );
    _loadDeduct();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            tooltip: 'Export stock movements (CSV)',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _exportCsv(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'off') setState(() => _showOff = !_showOff);
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'off',
                checked: _showOff,
                child: const Text('Show turned-off items'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Stock item'),
        onPressed: () async {
          if (!await _canManage(context)) return;
          if (context.mounted) await editStockItem(context, null);
        },
      ),
      body: StreamBuilder<List<StockItem>>(
        stream: _items,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load stock: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data!;
          final shown = all.where((i) => _showOff || i.active).toList();
          final low = all.where((i) => i.active && i.isLow).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Sales take stock'),
                subtitle: Text(_deductOn?.label ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changeDeduct,
              ),
              if (low.isNotEmpty)
                Card(
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.deepOrange,
                    ),
                    title: Text('${low.length} item(s) low on stock'),
                    subtitle: Text(
                      low
                          .map(
                            (i) =>
                                '${i.name}: ${Qty.withUnit(i.onHandMilli, i.unit)}',
                          )
                          .join('\n'),
                    ),
                  ),
                ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No stock items yet. Add your ingredients (rice, oil, '
                    'paneer…) with the unit you count them in, then enter '
                    'the opening stock. To take stock away with sales, add a '
                    'recipe to each menu item (Menu > item > Recipe).\n\n'
                    'Stock is only as accurate as the recipes and the stock '
                    'entered; check it with regular counts.',
                  ),
                ),
              for (final i in shown)
                ListTile(
                  leading: Icon(
                    i.isNegative || i.isLow
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_2_outlined,
                    color: i.isNegative
                        ? Colors.red
                        : i.isLow
                        ? Colors.deepOrange
                        : null,
                  ),
                  title: Text(
                    i.name,
                    style: TextStyle(
                      decoration: i.active ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (i.lowStockMilli != null)
                        'alert at ${Qty.withUnit(i.lowStockMilli!, i.unit)}',
                      if (i.isNegative) 'below zero: count it',
                      if (!i.active) 'turned off',
                    ].join(' · '),
                  ),
                  trailing: Text(
                    Qty.withUnit(i.onHandMilli, i.unit),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: i.isNegative ? Colors.red : null,
                    ),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StockItemScreen(itemId: i.id),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Add (null [item]) or edit a stock item.
Future<void> editStockItem(BuildContext context, StockItem? item) async {
  final s = StorageService.maybeInstance!;
  final name = TextEditingController(text: item?.name ?? '');
  final low = TextEditingController(
    text: item?.lowStockMilli == null ? '' : Qty.format(item!.lowStockMilli!),
  );
  final note = TextEditingController(text: item?.note ?? '');
  var unit = item?.unit ?? StockUnit.kg;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(item == null ? 'New stock item' : 'Edit ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: item == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<StockUnit>(
                initialValue: unit,
                decoration: const InputDecoration(
                  labelText: 'Counted in',
                  helperText: 'Recipes and stock use this unit.',
                ),
                items: [
                  for (final u in StockUnit.values)
                    DropdownMenuItem(value: u, child: Text(u.label)),
                ],
                onChanged: (u) => setState(() => unit = u ?? unit),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: low,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Alert when stock is at or below (optional)',
                  suffixText: unit.short,
                ),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional), e.g. supplier',
                ),
              ),
            ],
          ),
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
    ),
  );
  if (saved != true || !context.mounted) return;
  int? lowMilli;
  if (low.text.trim().isNotEmpty) {
    lowMilli = Qty.parse(low.text);
    if (lowMilli == null) {
      _snack(context, 'The alert level is not a number.');
      return;
    }
  }
  await _run(
    context,
    () => s.inventory.saveItem(
      id: item?.id,
      name: name.text,
      unit: unit,
      lowStockMilli: lowMilli,
      note: note.text,
    ),
  );
}

/// One stock item: on hand, stock in / wastage / count, history.
class StockItemScreen extends StatefulWidget {
  final String itemId;

  const StockItemScreen({super.key, required this.itemId});

  @override
  State<StockItemScreen> createState() => _StockItemScreenState();
}

class _StockItemScreenState extends State<StockItemScreen> {
  final s = StorageService.maybeInstance!;
  late final Stream<List<StockItem>> _items = s.inventory.watchItems();
  late final Stream<List<StockMovement>> _history = s.inventory.watchHistory(
    widget.itemId,
  );

  Future<void> _entry(StockItem it, StockMovementKind kind) async {
    if (!await _canManage(context) || !mounted) return;
    final qty = TextEditingController();
    final cost = TextEditingController();
    final reason = TextEditingController();
    final requestId = newId();
    final count = kind == StockMovementKind.count;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(count ? 'Count ${it.name}' : kind.label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (count)
                Text(
                  'The app expects ${Qty.withUnit(it.onHandMilli, it.unit)}. '
                  'Enter what is actually there.',
                ),
              TextField(
                controller: qty,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: count ? 'Counted' : 'Quantity',
                  suffixText: it.unit.short,
                ),
              ),
              if (kind == StockMovementKind.purchase)
                TextField(
                  controller: cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount paid for this quantity (optional)',
                    prefixText: '₹ ',
                  ),
                ),
              TextField(
                controller: reason,
                decoration: InputDecoration(
                  labelText: switch (kind) {
                    StockMovementKind.wastage => 'Reason (required)',
                    StockMovementKind.count =>
                      'Reason if different (required then)',
                    StockMovementKind.purchase =>
                      'Supplier / bill no. (optional)',
                    _ => 'Note (optional)',
                  },
                ),
              ),
            ],
          ),
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
    if (ok != true || !mounted) return;
    final q = Qty.parse(qty.text);
    if (q == null) {
      _snack(context, 'Enter a number, up to 3 decimals.');
      return;
    }
    int? costPaise;
    if (cost.text.trim().isNotEmpty) {
      final m = Money.parse(cost.text);
      if (m == null) {
        _snack(context, 'The amount is not valid.');
        return;
      }
      costPaise = m.paise;
    }
    await _run(context, () async {
      if (count) {
        final diff = await s.inventory.countStock(
          stockItemId: it.id,
          countedMilli: q,
          reason: reason.text,
          clientRequestId: requestId,
        );
        if (mounted) {
          _snack(
            context,
            diff == 0
                ? 'Count matches: nothing changed.'
                : 'Stock corrected by ${diff > 0 ? '+' : ''}'
                      '${Qty.withUnit(diff, it.unit)}.',
          );
        }
      } else {
        await s.inventory.record(
          stockItemId: it.id,
          kind: kind,
          qtyMilli: q,
          costPaise: costPaise,
          reason: reason.text,
          clientRequestId: requestId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('d MMM, h:mm a');
    return StreamBuilder<List<StockItem>>(
      stream: _items,
      builder: (context, snap) {
        final it = snap.data?.where((i) => i.id == widget.itemId).firstOrNull;
        if (it == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(it.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (!await _canManage(context)) return;
                  if (!context.mounted) return;
                  if (v == 'edit') await editStockItem(context, it);
                  if (v == 'active' && context.mounted) {
                    await _run(
                      context,
                      () => s.inventory.setItemActive(it.id, !it.active),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'active',
                    child: Text(it.active ? 'Turn off' : 'Turn back on'),
                  ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<StockMovement>>(
            stream: _history,
            builder: (context, hs) {
              final history = hs.data ?? const <StockMovement>[];
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('On hand (expected)'),
                          Text(
                            Qty.withUnit(it.onHandMilli, it.unit),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: it.isNegative
                                  ? Colors.red
                                  : it.isLow
                                  ? Colors.deepOrange
                                  : null,
                            ),
                          ),
                          if (it.isNegative)
                            const Text(
                              'Below zero: more was used than was recorded '
                              'coming in. Count it and record purchases.',
                              style: TextStyle(color: Colors.red),
                            ),
                          if (it.lowStockMilli != null)
                            Text(
                              'Alert at ${Qty.withUnit(it.lowStockMilli!, it.unit)}',
                            ),
                          if (it.lastCostPerUnitPaise != null)
                            Text(
                              'Last purchase: '
                              '${Money(it.lastCostPerUnitPaise!).format()} '
                              'per ${it.unit.short} (for reference; stock is '
                              'not valued)',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (history.isEmpty)
                        FilledButton.icon(
                          icon: const Icon(Icons.flag),
                          label: const Text('Opening stock'),
                          onPressed: () =>
                              _entry(it, StockMovementKind.opening),
                        ),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Stock in'),
                        onPressed: () => _entry(it, StockMovementKind.purchase),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Wastage'),
                        onPressed: () => _entry(it, StockMovementKind.wastage),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Count'),
                        onPressed: () => _entry(it, StockMovementKind.count),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nothing recorded yet.'),
                    ),
                  for (final m in history)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.kind.label),
                      subtitle: Text(
                        [
                          time.format(m.createdAt),
                          if (m.units != null) '${m.units} sold',
                          if (m.reason.isNotEmpty) m.reason,
                          if (m.costPaise != null)
                            'paid ${Money(m.costPaise!).format()}',
                          if (m.staffName.isNotEmpty) m.staffName,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${m.qtyMilli > 0 ? '+' : ''}'
                        '${Qty.withUnit(m.qtyMilli, it.unit)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: m.qtyMilli < 0 ? Colors.red.shade700 : null,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Stock movements for a date range as one CSV file, via the share sheet.
Future<void> _exportCsv(BuildContext context) async {
  final s = StorageService.maybeInstance!;
  final today = DateTime.now();
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: today,
    initialDateRange: DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today,
    ),
  );
  if (range == null || !context.mounted) return;
  final d = DateFormat('yyyy-MM-dd');
  final from = d.format(range.start), to = d.format(range.end);
  await _run(context, () async {
    final csv = await stockMovementsCsv(s, from, to);
    final dir = await getTemporaryDirectory();
    final f = File(p.join(dir.path, 'stock-movements-${from}_to_$to.csv'));
    await f.writeAsString(csv);
    await s.audit.record(
      action: 'stock.csv_exported',
      entity: 'stock_movements',
      details: {'from': from, 'to': to},
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(f.path, mimeType: 'text/csv')],
        subject: 'Stock movements $from to $to',
      ),
    );
  });
}

/// CSV of stock movements (UTF-8 with BOM; quantities as plain numbers;
/// typed text that starts with = + - @ gets a leading apostrophe).
Future<String> stockMovementsCsv(
  StorageService s,
  String from,
  String to,
) async {
  final items = {for (final i in await s.inventory.items()) i.id: i};
  final moves = await s.inventory.movementsBetween(from, to);
  final time = DateFormat('yyyy-MM-dd HH:mm');
  String txt(String v) => RegExp(r'^[=+\-@\t\r]').hasMatch(v) ? "'$v" : v;
  String amt(int paise) =>
      '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
  final rows = <List<Object?>>[
    [
      'time',
      'business_date',
      'item',
      'unit',
      'kind',
      'qty',
      'units_sold',
      'cost',
      'reason',
      'staff',
    ],
    for (final m in moves)
      [
        time.format(m.createdAt),
        m.businessDate,
        txt(items[m.stockItemId]?.name ?? ''),
        items[m.stockItemId]?.unit.short ?? '',
        m.kind.name,
        Qty.format(m.qtyMilli),
        m.units ?? '',
        m.costPaise == null ? '' : amt(m.costPaise!),
        txt(m.reason),
        txt(m.staffName),
      ],
  ];
  return '﻿${Csv(lineDelimiter: '\n').encode(rows)}';
}
