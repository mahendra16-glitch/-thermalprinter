import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/util/ids.dart';
import '../../domain/orders/table_models.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';

/// Create, rename and switch off dining areas and tables.
class ManageTablesScreen extends StatefulWidget {
  const ManageTablesScreen({super.key});

  @override
  State<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends State<ManageTablesScreen> {
  List<DiningArea>? _areas;
  List<RestaurantTable> _tables = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final areas = await storage.tables.listAreas();
    final tables = await storage.tables.listTables();
    if (mounted) {
      setState(() {
        _areas = areas;
        _tables = tables;
      });
    }
  }

  Future<void> _editArea([DiningArea? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New area' : 'Rename area'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Indoor, Terrace, Family',
          ),
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
                () => storage.tables.saveArea(
                  DiningArea(id: existing?.id ?? newId(), name: name.text),
                ),
              );
              if (ok && ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _editTable(String areaId, [RestaurantTable? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    final seats = TextEditingController(
      text: existing?.seats?.toString() ?? '',
    );
    var area = existing?.areaId ?? areaId;
    final areas = (_areas ?? []).where((a) => a.isActive || a.id == area);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New table' : 'Edit table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Table name',
                  hintText: 'e.g. T1, 12, Booth A',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seats,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Seats (optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: area,
                decoration: const InputDecoration(labelText: 'Area'),
                items: [
                  for (final a in areas)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (v) => setLocal(() => area = v ?? area),
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
                  () => storage.tables.saveTable(
                    RestaurantTable(
                      id: existing?.id ?? newId(),
                      areaId: area,
                      label: label.text,
                      seats: int.tryParse(seats.text),
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

  Future<void> _bulkAdd(DiningArea area) async {
    final prefix = TextEditingController(text: 'T');
    final from = TextEditingController(text: '1');
    final to = TextEditingController(text: '10');
    final seats = TextEditingController(text: '4');
    final created = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add several tables to ${area.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prefix,
              decoration: const InputDecoration(
                labelText: 'Name prefix',
                helperText: '"T" + 1…10 gives T1, T2 … T10',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: from,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'From'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: to,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'To'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: seats,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Seats each'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final f = int.tryParse(from.text.trim());
              final t = int.tryParse(to.text.trim());
              if (f == null || t == null) return;
              final storage = await StorageService.getInstance();
              if (!ctx.mounted) return;
              var n = 0;
              final ok = await runMenuAction(ctx, () async {
                n = await storage.tables.addTables(
                  areaId: area.id,
                  prefix: prefix.text,
                  from: f,
                  to: t,
                  seats: int.tryParse(seats.text.trim()),
                );
              });
              if (ok && ctx.mounted) Navigator.pop(ctx, n);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created == 0
                ? 'Those tables already exist.'
                : 'Added $created table(s).',
          ),
        ),
      );
      _load();
    }
  }

  Future<void> _toggleArea(DiningArea a) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.tables.setAreaActive(a.id, !a.isActive),
    );
    _load();
  }

  Future<void> _toggleTable(RestaurantTable t) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.tables.setTableActive(t.id, !t.isActive),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final areas = _areas;
    return Scaffold(
      appBar: AppBar(title: const Text('Areas & tables')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editArea,
        icon: const Icon(Icons.add),
        label: const Text('Add area'),
      ),
      body: areas == null
          ? const Center(child: CircularProgressIndicator())
          : areas.isEmpty
          ? const MessageState(
              icon: Icons.layers_rounded,
              title: 'No areas yet',
              message: 'Start with an area such as "Indoor", then add tables.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                for (final a in areas)
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            a.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: a.isActive ? null : Colors.grey,
                            ),
                          ),
                          subtitle: a.isActive ? null : const Text('Off'),
                          onTap: () => _editArea(a),
                          trailing: Switch(
                            value: a.isActive,
                            onChanged: (_) => _toggleArea(a),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in _tables.where(
                                (t) => t.areaId == a.id,
                              ))
                                InputChip(
                                  label: Text(
                                    t.seats == null
                                        ? t.label
                                        : '${t.label} · ${t.seats}',
                                  ),
                                  avatar: t.isActive
                                      ? null
                                      : const Icon(Icons.block, size: 16),
                                  onPressed: () => _editTable(a.id, t),
                                  onDeleted: () => _toggleTable(t),
                                  deleteIcon: Icon(
                                    t.isActive
                                        ? Icons.toggle_on_rounded
                                        : Icons.toggle_off_rounded,
                                  ),
                                  deleteButtonTooltipMessage: t.isActive
                                      ? 'Turn off'
                                      : 'Turn on',
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 18),
                                label: const Text('Table'),
                                onPressed: () => _editTable(a.id),
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.playlist_add,
                                  size: 18,
                                ),
                                label: const Text('Several'),
                                onPressed: () => _bulkAdd(a),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
