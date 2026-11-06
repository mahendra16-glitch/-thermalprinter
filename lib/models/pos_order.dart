import 'printer_device.dart';

class PosOrderItem {
  final String name;
  final int qty;
  final double price;
  final String? notes;
  final List<String> addOns;

  PosOrderItem({
    required this.name,
    required this.qty,
    this.price = 0.0,
    this.notes,
    this.addOns = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'qty': qty,
    'price': price,
    'notes': notes,
    if (addOns.isNotEmpty) 'addOns': addOns,
  };

  factory PosOrderItem.fromJson(Map<String, dynamic> json) => PosOrderItem(
    name: json['name'] as String? ?? 'Item',
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes'] as String?,
    addOns: (json['addOns'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class PosOrder {
  final String orderId;
  final String billNo;
  final String type; // e.g. "KOT", "BILL", "CUSTOMER_COPY"
  final PrinterRole printerRole;
  final String restaurantName;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? tableNumber;
  final String? waiterName;
  final String orderType;
  final String? specialNotes;
  final List<PosOrderItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final String paymentStatus; // e.g. "PAID", "PENDING"; empty = not printed
  final DateTime timestamp;

  // Kitchen ticket fields (type "KOT").
  /// "NEW" for items being sent, "VOID" for a cancellation ticket.
  final String kotKind;
  final int? kotRound;
  final String? stationName;

  /// Printed as a "REPRINT" banner so it is not mistaken for a new order.
  final bool isReprint;

  /// Reason shown on void tickets.
  final String? reason;

  /// Full finalized bill (`Bill.toJson()`) for type "BILL" jobs made by the
  /// billing module. When set, it is printed instead of the fields above.
  final Map<String, dynamic>? bill;

  /// Report data for type "SHIFT_REPORT" jobs.
  final Map<String, dynamic>? report;

  PosOrder({
    required this.orderId,
    String? billNo,
    this.type = 'BILL',
    this.printerRole = PrinterRole.bill,
    // No demo defaults: anything not provided is simply not printed.
    this.restaurantName = '',
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.tableNumber,
    this.waiterName,
    this.orderType = 'DINE-IN',
    this.specialNotes,
    required this.items,
    this.subtotal = 0.0,
    this.cgst = 0.0,
    this.sgst = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.paymentMethod = '',
    this.paymentStatus = '',
    DateTime? timestamp,
    this.kotKind = 'NEW',
    this.kotRound,
    this.stationName,
    this.isReprint = false,
    this.reason,
    this.bill,
    this.report,
  }) : billNo = billNo ?? orderId,
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'billNo': billNo,
    'type': type,
    'printerRole': printerRole.name,
    'restaurantName': restaurantName,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'tableNumber': tableNumber,
    'waiterName': waiterName,
    'orderType': orderType,
    'specialNotes': specialNotes,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'cgst': cgst,
    'sgst': sgst,
    'tax': tax,
    'discount': discount,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'timestamp': timestamp.toIso8601String(),
    'kotKind': kotKind,
    'kotRound': kotRound,
    'stationName': stationName,
    'isReprint': isReprint,
    'reason': reason,
    if (bill != null) 'bill': bill,
    if (report != null) 'report': report,
  };

  /// Same order marked as a reprint.
  PosOrder asReprint() => PosOrder.fromJson({...toJson(), 'isReprint': true});

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => PosOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final id = json['orderId'] as String? ?? '1001';

    return PosOrder(
      orderId: id,
      billNo: json['billNo'] as String? ?? id,
      type: json['type'] as String? ?? 'BILL',
      printerRole: PrinterRole.values.firstWhere(
        (r) =>
            r.name.toLowerCase() ==
            (json['printer'] ?? json['printerRole'] ?? 'bill')
                .toString()
                .toLowerCase(),
        orElse: () => PrinterRole.bill,
      ),
      restaurantName: json['restaurantName'] as String? ?? '',
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerAddress: json['customerAddress'] as String?,
      tableNumber: json['tableNumber'] as String?,
      waiterName: json['waiterName'] as String?,
      orderType: json['orderType'] as String? ?? 'DINE-IN',
      specialNotes: json['specialNotes'] as String?,
      items: itemsList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      cgst: (json['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (json['sgst'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      kotKind: json['kotKind'] as String? ?? 'NEW',
      kotRound: (json['kotRound'] as num?)?.toInt(),
      stationName: json['stationName'] as String?,
      isReprint: json['isReprint'] as bool? ?? false,
      reason: json['reason'] as String?,
      bill: (json['bill'] as Map?)?.cast<String, dynamic>(),
      report: (json['report'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
