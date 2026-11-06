import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/util/money.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/orders/order_models.dart';
import '../../domain/payments/payment_models.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import '../orders/order_launcher.dart';

/// Money still owed, and today's collections by method.
class DuesScreen extends StatefulWidget {
  const DuesScreen({super.key});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dues & payments'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Dues'),
              Tab(text: 'Today'),
            ],
          ),
        ),
        body: FutureBuilder<StorageService>(
          future: StorageService.getInstance(),
          builder: (ctx, s) {
            final storage = s.data;
            if (storage == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<void>(
              stream: storage.payments.watchChanges(),
              builder: (ctx, _) =>
                  TabBarView(children: [_dues(storage), _today(storage)]),
            );
          },
        ),
      ),
    );
  }

  Widget _dues(StorageService storage) => FutureBuilder<List<DueOrder>>(
    future: storage.payments.listDues(),
    builder: (ctx, snap) {
      final dues = snap.data;
      if (dues == null) return const Center(child: CircularProgressIndicator());
      if (dues.isEmpty) {
        return const MessageState(
          icon: Icons.check_circle_outline_rounded,
          title: 'Nothing is due',
          message: 'Every bill is fully paid.',
        );
      }
      final total = dues.fold(Money.zero, (s, d) => s + d.summary.balance);
      return ListView(
        children: [
          ListTile(
            title: Text(
              '${dues.length} bill(s) · ${total.format()} due',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final d in dues)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () => openOrder(context, d.order.id),
                title: Text(
                  [
                    'Bill ${d.bill.billNumber}',
                    if (d.order.customerName.isNotEmpty) d.order.customerName,
                    if (d.order.customerPhone.isNotEmpty) d.order.customerPhone,
                  ].join(' · '),
                ),
                subtitle: Text(
                  [
                    DateFormat('dd MMM, hh:mm a').format(d.bill.createdAt),
                    d.order.status == OrderStatus.due
                        ? 'Moved to dues'
                        : 'On the floor',
                    if (d.order.dueNote.isNotEmpty) d.order.dueNote,
                  ].join(' · '),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      d.summary.balance.format(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'of ${d.bill.grandTotal.format()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  static Future<List<LedgerEntry>> _todayEntries(StorageService s) async =>
      s.payments.entriesForDate(await s.orders.currentBusinessDate());

  Widget _today(StorageService storage) => FutureBuilder<List<LedgerEntry>>(
    future: _todayEntries(storage),
    builder: (ctx, snap) {
      final entries = snap.data;
      if (entries == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (entries.isEmpty) {
        return const MessageState(
          icon: Icons.payments_outlined,
          title: 'No payments today',
        );
      }
      final byMethod = netByMethod(entries);
      final net = byMethod.values.fold(Money.zero, (s, m) => s + m);
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final m in byMethod.entries)
            ListTile(
              dense: true,
              title: Text(m.key),
              trailing: Text(
                m.value.format(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ListTile(
            title: const Text(
              'Net collected',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              net.format(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'UPI, card and other amounts are as recorded by staff; check '
              'them against your bank statement.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const Divider(),
          for (final e in entries.reversed)
            ListTile(
              dense: true,
              onTap: () => openOrder(context, e.orderId),
              leading: Icon(
                e.isReversal ? Icons.undo_rounded : Icons.call_received_rounded,
                color: e.isReversal ? const Color(0xFFDC2626) : null,
              ),
              title: Text(
                '${e.isReversal ? 'Reversed' : 'Paid'} ${e.methodLabel}',
              ),
              subtitle: Text(
                [
                  DateFormat('hh:mm a').format(e.createdAt),
                  if (e.reference.isNotEmpty) 'Ref ${e.reference}',
                  if (e.reason.isNotEmpty) e.reason,
                ].join(' · '),
              ),
              trailing: Text(e.signedAmount.format()),
            ),
        ],
      );
    },
  );
}
