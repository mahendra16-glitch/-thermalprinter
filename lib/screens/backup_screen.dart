import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../core/security/backup_crypto.dart';
import '../services/backup_service.dart';
import '../services/storage_service.dart';

class BackupScreen extends StatefulWidget {
  /// For tests: a service with its own folders.
  final BackupService? service;

  const BackupScreen({super.key, this.service});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupService? _service;
  String? _folder;
  List<BackupInfo> _backups = [];
  String? _pending;
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final storage = await StorageService.getInstance();
      _service = widget.service ?? BackupService(storage.db, storage.audit);
      _folder = (await _service!.backupDirectory()).path;
      await _refresh();
    } catch (e) {
      _error = e.toString();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    final files = await _service!.listBackups();
    final infos = <BackupInfo>[];
    for (final f in files) {
      infos.add(await _service!.verify(f));
    }
    final pending = await _service!.pendingRestore();
    if (mounted) {
      setState(() {
        _backups = infos;
        _pending = pending;
        _loading = false;
      });
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _create() async {
    final password = await _askNewPassword();
    if (password == false || !mounted) return; // cancelled
    setState(() => _working = true);
    try {
      final info = await _service!.createBackup(
        password: password is String ? password : null,
      );
      _snack(
        info.encrypted
            ? 'Password-protected backup created and checked: '
                  '${info.fileName}'
            : 'Backup created and verified: ${info.fileName}',
      );
      await _refresh();
    } catch (e) {
      _snack('Backup failed: $e', error: true);
    }
    if (mounted) setState(() => _working = false);
  }

  /// Returns a password, null for "no password", or false on cancel.
  Future<Object?> _askNewPassword() async {
    final pw = TextEditingController();
    final again = TextEditingController();
    var protect = true;
    String? err;
    return showDialog<Object?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create backup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Protect with a password'),
                  subtitle: const Text(
                    'Recommended before sharing: the backup holds sales, '
                    'customer phone numbers and staff PIN hashes.',
                  ),
                  value: protect,
                  onChanged: (v) => setState(() => protect = v),
                ),
                if (protect) ...[
                  TextField(
                    controller: pw,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (at least 8 characters)',
                    ),
                  ),
                  TextField(
                    controller: again,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Same password again',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'There is no way to open the backup without this '
                    'password. Write it down somewhere safe.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
                if (err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      err!,
                      style: const TextStyle(color: Colors.red),
                    ),
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
              onPressed: () {
                if (!protect) {
                  Navigator.pop(ctx, null);
                  return;
                }
                if (pw.text.length < BackupCrypto.minPasswordLength) {
                  setState(
                    () => err =
                        'Use at least ${BackupCrypto.minPasswordLength} '
                        'characters.',
                  );
                  return;
                }
                if (pw.text != again.text) {
                  setState(() => err = 'The two passwords are different.');
                  return;
                }
                Navigator.pop(ctx, pw.text);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'POS backup'),
      );
    } catch (e) {
      _snack('Could not share: $e', error: true);
    }
  }

  Future<void> _restoreFromFile() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.any);
      if (files.isEmpty || !mounted) return;
      final bytes = await files.first.xFile.readAsBytes();
      final tmp = await Directory.systemTemp.createTemp('pos_pick');
      final f = File(p.join(tmp.path, files.first.name));
      await f.writeAsBytes(bytes, flush: true);
      await _restore(f);
    } catch (e) {
      if (mounted) _snack('Could not open the file: $e', error: true);
    }
  }

  Future<void> _restore(File source) async {
    String? password;
    if (await BackupService.isEncrypted(source)) {
      if (!mounted) return;
      password = await _askPassword();
      if (password == null) return;
    }
    if (!mounted) return;
    setState(() => _working = true);
    RestoreCheck check;
    try {
      check = await _service!.prepareRestore(source, password: password);
    } catch (e) {
      if (mounted) {
        setState(() => _working = false);
        _snack('$e', error: true);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _working = false);
    final ok = await _confirmRestore(check);
    if (ok != true || !mounted) return;
    try {
      await _service!.scheduleRestore(check);
      await _refresh();
      if (mounted) await _restartDialog();
    } catch (e) {
      if (mounted) _snack('Could not prepare the restore: $e', error: true);
    }
  }

  Future<String?> _askPassword() {
    final pw = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup password'),
        content: TextField(
          controller: pw,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, pw.text),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmRestore(RestoreCheck c) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final typed = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Replace all data with this backup?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup: ${c.sourceName} (checked, data v${c.schemaVersion})',
                ),
                if (c.lastActivity != null)
                  Text(
                    'Last order or payment in it: ${fmt.format(c.lastActivity!)}',
                  ),
                const SizedBox(height: 8),
                for (final e in c.counts.entries)
                  Text('• ${e.value} ${_label(e.key)}'),
                const SizedBox(height: 12),
                const Text(
                  'Everything on this device (orders, bills, payments, menu, '
                  'staff, settings) will be replaced by the backup when the '
                  'app next starts. Just before that, the current data is '
                  'saved as a "pre-restore" backup, so this can be undone.',
                ),
                const SizedBox(height: 12),
                const Text('Type RESTORE to confirm.'),
                TextField(
                  controller: typed,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: typed.text.trim().toUpperCase() == 'RESTORE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(String table) => switch (table) {
    'orders' => 'orders',
    'bills' => 'bills',
    'payments' => 'payment entries',
    'menu_items' => 'menu items',
    'staff_users' => 'staff accounts',
    'printer_profiles' => 'printers',
    _ => table,
  };

  Future<void> _restartDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Close the app to finish'),
        content: const Text(
          'The restore happens the next time the app starts. Close the app '
          'now and open it again.\n\nDon\'t take orders before that: '
          'anything entered now will be replaced (it is kept in the '
          'pre-restore backup).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Close app now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_pending != null)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restore of $_pending is waiting. It happens when '
                            'the app next starts.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: () => SystemNavigator.pop(),
                                child: const Text('Close app now'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _service!.cancelPendingRestore();
                                  await _refresh();
                                  if (mounted) _snack('Restore cancelled.');
                                },
                                child: const Text('Cancel restore'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const Text(
                  'A backup is a complete copy of this device\'s POS data: '
                  'menu, orders, bills, payments, shifts, stock, staff, '
                  'printers and settings. Each backup is checked after it is '
                  'written.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved in: $_folder\n'
                  'This folder is removed if the app is uninstalled. Use Share '
                  'to keep a copy elsewhere (Drive, email, computer).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _working ? null : _create,
                    icon: _working
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.backup_rounded),
                    label: const Text('Create backup now'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _working ? null : _restoreFromFile,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore from a file…'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Backups on this device (${_backups.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_backups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No backups yet.'),
                  ),
                ..._backups.map(
                  (b) => Card(
                    child: ListTile(
                      leading: Icon(
                        !b.integrityOk
                            ? Icons.error_rounded
                            : b.encrypted
                            ? Icons.lock_rounded
                            : Icons.verified_rounded,
                        color: b.integrityOk ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        b.fileName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        b.integrityOk
                            ? '${fmt.format(b.modified)} · '
                                  '${formatBytes(b.sizeBytes)} · data '
                                  'v${b.schemaVersion}'
                                  '${b.encrypted ? ' · password-protected' : ''}'
                            : 'Damaged: ${b.problem}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Backup actions',
                        onSelected: (v) {
                          if (v == 'share') _share(b.file);
                          if (v == 'restore') _restore(b.file);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'share',
                            child: Text('Share'),
                          ),
                          if (b.integrityOk)
                            const PopupMenuItem(
                              value: 'restore',
                              child: Text('Restore this backup…'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
