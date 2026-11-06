import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/ids.dart';
import '../../core/util/money.dart';
import '../../data/repositories/menu_repository.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

class ItemEditScreen extends StatefulWidget {
  /// Null to create a new item.
  final String? itemId;

  /// Pre-selected category for a new item.
  final String? initialCategoryId;

  const ItemEditScreen({super.key, this.itemId, this.initialCategoryId});

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _sku = TextEditingController();
  final _description = TextEditingController();
  final _prep = TextEditingController();

  MenuSnapshot? _snap;
  MenuItem? _original;
  String? _categoryId;
  String? _taxId;
  String? _stationId;
  FoodType _foodType = FoodType.veg;
  bool _dineIn = true;
  bool _takeaway = true;
  bool _favorite = false;
  bool _active = true;
  List<String> _groupIds = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _sku, _description, _prep]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final snap = await storage.menu.loadSnapshot();
    final item = widget.itemId == null
        ? null
        : snap.items.where((i) => i.id == widget.itemId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _snap = snap;
      _original = item;
      if (item != null) {
        _name.text = item.name;
        _price.text = item.basePrice.format(symbol: false).replaceAll(',', '');
        _sku.text = item.sku ?? '';
        _description.text = item.description;
        _prep.text = item.prepMinutes?.toString() ?? '';
        _categoryId = item.categoryId;
        _taxId = item.taxProfileId;
        _stationId = item.stationId;
        _foodType = item.foodType;
        _dineIn = item.availableDineIn;
        _takeaway = item.availableTakeaway;
        _favorite = item.isFavorite;
        _active = item.isActive;
        _groupIds = [...item.optionGroupIds];
      } else {
        _categoryId = widget.initialCategoryId;
        // A single active tax is the obvious default.
        final activeTaxes = snap.taxProfiles.where((t) => t.isActive).toList();
        if (activeTaxes.length == 1) _taxId = activeTaxes.single.id;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = Money.parse(_price.text)!;
    final prep = _prep.text.trim().isEmpty ? null : int.parse(_prep.text);
    final item = MenuItem(
      id: _original?.id ?? newId(),
      categoryId: _categoryId!,
      name: _name.text,
      description: _description.text,
      sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      basePrice: price,
      taxProfileId: _taxId,
      foodType: _foodType,
      isActive: _active,
      availableDineIn: _dineIn,
      availableTakeaway: _takeaway,
      stationId: _stationId,
      isFavorite: _favorite,
      prepMinutes: prep,
      sortOrder: _original?.sortOrder ?? 0,
      optionGroupIds: _groupIds,
    );
    setState(() => _saving = true);
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    final ok = await runMenuAction(
      context,
      () => storage.menu.saveItem(item),
      success: 'Saved "${item.name.trim()}"',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _addGroup() async {
    final snap = _snap!;
    final available = snap.optionGroups
        .where((g) => g.isActive && !_groupIds.contains(g.id))
        .toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No more groups to add. Create them under Menu › Variants & '
            'add-ons.',
          ),
        ),
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Attach option group',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final g in available)
              ListTile(
                title: Text(g.name),
                subtitle: Text(
                  '${g.kind.label} · ${g.ruleLabel} · '
                  '${g.activeChoices.map((c) => c.name).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(ctx, g.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _groupIds.add(picked));
  }

  List<DropdownMenuItem<String>> _categoryItems(MenuSnapshot snap) {
    final items = <DropdownMenuItem<String>>[];
    for (final top in snap.topLevelCategories) {
      final subs = snap.subcategoriesOf(top.id);
      for (final c in [top, ...subs]) {
        if (!c.isActive && c.id != _categoryId) continue;
        items.add(
          DropdownMenuItem(
            value: c.id,
            child: Text(
              snap.categoryPath(c.id) + (c.isActive ? '' : ' (hidden)'),
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    if (snap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (snap.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New item')),
        body: const MessageState(
          icon: Icons.folder_open_rounded,
          title: 'Create a category first',
          message: 'Every item belongs to a category. Use Menu › Categories.',
        ),
      );
    }

    final taxes = snap.taxProfiles
        .where((t) => t.isActive || t.id == _taxId)
        .toList();
    final stations = snap.stations
        .where((s) => s.isActive || s.id == _stationId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(_original == null ? 'New item' : 'Edit item')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save item'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: _original == null,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Base price (₹) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final m = Money.parse(v ?? '');
                      if (m == null) return 'Enter a price like 180 or 99.50';
                      if (m.isNegative) return 'Cannot be negative';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sku,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Short code / SKU',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categoryItems(snap),
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _taxId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Tax',
                border: const OutlineInputBorder(),
                helperText: taxes.isEmpty
                    ? 'No taxes set up yet (Menu › Taxes).'
                    : null,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No tax'),
                ),
                ...taxes.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text('${t.name} (${t.summary})'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _taxId = v),
            ),
            const SizedBox(height: 16),
            const Text(
              'Food type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: FoodType.values
                  .map(
                    (t) => ChoiceChip(
                      avatar: FoodTypeMark(t),
                      label: Text(t.label),
                      selected: _foodType == t,
                      onSelected: (_) => setState(() => _foodType = t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for dine-in'),
              value: _dineIn,
              onChanged: (v) => setState(() => _dineIn = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for takeaway'),
              value: _takeaway,
              onChanged: (v) => setState(() => _takeaway = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favourite (quick items)'),
              value: _favorite,
              onChanged: (v) => setState(() => _favorite = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text(
                'Turn off to hide the item. Items are never deleted, so past '
                'orders stay intact.',
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const Divider(height: 24),
            DropdownButtonFormField<String?>(
              initialValue: _stationId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Kitchen station',
                border: const OutlineInputBorder(),
                helperText: stations.isEmpty
                    ? 'No stations yet (Menu › Kitchen stations).'
                    : 'Where the KOT for this item goes.',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Default'),
                ),
                ...stations.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name + (s.isActive ? '' : ' (off)')),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _stationId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _prep,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Preparation time (minutes, optional)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return null;
                final n = int.tryParse(v!);
                return (n == null || n > 600) ? '0 to 600 minutes' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Short description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Variants & add-ons',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Attach'),
                ),
              ],
            ),
            if (_groupIds.isEmpty)
              const Text(
                'None. Attach groups such as Size or Extras.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (o, n) => setState(() {
                _groupIds.insert(n, _groupIds.removeAt(o));
              }),
              children: [
                for (final id in _groupIds)
                  Card(
                    key: ValueKey(id),
                    child: Builder(
                      builder: (context) {
                        final g = snap.groupById[id];
                        return ListTile(
                          title: Text(g?.name ?? 'Missing group'),
                          subtitle: Text(
                            g == null
                                ? ''
                                : '${g.kind.label} · ${g.ruleLabel}'
                                      '${g.isActive ? '' : ' · OFF (not offered)'}',
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: IconButton(
                              tooltip: 'Detach',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () =>
                                  setState(() => _groupIds.remove(id)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
