import 'package:flutter/material.dart';

import '../../core/util/ids.dart';
import '../../data/repositories/kitchen_repository.dart';
import '../../domain/menu/menu_models.dart';
import '../../models/printer_device.dart';
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
  List<PrinterDevice> _printers = [];
  Map<String, List<String>> _routing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final list = await storage.menu.listStations();
    final printers = await storage.getSavedPrinters();
    final routing = await storage.kitchen.stationPrinters();
    if (mounted) {
      setState(() {
        _stations = list;
        _printers = printers;
        _routing = routing;
      });
    }
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

  String _printerSummary(String stationId) {
    final ids = _routing[stationId] ?? const [];
    final names = _printers
        .where((p) => ids.contains(p.id))
        .map((p) => p.name)
        .toList();
    if (names.isNotEmpty) return 'Prints on: ${names.join(', ')}';
    return stationId == KitchenRepository.defaultStation
        ? 'No printer: uses the KOT printer, else the fallback printer'
        : 'No printer: uses the default kitchen printers';
  }

  Future<void> _assignPrinters(String stationId, String title) async {
    if (_printers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a printer first (Settings > Printers).'),
        ),
      );
      return;
    }
    final selected = {...?_routing[stationId]};
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('KOT printers: $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in _printers)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.contains(p.id),
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.role.label} · ${p.connectionType.name.toUpperCase()}',
                  ),
                  onChanged: (v) => setLocal(
                    () =>
                        v == true ? selected.add(p.id) : selected.remove(p.id),
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
    if (saved != true) return;
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.kitchen.setStationPrinters(stationId, [...selected]),
    );
    _load();
  }

  Widget _routingTile(
    String stationId,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool active = true,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.soup_kitchen_rounded),
        title: Text(
          title,
          style: TextStyle(color: active ? null : Colors.grey),
        ),
        subtitle: Text(_printerSummary(stationId)),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Choose printers',
              icon: const Icon(Icons.print_rounded),
              onPressed: () => _assignPrinters(stationId, title),
            ),
            ?trailing,
          ],
        ),
      ),
    );
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
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const Text(
                  "Each item's KOT lines print on its station's printers. "
                  'Items without a station use "Default kitchen".',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                _routingTile(
                  KitchenRepository.defaultStation,
                  'Default kitchen (items without a station)',
                ),
                if (stations.isEmpty)
                  const MessageState(
                    icon: Icons.soup_kitchen_rounded,
                    title: 'No stations yet',
                    message:
                        'Add stations such as Bar or Tandoor if they need '
                        'their own KOT printer, then assign items to them.',
                  ),
                for (final s in stations)
                  _routingTile(
                    s.id,
                    s.name,
                    active: s.isActive,
                    onTap: () => _edit(s),
                    trailing: Switch(
                      value: s.isActive,
                      onChanged: (_) => _toggle(s),
                    ),
                  ),
              ],
            ),
    );
  }
}
