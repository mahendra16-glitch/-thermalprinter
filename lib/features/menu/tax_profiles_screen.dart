import 'package:flutter/material.dart';

import '../../core/util/ids.dart';
import '../../domain/menu/menu_models.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

class TaxProfilesScreen extends StatefulWidget {
  const TaxProfilesScreen({super.key});

  @override
  State<TaxProfilesScreen> createState() => _TaxProfilesScreenState();
}

class _TaxProfilesScreenState extends State<TaxProfilesScreen> {
  List<TaxProfile>? _taxes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await StorageService.getInstance();
    final list = await storage.menu.listTaxProfiles();
    if (mounted) setState(() => _taxes = list);
  }

  Future<void> _edit([TaxProfile? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final rate = TextEditingController(
      text: existing == null ? '' : existing.rateLabel.replaceAll('%', ''),
    );
    var inclusive = existing?.isInclusive ?? false;
    var split = existing?.splitMode ?? TaxSplitMode.cgstSgst;
    String? rateError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'New tax' : 'Edit tax'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: existing == null,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. GST 5%',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rate,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Total rate (%)',
                    hintText: 'e.g. 5 or 18',
                    errorText: rateError,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: inclusive,
                  onChanged: (v) => setLocal(() => inclusive = v),
                  title: const Text('Menu prices include this tax'),
                  subtitle: Text(
                    inclusive
                        ? 'Tax is taken out of the price.'
                        : 'Tax is added on top of the price.',
                  ),
                ),
                DropdownButtonFormField<TaxSplitMode>(
                  initialValue: split,
                  decoration: const InputDecoration(
                    labelText: 'Show on bill as',
                  ),
                  items: TaxSplitMode.values
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => split = v ?? split),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final bp = parsePercentToBp(rate.text);
                if (bp == null) {
                  setLocal(
                    () => rateError = 'Enter 0 to 100, up to 2 decimals',
                  );
                  return;
                }
                final storage = await StorageService.getInstance();
                if (!ctx.mounted) return;
                final ok = await runMenuAction(
                  ctx,
                  () => storage.menu.saveTaxProfile(
                    TaxProfile(
                      id: existing?.id ?? newId(),
                      name: name.text,
                      rateBp: bp,
                      isInclusive: inclusive,
                      splitMode: split,
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

  Future<void> _toggle(TaxProfile t) async {
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await runMenuAction(
      context,
      () => storage.menu.setTaxProfileActive(t.id, !t.isActive),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final taxes = _taxes;
    return Scaffold(
      appBar: AppBar(title: const Text('Taxes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Add tax'),
      ),
      body: taxes == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const Text(
                  'Set up the tax rates your business charges and attach them '
                  'to items. The app does not decide which rate applies: '
                  'confirm rates and inclusive/exclusive pricing with your '
                  'accountant.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                if (taxes.isEmpty)
                  const MessageState(
                    icon: Icons.percent_rounded,
                    title: 'No taxes yet',
                    message: 'Items without a tax are billed with no tax.',
                  ),
                ...taxes.map(
                  (t) => Card(
                    child: ListTile(
                      onTap: () => _edit(t),
                      title: Text(
                        t.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: t.isActive ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(t.summary),
                      trailing: Switch(
                        value: t.isActive,
                        onChanged: (_) => _toggle(t),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
