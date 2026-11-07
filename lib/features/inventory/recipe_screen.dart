import 'package:flutter/material.dart';

import '../../data/repositories/menu_repository.dart';
import '../../domain/inventory/inventory_models.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/staff/staff_models.dart';
import '../../services/storage_service.dart';
import '../staff/permission_guard.dart';

/// What one unit of a menu item uses from stock, plus extra stock for each
/// variant or add-on that can be chosen with it.
class RecipeScreen extends StatefulWidget {
  final String menuItemId;

  const RecipeScreen({super.key, required this.menuItemId});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final s = StorageService.maybeInstance!;
  late final Stream<List<StockItem>> _stock = s.inventory.watchItems();
  MenuSnapshot? _menu;

  @override
  void initState() {
    super.initState();
    s.menu.loadSnapshot().then((m) {
      if (mounted) setState(() => _menu = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = _menu;
    final item = menu?.items
        .where((i) => i.id == widget.menuItemId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(item == null ? 'Recipe' : 'Recipe: ${item.name}'),
      ),
      body: menu == null || item == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<StockItem>>(
              stream: _stock,
              builder: (context, snap) {
                final stock = snap.data;
                if (stock == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final groups = [
                  for (final id in item.optionGroupIds)
                    if (menu.groupById[id] != null) menu.groupById[id]!,
                ];
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text(
                      'Enter what ONE portion uses, in each stock item\'s '
                      'unit (e.g. 0.150 kg). Sales take this from stock at '
                      'the moment set under Stock. Changing a recipe does not '
                      'change stock already taken.',
                    ),
                    if (stock.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Add stock items first (Menu > ⋮ > Stock).',
                          style: TextStyle(color: Colors.deepOrange),
                        ),
                      ),
                    _RecipeSection(
                      title: item.name,
                      subtitle: 'Every portion',
                      menuItemId: item.id,
                      stock: stock,
                    ),
                    for (final g in groups)
                      for (final c in g.choices)
                        _RecipeSection(
                          title: '${g.name}: ${c.name}',
                          subtitle: 'Extra when this is chosen',
                          choiceId: c.id,
                          stock: stock,
                          dense: true,
                        ),
                  ],
                );
              },
            ),
    );
  }
}

class _RecipeSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? menuItemId;
  final String? choiceId;
  final List<StockItem> stock;
  final bool dense;

  const _RecipeSection({
    required this.title,
    required this.subtitle,
    this.menuItemId,
    this.choiceId,
    required this.stock,
    this.dense = false,
  });

  @override
  State<_RecipeSection> createState() => _RecipeSectionState();
}

class _RecipeSectionState extends State<_RecipeSection> {
  final s = StorageService.maybeInstance!;
  late final Stream<List<RecipeLine>> _lines = s.inventory.watchRecipe(
    menuItemId: widget.menuItemId,
    choiceId: widget.choiceId,
  );

  Future<void> _edit({StockItem? item, int? current}) async {
    if (!await allow(context, Permission.manageInventory) || !mounted) return;
    var picked = item;
    final qty = TextEditingController(
      text: current == null ? '' : Qty.format(current),
    );
    final choices = widget.stock
        .where((i) => i.active || i.id == item?.id)
        .toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(widget.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: picked?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Stock item'),
                items: [
                  for (final i in choices)
                    DropdownMenuItem(value: i.id, child: Text(i.name)),
                ],
                onChanged: item != null
                    ? null
                    : (v) => setState(
                        () => picked = choices
                            .where((i) => i.id == v)
                            .firstOrNull,
                      ),
              ),
              TextField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Used per portion (0 removes it)',
                  suffixText: picked?.unit.short,
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final q = Qty.parse(qty.text);
    if (picked == null || q == null || q < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a stock item and enter a number.')),
      );
      return;
    }
    try {
      await s.inventory.setRecipeLine(
        menuItemId: widget.menuItemId,
        choiceId: widget.choiceId,
        stockItemId: picked!.id,
        qtyMilli: q,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final i in widget.stock) i.id: i};
    return StreamBuilder<List<RecipeLine>>(
      stream: _lines,
      builder: (context, snap) {
        final lines = snap.data ?? const <RecipeLine>[];
        return Card(
          margin: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                dense: widget.dense,
                title: Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(widget.subtitle),
                trailing: IconButton(
                  tooltip: 'Add stock item',
                  icon: const Icon(Icons.add),
                  onPressed: widget.stock.isEmpty ? null : () => _edit(),
                ),
              ),
              for (final l in lines)
                ListTile(
                  dense: true,
                  title: Text(byId[l.stockItemId]?.name ?? 'Unknown item'),
                  trailing: Text(
                    byId[l.stockItemId] == null
                        ? Qty.format(l.qtyMilli)
                        : Qty.withUnit(l.qtyMilli, byId[l.stockItemId]!.unit),
                  ),
                  onTap: () =>
                      _edit(item: byId[l.stockItemId], current: l.qtyMilli),
                ),
              if (lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('No stock used.', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// For lists: the recipe screen route.
MaterialPageRoute<void> recipeRoute(MenuItem item) =>
    MaterialPageRoute(builder: (_) => RecipeScreen(menuItemId: item.id));
