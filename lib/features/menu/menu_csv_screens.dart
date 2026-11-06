import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/menu_csv_service.dart';
import '../../services/storage_service.dart';
import 'menu_widgets.dart';

/// Writes the menu to a CSV file and opens the share sheet.
Future<void> exportMenuCsv(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final storage = await StorageService.getInstance();
    final snap = await storage.menu.loadSnapshot();
    if (snap.items.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('There are no items to export.')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File(p.join(dir.path, 'menu-$stamp.csv'));
    await file.writeAsBytes(utf8.encode(MenuCsvService.export(snap)));
    await storage.audit.record(
      action: 'menu.csv_exported',
      entity: 'menu_items',
      details: {'items': snap.items.length},
    );
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Menu export'),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

/// Pick a CSV, preview what would change, then import in one transaction.
class MenuImportScreen extends StatefulWidget {
  const MenuImportScreen({super.key});

  @override
  State<MenuImportScreen> createState() => _MenuImportScreenState();
}

class _MenuImportScreenState extends State<MenuImportScreen> {
  String? _fileName;
  CsvImportPlan? _plan;
  bool _busy = false;
  bool _showUnchanged = false;

  Future<void> _pick() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );
      if (files.isEmpty) return;
      setState(() => _busy = true);
      final bytes = await files.first.xFile.readAsBytes();
      final String text;
      try {
        text = utf8.decode(bytes);
      } on FormatException {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'The file is not UTF-8 text. In Excel use "Save As > CSV UTF-8".',
            ),
          ),
        );
        setState(() => _busy = false);
        return;
      }
      final storage = await StorageService.getInstance();
      final snap = await storage.menu.loadSnapshot();
      setState(() {
        _fileName = files.first.name;
        _plan = MenuCsvService.plan(text, snap);
        _busy = false;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final plan = _plan!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import menu?'),
        content: Text(
          'Create ${plan.count(CsvRowAction.create)} item(s), update '
          '${plan.count(CsvRowAction.update)} and add '
          '${plan.newCategories.length} categor(ies). If anything fails, '
          'nothing is changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    CsvImportResult? result;
    final ok = await runMenuAction(context, () async {
      result = await MenuCsvService.apply(
        storage.db,
        storage.menu,
        storage.audit,
        plan,
      );
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported: ${result!.created} new, ${result!.updated} updated, '
            '${result!.categoriesCreated} new categor(ies).',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Color _color(CsvRowAction a) => switch (a) {
    CsvRowAction.create => const Color(0xFF15803D),
    CsvRowAction.update => const Color(0xFF1D4ED8),
    CsvRowAction.unchanged => const Color(0xFF64748B),
    CsvRowAction.error => const Color(0xFFB91C1C),
  };

  String _label(CsvRowAction a) => switch (a) {
    CsvRowAction.create => 'New',
    CsvRowAction.update => 'Update',
    CsvRowAction.unchanged => 'No change',
    CsvRowAction.error => 'Error',
  };

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final rows =
        plan == null
              ? const <CsvImportRow>[]
              : plan.rows
                    .where(
                      (r) =>
                          _showUnchanged || r.action != CsvRowAction.unchanged,
                    )
                    .toList()
          ..sort((a, b) {
            // Errors first so they are seen.
            final ea = a.action == CsvRowAction.error ? 0 : 1;
            final eb = b.action == CsvRowAction.error ? 0 : 1;
            return ea != eb ? ea - eb : a.line - b.line;
          });

    return Scaffold(
      appBar: AppBar(title: const Text('Import menu CSV')),
      bottomNavigationBar: plan == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _busy ? null : _pick,
                      child: const Text('Choose another'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy || !plan.canApply ? null : _apply,
                        child: Text(
                          plan.hasErrors
                              ? 'Fix errors to import'
                              : plan.hasWork
                              ? 'Import'
                              : 'Nothing to import',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : plan == null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Import items from a CSV file (e.g. saved from Excel as '
                  '"CSV UTF-8"). You will see a preview before anything is '
                  'saved.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Columns (header row required; only category and name are '
                  'mandatory):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  MenuCsvColumns.all.join(', '),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Rows match existing items by id, then sku, then '
                  'category + name, and update them. Other rows create items.\n'
                  '• On update, a blank cell keeps the current value.\n'
                  '• Missing categories are created. Tax and station names '
                  'must already exist.\n'
                  '• food_type: veg, non-veg, egg or other. Yes/no columns: '
                  'yes or no.\n'
                  '• Variants and add-ons are not imported; attach them in '
                  'the app.\n'
                  '• Tip: export first to get a file in the right format.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Choose CSV file'),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  _fileName ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final e in plan.fileErrors)
                  Text(e, style: const TextStyle(color: Color(0xFFB91C1C))),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in CsvRowAction.values)
                      SmallBadge(
                        '${_label(a)}: ${plan.count(a)}',
                        color: _color(a),
                      ),
                    SmallBadge(
                      'New categories: ${plan.newCategories.length}',
                      color: const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                if (plan.newCategories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Will create: '
                    '${plan.newCategories.map((c) => c.path).join(', ')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (plan.count(CsvRowAction.unchanged) > 0)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show unchanged rows'),
                    value: _showUnchanged,
                    onChanged: (v) => setState(() => _showUnchanged = v),
                  ),
                const SizedBox(height: 4),
                for (final r in rows)
                  Card(
                    child: ListTile(
                      dense: true,
                      leading: SmallBadge(
                        _label(r.action),
                        color: _color(r.action),
                      ),
                      title: Text('Line ${r.line}: ${r.displayName}'),
                      subtitle: r.messages.isEmpty
                          ? null
                          : Text(
                              r.messages.join('\n'),
                              style: TextStyle(
                                color: r.action == CsvRowAction.error
                                    ? const Color(0xFFB91C1C)
                                    : null,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
    );
  }
}
