import '../../core/util/money.dart';

enum FoodType { veg, nonVeg, egg, other }

extension FoodTypeX on FoodType {
  String get label => switch (this) {
    FoodType.veg => 'Veg',
    FoodType.nonVeg => 'Non-veg',
    FoodType.egg => 'Egg',
    FoodType.other => 'Other',
  };

  static FoodType parse(String? s) =>
      FoodType.values.where((e) => e.name == s).firstOrNull ?? FoodType.veg;
}

/// How a tax rate is shown on the bill. The rate itself is always the
/// total rate; CGST/SGST splits it into two equal halves.
enum TaxSplitMode { none, cgstSgst, igst }

extension TaxSplitModeX on TaxSplitMode {
  String get label => switch (this) {
    TaxSplitMode.none => 'Single line',
    TaxSplitMode.cgstSgst => 'CGST + SGST (half each)',
    TaxSplitMode.igst => 'IGST',
  };

  static TaxSplitMode parse(String? s) =>
      TaxSplitMode.values.where((e) => e.name == s).firstOrNull ??
      TaxSplitMode.none;
}

/// Variant = changes what the item is (Size: Half/Full). Add-on = extras
/// (Extra cheese). Both use the same min/max selection rules.
enum OptionGroupKind { variant, addon }

extension OptionGroupKindX on OptionGroupKind {
  String get label => this == OptionGroupKind.variant ? 'Variant' : 'Add-on';

  static OptionGroupKind parse(String? s) =>
      OptionGroupKind.values.where((e) => e.name == s).firstOrNull ??
      OptionGroupKind.addon;
}

class TaxProfile {
  final String id;
  final String name;

  /// Basis points: 5% = 500.
  final int rateBp;
  final bool isInclusive;
  final TaxSplitMode splitMode;
  final bool isActive;

  const TaxProfile({
    required this.id,
    required this.name,
    required this.rateBp,
    this.isInclusive = false,
    this.splitMode = TaxSplitMode.none,
    this.isActive = true,
  });

  String get rateLabel => formatBp(rateBp);

  String get summary =>
      '$rateLabel ${isInclusive ? 'incl.' : 'excl.'} · ${splitMode.label}';
}

/// `500` -> `5%`, `250` -> `2.5%`, `1825` -> `18.25%`.
String formatBp(int bp) {
  final whole = bp ~/ 100;
  final frac = bp % 100;
  if (frac == 0) return '$whole%';
  final f = frac.toString().padLeft(2, '0').replaceAll(RegExp(r'0+$'), '');
  return '$whole.$f%';
}

/// Parses a percentage such as `5`, `2.5`, `18.25` into basis points.
/// Returns null unless 0 <= value <= 100 with at most two decimals.
int? parsePercentToBp(String input) {
  final s = input.trim().replaceAll('%', '').trim();
  final m = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$').firstMatch(s);
  if (m == null) return null;
  final bp =
      int.parse(m.group(1)!) * 100 +
      int.parse((m.group(2) ?? '').padRight(2, '0'));
  return bp <= 10000 ? bp : null;
}

class KitchenStation {
  final String id;
  final String name;
  final bool isActive;

  const KitchenStation({
    required this.id,
    required this.name,
    this.isActive = true,
  });
}

class MenuCategory {
  final String id;
  final String name;
  final String? parentId;
  final bool isActive;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
  });

  bool get isSubcategory => parentId != null;
}

class OptionChoice {
  final String id;
  final String groupId;
  final String name;
  final Money priceDelta;
  final bool isActive;

  const OptionChoice({
    required this.id,
    required this.groupId,
    required this.name,
    this.priceDelta = Money.zero,
    this.isActive = true,
  });
}

class OptionGroup {
  final String id;
  final String name;
  final OptionGroupKind kind;
  final int minSelect;
  final int maxSelect;
  final bool isActive;

  /// All choices, in display order (including inactive ones).
  final List<OptionChoice> choices;

  const OptionGroup({
    required this.id,
    required this.name,
    required this.kind,
    this.minSelect = 0,
    this.maxSelect = 1,
    this.isActive = true,
    this.choices = const [],
  });

  bool get isRequired => minSelect > 0;
  bool get isSingleSelect => maxSelect == 1;
  List<OptionChoice> get activeChoices =>
      choices.where((c) => c.isActive).toList();

  /// Human description of the rule, e.g. "Pick 1", "Up to 3", "2 to 4".
  String get ruleLabel {
    if (minSelect == maxSelect) return 'Pick $minSelect';
    if (minSelect == 0) {
      return maxSelect == 1 ? 'Optional, pick 1' : 'Optional, up to $maxSelect';
    }
    return 'Pick $minSelect to $maxSelect';
  }

  /// Problems that would stop anyone ordering an item with this group.
  List<String> get configurationProblems {
    final problems = <String>[];
    if (activeChoices.length < minSelect) {
      problems.add(
        'Needs at least $minSelect active choice(s); has '
        '${activeChoices.length}.',
      );
    }
    return problems;
  }
}

class MenuItem {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String? sku;
  final Money basePrice;
  final String? taxProfileId;
  final FoodType foodType;
  final bool isActive;
  final bool availableDineIn;
  final bool availableTakeaway;
  final String? stationId;
  final bool isFavorite;
  final int? prepMinutes;
  final int sortOrder;

  /// Ids of attached option groups, in display order.
  final List<String> optionGroupIds;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.sku,
    required this.basePrice,
    this.taxProfileId,
    this.foodType = FoodType.veg,
    this.isActive = true,
    this.availableDineIn = true,
    this.availableTakeaway = true,
    this.stationId,
    this.isFavorite = false,
    this.prepMinutes,
    this.sortOrder = 0,
    this.optionGroupIds = const [],
  });

  MenuItem copyWith({
    String? categoryId,
    String? name,
    String? description,
    String? sku,
    bool clearSku = false,
    Money? basePrice,
    String? taxProfileId,
    bool clearTax = false,
    FoodType? foodType,
    bool? isActive,
    bool? availableDineIn,
    bool? availableTakeaway,
    String? stationId,
    bool clearStation = false,
    bool? isFavorite,
    int? prepMinutes,
    bool clearPrep = false,
    int? sortOrder,
    List<String>? optionGroupIds,
  }) {
    return MenuItem(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: clearSku ? null : (sku ?? this.sku),
      basePrice: basePrice ?? this.basePrice,
      taxProfileId: clearTax ? null : (taxProfileId ?? this.taxProfileId),
      foodType: foodType ?? this.foodType,
      isActive: isActive ?? this.isActive,
      availableDineIn: availableDineIn ?? this.availableDineIn,
      availableTakeaway: availableTakeaway ?? this.availableTakeaway,
      stationId: clearStation ? null : (stationId ?? this.stationId),
      isFavorite: isFavorite ?? this.isFavorite,
      prepMinutes: clearPrep ? null : (prepMinutes ?? this.prepMinutes),
      sortOrder: sortOrder ?? this.sortOrder,
      optionGroupIds: optionGroupIds ?? this.optionGroupIds,
    );
  }
}
