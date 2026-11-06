import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

/// Lists variant and add-on groups.
class OptionGroupsScreen extends StatefulWidget {
  const OptionGroupsScreen({super.key});

  @override
  State<OptionGroupsScreen> createState() => _OptionGroupsScreenState();
}

class _OptionGroupsScreenState extends State<OptionGroupsScreen> {
  List<OptionGroup>? _groups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final list = await storage.menu.listOptionGroups();
    if (mounted) setState(() => _groups = list);
  }

  Future<void> _open([OptionGroup? g]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OptionGroupEditScreen(groupId: g?.id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      appBar: AppBar(title: const Text('Variants & add-ons')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.add),
        label: const Text('Add group'),
      ),
      body: groups == null
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? const MessageState(
              icon: Icons.tune_rounded,
              title: 'No option groups yet',
              message:
                  'Create a group such as "Size" (Half / Full) or "Extras" '
                  '(Cheese, Butter), then attach it to items.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: groups.map((g) {
                final problems = g.configurationProblems;
                return Card(
                  child: ListTile(
                    onTap: () => _open(g),
                    title: Text(
                      g.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: g.isActive ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${g.kind.label} · ${g.ruleLabel} · '
                          '${g.activeChoices.map((c) => c.name).join(', ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        for (final p in problems)
                          Text(
                            p,
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: g.isActive
                        ? const Icon(Icons.chevron_right_rounded)
                        : const SmallBadge('Off'),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

/// Edits one group's rules and its choices.
class OptionGroupEditScreen extends StatefulWidget {
  /// Null to create a new group.
  final String? groupId;

  const OptionGroupEditScreen({super.key, this.groupId});

  @override
  State<OptionGroupEditScreen> createState() => _OptionGroupEditScreenState();
}

class _OptionGroupEditScreenState extends State<OptionGroupEditScreen> {
  late final String _id = widget.groupId ?? newId();
  final _name = TextEditingController();
  final _min = TextEditingController(text: '1');
  final _max = TextEditingController(text: '1');
  OptionGroupKind _kind = OptionGroupKind.variant;
  OptionGroup? _saved;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final groups = await storage.menu.listOptionGroups();
    final g = groups.where((x) => x.id == _id).firstOrNull;
    if (!mounted) return;
    setState(() {
      if (g != null && _saved == null) {
        _name.text = g.name;
        _min.text = '${g.minSelect}';
        _max.text = '${g.maxSelect}';
        _kind = g.kind;
      }
      _saved = g;
      _loading = false;
    });
  }

  Future<void> _saveGroup() async {
    final min = int.tryParse(_min.text.trim());
    final max = int.tryParse(_max.text.trim());
    if (min == null || max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum and maximum must be numbers.')),
      );
      return;
    }
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    final ok = await runMenuAction(
      context,
      () => storage.menu.saveOptionGroup(
        OptionGroup(
          id: _id,
          name: _name.text,
          kind: _kind,
          minSelect: min,
          maxSelect: max,
        ),
      ),
      success: 'Group saved',
    );
    if (ok) _load();
  }

  Future<void> _editChoice([OptionChoice? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
      text: existing == null || existing.priceDelta.isZero
          ? ''
          : existing.priceDelta.format(symbol: false).replaceAll(',', ''),
    );
    String? priceError;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New choice' : 'Edit choice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Full, Extra cheese',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Extra price (₹)',
                  hintText: '0 if free',
                  errorText: priceError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final p = price.text.trim().isEmpty
                    ? Money.zero
                    : Money.parse(price.text);
                if (p == null) {
                  setLocal(
                    () => priceError = 'Enter an amount like 30 or 12.50',
                  );
                  return;
                }
                final storage = await StorageService.getInstance();
                if (!ctx.mounted) return;
                final ok = await runMenuAction(
                  ctx,
                  () => storage.menu.saveOptionChoice(
                    OptionChoice(
                      id: existing?.id ?? newId(),
                      groupId: _id,
                      name: name.text,
                      priceDelta: p,
                    ),
                  ),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _toggleChoice(OptionChoice c) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setOptionChoiceActive(c.id, !c.isActive),
    );
    _load();
  }

  Future<void> _toggleGroup() async {
    final g = _saved;
    if (g == null) return;
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setOptionGroupActive(g.id, !g.isActive),
      success: g.isActive
          ? 'Group turned off. Items no longer offer it.'
          : 'Group turned on.',
    );
    _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final choices = [...?_saved?.choices];
    choices.insert(newIndex, choices.removeAt(oldIndex));
    final storage = await StorageService.getInstance();
    await storage.menu.reorderOptionChoices(choices.map((c) => c.id).toList());
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final g = _saved;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupId == null && g == null ? 'New group' : 'Group',
        ),
        actions: [
          if (g != null)
            TextButton(
              onPressed: _toggleGroup,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(g.isActive ? 'Turn off' : 'Turn on'),
            ),
        ],
      ),
      floatingActionButton: g == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _editChoice,
              icon: const Icon(Icons.add),
              label: const Text('Add choice'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'e.g. Size, Extras, Spice level',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<OptionGroupKind>(
                  segments: const [
                    ButtonSegment(
                      value: OptionGroupKind.variant,
                      label: Text('Variant'),
                      icon: Icon(Icons.straighten_rounded),
                    ),
                    ButtonSegment(
                      value: OptionGroupKind.addon,
                      label: Text('Add-on'),
                      icon: Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() {
                    _kind = s.first;
                    if (_kind == OptionGroupKind.addon && _saved == null) {
                      _min.text = '0';
                    }
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _kind == OptionGroupKind.variant
                      ? 'Variants change the item itself and print with its '
                            'name, e.g. "Paneer Tikka (Full)".'
                      : 'Add-ons are extras printed under the item.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _min,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minimum to pick',
                          helperText: '0 = optional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _max,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum to pick',
                          helperText: '1 = single choice',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saveGroup,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(g == null ? 'Create group' : 'Save rules'),
                ),
                const Divider(height: 32),
                if (g == null)
                  const Text(
                    'Create the group first, then add its choices.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  )
                else ...[
                  Text(
                    'Choices (${g.activeChoices.length} active)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final p in g.configurationProblems)
                    Text(p, style: const TextStyle(color: Color(0xFFB45309))),
                  const SizedBox(height: 8),
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorderItem: _reorder,
                    children: [
                      for (final c in g.choices)
                        Card(
                          key: ValueKey(c.id),
                          child: ListTile(
                            onTap: () => _editChoice(c),
                            title: Text(
                              c.name,
                              style: TextStyle(
                                color: c.isActive ? null : Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              c.priceDelta.isZero
                                  ? 'No extra charge'
                                  : '+ ${c.priceDelta.format()}',
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Switch(
                                value: c.isActive,
                                onChanged: (_) => _toggleChoice(c),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
