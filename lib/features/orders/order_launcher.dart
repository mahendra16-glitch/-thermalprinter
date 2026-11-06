import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/orders/table_models.dart';
import '../../services/storage_service.dart';
import 'order_screen.dart';

/// Opens an existing order.
Future<void> openOrder(BuildContext context, String orderId) {
  return Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: orderId)));
}

/// Creates an order (one request id per call, so a double tap cannot make
/// two) and opens it. For a busy table, asks before sharing it.
Future<void> startOrder(
  BuildContext context, {
  required OrderType type,
  RestaurantTable? table,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final storage = await StorageService.getInstance();
  var request = NewOrderRequest(
    clientRequestId: newId(),
    type: type,
    tableId: table?.id,
  );
  try {
    String id;
    try {
      id = await storage.orders.createOrder(request);
    } on TableBusyException catch (busy) {
      if (!context.mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${table?.label ?? 'Table'} is in use'),
          content: const Text(
            'This table already has a running order. Open it, or start a '
            'separate order on the same table?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: const Text('Start another'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'open'),
              child: const Text('Open existing'),
            ),
          ],
        ),
      );
      if (choice == 'open') {
        id = busy.existingOrderId;
      } else if (choice == 'new') {
        request = NewOrderRequest(
          clientRequestId: request.clientRequestId,
          type: type,
          tableId: table?.id,
          allowSharedTable: true,
        );
        id = await storage.orders.createOrder(request);
      } else {
        return;
      }
    }
    if (context.mounted) await openOrder(context, id);
  } on ValidationException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not start order: $e')),
    );
  }
}

/// Lets staff pick a table. Busy tables are marked; returns null on cancel.
Future<RestaurantTable?> pickTable(
  BuildContext context, {
  String title = 'Choose table',
  String? excludeTableId,
}) async {
  final storage = await StorageService.getInstance();
  final areas = (await storage.tables.listAreas())
      .where((a) => a.isActive)
      .toList();
  final tables = (await storage.tables.listTables())
      .where((t) => t.isActive && t.id != excludeTableId)
      .toList();
  final busy = {
    for (final s in await storage.orders.listActive())
      if (s.order.tableId != null) s.order.tableId!,
  };
  if (!context.mounted) return null;
  if (tables.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tables set up yet (Tables › Manage).')),
    );
    return null;
  }
  return showModalBottomSheet<RestaurantTable>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final a in areas) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                a.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tables.where((t) => t.areaId == a.id))
                  ActionChip(
                    avatar: Icon(
                      busy.contains(t.id)
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 14,
                      color: busy.contains(t.id)
                          ? const Color(0xFFEA580C)
                          : const Color(0xFF16A34A),
                    ),
                    label: Text(t.label),
                    onPressed: () => Navigator.pop(ctx, t),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
