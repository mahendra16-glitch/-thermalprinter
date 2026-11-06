import '../../core/util/money.dart';
import '../menu/menu_models.dart';
import '../orders/order_models.dart';

/// How the grand total is rounded. The difference is printed as
/// "Round off" so the bill always adds up.
enum RoundingMode { none, nearestRupee, nearestHalfRupee, downRupee, upRupee }

extension RoundingModeX on RoundingMode {
  String get label => switch (this) {
    RoundingMode.none => 'No rounding (exact paise)',
    RoundingMode.nearestRupee => 'Nearest ₹1 (50 paise rounds up)',
    RoundingMode.nearestHalfRupee => 'Nearest 50 paise',
    RoundingMode.downRupee => 'Always down to ₹1',
    RoundingMode.upRupee => 'Always up to ₹1',
  };

  static RoundingMode parse(String? s) =>
      RoundingMode.values.where((e) => e.name == s).firstOrNull ??
      RoundingMode.none;

  /// Rounds a non-negative amount.
  Money apply(Money raw) {
    final p = raw.paise;
    final out = switch (this) {
      RoundingMode.none => p,
      RoundingMode.nearestRupee => ((p + 50) ~/ 100) * 100,
      RoundingMode.nearestHalfRupee => ((p + 25) ~/ 50) * 50,
      RoundingMode.downRupee => (p ~/ 100) * 100,
      RoundingMode.upRupee => ((p + 99) ~/ 100) * 100,
    };
    return Money(out);
  }
}

/// Bill settings chosen by the business. The app only applies what is
/// configured here; it does not decide which taxes or charges apply.
class BillingSettings {
  /// Service charge in basis points of the item value after discount and
  /// before tax. 0 = no service charge.
  final int serviceChargeBp;

  /// Order types the service charge applies to.
  final Set<OrderType> serviceChargeOrderTypes;

  /// Tax on the service charge, in basis points (0 = not taxed).
  final int serviceChargeTaxBp;
  final TaxSplitMode serviceChargeTaxSplit;

  final RoundingMode rounding;

  /// Printed before the bill sequence number, e.g. `FY26/` -> `FY26/1`.
  /// Each prefix has its own sequence starting at 1.
  final String billNumberPrefix;

  const BillingSettings({
    this.serviceChargeBp = 0,
    this.serviceChargeOrderTypes = const {OrderType.dineIn},
    this.serviceChargeTaxBp = 0,
    this.serviceChargeTaxSplit = TaxSplitMode.cgstSgst,
    this.rounding = RoundingMode.none,
    this.billNumberPrefix = '',
  });

  static const defaults = BillingSettings();

  bool serviceChargeAppliesTo(OrderType t) =>
      serviceChargeBp > 0 && serviceChargeOrderTypes.contains(t);

  BillingSettings copyWith({
    int? serviceChargeBp,
    Set<OrderType>? serviceChargeOrderTypes,
    int? serviceChargeTaxBp,
    TaxSplitMode? serviceChargeTaxSplit,
    RoundingMode? rounding,
    String? billNumberPrefix,
  }) => BillingSettings(
    serviceChargeBp: serviceChargeBp ?? this.serviceChargeBp,
    serviceChargeOrderTypes:
        serviceChargeOrderTypes ?? this.serviceChargeOrderTypes,
    serviceChargeTaxBp: serviceChargeTaxBp ?? this.serviceChargeTaxBp,
    serviceChargeTaxSplit: serviceChargeTaxSplit ?? this.serviceChargeTaxSplit,
    rounding: rounding ?? this.rounding,
    billNumberPrefix: billNumberPrefix ?? this.billNumberPrefix,
  );

  Map<String, Object?> toJson() => {
    'serviceChargeBp': serviceChargeBp,
    'serviceChargeOrderTypes': [
      for (final t in OrderType.values)
        if (serviceChargeOrderTypes.contains(t)) t.name,
    ],
    'serviceChargeTaxBp': serviceChargeTaxBp,
    'serviceChargeTaxSplit': serviceChargeTaxSplit.name,
    'rounding': rounding.name,
    'billNumberPrefix': billNumberPrefix,
  };

  factory BillingSettings.fromJson(Map<String, dynamic> j) => BillingSettings(
    serviceChargeBp: (j['serviceChargeBp'] as num?)?.toInt() ?? 0,
    serviceChargeOrderTypes: {
      for (final s in (j['serviceChargeOrderTypes'] as List? ?? const []))
        OrderTypeX.parse(s as String?),
    },
    serviceChargeTaxBp: (j['serviceChargeTaxBp'] as num?)?.toInt() ?? 0,
    serviceChargeTaxSplit: TaxSplitModeX.parse(
      j['serviceChargeTaxSplit'] as String?,
    ),
    rounding: RoundingModeX.parse(j['rounding'] as String?),
    billNumberPrefix: j['billNumberPrefix'] as String? ?? '',
  );
}
