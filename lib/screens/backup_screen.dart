import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/backup_service.dart';
import '../services/storage_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupService? _service;
  String? _folder;
  List<BackupInfo> _backups = [];
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
      _service = BackupService(storage.db, storage.audit);
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
    if (mounted) {
      setState(() {
        _backups = infos;
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    setState(() => _working = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final info = await _service!.createBackup();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup created and verified: ${info.fileName}'),
        ),
      );
      await _refresh();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    if (mounted) setState(() => _working = false);
  }

  Future<void> _share(File file) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'POS backup'),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not share: $e')));
    }
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'A backup is a complete copy of this device\'s POS database '
                  '(printers, settings, queue, history and, later, menu, '
                  'orders and payments). Each backup is checked after it is '
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
                const SizedBox(height: 8),
                const Text(
                  'Restoring from a backup is not available yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
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
                        b.integrityOk
                            ? Icons.verified_rounded
                            : Icons.error_rounded,
                        color: b.integrityOk ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        b.fileName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        b.integrityOk
                            ? '${fmt.format(b.modified)} · ${_size(b.sizeBytes)} · schema v${b.schemaVersion}'
                            : 'Damaged: ${b.problem}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        tooltip: 'Share',
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => _share(b.file),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
