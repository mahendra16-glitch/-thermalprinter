import 'package:flutter/material.dart';

import '../../domain/menu/item_configuration.dart';
import '../../domain/menu/menu_models.dart';

/// What staff chose for one item.
class ItemChoice {
  final Map<String, Set<String>> selected;
  final int qty;
  final String notes;

  const ItemChoice(this.selected, this.qty, this.notes);
}

/// Common kitchen instructions offered as one-tap chips.
const List<String> quickNotes = [
  'Less spicy',
  'Extra spicy',
  'No onion',
  'No garlic',
  'Jain',
  'Less oil',
  'Extra cheese',
  'Parcel',
];

/// Picks variants/add-ons, quantity and notes for [item]. Returns null if
/// cancelled. The Add button is enabled only for a valid selection.
Future<ItemChoice?> showItemOptionsSheet(
  BuildContext context, {
  required MenuItem item,
  required List<OptionGroup> groups,
}) {
  return showModalBottomSheet<ItemChoice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemOptionsSheet(item: item, groups: groups),
  );
}

class _ItemOptionsSheet extends StatefulWidget {
  final MenuItem item;
  final List<OptionGroup> groups;

  const _ItemOptionsSheet({required this.item, required this.groups});

  @override
  State<_ItemOptionsSheet> createState() => _ItemOptionsSheetState();
}

class _ItemOptionsSheetState extends State<_ItemOptionsSheet> {
  final Map<String, Set<String>> _selected = {};
  final _notes = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    // Pre-select the only choice of a required single-choice group.
    for (final g in widget.groups) {
      final active = g.activeChoices;
      if (g.minSelect == 1 && g.maxSelect == 1 && active.length == 1) {
        _selected[g.id] = {active.single.id};
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _toggle(OptionGroup g, OptionChoice c) {
    setState(() {
      final set = _selected.putIfAbsent(g.id, () => <String>{});
      if (g.isSingleSelect) {
        if (set.contains(c.id) && !g.isRequired) {
          set.clear();
        } else {
          set
            ..clear()
            ..add(c.id);
        }
      } else if (set.contains(c.id)) {
        set.remove(c.id);
      } else if (set.length < g.maxSelect) {
        set.add(c.id);
      }
    });
  }

  void _addNote(String n) {
    final parts = _notes.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.contains(n)) {
      parts.remove(n);
    } else {
      parts.add(n);
    }
    setState(() => _notes.text = parts.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final errors = validateSelection(widget.groups, _selected);
    var unit = widget.item.basePrice;
    for (final g in widget.groups) {
      for (final c in g.activeChoices) {
        if (_selected[g.id]?.contains(c.id) ?? false) unit += c.priceDelta;
      }
    }
    final errorsByGroup = {for (final e in errors) e.groupId: e.message};
    final noteParts = _notes.text.split(',').map((s) => s.trim()).toSet();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Base ${widget.item.basePrice.format()}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                for (final g in widget.groups) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        g.ruleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: errorsByGroup.containsKey(g.id)
                              ? Colors.red
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in g.activeChoices)
                        FilterChip(
                          showCheckmark: !g.isSingleSelect,
                          label: Text(
                            c.priceDelta.isZero
                                ? c.name
                                : '${c.name}  +${c.priceDelta.format()}',
                          ),
                          selected: _selected[g.id]?.contains(c.id) ?? false,
                          onSelected: (_) => _toggle(g, c),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Kitchen instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final n in quickNotes)
                      FilterChip(
                        label: Text(n),
                        selected: noteParts.contains(n),
                        onSelected: (_) => _addNote(n),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Other instructions',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        errors.map((e) => e.message).join(' '),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Row(
                    children: [
                      QtyStepper(
                        qty: _qty,
                        onChanged: (q) => setState(() => _qty = q),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: errors.isEmpty
                                ? () => Navigator.pop(
                                    context,
                                    ItemChoice(
                                      {
                                        for (final e in _selected.entries)
                                          e.key: {...e.value},
                                      },
                                      _qty,
                                      _notes.text,
                                    ),
                                  )
                                : null,
                            child: Text('Add  ${(unit * _qty).format()}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// − qty + control with large touch targets.
class QtyStepper extends StatelessWidget {
  final int qty;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;
  final bool compact;

  const QtyStepper({
    super.key,
    required this.qty,
    this.min = 1,
    this.max = 999,
    this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 48.0;
    Widget button(IconData icon, int? next) => SizedBox(
      width: size,
      height: size,
      child: IconButton.filledTonal(
        padding: EdgeInsets.zero,
        iconSize: compact ? 18 : 22,
        icon: Icon(icon),
        onPressed: onChanged == null || next == null
            ? null
            : () => onChanged!(next),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove_rounded, qty > min ? qty - 1 : null),
        SizedBox(
          width: compact ? 32 : 44,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        button(Icons.add_rounded, qty < max ? qty + 1 : null),
      ],
    );
  }
}
