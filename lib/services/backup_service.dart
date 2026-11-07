import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../core/security/backup_crypto.dart';
import '../data/db/app_database.dart';
import '../data/repositories/audit_repository.dart';

class BackupInfo {
  final File file;
  final int sizeBytes;
  final DateTime modified;

  /// Database schema version stored in the backup (SQLite `user_version`,
  /// or the header of a password-protected file).
  final int schemaVersion;
  final bool integrityOk;
  final String? problem;

  /// Password-protected (`.posbak`): its contents can only be checked with
  /// the password, so [integrityOk] means "the header is readable".
  final bool encrypted;

  const BackupInfo({
    required this.file,
    required this.sizeBytes,
    required this.modified,
    required this.schemaVersion,
    required this.integrityOk,
    this.problem,
    this.encrypted = false,
  });

  String get fileName => p.basename(file.path);
}

/// What a backup holds, checked and ready to restore.
class RestoreCheck {
  /// Plain database copy in a temporary folder.
  final File plainFile;
  final String sourceName;
  final int schemaVersion;
  final Map<String, int> counts;

  /// Latest order or payment time in the backup (local), if any.
  final DateTime? lastActivity;

  const RestoreCheck({
    required this.plainFile,
    required this.sourceName,
    required this.schemaVersion,
    required this.counts,
    required this.lastActivity,
  });
}

/// Result of a restore applied at start-up.
class RestoreOutcome {
  final bool ok;
  final String message;
  final Map<String, Object?> details;

  const RestoreOutcome(this.ok, this.message, [this.details = const {}]);
}

class RestoreException implements Exception {
  final String message;

  RestoreException(this.message);

  @override
  String toString() => message;
}

/// Manual local backups of the whole database, and restore.
///
/// - A backup is a consistent SQLite copy made with `VACUUM INTO`, checked
///   with `PRAGMA integrity_check` after writing. With a password it is
///   then sealed with AES-256-GCM ([BackupCrypto]) and the plain copy is
///   deleted.
/// - Restore is two steps. [prepareRestore] opens the backup (password if
///   needed), checks it fully and shows what it holds; nothing changes yet.
///   [scheduleRestore] puts it next to the live database. On the next
///   start, before the database is opened, [applyPendingRestore] makes a
///   pre-restore backup of the current data, checks both again and only
///   then swaps the files. Older backups are upgraded by the normal
///   migrations when the database opens.
class BackupService {
  final AppDatabase _db;
  final AuditRepository _audit;
  final Future<Directory> Function() _directoryProvider;
  final Future<String> Function() _dbPathProvider;

  BackupService(
    this._db,
    this._audit, {
    Future<Directory> Function()? directoryProvider,
    Future<String> Function()? databasePathProvider,
  }) : _directoryProvider = directoryProvider ?? defaultBackupDirectory,
       _dbPathProvider = databasePathProvider ?? posDatabasePath;

  static const String filePrefix = 'pos-backup-';
  static const String encryptedExtension = '.posbak';
  static const String pendingSuffix = '.restore-pending';

  /// Tables every POS database has had since v1.
  static const _requiredTables = [
    'migration_log',
    'app_settings',
    'business_profiles',
    'printer_profiles',
    'print_jobs',
    'audit_log',
  ];

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

  static Future<File> _newTarget(
    Directory dir,
    String ext, [
    String tag = '',
  ]) async {
    await dir.create(recursive: true);
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    var target = File(p.join(dir.path, '$filePrefix$stamp$tag$ext'));
    var n = 1;
    while (await target.exists()) {
      target = File(p.join(dir.path, '$filePrefix$stamp$tag-${n++}$ext'));
    }
    return target;
  }

