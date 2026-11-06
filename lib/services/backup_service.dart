import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../data/db/app_database.dart';
import '../data/repositories/audit_repository.dart';

class BackupInfo {
  final File file;
  final int sizeBytes;
  final DateTime modified;

  /// Database schema version stored in the backup (SQLite `user_version`).
  final int schemaVersion;
  final bool integrityOk;
  final String? problem;

  const BackupInfo({
    required this.file,
    required this.sizeBytes,
    required this.modified,
    required this.schemaVersion,
    required this.integrityOk,
    this.problem,
  });

  String get fileName => p.basename(file.path);
}

/// Manual local backups of the whole database.
///
/// A backup is a consistent SQLite copy made with `VACUUM INTO`, so it is
/// safe to take while the app is running. Restore is not implemented yet
/// (planned with backup validation in a later phase); see
/// docs/IMPLEMENTATION_PLAN.md.
class BackupService {
  final AppDatabase _db;
  final AuditRepository _audit;
  final Future<Directory> Function() _directoryProvider;

  BackupService(
    this._db,
    this._audit, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? defaultBackupDirectory;

  static const String filePrefix = 'pos-backup-';

  /// `Android/data/<app id>/files/backups` when available (reachable over
  /// USB from a computer), otherwise the app's private documents folder.
  /// Both are deleted if the app is uninstalled: share backups off the
  /// device to keep them.
  static Future<Directory> defaultBackupDirectory() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'backups'));
  }

  Future<Directory> backupDirectory() => _directoryProvider();

  Future<BackupInfo> createBackup() async {
    final dir = await _directoryProvider();
    await dir.create(recursive: true);
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    var target = File(p.join(dir.path, '$filePrefix$stamp.db'));
    var n = 1;
    while (await target.exists()) {
      target = File(p.join(dir.path, '$filePrefix$stamp-${n++}.db'));
    }

    await _db.customStatement('VACUUM INTO ?', [target.path]);

    final info = await verify(target);
    if (!info.integrityOk) {
      throw StateError(
        'Backup was written but failed verification: ${info.problem}',
      );
    }
    await _audit.record(
      action: 'backup.created',
      entity: 'database',
      details: {
        'file': info.fileName,
        'bytes': info.sizeBytes,
        'schemaVersion': info.schemaVersion,
      },
    );
    return info;
  }

  /// Opens [file] read-only and runs SQLite's integrity check.
  Future<BackupInfo> verify(File file) async {
    final stat = await file.stat();
    var version = 0;
    var ok = false;
    String? problem;
    try {
      final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
      try {
        final check = db.select('PRAGMA integrity_check');
        final result = check.isEmpty ? '' : '${check.first.values.first}';
        version = db.userVersion;
        ok = result == 'ok' && version > 0;
        if (result != 'ok') {
          problem = 'integrity check: $result';
        } else if (version <= 0) {
          problem = 'not a POS database (no schema version)';
        }
      } finally {
        db.close();
      }
    } catch (e) {
      problem = e.toString();
    }
    return BackupInfo(
      file: file,
      sizeBytes: stat.size,
      modified: stat.modified,
      schemaVersion: version,
      integrityOk: ok,
      problem: problem,
    );
  }

  /// Backups in the backup folder, newest first.
  Future<List<File>> listBackups() async {
    final dir = await _directoryProvider();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where(
          (e) =>
              e is File &&
              p.basename(e.path).startsWith(filePrefix) &&
              e.path.endsWith('.db'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }
}
