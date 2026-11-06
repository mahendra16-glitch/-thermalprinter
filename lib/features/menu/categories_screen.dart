import 'package:flutter/material.dart';

import '../../core/util/ids.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<MenuCategory>? _all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final list = await storage.menu.listCategories();
    if (mounted) setState(() => _all = list);
  }

  List<MenuCategory> get _top =>
      (_all ?? []).where((c) => c.parentId == null).toList();

  List<MenuCategory> _subsOf(String id) =>
      (_all ?? []).where((c) => c.parentId == id).toList();

  Future<void> _edit({MenuCategory? existing, String? parentId}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    String? parent = existing?.parentId ?? parentId;
    final hasSubs = existing != null && _subsOf(existing.id).isNotEmpty;
    final parents = _top.where((c) => c.id != existing?.id).toList();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Starters',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: parent,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Inside',
                  helperText: hasSubs
                      ? 'Has subcategories, so it must stay top-level.'
                      : null,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Top level'),
                  ),
                  if (!hasSubs)
                    ...parents.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                ],
                onChanged: hasSubs ? null : (v) => setLocal(() => parent = v),
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
                final storage = await StorageService.getInstance();
                if (!ctx.mounted) return;
                final ok = await runMenuAction(
                  ctx,
                  () => storage.menu.saveCategory(
                    MenuCategory(
                      id: existing?.id ?? newId(),
                      name: name.text,
                      parentId: parent,
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

  Future<void> _toggle(MenuCategory c) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setCategoryActive(c.id, !c.isActive),
      success: c.isActive
          ? '"${c.name}" hidden. Its items cannot be ordered until it is '
                'turned back on.'
          : null,
    );
    _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final top = _top;
    final moved = top.removeAt(oldIndex);
    top.insert(newIndex, moved);
    // Keep subcategories after their parent so the stored order stays tidy.
    final ids = <String>[
      for (final c in top) ...[c.id, ..._subsOf(c.id).map((s) => s.id)],
    ];
    final storage = await StorageService.getInstance();
    await storage.menu.reorderCategories(ids);
    _load();
  }

  Widget _row(MenuCategory c, {bool indent = false}) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent ? 40 : 16, right: 8),
      leading: Icon(
        indent ? Icons.subdirectory_arrow_right_rounded : Icons.folder_rounded,
        color: c.isActive ? const Color(0xFF0F766E) : Colors.grey,
      ),
      title: Text(
        c.name,
        style: TextStyle(
          fontWeight: indent ? FontWeight.normal : FontWeight.bold,
          color: c.isActive ? null : Colors.grey,
        ),
      ),
      subtitle: c.isActive ? null : const Text('Hidden'),
      onTap: () => _edit(existing: c),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!indent)
            IconButton(
              tooltip: 'Add subcategory',
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () => _edit(parentId: c.id),
            ),
          Switch(value: c.isActive, onChanged: (_) => _toggle(c)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
          ? const MessageState(
              icon: Icons.folder_open_rounded,
              title: 'No categories yet',
              message: 'Every item belongs to a category, e.g. Starters.',
            )
          : ReorderableListView(
              padding: const EdgeInsets.only(bottom: 96),
              header: const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Drag the handle to reorder. Hidden categories keep their '
                  'items; they just cannot be ordered.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              onReorderItem: _reorder,
              children: [
                for (final c in _top)
                  Card(
                    key: ValueKey(c.id),
                    margin: const EdgeInsets.fromLTRB(12, 6, 40, 6),
                    child: Column(
                      children: [
                        _row(c),
                        for (final s in _subsOf(c.id)) _row(s, indent: true),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
