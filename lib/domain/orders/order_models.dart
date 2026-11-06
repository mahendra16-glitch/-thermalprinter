import '../../core/util/money.dart';
import '../menu/menu_models.dart';

enum OrderType { dineIn, takeaway, delivery }

extension OrderTypeX on OrderType {
  String get label => switch (this) {
    OrderType.dineIn => 'Dine-in',
    OrderType.takeaway => 'Takeaway',
    OrderType.delivery => 'Delivery',
  };

  static OrderType parse(String? s) =>
      OrderType.values.where((e) => e.name == s).firstOrNull ??
      OrderType.dineIn;
}

/// Order lifecycle.
///
/// `open` and `held` orders are active: they can be edited. A `billed`
/// order has a finalized bill and waits for payment; it still occupies its
/// table but cannot be edited unless the bill is voided. `settled` is set
/// when payments cover the bill. `due` is a billed order closed with money
/// still owed (the table is free; the balance stays visible until paid).
/// `cancelled` orders are kept, read-only, with their reason.
enum OrderStatus { open, held, billed, settled, due, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.open => 'Running',
    OrderStatus.held => 'On hold',
    OrderStatus.billed => 'Payment pending',
    OrderStatus.settled => 'Paid',
    OrderStatus.due => 'Due',
    OrderStatus.cancelled => 'Cancelled',
  };

  /// Can be edited (items, discount, kitchen).
  bool get isActive => this == OrderStatus.open || this == OrderStatus.held;

  /// Still on the floor: shown as running and keeps its table busy.
  bool get occupiesTable => isActive || this == OrderStatus.billed;

  static OrderStatus parse(String? s) =>
      OrderStatus.values.where((e) => e.name == s).firstOrNull ??
      OrderStatus.open;
}

enum DiscountKind { none, percent, amount }

extension DiscountKindX on DiscountKind {
  static DiscountKind parse(String? s) =>
      DiscountKind.values.where((e) => e.name == s).firstOrNull ??
      DiscountKind.none;
}

class OrderDiscount {
  final DiscountKind kind;

  /// Basis points for [DiscountKind.percent], paise for [DiscountKind.amount].
  final int value;
  final String reason;

  const OrderDiscount({
    this.kind = DiscountKind.none,
    this.value = 0,
    this.reason = '',
  });

  static const none = OrderDiscount();

  bool get isNone => kind == DiscountKind.none || value <= 0;

  String get label => switch (kind) {
    DiscountKind.none => 'No discount',
    DiscountKind.percent => '${formatBp(value)} off',
    DiscountKind.amount => '${Money(value).format()} off',
  };
}

class OrderLineOption {
  final String groupId;
  final String groupName;
  final OptionGroupKind kind;
  final String choiceId;
  final String name;
  final Money priceDelta;

  const OrderLineOption({
    required this.groupId,
    required this.groupName,
    required this.kind,
    required this.choiceId,
    required this.name,
    required this.priceDelta,
  });
}

class OrderLine {
  final String id;
  final String orderId;
  final String? menuItemId;
  final String itemName;
  final String variantText;
  final Money basePrice;
  final Money unitPrice;
  final String? taxProfileId;
  final int taxRateBp;
  final bool taxInclusive;
  final TaxSplitMode taxSplitMode;
  final String? stationId;
  final int qty;
  final int sentQty;
  final int voidedQty;
  final String notes;
  final int sortOrder;
  final List<OrderLineOption> options;

  const OrderLine({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    this.variantText = '',
    required this.basePrice,
    required this.unitPrice,
    this.taxProfileId,
    this.taxRateBp = 0,
    this.taxInclusive = false,
    this.taxSplitMode = TaxSplitMode.none,
    this.stationId,
    required this.qty,
    this.sentQty = 0,
    this.voidedQty = 0,
    this.notes = '',
    this.sortOrder = 0,
    this.options = const [],
  });

  // Invariant: 0 <= voidedQty <= sentQty <= qty. Voids only ever apply to
  // units already sent; unsent units are simply removed.

  /// Units that are still being charged for.
  int get billableQty => qty - voidedQty;

  /// Units not yet sent to the kitchen.
  int get unsentQty => qty - sentQty;

  /// Units in the kitchen that can still be voided.
  int get voidableQty => sentQty - voidedQty;

  Money get lineTotal => unitPrice * billableQty;

  /// "Paneer Tikka (Full)".
  String get displayName =>
      variantText.isEmpty ? itemName : '$itemName ($variantText)';

  List<OrderLineOption> get addons =>
      options.where((o) => o.kind == OptionGroupKind.addon).toList();
}

class Order {
  final String id;
  final int orderNo;
  final String businessDate;
  final OrderType type;
  final String? tableId;
  final String customerName;
  final String customerPhone;
  final int? guests;
  final String staffName;
  final OrderStatus status;
  final String notes;
  final OrderDiscount discount;
  final String cancelReason;

  /// Why the order was closed with money still due.
  final String dueNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  const Order({
    required this.id,
    required this.orderNo,
    required this.businessDate,
    required this.type,
    this.tableId,
    this.customerName = '',
    this.customerPhone = '',
    this.guests,
    this.staffName = '',
    required this.status,
    this.notes = '',
    this.discount = OrderDiscount.none,
    this.cancelReason = '',
    this.dueNote = '',
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  bool get isEditable => status.isActive;
}

/// An order with its lines.
class OrderDetail {
  final Order order;
  final List<OrderLine> lines;

  const OrderDetail(this.order, this.lines);

  OrderTotals get totals => OrderTotals.of(lines, order.discount);
}

/// Pre-tax totals shown while taking an order. Tax, service charge and
/// rounding are added by the billing module when the bill is generated.
class OrderTotals {
  /// Sum of billable line totals (prices as entered, which may already
  /// include tax for inclusive-tax items).
  final Money itemsTotal;

  /// Order-level discount, never more than [itemsTotal].
  final Money discount;
  final int itemCount;

  const OrderTotals({
    required this.itemsTotal,
    required this.discount,
    required this.itemCount,
  });

  Money get afterDiscount => itemsTotal - discount;

  static OrderTotals of(List<OrderLine> lines, OrderDiscount d) {
    var total = Money.zero;
    var count = 0;
    for (final l in lines) {
      total += l.lineTotal;
      count += l.billableQty;
    }
    return OrderTotals(
      itemsTotal: total,
      discount: discountAmount(total, d),
      itemCount: count,
    );
  }

  /// Discount in paise for [total]. Percent discounts round half up to the
  /// paisa. Never negative and never more than [total].
  static Money discountAmount(Money total, OrderDiscount d) {
    if (d.isNone || total.paise <= 0) return Money.zero;
    final raw = switch (d.kind) {
      DiscountKind.percent => (total.paise * d.value + 5000) ~/ 10000,
      DiscountKind.amount => d.value,
      DiscountKind.none => 0,
    };
    return Money(raw.clamp(0, total.paise));
  }
}

/// Local business date for [at]. A day that starts at 4 am counts orders
/// placed at 1 am as the previous day's business.
String businessDateFor(DateTime at, {int dayStartHour = 0}) {
  final shifted = at.toLocal().subtract(Duration(hours: dayStartHour));
  final m = shifted.month.toString().padLeft(2, '0');
  final d = shifted.day.toString().padLeft(2, '0');
  return '${shifted.year}-$m-$d';
}
