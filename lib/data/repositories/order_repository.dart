import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/menu/item_configuration.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/orders/order_models.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'settings_repository.dart';

/// The chosen table already has a running order.
class TableBusyException extends ValidationException {
  final String existingOrderId;
  TableBusyException(this.existingOrderId)
    : super('This table already has a running order.');
}

class NewOrderRequest {
  /// Generated once per "new order" action on the device. Sending the same
  /// id again returns the order already created for it.
  final String clientRequestId;
  final OrderType type;
  final String? tableId;
  final int? guests;
  final String customerName;
  final String customerPhone;

  /// Set only after staff explicitly chose to open a second order on a
  /// table that is already in use.
  final bool allowSharedTable;

  const NewOrderRequest({
    required this.clientRequestId,
    required this.type,
    this.tableId,
    this.guests,
    this.customerName = '',
    this.customerPhone = '',
    this.allowSharedTable = false,
  });
}

/// An order with its pre-tax totals, for lists and table cards.
class OrderSummary {
  final Order order;
  final OrderTotals totals;
  final int lineCount;

  /// Grand total of the current (not voided) bill, once billed.
  final Money? billTotal;

  const OrderSummary(this.order, this.totals, this.lineCount, {this.billTotal});

  /// The bill total once billed, otherwise the running pre-tax total.
  Money get displayTotal => billTotal ?? totals.afterDiscount;
}

/// One timeline entry for an order (from the audit log).
class OrderEvent {
  final DateTime at;
  final String action;
  final Map<String, dynamic> details;

  const OrderEvent(this.at, this.action, this.details);
}

