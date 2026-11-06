import '../../core/util/money.dart';
import 'menu_models.dart';

/// A problem with the choices made for one option group.
class SelectionError {
  final String groupId;
  final String message;

  const SelectionError(this.groupId, this.message);

  @override
  String toString() => message;
}

/// A chosen option, copied so later menu edits cannot change it.
class ChosenOption {
  final String groupId;
  final String groupName;
  final OptionGroupKind kind;
  final String choiceId;
  final String name;
  final Money priceDelta;

  const ChosenOption({
    required this.groupId,
    required this.groupName,
    required this.kind,
    required this.choiceId,
    required this.name,
    required this.priceDelta,
  });
}

/// An item exactly as ordered: what an order line stores. Built only from a
/// valid selection (see [configureItem]).
class ConfiguredItem {
  final String itemId;
  final String itemName;
  final Money basePrice;
  final List<ChosenOption> options;
  final String? taxProfileId;
  final int taxRateBp;
  final bool taxInclusive;
  final TaxSplitMode taxSplitMode;
  final String? stationId;

  const ConfiguredItem({
    required this.itemId,
    required this.itemName,
    required this.basePrice,
    required this.options,
    required this.taxProfileId,
    required this.taxRateBp,
    required this.taxInclusive,
    required this.taxSplitMode,
    required this.stationId,
  });

  /// Base price plus every chosen option's price.
  Money get unitPrice =>
      options.fold(basePrice, (sum, o) => sum + o.priceDelta);

  /// e.g. "Full" for variants, so a KOT can print "Paneer Tikka (Full)".
  String get variantText => options
      .where((o) => o.kind == OptionGroupKind.variant)
      .map((o) => o.name)
      .join(', ');

  List<ChosenOption> get addons =>
      options.where((o) => o.kind == OptionGroupKind.addon).toList();
}

/// The groups of [item] that are offered to staff when ordering: attached,
/// active, in the item's order.
List<OptionGroup> offeredGroups(MenuItem item, Map<String, OptionGroup> all) {
  return [
    for (final id in item.optionGroupIds)
      if (all[id] case final g? when g.isActive) g,
  ];
}

/// Checks [selected] (group id -> chosen choice ids) against each group's
/// min/max rules. Returns an empty list when the selection is valid.
List<SelectionError> validateSelection(
  List<OptionGroup> groups,
  Map<String, Set<String>> selected,
) {
  final errors = <SelectionError>[];
  final known = {for (final g in groups) g.id};

  for (final groupId in selected.keys) {
    if (!known.contains(groupId) && selected[groupId]!.isNotEmpty) {
      errors.add(SelectionError(groupId, 'Option group is not offered.'));
    }
  }

  for (final g in groups) {
    final picks = selected[g.id] ?? const <String>{};
    final active = {for (final c in g.activeChoices) c.id};
    final unknown = picks.where((id) => !active.contains(id));
    if (unknown.isNotEmpty) {
      errors.add(SelectionError(g.id, '${g.name}: a choice is unavailable.'));
      continue;
    }
    if (picks.length < g.minSelect) {
      errors.add(
        SelectionError(
          g.id,
          g.minSelect == 1
              ? '${g.name}: choose one.'
              : '${g.name}: choose at least ${g.minSelect}.',
        ),
      );
    } else if (picks.length > g.maxSelect) {
      errors.add(
        SelectionError(
          g.id,
          g.maxSelect == 1
              ? '${g.name}: choose only one.'
              : '${g.name}: choose at most ${g.maxSelect}.',
        ),
      );
    }
  }
  return errors;
}

class InvalidSelectionException implements Exception {
  final List<SelectionError> errors;
  InvalidSelectionException(this.errors);

  @override
  String toString() => errors.join(' ');
}

/// Validates [selected] and returns the order-line snapshot. Throws
/// [InvalidSelectionException] if any group rule is broken.
ConfiguredItem configureItem({
  required MenuItem item,
  required Map<String, OptionGroup> groups,
  required Map<String, Set<String>> selected,
  TaxProfile? tax,
}) {
  final offered = offeredGroups(item, groups);
  final errors = validateSelection(offered, selected);
  if (errors.isNotEmpty) throw InvalidSelectionException(errors);

  final options = <ChosenOption>[];
  for (final g in offered) {
    final picks = selected[g.id] ?? const <String>{};
    // Keep the group's display order, not the tap order.
    for (final c in g.activeChoices.where((c) => picks.contains(c.id))) {
      options.add(
        ChosenOption(
          groupId: g.id,
          groupName: g.name,
          kind: g.kind,
          choiceId: c.id,
          name: c.name,
          priceDelta: c.priceDelta,
        ),
      );
    }
  }

  return ConfiguredItem(
    itemId: item.id,
    itemName: item.name,
    basePrice: item.basePrice,
    options: options,
    taxProfileId: tax?.id,
    taxRateBp: tax?.rateBp ?? 0,
    taxInclusive: tax?.isInclusive ?? false,
    taxSplitMode: tax?.splitMode ?? TaxSplitMode.none,
    stationId: item.stationId,
  );
}
