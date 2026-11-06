import 'package:flutter/material.dart';

import '../../core/util/ids.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

/// Preparation stations (Kitchen, Bar, Bakery…). Items are assigned to a
/// station so their KOT lines go to the right place.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  List<KitchenStation>? _stations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final list = await storage.menu.listStations();
    if (mounted) setState(() => _stations = list);
  }

  Future<void> _edit([KitchenStation? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New station' : 'Rename station'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Kitchen, Bar, Tandoor',
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
                () => storage.menu.saveStation(
                  KitchenStation(id: existing?.id ?? newId(), name: name.text),
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

  Future<void> _toggle(KitchenStation s) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setStationActive(s.id, !s.isActive),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final stations = _stations;
    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen stations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Add station'),
      ),
      body: stations == null
          ? const Center(child: CircularProgressIndicator())
          : stations.isEmpty
          ? const MessageState(
              icon: Icons.soup_kitchen_rounded,
              title: 'No stations yet',
              message:
                  'Add stations such as Kitchen or Bar, then assign items to '
                  'them. Printer routing per station comes with the KOT '
                  'module.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: stations
                  .map(
                    (s) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.soup_kitchen_rounded),
                        title: Text(
                          s.name,
                          style: TextStyle(
                            color: s.isActive ? null : Colors.grey,
                          ),
                        ),
                        onTap: () => _edit(s),
                        trailing: Switch(
                          value: s.isActive,
                          onChanged: (_) => _toggle(s),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
