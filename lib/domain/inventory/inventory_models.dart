/// Unit a stock item is counted in. Quantities are stored as integer
/// thousandths of the unit ("milli"), so 1.250 kg is 1250.
enum StockUnit { kg, g, l, ml, pcs }

extension StockUnitX on StockUnit {
  String get label => switch (this) {
    StockUnit.kg => 'kg',
    StockUnit.g => 'g',
    StockUnit.l => 'litre',
    StockUnit.ml => 'ml',
    StockUnit.pcs => 'pcs',
  };

  String get short => switch (this) {
    StockUnit.l => 'L',
    _ => label,
  };

  static StockUnit parse(String s) => StockUnit.values.firstWhere(
    (u) => u.name == s,
    orElse: () => StockUnit.pcs,
  );
}

/// Formats and reads quantities in thousandths.
class Qty {
  Qty._();

  /// `1250` -> `1.25`, `2000` -> `2`, `-500` -> `-0.5`.
  static String format(int milli) {
    final sign = milli < 0 ? '-' : '';
    final a = milli.abs();
    final whole = a ~/ 1000;
    final frac = a % 1000;
    if (frac == 0) return '$sign$whole';
    var f = frac.toString().padLeft(3, '0');
    while (f.endsWith('0')) {
      f = f.substring(0, f.length - 1);
    }
    return '$sign$whole.$f';
  }

  static String withUnit(int milli, StockUnit unit) =>
      '${format(milli)} ${unit.short}';

  /// Reads `1.25`, `0.5`, `3` (up to 3 decimals). Null if not a number.
  static int? parse(String text) {
    final t = text.trim().replaceAll(',', '');
    final m = RegExp(r'^(-)?(\d*)(?:\.(\d{0,3}))?$').firstMatch(t);
    if (m == null || t.isEmpty || t == '-' || t == '.') return null;
    final whole = int.tryParse(m.group(2)!.isEmpty ? '0' : m.group(2)!);
    if (whole == null) return null;
    final frac = int.parse((m.group(3) ?? '').padRight(3, '0'));
    final v = whole * 1000 + frac;
    return m.group(1) == null ? v : -v;
  }
}

enum StockMovementKind { opening, purchase, wastage, count, sale, saleReturn }

extension StockMovementKindX on StockMovementKind {
  String get label => switch (this) {
    StockMovementKind.opening => 'Opening stock',
    StockMovementKind.purchase => 'Purchase / stock in',
    StockMovementKind.wastage => 'Wastage',
    StockMovementKind.count => 'Stock count correction',
    StockMovementKind.sale => 'Used by sales',
    StockMovementKind.saleReturn => 'Returned (bill voided)',
  };

  static StockMovementKind parse(String s) => StockMovementKind.values
      .firstWhere((k) => k.name == s, orElse: () => StockMovementKind.count);
}

/// When sales take stock away. Changed under Inventory > Settings.
enum DeductOn { off, kot, bill }

extension DeductOnX on DeductOn {
  String get label => switch (this) {
    DeductOn.off => 'Off (record stock in and counts only)',
    DeductOn.kot => 'When items are sent to the kitchen (KOT)',
    DeductOn.bill => 'When the bill is made',
  };

  static DeductOn parse(String? s) => DeductOn.values.firstWhere(
    (d) => d.name == s,
    orElse: () => DeductOn.off,
  );
}

class StockItem {
  final String id;
  final String name;
  final StockUnit unit;
  final int? lowStockMilli;
  final String note;
  final bool active;

  /// Sum of all movements.
  final int onHandMilli;

  /// Cost per unit from the latest purchase that had a cost (paise per
  /// whole unit), for information only. Null if no purchase had a cost.
  final int? lastCostPerUnitPaise;

  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.lowStockMilli,
    required this.note,
    required this.active,
    required this.onHandMilli,
    required this.lastCostPerUnitPaise,
  });

  bool get isLow => lowStockMilli != null && onHandMilli <= lowStockMilli!;
  bool get isNegative => onHandMilli < 0;
}

class StockMovement {
  final String id;
  final String stockItemId;
  final StockMovementKind kind;
  final int qtyMilli;
  final int? costPaise;
  final String reason;
  final String? orderId;
  final int? units;
  final String staffName;
  final String businessDate;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.stockItemId,
    required this.kind,
    required this.qtyMilli,
    required this.costPaise,
    required this.reason,
    required this.orderId,
    required this.units,
    required this.staffName,
    required this.businessDate,
    required this.createdAt,
  });
}

class RecipeLine {
  final String id;
  final String? menuItemId;
  final String? optionChoiceId;
  final String stockItemId;
  final int qtyMilli;

  const RecipeLine({
    required this.id,
    required this.menuItemId,
    required this.optionChoiceId,
    required this.stockItemId,
    required this.qtyMilli,
  });
}
