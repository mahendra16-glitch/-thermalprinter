import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/menu_repository.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'categories_screen.dart';
import 'item_edit_screen.dart';
import 'menu_csv_screens.dart';
import 'menu_widgets.dart';
import 'option_groups_screen.dart';
import 'stations_screen.dart';
import 'tax_profiles_screen.dart';
import '../staff/permission_guard.dart';
import '../../domain/staff/staff_models.dart';
import '../inventory/inventory_screen.dart';
import '../inventory/recipe_screen.dart';

const String _all = '__all__';
const String _favorites = '__fav__';

/// Menu tab: browse, search, filter and edit items.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  MenuSnapshot? _snap;
  String? _error;
  StreamSubscription<void>? _changes;
  final _search = TextEditingController();
  String _filter = _all;
  String? _subFilter;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await StorageService.getInstance();
    _changes = storage.menu.watchChanges().listen((_) => _load());
    await _load();
  }

  @override
  void dispose() {
    _changes?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final storage = await StorageService.getInstance();
      final snap = await storage.menu.loadSnapshot();
      if (mounted) setState(() => _snap = snap);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Every page opened from here edits the menu.
  Future<void> _open(Widget page) async {
    if (!await _canEdit()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<bool> _canEdit() async =>
      await allow(context, Permission.editMenu) && mounted;

  /// The category whose items can be dragged into a new order, or null.
  String? get _reorderCategory {
    if (_search.text.trim().isNotEmpty) return null;
    if (_filter == _all || _filter == _favorites) return null;
    final snap = _snap;
    if (snap == null) return null;
    if (_subFilter != null) return _subFilter;
    return snap.subcategoriesOf(_filter).isEmpty ? _filter : null;
  }

  List<MenuItem> _visibleItems(MenuSnapshot snap) {
    final q = _search.text.trim().toLowerCase();
    Iterable<MenuItem> items = snap.items;
    if (!_showInactive) items = items.where(snap.isOrderable);
    if (_filter == _favorites) {
      items = items.where((i) => i.isFavorite);
    } else if (_filter != _all) {
      final ids = _subFilter != null
          ? {_subFilter!}
          : {_filter, ...snap.subcategoriesOf(_filter).map((c) => c.id)};
      items = items.where((i) => ids.contains(i.categoryId));
    }
    if (q.isNotEmpty) {
      items = items.where(
        (i) =>
            i.name.toLowerCase().contains(q) ||
            (i.sku?.toLowerCase().contains(q) ?? false),
      );
    }
    // Category display order first, then item order inside it.
    final catOrder = <String, int>{};
    var n = 0;
    for (final top in snap.topLevelCategories) {
      catOrder[top.id] = n++;
      for (final s in snap.subcategoriesOf(top.id)) {
        catOrder[s.id] = n++;
      }
    }
    final list = items.toList()
      ..sort((a, b) {
        final c = (catOrder[a.categoryId] ?? 1 << 30).compareTo(
          catOrder[b.categoryId] ?? 1 << 30,
        );
        return c != 0 ? c : a.sortOrder.compareTo(b.sortOrder);
      });
    return list;
  }

  Future<void> _toggleActive(MenuItem item) async {
    if (!await _canEdit()) return;
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setItemActive(item.id, !item.isActive),
      success: item.isActive
          ? '"${item.name}" turned off'
          : '"${item.name}" turned on',
    );
  }

  Future<void> _toggleFavorite(MenuItem item) async {
    if (!await _canEdit()) return;
    final storage = await StorageService.getInstance();
    await storage.menu.setItemFavorite(item.id, !item.isFavorite);
  }

  Future<void> _reorder(
    List<MenuItem> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (!await _canEdit()) return;
    final ids = items.map((i) => i.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));
    final storage = await StorageService.getInstance();
    await storage.menu.reorderItems(ids);
  }

  Widget _itemTile(MenuSnapshot snap, MenuItem item, {Widget? dragHandle}) {
    final orderable = snap.isOrderable(item);
    final tax = item.taxProfileId == null
        ? null
        : snap.taxById[item.taxProfileId];
    final details = [
      snap.categoryPath(item.categoryId),
      if (item.sku != null) item.sku!,
      tax == null ? 'No tax' : tax.name,
      if (item.optionGroupIds.isNotEmpty)
        '${item.optionGroupIds.length} option group(s)',
    ].join(' · ');
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        onTap: () => _open(ItemEditScreen(itemId: item.id)),
        leading: FoodTypeMark(item.foodType, size: 18),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: orderable ? null : Colors.grey,
                ),
              ),
            ),
            Text(
              item.basePrice.format(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            if (!orderable || !item.availableDineIn || !item.availableTakeaway)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (!item.isActive)
                      const SmallBadge('Off', color: Colors.red),
                    if (item.isActive && !orderable)
                      const SmallBadge('Category hidden', color: Colors.red),
                    if (!item.availableDineIn) const SmallBadge('No dine-in'),
                    if (!item.availableTakeaway)
                      const SmallBadge('No takeaway'),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: item.isFavorite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              icon: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: item.isFavorite ? const Color(0xFFF59E0B) : null,
              ),
              onPressed: () => _toggleFavorite(item),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _open(ItemEditScreen(itemId: item.id));
                if (v == 'active') _toggleActive(item);
                if (v == 'recipe') {
                  Navigator.of(context).push(recipeRoute(item));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'recipe',
                  child: Text('Recipe (stock used)'),
                ),
                PopupMenuItem(
                  value: 'active',
                  child: Text(item.isActive ? 'Turn off' : 'Turn on'),
                ),
              ],
            ),
            ?dragHandle,
          ],
        ),
      ),
    );
  }

  Widget _chips(MenuSnapshot snap) {
    final tops = snap.topLevelCategories
        .where((c) => c.isActive || _showInactive)
        .toList();
    final selectedTop = _filter == _all || _filter == _favorites
        ? null
        : snap.categoryById[_filter];
    final subs = selectedTop == null
        ? <MenuCategory>[]
        : snap
              .subcategoriesOf(selectedTop.id)
              .where((c) => c.isActive || _showInactive)
              .toList();

    Widget chip(
      String label,
      bool selected,
      VoidCallback onTap, {
      Widget? avatar,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: avatar,
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              chip('All', _filter == _all, () {
                setState(() {
                  _filter = _all;
                  _subFilter = null;
                });
              }),
              chip(
                'Favourites',
                _filter == _favorites,
                () => setState(() {
                  _filter = _favorites;
                  _subFilter = null;
                }),
                avatar: const Icon(Icons.star_rounded, size: 16),
              ),
              for (final c in tops)
                chip(
                  c.isActive ? c.name : '${c.name} (hidden)',
                  _filter == c.id,
                  () => setState(() {
                    _filter = c.id;
                    _subFilter = null;
                  }),
                ),
            ],
          ),
        ),
        if (subs.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                chip(
                  'All ${selectedTop!.name}',
                  _subFilter == null,
                  () => setState(() => _subFilter = null),
                ),
                for (final s in subs)
                  chip(
                    s.name,
                    _subFilter == s.id,
                    () => setState(() => _subFilter = s.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'inactive':
                  setState(() => _showInactive = !_showInactive);
                case 'categories':
                  _open(const CategoriesScreen());
                case 'groups':
                  _open(const OptionGroupsScreen());
                case 'taxes':
                  _open(const TaxProfilesScreen());
                case 'stations':
                  _open(const StationsScreen());
                case 'import':
                  _open(const MenuImportScreen());
                case 'export':
                  exportMenuCsv(context);
                case 'stock':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
              }
            },
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: 'inactive',
                checked: _showInactive,
                child: const Text('Show turned-off items'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'categories',
                child: Text('Categories'),
              ),
              const PopupMenuItem(
                value: 'groups',
                child: Text('Variants & add-ons'),
              ),
              const PopupMenuItem(value: 'taxes', child: Text('Taxes')),
              const PopupMenuItem(
                value: 'stations',
                child: Text('Kitchen stations'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'stock', child: Text('Stock')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'import', child: Text('Import CSV')),
              const PopupMenuItem(value: 'export', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      floatingActionButton: snap == null || snap.categories.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _open(
                ItemEditScreen(
                  initialCategoryId:
                      _subFilter ??
                      (_filter == _all || _filter == _favorites
                          ? null
                          : _filter),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
      body: _error != null
          ? MessageState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load the menu',
              message: _error,
            )
          : snap == null
          ? const Center(child: CircularProgressIndicator())
          : snap.categories.isEmpty
          ? MessageState(
              icon: Icons.restaurant_menu_rounded,
              title: 'Your menu is empty',
              message:
                  'Start by creating categories (e.g. Starters, Main Course), '
                  'or import a CSV file.',
              action: Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _open(const CategoriesScreen()),
                    icon: const Icon(Icons.folder_rounded),
                    label: const Text('Categories'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(const MenuImportScreen()),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Import CSV'),
                  ),
                ],
              ),
            )
          : _buildList(snap),
    );
  }

  Widget _buildList(MenuSnapshot snap) {
    final items = _visibleItems(snap);
    final reorderCat = _reorderCategory;
    final header = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search name or short code',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        _chips(snap),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Text(
                '${items.length} item(s)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              if (reorderCat != null && items.length > 1)
                const Text(
                  'Drag ≡ to reorder',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
            ],
          ),
        ),
      ],
    );

    if (items.isEmpty) {
      return ListView(
        children: [
          header,
          const MessageState(
            icon: Icons.search_off_rounded,
            title: 'No items here',
            message: 'Change the search or filter, or add an item.',
          ),
        ],
      );
    }

    if (reorderCat != null) {
      return ReorderableListView.builder(
        header: header,
        padding: const EdgeInsets.only(bottom: 96),
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorderItem: (o, n) => _reorder(items, o, n),
        itemBuilder: (context, i) => _itemTile(
          snap,
          items[i],
          dragHandle: ReorderableDragStartListener(
            index: i,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.drag_handle_rounded),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return header;
        final item = items[i - 1];
        final prev = i >= 2 ? items[i - 2] : null;
        final showHeading =
            _filter != _favorites &&
            (prev == null || prev.categoryId != item.categoryId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  snap.categoryPath(item.categoryId).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            _itemTile(snap, item),
          ],
        );
      },
    );
  }
}
