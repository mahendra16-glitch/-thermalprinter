import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/util/money.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/orders/table_models.dart';
import '../../services/storage_service.dart';
import '../common/time_format.dart';
import '../menu/menu_widgets.dart';
import '../orders/order_launcher.dart';
import 'manage_tables_screen.dart';
import '../staff/permission_guard.dart';
import '../../domain/staff/staff_models.dart';

/// Floor view: every table with its live status.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<DiningArea>? _areas;
  List<RestaurantTable> _tables = [];
  List<OrderSummary> _active = [];
  String? _areaFilter;
  final List<StreamSubscription<void>> _subs = [];
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _init();
    // Refresh elapsed times.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _subs.add(storage.tables.watchChanges().listen((_) => _loadTables()));
    _subs.add(
      storage.orders.watchActive().listen((a) {
        if (mounted) setState(() => _active = a);
      }),
    );
    await _loadTables();
  }

  Future<void> _loadTables() async {
    final storage = await StorageService.getInstance();
    final areas = await storage.tables.listAreas();
    final tables = await storage.tables.listTables();
    if (mounted) {
      setState(() {
        _areas = areas;
        _tables = tables;
      });
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _onTap(RestaurantTable t, List<OrderSummary> orders) async {
    if (orders.isEmpty) {
      await startOrder(context, type: OrderType.dineIn, table: t);
    } else if (orders.length == 1) {
      await openOrder(context, orders.single.order.id);
    } else {
      final picked = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text(
                  '${t.label}: ${orders.length} orders',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final o in orders)
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: Text('Order #${o.order.orderNo}'),
                  subtitle: Text(
                    '${o.totals.itemCount} item(s) · '
                    '${o.displayTotal.format()}',
                  ),
                  onTap: () => Navigator.pop(ctx, o.order.id),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Start another order on this table'),
                onTap: () => Navigator.pop(ctx, '__new__'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || picked == null) return;
      if (picked == '__new__') {
        await startOrder(context, type: OrderType.dineIn, table: t);
      } else {
        await openOrder(context, picked);
      }
    }
  }

  Widget _card(RestaurantTable t, List<OrderSummary> orders) {
    final now = DateTime.now();
    final busy = orders.isNotEmpty;
    final held =
        busy && orders.every((o) => o.order.status == OrderStatus.held);
    final billed =
        busy && orders.every((o) => o.order.status == OrderStatus.billed);
    final color = !busy
        ? const Color(0xFF16A34A)
        : billed
        ? const Color(0xFF2563EB)
        : held
        ? const Color(0xFF7C3AED)
        : const Color(0xFFEA580C);
    final status = !busy
        ? 'Available'
        : orders.length > 1
        ? '${orders.length} orders'
        : billed
        ? 'Payment pending · #${orders.single.order.orderNo}'
        : held
        ? 'On hold · #${orders.single.order.orderNo}'
        : 'Running · #${orders.single.order.orderNo}';
    final total = orders.fold(0, (sum, o) => sum + o.displayTotal.paise);
    final oldest = busy
        ? orders
              .map((o) => o.order.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    final guests = orders.fold<int>(0, (s, o) => s + (o.order.guests ?? 0));

    return Material(
      color: busy ? color.withValues(alpha: 0.10) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: busy ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTap(t, orders),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (t.seats != null)
                    Text(
                      '${guests > 0 ? '$guests/' : ''}${t.seats}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (busy) ...[
                Text(
                  Money(total).format(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  elapsedLabel(oldest!, now),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = _areas;
    final activeAreas = (areas ?? []).where((a) => a.isActive).toList();
    final byTable = <String, List<OrderSummary>>{};
    for (final o in _active) {
      final id = o.order.tableId;
      if (id != null) byTable.putIfAbsent(id, () => []).add(o);
    }
    final visibleAreas = _areaFilter == null
        ? activeAreas
        : activeAreas.where((a) => a.id == _areaFilter).toList();
    final busyCount = byTable.length;
    final activeTables = _tables.where((t) => t.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(
            tooltip: 'Manage areas and tables',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _manageTables(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'takeaway',
        onPressed: () => startOrder(context, type: OrderType.takeaway),
        icon: const Icon(Icons.shopping_bag_rounded),
        label: const Text('Takeaway'),
      ),
      body: areas == null
          ? const Center(child: CircularProgressIndicator())
          : activeAreas.isEmpty
          ? MessageState(
              icon: Icons.table_restaurant_rounded,
              title: 'No tables yet',
              message:
                  'Add areas (Indoor, Terrace…) and tables to take dine-in '
                  'orders. Takeaway orders work without tables.',
              action: FilledButton.icon(
                onPressed: () => _manageTables(context),
                icon: const Icon(Icons.add),
                label: const Text('Set up tables'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('All ($busyCount/$activeTables busy)'),
                          selected: _areaFilter == null,
                          onSelected: (_) => setState(() => _areaFilter = null),
                        ),
                      ),
                      for (final a in activeAreas)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(a.name),
                            selected: _areaFilter == a.id,
                            onSelected: (_) =>
                                setState(() => _areaFilter = a.id),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final a in visibleAreas) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      a.name.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.extent(
                      maxCrossAxisExtent: 170,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final t in _tables.where(
                          (t) => t.isActive && t.areaId == a.id,
                        ))
                          _card(t, byTable[t.id] ?? const []),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

Future<void> _manageTables(BuildContext context) async {
  if (!await allow(context, Permission.changeSettings) || !context.mounted) {
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ManageTablesScreen()));
}