/// Order taking. Every change runs in a transaction and writes an audit
/// entry (entity `orders`, entity id = order id), which is also the order's
/// timeline.
class OrderRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final SettingsRepository _settings;

  OrderRepository(this._db, this._audit, this._settings);

  static const int maxQty = 999;
  static const String keyDayStartHour = 'business_day_start_hour';

  /// Orders still on the floor: running, on hold, or billed and waiting
  /// for payment. They occupy their table.
  static final List<String> _activeStatuses = [
    for (final s in OrderStatus.values)
      if (s.occupiesTable) s.name,
  ];

  // ---------------------------------------------------------------- settings

  /// Hour (0–6) at which a new business day starts. Orders before it count
  /// towards the previous day (late-night service).
  Future<int> getDayStartHour() async {
    final v = int.tryParse(await _settings.getRaw(keyDayStartHour) ?? '');
    return (v == null || v < 0 || v > 6) ? 0 : v;
  }

  Future<void> setDayStartHour(int hour) async {
    if (hour < 0 || hour > 6) {
      throw ValidationException('Business day must start between 0 and 6 am.');
    }
    await _settings.setRaw(keyDayStartHour, '$hour');
  }

  Future<String> currentBusinessDate() async =>
      businessDateFor(Clock.now(), dayStartHour: await getDayStartHour());

  // ------------------------------------------------------------------ create

  /// Creates an order and returns its id. Safe to call twice with the same
  /// [NewOrderRequest.clientRequestId].
  Future<String> createOrder(NewOrderRequest r) {
    return _db.transaction(() async {
      final dup =
          await (_db.select(_db.orders)
                ..where((o) => o.clientRequestId.equals(r.clientRequestId)))
              .getSingleOrNull();
      if (dup != null) return dup.id;

      if (r.type == OrderType.dineIn) {
        final tableId = r.tableId;
        if (tableId == null) {
          throw ValidationException('Choose a table for a dine-in order.');
        }
        await _requireActiveTable(tableId);
        if (!r.allowSharedTable) {
          final busy = await _activeOrderOnTable(tableId);
          if (busy != null) throw TableBusyException(busy);
        }
      } else if (r.tableId != null) {
        throw ValidationException('Only dine-in orders have a table.');
      }
      if (r.guests != null && (r.guests! < 1 || r.guests! > 500)) {
        throw ValidationException('Guests must be 1 to 500.');
      }

      final date = await currentBusinessDate();
      final max = _db.orders.orderNo.max();
      final row =
          await (_db.selectOnly(_db.orders)
                ..addColumns([max])
                ..where(_db.orders.businessDate.equals(date)))
              .getSingle();
      final orderNo = (row.read(max) ?? 0) + 1;
      final id = newId();
      final now = Clock.nowMs();
      await _db
          .into(_db.orders)
          .insert(
            OrdersCompanion.insert(
              id: id,
              orderNo: orderNo,
              businessDate: date,
              orderType: r.type.name,
              tableId: Value(r.tableId),
              customerName: Value(r.customerName.trim()),
              customerPhone: Value(r.customerPhone.trim()),
              guests: Value(r.guests),
              status: OrderStatus.open.name,
              clientRequestId: r.clientRequestId,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _log(id, 'order.created', {
        'orderNo': orderNo,
        'businessDate': date,
        'type': r.type.name,
        'tableId': r.tableId,
        'sharedTable': r.allowSharedTable,
      });
      return id;
    });
  }

  // ------------------------------------------------------------------ read

  Future<OrderDetail?> getDetail(String orderId) async {
    final row = await (_db.select(
      _db.orders,
    )..where((o) => o.id.equals(orderId))).getSingleOrNull();
    if (row == null) return null;
    final lines = await _linesFor([orderId]);
    return OrderDetail(_orderFromRow(row), lines[orderId] ?? const []);
  }

  Stream<OrderDetail?> watchDetail(String orderId) {
    return _changes().asyncMap((_) => getDetail(orderId));
  }

  Future<List<OrderSummary>> listActive() async {
    final rows =
        await (_db.select(_db.orders)
              ..where((o) => o.status.isIn(_activeStatuses))
              ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
            .get();
    return _summaries(rows);
  }

  Stream<List<OrderSummary>> watchActive() =>
      _changes().asyncMap((_) => listActive());

  /// Orders of one business day that are closed (settled or cancelled),
  /// newest first.
  Future<List<OrderSummary>> listClosedFor(String businessDate) async {
    final rows =
        await (_db.select(_db.orders)
              ..where(
                (o) =>
                    o.businessDate.equals(businessDate) &
                    o.status.isNotIn(_activeStatuses),
              )
              ..orderBy([(o) => OrderingTerm.desc(o.updatedAt)]))
            .get();
    return _summaries(rows);
  }

  Future<List<OrderEvent>> timeline(String orderId) async {
    final rows =
        await (_db.select(_db.auditLog)
              ..where(
                (a) => a.entity.equals('orders') & a.entityId.equals(orderId),
              )
              ..orderBy([
                (a) => OrderingTerm.asc(a.at),
                (a) => OrderingTerm.asc(a.rowId),
              ]))
            .get();
    return rows
        .map(
          (r) => OrderEvent(
            Clock.toLocal(r.at),
            r.action,
            r.detailsJson == null
                ? const {}
                : jsonDecode(r.detailsJson!) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ------------------------------------------------------------------ lines

  /// Adds [item] to the order. If an identical line exists (same item,
  /// options, price and notes) its quantity is increased instead.
  /// Returns the line id.
  Future<String> addItem(
    String orderId,
    ConfiguredItem item, {
    int qty = 1,
    String notes = '',
  }) {
    return _db.transaction(() async {
      await _requireEditable(orderId);
      _checkQty(qty);
      final cleanNotes = notes.trim();
      final choiceKey = (item.options.map((o) => o.choiceId).toList()..sort())
          .join(',');

      final lines = (await _linesFor([orderId]))[orderId] ?? const [];
      for (final l in lines) {
        final key = (l.options.map((o) => o.choiceId).toList()..sort()).join(
          ',',
        );
        if (l.menuItemId == item.itemId &&
            l.unitPrice == item.unitPrice &&
            l.notes == cleanNotes &&
            key == choiceKey &&
            l.taxRateBp == item.taxRateBp) {
          final newQty = l.qty + qty;
          _checkQty(newQty);
          await _writeQty(l.id, newQty);
          await _log(orderId, 'order.item_added', {
            'lineId': l.id,
            'name': l.displayName,
            'added': qty,
            'qty': newQty,
          });
          return l.id;
        }
      }

      final lineId = newId();
      final now = Clock.nowMs();
      final sort = lines.isEmpty
          ? 0
          : lines.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
      await _db
          .into(_db.orderLines)
          .insert(
            OrderLinesCompanion.insert(
              id: lineId,
              orderId: orderId,
              menuItemId: Value(item.itemId),
              itemName: item.itemName,
              variantText: Value(item.variantText),
              basePricePaise: item.basePrice.paise,
              unitPricePaise: item.unitPrice.paise,
              taxProfileId: Value(item.taxProfileId),
              taxRateBp: Value(item.taxRateBp),
              taxInclusive: Value(item.taxInclusive),
              taxSplitMode: Value(item.taxSplitMode.name),
              stationId: Value(item.stationId),
              qty: qty,
              notes: Value(cleanNotes),
              sortOrder: Value(sort),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var i = 0; i < item.options.length; i++) {
        final o = item.options[i];
        await _db
            .into(_db.orderLineOptions)
            .insert(
              OrderLineOptionsCompanion.insert(
                id: newId(),
                lineId: lineId,
                groupId: o.groupId,
                groupName: o.groupName,
                kind: o.kind.name,
                choiceId: o.choiceId,
                name: o.name,
                priceDeltaPaise: o.priceDelta.paise,
                sortOrder: Value(i),
              ),
            );
      }
      await _touch(orderId);
      await _log(orderId, 'order.item_added', {
        'lineId': lineId,
        'name': item.variantText.isEmpty
            ? item.itemName
            : '${item.itemName} (${item.variantText})',
        'added': qty,
        'qty': qty,
        'unitPricePaise': item.unitPrice.paise,
        'options': item.options.map((o) => o.name).toList(),
      });
      return lineId;
    });
  }

  Future<void> setLineQty(String lineId, int qty) {
    return _db.transaction(() async {
      final line = await _requireLine(lineId);
      await _requireEditable(line.orderId);
      _checkQty(qty);
      if (qty < line.sentQty) {
        throw ValidationException(
          '${line.sentQty} already sent to the kitchen. Void them instead of '
          'reducing the quantity.',
        );
      }
      if (qty == line.qty) return;
      await _writeQty(lineId, qty);
      await _log(line.orderId, 'order.qty_changed', {
        'lineId': lineId,
        'name': line.itemName,
        'from': line.qty,
        'to': qty,
      });
    });
  }

  Future<void> setLineNotes(String lineId, String notes) {
    return _db.transaction(() async {
      final line = await _requireLine(lineId);
      await _requireEditable(line.orderId);
      if (line.sentQty > 0) {
        throw ValidationException(
          'This item was already sent to the kitchen. Add it again with the '
          'new instructions.',
        );
      }
      final clean = notes.trim();
      if (clean == line.notes) return;
      await (_db.update(
        _db.orderLines,
      )..where((l) => l.id.equals(lineId))).write(
        OrderLinesCompanion(
          notes: Value(clean),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _touch(line.orderId);
      await _log(line.orderId, 'order.notes_changed', {
        'lineId': lineId,
        'name': line.itemName,
        'from': line.notes,
        'to': clean,
      });
    });
  }

  /// Removes a line that was never sent to the kitchen.
  Future<void> removeLine(String lineId) {
    return _db.transaction(() async {
      final line = await _requireLine(lineId);
      await _requireEditable(line.orderId);
      if (line.sentQty > 0 || line.voidedQty > 0) {
        throw ValidationException(
          'This item was already sent to the kitchen. Void it instead.',
        );
      }
      await (_db.delete(
        _db.orderLineOptions,
      )..where((o) => o.lineId.equals(lineId))).go();
      await (_db.delete(
        _db.orderLines,
      )..where((l) => l.id.equals(lineId))).go();
      await _touch(line.orderId);
      await _log(line.orderId, 'order.item_removed', {
        'lineId': lineId,
        'name': line.itemName,
        'qty': line.qty,
        'unitPricePaise': line.unitPricePaise,
      });
    });
  }

  // ----------------------------------------------------------- order-level

  Future<void> updateDetails(
    String orderId, {
    required String customerName,
    required String customerPhone,
    int? guests,
    required String notes,
  }) {
    return _db.transaction(() async {
      // Customer and notes do not change any amount, so they can still be
      // filled in on a billed or due order (e.g. before moving it to dues).
      // The finalized bill keeps the details it was made with.
      final o = await _requireOrder(orderId);
      final st = OrderStatusX.parse(o.status);
      if (!st.isActive && st != OrderStatus.billed && st != OrderStatus.due) {
        await _requireEditable(orderId);
      }
      final phone = customerPhone.replaceAll(RegExp(r'[\s\-]'), '');
      if (phone.isNotEmpty && !RegExp(r'^\+?\d{6,15}$').hasMatch(phone)) {
        throw ValidationException('Phone number must be 6 to 15 digits.');
      }
      if (guests != null && (guests < 1 || guests > 500)) {
        throw ValidationException('Guests must be 1 to 500.');
      }
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          customerName: Value(customerName.trim()),
          customerPhone: Value(phone),
          guests: Value(guests),
          notes: Value(notes.trim()),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _log(orderId, 'order.details_changed', {
        'from': {
          'customerName': o.customerName,
          'customerPhone': o.customerPhone,
          'guests': o.guests,
          'notes': o.notes,
        },
        'to': {
          'customerName': customerName.trim(),
          'customerPhone': phone,
          'guests': guests,
          'notes': notes.trim(),
        },
      });
    });
  }

  /// Sets or clears the order discount. A reason is required.
  Future<void> setDiscount(String orderId, OrderDiscount d) {
    return _db.transaction(() async {
      final o = await _requireEditable(orderId);
      if (d.kind == DiscountKind.percent && (d.value < 0 || d.value > 10000)) {
        throw ValidationException('Discount must be 0% to 100%.');
      }
      if (d.kind == DiscountKind.amount && d.value < 0) {
        throw ValidationException('Discount cannot be negative.');
      }
      if (!d.isNone && d.reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for the discount.');
      }
      final kind = d.isNone ? DiscountKind.none : d.kind;
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          discountKind: Value(kind.name),
          discountValue: Value(d.isNone ? 0 : d.value),
          discountReason: Value(d.isNone ? '' : d.reason.trim()),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _log(orderId, 'order.discount_changed', {
        'from': {
          'kind': o.discountKind,
          'value': o.discountValue,
          'reason': o.discountReason,
        },
        'to': {
          'kind': kind.name,
          'value': d.isNone ? 0 : d.value,
          'reason': d.reason.trim(),
        },
      });
    });
  }

  Future<void> hold(String orderId) => _setStatus(
    orderId,
    from: OrderStatus.open,
    to: OrderStatus.held,
    action: 'order.held',
  );

  Future<void> resume(String orderId) => _setStatus(
    orderId,
    from: OrderStatus.held,
    to: OrderStatus.open,
    action: 'order.resumed',
  );

  /// Cancels an order that has nothing in the kitchen. Lines are kept.
  Future<void> cancel(String orderId, String reason) {
    return _db.transaction(() async {
      await _requireEditable(orderId);
      if (reason.trim().isEmpty) {
        throw ValidationException('Enter a reason for cancelling.');
      }
      final lines = (await _linesFor([orderId]))[orderId] ?? const [];
      final inKitchen = lines.where((l) => l.sentQty > l.voidedQty).length;
      if (inKitchen > 0) {
        throw ValidationException(
          '$inKitchen item(s) were sent to the kitchen. Void them before '
          'cancelling the order.',
        );
      }
      final now = Clock.nowMs();
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(OrderStatus.cancelled.name),
          cancelReason: Value(reason.trim()),
          closedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final totals = OrderTotals.of(lines, OrderDiscount.none);
      await _log(orderId, 'order.cancelled', {
        'reason': reason.trim(),
        'lines': lines.length,
        'itemsTotalPaise': totals.itemsTotal.paise,
      });
    });
  }

  /// Moves a dine-in order to another table.
  Future<void> moveToTable(
    String orderId,
    String tableId, {
    bool allowSharedTable = false,
  }) {
    return _db.transaction(() async {
      final o = await _requireEditable(orderId);
      if (o.orderType != OrderType.dineIn.name) {
        throw ValidationException('Only dine-in orders can move tables.');
      }
      if (o.tableId == tableId) return;
      await _requireActiveTable(tableId);
      if (!allowSharedTable) {
        final busy = await _activeOrderOnTable(tableId, except: orderId);
        if (busy != null) throw TableBusyException(busy);
      }
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          tableId: Value(tableId),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _log(orderId, 'order.table_moved', {
        'from': o.tableId,
        'to': tableId,
      });
    });
  }

  /// Moves every line of [sourceId] into [targetId] and cancels the source
  /// with a "merged" reason. Kitchen progress (sent quantities) moves with
  /// the lines.
  Future<void> mergeInto(String sourceId, String targetId) {
    return _db.transaction(() async {
      if (sourceId == targetId) {
        throw ValidationException('Choose a different order to merge into.');
      }
      final source = await _requireEditable(sourceId);
      final target = await _requireEditable(targetId);
      if (DiscountKindX.parse(source.discountKind) != DiscountKind.none &&
          source.discountValue > 0) {
        throw ValidationException(
          'Order #${source.orderNo} has a discount. Remove it before merging.',
        );
      }
      final moved = await _moveLines(
        sourceId,
        targetId,
        ((await _linesFor([sourceId]))[sourceId] ?? const [])
            .map((l) => l.id)
            .toList(),
      );
      final now = Clock.nowMs();
      await (_db.update(_db.orders)..where((r) => r.id.equals(sourceId))).write(
        OrdersCompanion(
          status: Value(OrderStatus.cancelled.name),
          cancelReason: Value('Merged into order #${target.orderNo}'),
          closedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await _log(sourceId, 'order.merged_out', {
        'into': targetId,
        'intoNo': target.orderNo,
        'lines': moved,
      });
      await _log(targetId, 'order.merged_in', {
        'from': sourceId,
        'fromNo': source.orderNo,
        'lines': moved,
      });
    });
  }

  /// Moves the given whole lines to a new order (split bill / split table)
  /// and returns the new order's id.
  Future<String> splitToNewOrder(
    String orderId,
    List<String> lineIds,
    NewOrderRequest request,
  ) {
    return _db.transaction(() async {
      final source = await _requireEditable(orderId);
      if (lineIds.isEmpty) {
        throw ValidationException('Select the items to move.');
      }
      final newId = await createOrder(request);
      if (newId == orderId) {
        throw ValidationException('Choose a different target.');
      }
      final moved = await _moveLines(orderId, newId, lineIds);
      final target = await _requireEditable(newId);
      await _log(orderId, 'order.split_out', {
        'into': newId,
        'intoNo': target.orderNo,
        'lines': moved,
      });
      await _log(newId, 'order.split_in', {
        'from': orderId,
        'fromNo': source.orderNo,
        'lines': moved,
      });
      return newId;
    });
  }

  // ---------------------------------------------------------------- helpers

  Stream<void> _changes() async* {
    yield null;
    yield* _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.orders,
        _db.orderLines,
        _db.orderLineOptions,
      ]),
    );
  }

  Future<int> _moveLines(String from, String to, List<String> lineIds) async {
    final sourceLines = (await _linesFor([from]))[from] ?? const [];
    final ids = sourceLines.map((l) => l.id).toSet();
    for (final id in lineIds) {
      if (!ids.contains(id)) {
        throw ValidationException('An item is not on this order.');
      }
    }
    final targetLines = (await _linesFor([to]))[to] ?? const [];
    var sort = targetLines.isEmpty
        ? 0
        : targetLines.map((l) => l.sortOrder).reduce((a, b) => a > b ? a : b) +
              1;
    final now = Clock.nowMs();
    for (final l in sourceLines.where((l) => lineIds.contains(l.id))) {
      await (_db.update(_db.orderLines)..where((r) => r.id.equals(l.id))).write(
        OrderLinesCompanion(
          orderId: Value(to),
          sortOrder: Value(sort++),
          updatedAt: Value(now),
        ),
      );
    }
    await _touch(from);
    await _touch(to);
    return lineIds.length;
  }

  Future<void> _setStatus(
    String orderId, {
    required OrderStatus from,
    required OrderStatus to,
    required String action,
  }) {
    return _db.transaction(() async {
      final o = await _requireOrder(orderId);
      if (o.status != from.name) {
        throw ValidationException(
          'Order is ${OrderStatusX.parse(o.status).label.toLowerCase()}.',
        );
      }
      await (_db.update(_db.orders)..where((r) => r.id.equals(orderId))).write(
        OrdersCompanion(
          status: Value(to.name),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _log(orderId, action, const {});
    });
  }

  void _checkQty(int qty) {
    if (qty < 1 || qty > maxQty) {
      throw ValidationException('Quantity must be 1 to $maxQty.');
    }
  }

  Future<void> _writeQty(String lineId, int qty) async {
    final line = await _requireLine(lineId);
    await (_db.update(_db.orderLines)..where((l) => l.id.equals(lineId))).write(
      OrderLinesCompanion(qty: Value(qty), updatedAt: Value(Clock.nowMs())),
    );
    await _touch(line.orderId);
  }

  Future<void> _touch(String orderId) =>
      (_db.update(_db.orders)..where((o) => o.id.equals(orderId))).write(
        OrdersCompanion(updatedAt: Value(Clock.nowMs())),
      );

  Future<void> _log(String orderId, String action, Map<String, Object?> d) =>
      _audit.record(
        action: action,
        entity: 'orders',
        entityId: orderId,
        details: d,
      );

  Future<OrderRow> _requireOrder(String id) async {
    final o = await (_db.select(
      _db.orders,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (o == null) throw ValidationException('Order not found.');
    return o;
  }

  Future<OrderRow> _requireEditable(String id) async {
    final o = await _requireOrder(id);
    final status = OrderStatusX.parse(o.status);
    if (status == OrderStatus.billed) {
      throw ValidationException(
        'Order #${o.orderNo} is billed. Void the bill to make changes.',
      );
    }
    if (!status.isActive) {
      throw ValidationException(
        'Order #${o.orderNo} is ${status.label.toLowerCase()} and cannot be '
        'changed.',
      );
    }
    return o;
  }

  Future<OrderLineRow> _requireLine(String id) async {
    final l = await (_db.select(
      _db.orderLines,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (l == null) throw ValidationException('Item not found on the order.');
    return l;
  }

  Future<void> _requireActiveTable(String tableId) async {
    final t = await (_db.select(
      _db.restaurantTables,
    )..where((r) => r.id.equals(tableId))).getSingleOrNull();
    if (t == null || !t.isActive) {
      throw ValidationException('That table is not available.');
    }
  }

  Future<String?> _activeOrderOnTable(String tableId, {String? except}) async {
    final rows =
        await (_db.select(_db.orders)..where(
              (o) => o.tableId.equals(tableId) & o.status.isIn(_activeStatuses),
            ))
            .get();
    return rows.where((o) => o.id != except).firstOrNull?.id;
  }

  Future<List<OrderSummary>> _summaries(List<OrderRow> rows) async {
    final ids = rows.map((r) => r.id).toList();
    final lines = await _linesFor(ids);
    final bills = ids.isEmpty
        ? const <BillRow>[]
        : await (_db.select(_db.bills)..where(
                (b) => b.orderId.isIn(ids) & b.status.equals('finalized'),
              ))
              .get();
    final billTotal = {for (final b in bills) b.orderId: b.grandTotalPaise};
    return rows.map((r) {
      final o = _orderFromRow(r);
      final ls = lines[r.id] ?? const [];
      final bt = billTotal[r.id];
      return OrderSummary(
        o,
        OrderTotals.of(ls, o.discount),
        ls.length,
        billTotal: bt == null ? null : Money(bt),
      );
    }).toList();
  }

  Future<Map<String, List<OrderLine>>> _linesFor(List<String> orderIds) async {
    if (orderIds.isEmpty) return {};
    final rows =
        await (_db.select(_db.orderLines)
              ..where((l) => l.orderId.isIn(orderIds))
              ..orderBy([
                (l) => OrderingTerm.asc(l.sortOrder),
                (l) => OrderingTerm.asc(l.createdAt),
              ]))
            .get();
    final opts = rows.isEmpty
        ? <OrderLineOptionRow>[]
        : await (_db.select(_db.orderLineOptions)
                ..where((o) => o.lineId.isIn(rows.map((r) => r.id)))
                ..orderBy([(o) => OrderingTerm.asc(o.sortOrder)]))
              .get();
    final byLine = <String, List<OrderLineOption>>{};
    for (final o in opts) {
      byLine
          .putIfAbsent(o.lineId, () => [])
          .add(
            OrderLineOption(
              groupId: o.groupId,
              groupName: o.groupName,
              kind: OptionGroupKindX.parse(o.kind),
              choiceId: o.choiceId,
              name: o.name,
              priceDelta: Money(o.priceDeltaPaise),
            ),
          );
    }
    final out = <String, List<OrderLine>>{};
    for (final r in rows) {
      out
          .putIfAbsent(r.orderId, () => [])
          .add(
            OrderLine(
              id: r.id,
              orderId: r.orderId,
              menuItemId: r.menuItemId,
              itemName: r.itemName,
              variantText: r.variantText,
              basePrice: Money(r.basePricePaise),
              unitPrice: Money(r.unitPricePaise),
              taxProfileId: r.taxProfileId,
              taxRateBp: r.taxRateBp,
              taxInclusive: r.taxInclusive,
              taxSplitMode: TaxSplitModeX.parse(r.taxSplitMode),
              stationId: r.stationId,
              qty: r.qty,
              sentQty: r.sentQty,
              voidedQty: r.voidedQty,
              notes: r.notes,
              sortOrder: r.sortOrder,
              options: byLine[r.id] ?? const [],
            ),
          );
    }
    return out;
  }

  static Order _orderFromRow(OrderRow r) => Order(
    id: r.id,
    orderNo: r.orderNo,
    businessDate: r.businessDate,
    type: OrderTypeX.parse(r.orderType),
    tableId: r.tableId,
    customerName: r.customerName,
    customerPhone: r.customerPhone,
    guests: r.guests,
    staffName: r.staffName,
    status: OrderStatusX.parse(r.status),
    notes: r.notes,
    discount: OrderDiscount(
      kind: DiscountKindX.parse(r.discountKind),
      value: r.discountValue,
      reason: r.discountReason,
    ),
    cancelReason: r.cancelReason,
    dueNote: r.dueNote,
    createdAt: Clock.toLocal(r.createdAt),
    updatedAt: Clock.toLocal(r.updatedAt),
    closedAt: r.closedAt == null ? null : Clock.toLocal(r.closedAt!),
  );
}