  /// Writes and checks a backup. With [password] (at least
  /// [BackupCrypto.minPasswordLength] characters) the file is encrypted.
  Future<BackupInfo> createBackup({String? password}) async {
    if (password != null && password.length < BackupCrypto.minPasswordLength) {
      throw ArgumentError(
        'Use a password of at least ${BackupCrypto.minPasswordLength} '
        'characters.',
      );
    }
    final dir = await _directoryProvider();
    final plain = await _newTarget(dir, '.db');
    await _db.customStatement('VACUUM INTO ?', [plain.path]);

    var info = await verify(plain);
    if (!info.integrityOk) {
      await _deleteQuietly(plain);
      throw StateError(
        'Backup was written but failed verification: ${info.problem}',
      );
    }
    if (password != null) {
      final target = File(
        plain.path.replaceFirst(RegExp(r'\.db$'), encryptedExtension),
      );
      try {
        final sealed = await BackupCrypto.encrypt(
          await plain.readAsBytes(),
          password,
          schemaVersion: info.schemaVersion,
        );
        await target.writeAsBytes(sealed, flush: true);
        // Prove the file opens with the password before trusting it.
        final back = await BackupCrypto.decrypt(
          await target.readAsBytes(),
          password,
        );
        if (back.length != await plain.length()) {
          throw StateError('Encrypted backup did not read back correctly.');
        }
      } catch (_) {
        await _deleteQuietly(target);
        rethrow;
      } finally {
        await _deleteQuietly(plain);
      }
      info = await verify(target);
    }
    await _audit.record(
      action: 'backup.created',
      entity: 'database',
      details: {
        'file': info.fileName,
        'bytes': info.sizeBytes,
        'schemaVersion': info.schemaVersion,
        'encrypted': info.encrypted,
      },
    );
    return info;
  }

  static Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Checks [file]: a plain backup is opened read-only and integrity
  /// checked; a password-protected one only has its header read.
  Future<BackupInfo> verify(File file) async {
    final stat = await file.stat();
    final head = await _head(file);
    if (BackupCrypto.looksEncrypted(head)) {
      final header = BackupCrypto.readHeader(await file.readAsBytes());
      return BackupInfo(
        file: file,
        sizeBytes: stat.size,
        modified: stat.modified,
        schemaVersion: (header?['schemaVersion'] as int?) ?? 0,
        integrityOk: header != null,
        problem: header == null ? 'unreadable header' : null,
        encrypted: true,
      );
    }
    final r = checkDatabaseFile(file);
    return BackupInfo(
      file: file,
      sizeBytes: stat.size,
      modified: stat.modified,
      schemaVersion: r.version,
      integrityOk: r.problem == null,
      problem: r.problem,
    );
  }

  static Future<List<int>> _head(File f) async {
    final raf = await f.open();
    try {
      return await raf.read(BackupCrypto.magic.length);
    } finally {
      await raf.close();
    }
  }

  /// Integrity, foreign keys and the POS tables. [maxVersion] rejects
  /// backups from a newer app.
  static ({int version, String? problem}) checkDatabaseFile(
    File file, {
    int? maxVersion,
  }) {
    try {
      final db = sqlite.sqlite3.open(file.path, mode: sqlite.OpenMode.readOnly);
      try {
        final check = db.select('PRAGMA integrity_check');
        final result = check.isEmpty ? '' : '${check.first.values.first}';
        final version = db.userVersion;
        if (result != 'ok') {
          return (version: version, problem: 'integrity check: $result');
        }
        if (version <= 0) {
          return (
            version: version,
            problem: 'not a POS database (no schema version)',
          );
        }
        final tables = db
            .select("SELECT name FROM sqlite_master WHERE type = 'table'")
            .map((r) => r['name'] as String)
            .toSet();
        final missing = _requiredTables.where((t) => !tables.contains(t));
        if (missing.isNotEmpty) {
          return (
            version: version,
            problem: 'not a POS database (missing ${missing.join(', ')})',
          );
        }
        if (db.select('PRAGMA foreign_key_check').isNotEmpty) {
          return (
            version: version,
            problem: 'records point at missing records (foreign key check)',
          );
        }
        if (maxVersion != null && version > maxVersion) {
          return (
            version: version,
            problem:
                'made by a newer version of the app (data v$version, this '
                'app v$maxVersion). Update the app first.',
          );
        }
        return (version: version, problem: null);
      } finally {
        db.close();
      }
    } catch (e) {
      return (version: 0, problem: e.toString());
    }
  }

