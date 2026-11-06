import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/orders/kitchen_models.dart';
import '../../domain/orders/order_models.dart';
import '../../models/pos_order.dart';
import '../../models/print_job.dart';
import '../../models/printer_device.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'audit_repository.dart';
import 'print_job_repository.dart';

/// Kitchen order tickets (KOT).
///
/// Sending creates one ticket per station with only the units not sent
/// before, raises each line's `sent_qty`, and writes the print jobs, all in
/// one transaction. The order is never rolled back because a printer
/// fails: failed jobs stay in the queue for retry.
///
/// After [sendToKitchen], [voidItems] or [reprintTicket], call
/// `PrintQueueManager.syncFromStorage()` so the new jobs start printing.
class KitchenRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final PrintJobRepository _jobs;

  KitchenRepository(this._db, this._audit, this._jobs);

  static const String defaultStation = StationPrinters.defaultStation;
  static const String defaultStationName = 'Kitchen';

  // ---------------------------------------------------------------- routing

  /// Station id -> printer ids. Items without a station use
  /// [defaultStation].
  Future<Map<String, List<String>>> stationPrinters() async {
    final rows = await _db.select(_db.stationPrinters).get();
    final out = <String, List<String>>{};
    for (final r in rows) {
      out.putIfAbsent(r.stationId, () => []).add(r.printerId);
    }
    return out;
  }

  Future<void> setStationPrinters(String stationId, List<String> printerIds) {
    return _db.transaction(() async {
      await (_db.delete(
        _db.stationPrinters,
      )..where((t) => t.stationId.equals(stationId))).go();
      for (final p in printerIds.toSet()) {
        await _db
            .into(_db.stationPrinters)
            .insert(
              StationPrintersCompanion.insert(
                stationId: stationId,
                printerId: p,
              ),
            );
      }
      await _audit.record(
        action: 'station.printers_changed',
        entity: 'kitchen_stations',
        entityId: stationId,
        details: {'printers': printerIds},
      );
    });
  }

  // ------------------------------------------------------------------- send

  /// Sends every unsent unit of [orderId] to the kitchen. Calling again
  /// with the same [clientRequestId] returns the first result.
  Future<KitchenSendResult> sendToKitchen(
    String orderId, {
    required String clientRequestId,
  }) {
    return _db.transaction(() async {
      final done = await _ticketsForRequest(clientRequestId);
      if (done.isNotEmpty) return KitchenSendResult(done, 0, const []);

      final order = await _requireActiveOrder(orderId);
      final lines =
          await (_db.select(_db.orderLines)
                ..where((l) => l.orderId.equals(orderId))
                ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
              .get();
      final unsent = lines.where((l) => l.qty > l.sentQty).toList();
      if (unsent.isEmpty) {
        throw ValidationException('Nothing new to send to the kitchen.');
      }

      final round = await _nextRound(orderId);
      final byStation = <String, List<OrderLineRow>>{};
      for (final l in unsent) {
        byStation.putIfAbsent(l.stationId ?? defaultStation, () => []).add(l);
      }

      final ticketIds = <String>[];
      final unrouted = <String>[];
      var jobCount = 0;
      final now = Clock.nowMs();
      for (final entry in byStation.entries) {
        final stationName = await _stationName(entry.key);
        final ticketId = newId();
        await _db
            .into(_db.kitchenTickets)
            .insert(
              KitchenTicketsCompanion.insert(
                id: ticketId,
                orderId: orderId,
                stationId: entry.key,
                stationName: stationName,
                roundNo: round,
                kind: KitchenTicketKind.send.name,
                clientRequestId: clientRequestId,
                createdAt: now,
              ),
            );
        var sort = 0;
        for (final l in entry.value) {
          final addons = await _addonsText(l.id);
          await _db
              .into(_db.kitchenTicketLines)
              .insert(
                KitchenTicketLinesCompanion.insert(
                  id: newId(),
                  ticketId: ticketId,
                  orderLineId: l.id,
                  qty: l.qty - l.sentQty,
                  itemName: _displayName(l),
                  addonsText: Value(addons),
                  notes: Value(l.notes),
                  sortOrder: Value(sort++),
                ),
              );
          await (_db.update(
            _db.orderLines,
          )..where((r) => r.id.equals(l.id))).write(
            OrderLinesCompanion(sentQty: Value(l.qty), updatedAt: Value(now)),
          );
        }
        final printers = await _printersFor(entry.key);
        if (printers.isEmpty) unrouted.add(stationName);
        jobCount += await _queueTicket(ticketId, order, printers);
        ticketIds.add(ticketId);
      }
      await _touch(orderId, now);
      await _audit.record(
        action: 'order.kot_sent',
        entity: 'orders',
        entityId: orderId,
        details: {
          'round': round,
          'tickets': ticketIds.length,
          'stations': [for (final k in byStation.keys) await _stationName(k)],
          'lines': unsent
              .map((l) => {'name': _displayName(l), 'qty': l.qty - l.sentQty})
              .toList(),
        },
      );
      return KitchenSendResult(ticketIds, jobCount, unrouted);
    });
  }

  // ------------------------------------------------------------------- void

  /// Voids [qty] units of a line that were already sent, and prints a void
  /// ticket for its station. The units stay on the order record but are no
  /// longer charged.
  Future<String> voidItems(
    String lineId, {
    required int qty,
    required String reason,
    required String clientRequestId,
  }) {
    return _db.transaction(() async {
      final done = await _ticketsForRequest(clientRequestId);
      if (done.isNotEmpty) return done.first;

      final line = await (_db.select(
        _db.orderLines,
      )..where((l) => l.id.equals(lineId))).getSingleOrNull();
      if (line == null) throw ValidationException('Item not found.');
      final order = await _requireActiveOrder(line.orderId);
      final voidable = line.sentQty - line.voidedQty;
      if (voidable <= 0) {
        throw ValidationException(
          'Nothing to void: no units of this item are in the kitchen.',
        );
      }
      if (qty < 1 || qty > voidable) {
        throw ValidationException('You can void 1 to $voidable.');
      }
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for the void.');
      }

      final now = Clock.nowMs();
      final station = line.stationId ?? defaultStation;
      final ticketId = newId();
      await _db
          .into(_db.kitchenTickets)
          .insert(
            KitchenTicketsCompanion.insert(
              id: ticketId,
              orderId: line.orderId,
              stationId: station,
              stationName: await _stationName(station),
              roundNo: await _nextRound(line.orderId),
              kind: KitchenTicketKind.voided.name,
              reason: Value(reason.trim()),
              clientRequestId: clientRequestId,
              createdAt: now,
            ),
          );
      await _db
          .into(_db.kitchenTicketLines)
          .insert(
            KitchenTicketLinesCompanion.insert(
              id: newId(),
              ticketId: ticketId,
              orderLineId: line.id,
              qty: qty,
              itemName: _displayName(line),
              addonsText: Value(await _addonsText(line.id)),
              notes: Value(line.notes),
            ),
          );
      await (_db.update(
        _db.orderLines,
      )..where((r) => r.id.equals(line.id))).write(
        OrderLinesCompanion(
          voidedQty: Value(line.voidedQty + qty),
          updatedAt: Value(now),
        ),
      );
      await _queueTicket(ticketId, order, await _printersFor(station));
      await _touch(line.orderId, now);
      await _audit.record(
        action: 'order.items_voided',
        entity: 'orders',
        entityId: line.orderId,
        details: {
          'lineId': line.id,
          'name': _displayName(line),
          'qty': qty,
          'reason': reason.trim(),
          'unitPricePaise': line.unitPricePaise,
        },
      );
      return ticketId;
    });
  }

  // ---------------------------------------------------------------- reprint

  /// Queues a copy of a ticket marked "REPRINT", built from the stored
  /// ticket. Creates no new ticket and changes no quantities.
  Future<int> reprintTicket(String ticketId) {
    return _db.transaction(() async {
      final t = await (_db.select(
        _db.kitchenTickets,
      )..where((r) => r.id.equals(ticketId))).getSingleOrNull();
      if (t == null) throw ValidationException('Ticket not found.');
      final order = await (_db.select(
        _db.orders,
      )..where((o) => o.id.equals(t.orderId))).getSingle();
      final n = await _queueTicket(
        ticketId,
        order,
        await _printersFor(t.stationId),
        reprint: true,
      );
      await _audit.record(
        action: 'order.kot_reprinted',
        entity: 'orders',
        entityId: t.orderId,
        details: {'ticketId': ticketId, 'round': t.roundNo},
      );
      return n;
    });
  }

  // ------------------------------------------------------------------ read

  Future<List<KitchenTicket>> ticketsFor(String orderId) async {
    final rows =
        await (_db.select(_db.kitchenTickets)
              ..where((t) => t.orderId.equals(orderId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    final out = <KitchenTicket>[];
    for (final r in rows) {
      final lines =
          await (_db.select(_db.kitchenTicketLines)
                ..where((l) => l.ticketId.equals(r.id))
                ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
              .get();
      final jobs = [
        ...await _jobs.jobsWithSourcePrefix('KOT:${r.id}:'),
        ...await _jobs.jobsWithSourcePrefix('REPRINT:KOT:${r.id}:'),
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      out.add(
        KitchenTicket(
          id: r.id,
          orderId: r.orderId,
          stationId: r.stationId,
          stationName: r.stationName,
          roundNo: r.roundNo,
          kind: r.kind == KitchenTicketKind.voided.name
              ? KitchenTicketKind.voided
              : KitchenTicketKind.send,
          reason: r.reason,
          createdAt: Clock.toLocal(r.createdAt),
          lines: lines
              .map(
                (l) => KitchenTicketLine(
                  orderLineId: l.orderLineId,
                  qty: l.qty,
                  itemName: l.itemName,
                  addonsText: l.addonsText,
                  notes: l.notes,
                ),
              )
              .toList(),
          jobs: jobs,
        ),
      );
    }
    return out;
  }

  Stream<void> watchChanges() => _db.tableUpdates(
    TableUpdateQuery.onAllTables([_db.kitchenTickets, _db.printJobs]),
  );

  // ---------------------------------------------------------------- helpers

  /// Writes one print job per printer (or one role-routed job when the
  /// station has no printer). Returns the number of jobs.
  Future<int> _queueTicket(
    String ticketId,
    OrderRow order,
    List<String> printerIds, {
    bool reprint = false,
  }) async {
    final ticket = await (_db.select(
      _db.kitchenTickets,
    )..where((t) => t.id.equals(ticketId))).getSingle();
    final lines =
        await (_db.select(_db.kitchenTicketLines)
              ..where((l) => l.ticketId.equals(ticketId))
              ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
            .get();
    final table = order.tableId == null
        ? null
        : await (_db.select(
            _db.restaurantTables,
          )..where((t) => t.id.equals(order.tableId!))).getSingleOrNull();
    final isVoid = ticket.kind == KitchenTicketKind.voided.name;
    final pos = PosOrder(
      orderId: '${order.orderNo}',
      type: 'KOT',
      printerRole: PrinterRole.kot,
      tableNumber: table?.label,
      orderType: OrderTypeX.parse(order.orderType).label,
      waiterName: order.staffName.isEmpty ? null : order.staffName,
      specialNotes: isVoid || order.notes.isEmpty ? null : order.notes,
      items: [
        for (final l in lines)
          PosOrderItem(
            name: l.itemName,
            qty: l.qty,
            notes: l.notes.isEmpty ? null : l.notes,
            addOns: l.addonsText.isEmpty ? const [] : l.addonsText.split(', '),
          ),
      ],
      timestamp: Clock.toLocal(ticket.createdAt),
      kotKind: isVoid ? 'VOID' : 'NEW',
      kotRound: isVoid ? null : ticket.roundNo,
      stationName: ticket.stationName,
      isReprint: reprint,
      reason: isVoid ? ticket.reason : null,
    );
    final targets = printerIds.isEmpty ? <String?>[null] : printerIds;
    for (final p in targets) {
      final key = 'KOT:$ticketId:${p ?? 'role'}';
      await _jobs.upsertJob(
        PrintJob(
          id: newId(),
          orderId: '${order.orderNo}',
          printType: 'KOT',
          targetRole: PrinterRole.kot,
          targetPrinterId: p,
          posOrderJson: pos.toJson(),
          sourceKey: reprint ? 'REPRINT:$key:${newId()}' : key,
        ),
      );
    }
    return targets.length;
  }

  /// Printers for a station; a station without its own printers uses the
  /// default station's printers. Deleted printers are skipped.
  Future<List<String>> _printersFor(String stationId) async {
    final map = await stationPrinters();
    final existing = {
      for (final r in await _db.select(_db.printerProfiles).get()) r.id,
    };
    List<String> valid(String s) =>
        (map[s] ?? const []).where(existing.contains).toList();
    final own = valid(stationId);
    if (own.isNotEmpty || stationId == defaultStation) return own;
    return valid(defaultStation);
  }

  Future<String> _stationName(String stationId) async {
    if (stationId == defaultStation) return defaultStationName;
    final s = await (_db.select(
      _db.kitchenStations,
    )..where((t) => t.id.equals(stationId))).getSingleOrNull();
    return s?.name ?? defaultStationName;
  }

  Future<String> _addonsText(String lineId) async {
    final opts =
        await (_db.select(_db.orderLineOptions)
              ..where((o) => o.lineId.equals(lineId) & o.kind.equals('addon'))
              ..orderBy([(o) => OrderingTerm.asc(o.sortOrder)]))
            .get();
    return opts.map((o) => o.name).join(', ');
  }

  String _displayName(OrderLineRow l) =>
      l.variantText.isEmpty ? l.itemName : '${l.itemName} (${l.variantText})';

  Future<int> _nextRound(String orderId) async {
    final max = _db.kitchenTickets.roundNo.max();
    final r =
        await (_db.selectOnly(_db.kitchenTickets)
              ..addColumns([max])
              ..where(_db.kitchenTickets.orderId.equals(orderId)))
            .getSingle();
    return (r.read(max) ?? 0) + 1;
  }

  Future<List<String>> _ticketsForRequest(String requestId) async {
    final rows = await (_db.select(
      _db.kitchenTickets,
    )..where((t) => t.clientRequestId.equals(requestId))).get();
    return rows.map((r) => r.id).toList();
  }

  Future<OrderRow> _requireActiveOrder(String orderId) async {
    final o = await (_db.select(
      _db.orders,
    )..where((r) => r.id.equals(orderId))).getSingleOrNull();
    if (o == null) throw ValidationException('Order not found.');
    if (!OrderStatusX.parse(o.status).isActive) {
      throw ValidationException('Order #${o.orderNo} is closed.');
    }
    return o;
  }

  Future<void> _touch(String orderId, int now) =>
      (_db.update(_db.orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(updatedAt: Value(now)),
      );
}
