import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/order_repository.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/orders/table_models.dart';
import '../../services/storage_service.dart';
import '../common/time_format.dart';
import '../menu/menu_widgets.dart';
import '../payments/dues_screen.dart';
import 'order_launcher.dart';

enum _Filter { all, dineIn, takeaway, held, billed }

/// Running orders, plus today's closed ones.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderSummary>? _active;
  List<OrderSummary> _closed = [];
  Map<String, RestaurantTable> _tables = {};
  _Filter _filter = _Filter.all;
  StreamSubscription<List<OrderSummary>>? _sub;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _init();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _sub = storage.orders.watchActive().listen((a) async {
      final tables = {
        for (final t in await storage.tables.listTables()) t.id: t,
      };
      final closed = await storage.orders.listClosedFor(
        await storage.orders.currentBusinessDate(),
      );
      if (!mounted) return;
      setState(() {
        _active = a;
        _tables = tables;
        _closed = closed;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  bool _matches(OrderSummary s) => switch (_filter) {
    _Filter.all => true,
    _Filter.dineIn => s.order.type == OrderType.dineIn,
    _Filter.takeaway => s.order.type != OrderType.dineIn,
    _Filter.held => s.order.status == OrderStatus.held,
    _Filter.billed => s.order.status == OrderStatus.billed,
  };

  Widget _tile(OrderSummary s) {
    final o = s.order;
    final where = o.tableId == null
        ? o.type.label
        : '${_tables[o.tableId]?.label ?? 'Table'} · ${o.type.label}';
    final color = switch (o.status) {
      OrderStatus.open => const Color(0xFFEA580C),
      OrderStatus.held => const Color(0xFF7C3AED),
      OrderStatus.billed => const Color(0xFF2563EB),
      OrderStatus.due => const Color(0xFFDC2626),
      OrderStatus.cancelled => Colors.grey,
      _ => const Color(0xFF16A34A),
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () => openOrder(context, o.id),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            '#${o.orderNo}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(where, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            '${s.totals.itemCount} item(s)',
            if (o.customerName.isNotEmpty) o.customerName,
            if (o.status.occupiesTable)
              elapsedLabel(o.createdAt, DateTime.now())
            else if (o.status == OrderStatus.cancelled)
              o.cancelReason
            else if (o.status == OrderStatus.due && o.dueNote.isNotEmpty)
              o.dueNote,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              s.displayTotal.format(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SmallBadge(o.status.label, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final visible = (active ?? []).where(_matches).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DuesScreen())),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Dues & payments'),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'dinein',
            onPressed: () async {
              final t = await pickTable(context, title: 'New dine-in order');
              if (t != null && context.mounted) {
                await startOrder(context, type: OrderType.dineIn, table: t);
              }
            },
            icon: const Icon(Icons.table_restaurant_rounded),
            label: const Text('Dine-in'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'takeaway2',
            onPressed: () => startOrder(context, type: OrderType.takeaway),
            icon: const Icon(Icons.shopping_bag_rounded),
            label: const Text('Takeaway'),
          ),
        ],
      ),
      body: active == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 160),
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
                      for (final (f, label) in [
                        (_Filter.all, 'All (${active.length})'),
                        (_Filter.dineIn, 'Dine-in'),
                        (_Filter.takeaway, 'Takeaway'),
                        (_Filter.held, 'On hold'),
                        (_Filter.billed, 'Payment pending'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                if (visible.isEmpty)
                  const MessageState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No running orders',
                    message:
                        'Start a dine-in order from the Tables tab, or a '
                        'takeaway order with the button below.',
                  ),
                ...visible.map(_tile),
                if (_closed.isNotEmpty)
                  ExpansionTile(
                    title: Text('Closed today (${_closed.length})'),
                    children: _closed.map(_tile).toList(),
                  ),
              ],
            ),
    );
  }
}
