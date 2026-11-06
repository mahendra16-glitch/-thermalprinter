import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../data/repositories/menu_repository.dart';
import '../../domain/billing/bill_models.dart';
import '../../domain/menu/item_configuration.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/orders/table_models.dart';
import '../../services/storage_service.dart';
import '../billing/bill_actions.dart';
import '../common/time_format.dart';
import '../menu/menu_widgets.dart';
import 'item_options_sheet.dart';
import 'kitchen_actions.dart';
import 'order_actions.dart';

/// Order taking: menu on one side, the running order on the other (tabs on
/// phones).
class OrderScreen extends StatefulWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  OrderDetail? _detail;

  /// The current bill, once the order is billed.
  Bill? _bill;
  MenuSnapshot? _menu;
  Map<String, RestaurantTable> _tables = {};
  StreamSubscription<OrderDetail?>? _sub;
  StreamSubscription<void>? _menuSub;
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _category = '__fav_or_all__';
  bool _busy = false;
  bool _missing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _tables = {for (final t in await storage.tables.listTables()) t.id: t};
    _sub = storage.orders.watchDetail(widget.orderId).listen((d) async {
      final bill = d != null && d.order.status != OrderStatus.open
          ? await storage.bills.currentBillFor(d.order.id)
          : null;
      if (!mounted) return;
      setState(() {
        _detail = d;
        _bill = bill;
        _missing = d == null;
      });
    });
    _menuSub = storage.menu.watchChanges().listen((_) => _loadMenu());
    await _loadMenu();
  }

  Future<void> _loadMenu() async {
    final storage = await StorageService.getInstance();
    final snap = await storage.menu.loadSnapshot();
    if (mounted) setState(() => _menu = snap);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _menuSub?.cancel();
    _tabs.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _editable => _detail?.order.isEditable ?? false;

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- menu

  List<MenuItem> _items(MenuSnapshot snap, OrderType type) {
    final q = _search.text.trim().toLowerCase();
    var items = snap.items
        .where(snap.isOrderable)
        .where(
          (i) => switch (type) {
            OrderType.dineIn => i.availableDineIn,
            OrderType.takeaway || OrderType.delivery => i.availableTakeaway,
          },
        );
    if (q.isNotEmpty) {
      return items
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                (i.sku?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    final cat = _effectiveCategory(snap);
    if (cat == '__fav__') {
      items = items.where((i) => i.isFavorite);
    } else if (cat != '__all__') {
      final ids = {cat, ...snap.subcategoriesOf(cat).map((c) => c.id)};
      items = items.where((i) => ids.contains(i.categoryId));
    }
    return items.toList();
  }

  /// Favourites first if there are any, otherwise everything.
  String _effectiveCategory(MenuSnapshot snap) {
    if (_category != '__fav_or_all__') return _category;
    return snap.items.any((i) => i.isFavorite && snap.isOrderable(i))
        ? '__fav__'
        : '__all__';
  }

  Future<void> _tapItem(MenuItem item, {bool askAlways = false}) async {
    final snap = _menu;
    if (snap == null || !_editable) return;
    final groups = offeredGroups(item, snap.groupById);
    final tax = item.taxProfileId == null
        ? null
        : snap.taxById[item.taxProfileId];
    final storage = await StorageService.getInstance();
    if (groups.isEmpty && !askAlways) {
      await _guard(() async {
        final c = configureItem(
          item: item,
          groups: snap.groupById,
          selected: const {},
          tax: tax,
        );
        await storage.orders.addItem(widget.orderId, c);
      });
      return;
    }
    if (!mounted) return;
    final choice = await showItemOptionsSheet(
      context,
      item: item,
      groups: groups,
    );
    if (choice == null) return;
    await _guard(() async {
      final c = configureItem(
        item: item,
        groups: snap.groupById,
        selected: choice.selected,
        tax: tax,
      );
      await storage.orders.addItem(
        widget.orderId,
        c,
        qty: choice.qty,
        notes: choice.notes,
      );
    });
  }

  /// Enter in the search box adds the item whose short code matches
  /// exactly (keyboard / barcode-scanner wedge input).
  Future<void> _submitSearch(String text) async {
    final snap = _menu;
    final d = _detail;
    if (snap == null || d == null) return;
    final code = text.trim().toLowerCase();
    if (code.isEmpty) return;
    final visible = _items(snap, d.order.type);
    final exact = visible
        .where((i) => i.sku != null && i.sku!.toLowerCase() == code)
        .toList();
    final pick = exact.length == 1
        ? exact.single
        : (visible.length == 1 ? visible.single : null);
    if (pick == null) return;
    await _tapItem(pick);
    _search.clear();
    setState(() {});
    _searchFocus.requestFocus();
  }

  Widget _menuPanel(MenuSnapshot snap, OrderType type) {
    final items = _items(snap, type);
    final cat = _effectiveCategory(snap);
    final cats = snap.topLevelCategories.where((c) => c.isActive).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            focusNode: _searchFocus,
            onChanged: (_) => setState(() {}),
            onSubmitted: _submitSearch,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search or type short code + Enter',
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              _chip('★ Quick', cat == '__fav__', '__fav__'),
              _chip('All', cat == '__all__', '__all__'),
              for (final c in cats) _chip(c.name, cat == c.id, c.id),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? MessageState(
                  icon: Icons.search_off_rounded,
                  title: snap.items.isEmpty ? 'Menu is empty' : 'No items',
                  message: snap.items.isEmpty
                      ? 'Add items in the Menu tab first.'
                      : cat == '__fav__'
                      ? 'Mark items as favourites (★) in the Menu tab.'
                      : null,
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 92,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _itemButton(snap, items[i]),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, String value) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = value),
    ),
  );

  Widget _itemButton(MenuSnapshot snap, MenuItem item) {
    final hasOptions = offeredGroups(item, snap.groupById).isNotEmpty;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _editable ? () => _tapItem(item) : null,
        onLongPress: _editable ? () => _tapItem(item, askAlways: true) : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 6),
                    child: FoodTypeMark(item.foodType, size: 12),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    item.basePrice.format(),
                    style: const TextStyle(color: Color(0xFF334155)),
                  ),
                  const Spacer(),
                  if (hasOptions)
                    const Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- order

  String _title(Order o) {
    final table = o.tableId == null ? null : _tables[o.tableId]?.label;
    return [
      'Order #${o.orderNo}',
      if (table != null) table else o.type.label,
    ].join(' · ');
  }

  Widget _orderPanel(OrderDetail d) {
    final o = d.order;
    final totals = d.totals;
    final unsent = d.lines.fold<int>(0, (n, l) => n + l.unsentQty);
    return Column(
      children: [
        if (o.status == OrderStatus.billed)
          MaterialBanner(
            backgroundColor: const Color(0xFFDBEAFE),
            content: Text(
              _bill == null
                  ? 'Billed · waiting for payment'
                  : 'Bill ${_bill!.billNumber} · ${_bill!.grandTotal.format()}'
                        ' · waiting for payment',
            ),
            actions: [
              if (_bill != null)
                TextButton(
                  onPressed: () => showBill(context, _bill!.id),
                  child: const Text('View bill'),
                ),
            ],
          )
        else if (!o.isEditable)
          MaterialBanner(
            backgroundColor: Colors.grey.shade200,
            content: Text(
              o.status == OrderStatus.cancelled
                  ? 'Cancelled: ${o.cancelReason}'
                  : 'This order is ${o.status.label.toLowerCase()} and '
                        'cannot be changed.',
            ),
            actions: const [SizedBox.shrink()],
          ),
        if (o.status == OrderStatus.held)
          MaterialBanner(
            backgroundColor: const Color(0xFFEDE9FE),
            content: const Text('On hold'),
            actions: [
              TextButton(
                onPressed: () => _guard(
                  () async =>
                      (await StorageService.getInstance()).orders.resume(o.id),
                ),
                child: const Text('Resume'),
              ),
            ],
          ),
        ListTile(
          dense: true,
          title: Text(
            [
              o.type.label,
              if (o.guests != null) '${o.guests} guest(s)',
              if (o.customerName.isNotEmpty) o.customerName,
              if (o.customerPhone.isNotEmpty) o.customerPhone,
            ].join(' · '),
          ),
          subtitle: Text(
            'Started ${elapsedLabel(o.createdAt, DateTime.now())} ago'
            '${o.notes.isEmpty ? '' : '\nNote: ${o.notes}'}',
          ),
          trailing: o.isEditable
              ? IconButton(
                  tooltip: 'Customer & notes',
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: () => editOrderDetails(context, o),
                )
              : null,
        ),
        const Divider(height: 1),
        Expanded(
          child: d.lines.isEmpty
              ? const MessageState(
                  icon: Icons.add_shopping_cart_rounded,
                  title: 'No items yet',
                  message: 'Tap items from the menu to add them.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: d.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _lineTile(d.lines[i], o.isEditable, o),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _bill != null && o.status == OrderStatus.billed
              ? BreakdownView(rowsForBill(_bill!))
              : Column(
                  children: [
                    _totalRow(
                      'Items (${totals.itemCount})',
                      totals.itemsTotal.format(),
                    ),
                    if (!totals.discount.isZero)
                      _totalRow(
                        'Discount (${o.discount.label})',
                        '-${totals.discount.format()}',
                      ),
                    _totalRow(
                      'Amount before tax',
                      totals.afterDiscount.format(),
                      bold: true,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Taxes and charges are added when the bill is generated.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (o.status == OrderStatus.billed && _bill != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => voidBill(context, _bill!),
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Void bill'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => showBill(context, _bill!.id),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Bill & print'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (o.isEditable)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (unsent > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _guard(() => sendToKitchen(context, o.id)),
                        icon: const Icon(Icons.soup_kitchen_rounded),
                        label: Text('Send to kitchen ($unsent new)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: unsent > 0
                        ? FilledButton.tonalIcon(
                            onPressed: _busy || d.lines.isEmpty
                                ? null
                                : () => _guard(() => _generateBill(o.id)),
                            icon: const Icon(Icons.receipt_long_rounded),
                            label: const Text('Generate bill'),
                          )
                        : FilledButton.icon(
                            onPressed: _busy || d.lines.isEmpty
                                ? null
                                : () => _guard(() => _generateBill(o.id)),
                            icon: const Icon(Icons.receipt_long_rounded),
                            label: const Text('Generate bill'),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => editDiscount(context, d),
                          icon: const Icon(Icons.percent_rounded),
                          label: const Text('Discount'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: o.status == OrderStatus.open
                              ? () => _guard(() async {
                                  await (await StorageService.getInstance())
                                      .orders
                                      .hold(o.id);
                                  if (mounted) Navigator.of(context).pop();
                                })
                              : null,
                          icon: const Icon(Icons.pause_circle_outline_rounded),
                          label: const Text('Hold'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _generateBill(String orderId) async {
    await generateBill(context, orderId);
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _lineTile(OrderLine l, bool editable, Order o) {
    final addons = l.addons;
    return InkWell(
      onTap: editable ? () => editLine(context, l) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: l.billableQty == 0
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (addons.isNotEmpty)
                    Text(
                      addons
                          .map(
                            (a) => a.priceDelta.isZero
                                ? '+ ${a.name}'
                                : '+ ${a.name} (${a.priceDelta.format()})',
                          )
                          .join('\n'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (l.notes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.notes,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  Text(
                    [
                      '${l.unitPrice.format()} each',
                      if (l.sentQty > 0 && l.unsentQty == 0)
                        'in kitchen'
                      else if (l.sentQty > 0)
                        '${l.sentQty} in kitchen, ${l.unsentQty} new'
                      else if (o.isEditable)
                        'not sent',
                      if (l.voidedQty > 0) '${l.voidedQty} voided',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (editable)
              QtyStepper(
                compact: true,
                qty: l.qty,
                min: l.sentQty > 0 ? l.sentQty : 1,
                onChanged: _busy
                    ? null
                    : (q) => _guard(
                        () async => (await StorageService.getInstance()).orders
                            .setLineQty(l.id, q),
                      ),
              )
            else
              Text('× ${l.qty}'),
            SizedBox(
              width: 84,
              child: Text(
                l.lineTotal.format(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const MessageState(
          icon: Icons.error_outline_rounded,
          title: 'Order not found',
        ),
      );
    }
    final d = _detail;
    final snap = _menu;
    if (d == null || snap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final actions = [
      if (d.order.isEditable)
        PopupMenuButton<OrderMenuAction>(
          onSelected: (a) => runOrderMenuAction(context, a, d),
          itemBuilder: (_) => orderMenuItems(d),
        )
      else
        IconButton(
          tooltip: 'Timeline',
          icon: const Icon(Icons.history_rounded),
          onPressed: () => showOrderTimeline(context, d.order),
        ),
    ];

    if (wide) {
      return Scaffold(
        appBar: AppBar(title: Text(_title(d.order)), actions: actions),
        body: Row(
          children: [
            Expanded(flex: 3, child: _menuPanel(snap, d.order.type)),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2,
              child: ColoredBox(color: Colors.white, child: _orderPanel(d)),
            ),
          ],
        ),
      );
    }

    final count = d.totals.itemCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(d.order)),
        actions: actions,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'Menu'),
            Tab(text: 'Order ($count)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Column(
            children: [
              Expanded(child: _menuPanel(snap, d.order.type)),
              Material(
                color: const Color(0xFF1E293B),
                child: InkWell(
                  onTap: () => _tabs.animateTo(1),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$count item(s)',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            d.totals.afterDiscount.format(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _orderPanel(d),
        ],
      ),
    );
  }
}