  /// Backups in the backup folder (plain and password-protected), newest
  /// first.
  Future<List<File>> listBackups() async {
    final dir = await _directoryProvider();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where(
          (e) =>
              e is File &&
              p.basename(e.path).startsWith(filePrefix) &&
              (e.path.endsWith('.db') || e.path.endsWith(encryptedExtension)),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  // --- Restore -------------------------------------------------------------

  static Future<bool> isEncrypted(File f) async =>
      BackupCrypto.looksEncrypted(await _head(f));

  /// Opens [source] (with [password] if it is protected), checks it and
  /// reads what it holds. Changes nothing.
  Future<RestoreCheck> prepareRestore(File source, {String? password}) async {
    final tmpDir = await Directory.systemTemp.createTemp('pos_restore');
    final plain = File(p.join(tmpDir.path, 'restore.db'));
    if (await isEncrypted(source)) {
      if (password == null || password.isEmpty) {
        throw RestoreException('This backup is protected. Enter its password.');
      }
      try {
        await plain.writeAsBytes(
          await BackupCrypto.decrypt(await source.readAsBytes(), password),
          flush: true,
        );
      } on BackupPasswordException catch (e) {
        throw RestoreException(e.message);
      }
    } else {
      await source.copy(plain.path);
    }
    final r = checkDatabaseFile(plain, maxVersion: _db.schemaVersion);
    if (r.problem != null) {
      await _deleteQuietly(plain);
      throw RestoreException('This backup cannot be restored: ${r.problem}.');
    }
    final counts = <String, int>{};
    DateTime? last;
    final db = sqlite.sqlite3.open(plain.path, mode: sqlite.OpenMode.readOnly);
    try {
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((x) => x['name'] as String)
          .toSet();
      for (final t in [
        'orders',
        'bills',
        'payments',
        'menu_items',
        'staff_users',
        'printer_profiles',
      ]) {
        if (!tables.contains(t)) continue;
        counts[t] = db.select('SELECT COUNT(*) AS n FROM $t').first['n'] as int;
      }
      int? lastMs;
      for (final q in [
        if (tables.contains('orders'))
          'SELECT MAX(updated_at) AS t FROM orders',
        if (tables.contains('payments'))
          'SELECT MAX(created_at) AS t FROM payments',
      ]) {
        final t = db.select(q).first['t'] as int?;
        if (t != null && (lastMs == null || t > lastMs)) lastMs = t;
      }
      if (lastMs != null) {
        last = DateTime.fromMillisecondsSinceEpoch(
          lastMs,
          isUtc: true,
        ).toLocal();
      }
    } finally {
      db.close();
    }
    return RestoreCheck(
      plainFile: plain,
      sourceName: p.basename(source.path),
      schemaVersion: r.version,
      counts: counts,
      lastActivity: last,
    );
  }

  /// Places the checked backup next to the live database. It replaces the
  /// data the next time the app starts (after a pre-restore backup).
  Future<void> scheduleRestore(RestoreCheck check) async {
    final dbPath = await _dbPathProvider();
    final pending = File('$dbPath$pendingSuffix');
    await check.plainFile.copy(pending.path);
    await File('$dbPath$pendingSuffix.json').writeAsString(
      jsonEncode({
        'source': check.sourceName,
        'schemaVersion': check.schemaVersion,
        'scheduledAt': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
    await _audit.record(
      action: 'backup.restore_scheduled',
      entity: 'database',
      details: {
        'source': check.sourceName,
        'schemaVersion': check.schemaVersion,
        ...check.counts,
      },
    );
  }

  /// Name of the backup waiting to be restored, or null.
  Future<String?> pendingRestore() async {
    final dbPath = await _dbPathProvider();
    final marker = File('$dbPath$pendingSuffix.json');
    if (!await File('$dbPath$pendingSuffix').exists()) return null;
    if (!await marker.exists()) return 'backup';
    try {
      return (jsonDecode(await marker.readAsString()) as Map)['source']
          as String?;
    } catch (_) {
      return 'backup';
    }
  }

  Future<void> cancelPendingRestore() async {
    final dbPath = await _dbPathProvider();
    await _deleteQuietly(File('$dbPath$pendingSuffix'));
    await _deleteQuietly(File('$dbPath$pendingSuffix.json'));
    await _audit.record(action: 'backup.restore_cancelled', entity: 'database');
  }

  /// Runs at start-up BEFORE the database is opened. If a restore is
  /// waiting: backs up the current database ("pre-restore"), checks both
  /// files and swaps them. On any problem the current data is kept and the
  /// reason returned. Returns null when nothing was waiting.
  static Future<RestoreOutcome?> applyPendingRestore({
    required String dbPath,
    required Directory backupDir,
    required int maxVersion,
  }) async {
    final pending = File('$dbPath$pendingSuffix');
    final marker = File('$dbPath$pendingSuffix.json');
    if (!await pending.exists()) return null;
    Map<String, Object?> meta = {};
    try {
      meta = (jsonDecode(await marker.readAsString()) as Map)
          .cast<String, Object?>();
    } catch (_) {}

    Future<void> dropPending() async {
      await _deleteQuietly(pending);
      await _deleteQuietly(marker);
    }

    final check = checkDatabaseFile(pending, maxVersion: maxVersion);
    if (check.problem != null) {
      await dropPending();
      return RestoreOutcome(
        false,
        'The restore was not done: the backup failed its check '
        '(${check.problem}). Your current data is unchanged.',
        meta,
      );
    }

    final live = File(dbPath);
    String? preRestore;
    if (await live.exists()) {
      try {
        final target = await _newTarget(backupDir, '.db', '-pre-restore');
        final db = sqlite.sqlite3.open(dbPath);
        try {
          db.execute('VACUUM INTO ?', [target.path]);
        } finally {
          db.close();
        }
        final pre = checkDatabaseFile(target);
        if (pre.problem != null) {
          await _deleteQuietly(target);
          throw StateError(pre.problem!);
        }
        preRestore = p.basename(target.path);
      } catch (e) {
        // Keep the pending file so it can be tried again after the cause
        // is fixed (e.g. storage full).
        return RestoreOutcome(
          false,
          'The restore was not done: could not back up the current data '
          'first ($e). Your current data is unchanged.',
          meta,
        );
      }
    }

    // Move the current file aside (not deleted) until the new one is in
    // place, so a failure here can always be undone.
    final aside = File('$dbPath.before-restore');
    try {
      await _deleteQuietly(aside);
      if (await live.exists()) await live.rename(aside.path);
      for (final ext in ['-journal', '-wal', '-shm']) {
        await _deleteQuietly(File('$dbPath$ext'));
      }
      await pending.rename(dbPath);
    } catch (e) {
      if (!await live.exists() && await aside.exists()) {
        await aside.rename(dbPath);
      }
      return RestoreOutcome(
        false,
        'The restore failed while replacing the data ($e). Your current '
        'data is unchanged.',
        meta,
      );
    }
    await _deleteQuietly(aside);
    await _deleteQuietly(marker);
    return RestoreOutcome(
      true,
      'Backup ${meta['source'] ?? ''} was restored.'
      '${preRestore == null ? '' : ' The data from before is kept in backup $preRestore.'}',
      {...meta, 'preRestoreBackup': preRestore},
    );
  }
}

/// Sizes for display.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
