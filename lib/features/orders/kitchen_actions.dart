import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/errors.dart';
import '../../core/util/ids.dart';
import '../../domain/orders/kitchen_models.dart';
import '../../domain/orders/order_models.dart';
import '../../queue/print_queue_manager.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import 'item_options_sheet.dart';
import '../staff/permission_guard.dart';
import '../../domain/staff/staff_models.dart';

/// Sends all unsent items of [orderId] to the kitchen and starts printing.
Future<void> sendToKitchen(BuildContext context, String orderId) async {
  if (!await allow(context, Permission.takeOrders) || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final storage = await StorageService.getInstance();
  try {
    final result = await storage.kitchen.sendToKitchen(
      orderId,
      clientRequestId: newId(),
    );
    final queue = await PrintQueueManager.getInstance();
    await queue.syncFromStorage();
    final warn = result.unroutedStations.isEmpty
        ? ''
        : ' No printer is assigned to ${result.unroutedStations.join(', ')}; '
              'using the KOT/fallback printer.';
    messenger.showSnackBar(
      SnackBar(
        content: Text('Sent ${result.ticketIds.length} KOT(s) to print.$warn'),
      ),
    );
  } on ValidationException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not send to kitchen: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

/// Voids units of a line that are already in the kitchen.
Future<void> voidSentItems(BuildContext context, OrderLine line) async {
  if (!await allow(context, Permission.cancelOrder) || !context.mounted) return;
  final reason = TextEditingController();
  var qty = line.voidableQty;
  final requestId = newId();
  const reasons = [
    'Customer cancelled',
    'Wrong item entered',
    'Item not available',
    'Quality issue',
  ];
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text('Void ${line.displayName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${line.voidableQty} in the kitchen. A void ticket is printed '
              'for the kitchen and the units are no longer charged.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Units to void'),
                const Spacer(),
                QtyStepper(
                  qty: qty,
                  max: line.voidableQty,
                  onChanged: (q) => setLocal(() => qty = q),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            child: const Text('Void'),
          ),
        ],
      ),
    ),
  );
  if (go != true || !context.mounted) return;
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  final ok = await runMenuAction(
    context,
    () => storage.kitchen.voidItems(
      line.id,
      qty: qty,
      reason: reason.text,
      clientRequestId: requestId,
    ),
    success: 'Voided $qty × ${line.displayName}. Void ticket sent to print.',
  );
  if (ok) await (await PrintQueueManager.getInstance()).syncFromStorage();
}

/// Lists the order's kitchen tickets with their print status, and lets
/// staff reprint one or retry a failed print.
Future<void> showKitchenTickets(BuildContext context, Order order) async {
  final storage = await StorageService.getInstance();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (ctx, scroll) => StreamBuilder<void>(
        stream: storage.kitchen.watchChanges(),
        builder: (ctx, _) => FutureBuilder<List<KitchenTicket>>(
          future: storage.kitchen.ticketsFor(order.id),
          builder: (ctx, snap) {
            final tickets = snap.data;
            if (tickets == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              controller: scroll,
              children: [
                ListTile(
                  title: Text(
                    'Kitchen tickets · Order #${order.orderNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    '"Printed" means the printer accepted the data; check '
                    'the slip actually came out.',
                  ),
                ),
                if (tickets.isEmpty)
                  const MessageState(
                    icon: Icons.soup_kitchen_outlined,
                    title: 'Nothing sent yet',
                  ),
                for (final t in tickets.reversed) _TicketCard(ticket: t),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  final KitchenTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final (label, color) = switch (t.printState) {
      TicketPrintState.printed => ('Printed', const Color(0xFF16A34A)),
      TicketPrintState.printing => ('Printing…', const Color(0xFF2563EB)),
      TicketPrintState.failed => ('Print failed', const Color(0xFFDC2626)),
      TicketPrintState.notQueued => ('Not queued', const Color(0xFF64748B)),
    };
    final isVoid = t.kind == KitchenTicketKind.voided;
    final failed = t.jobs
        .where((j) => j.status.name == 'failed')
        .map((j) => j.id)
        .toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isVoid
                      ? 'VOID · ${t.stationName}'
                      : 'Round ${t.roundNo} · ${t.stationName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isVoid ? Colors.red : null,
                  ),
                ),
                const Spacer(),
                SmallBadge(label, color: color),
              ],
            ),
            Text(
              DateFormat('hh:mm a').format(t.createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            for (final l in t.lines)
              Text(
                '${isVoid ? '−' : ''}${l.qty} × ${l.itemName}'
                '${l.addonsText.isEmpty ? '' : ' + ${l.addonsText}'}'
                '${l.notes.isEmpty ? '' : '  [${l.notes}]'}',
              ),
            if (isVoid && t.reason.isNotEmpty)
              Text('Reason: ${t.reason}', style: const TextStyle(fontSize: 12)),
            if (t.printState == TicketPrintState.failed && t.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  t.lastError!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
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
                    label: const Text('Reprint'),
                    onPressed: () async {
                      final storage = await StorageService.getInstance();
                      if (!context.mounted) return;
                      final ok = await runMenuAction(
                        context,
                        () => storage.kitchen.reprintTicket(t.id),
                        success: 'Reprint queued (marked REPRINT).',
                      );
                      if (ok) {
                        await (await PrintQueueManager.getInstance())
                            .syncFromStorage();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
