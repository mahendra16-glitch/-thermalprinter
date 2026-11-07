import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local log of unexpected errors (nothing is sent anywhere). Kept in the
/// app's documents folder, up to about 2 × [maxBytes]; shown and shared
/// from Settings > App error log.
class ErrorLog {
  ErrorLog._();

  static final ErrorLog instance = ErrorLog._();

  static const int maxBytes = 256 * 1024;

  Directory? _dir;
  Future<void> _writing = Future.value();

  /// For tests.
  @visibleForTesting
  set directory(Directory d) => _dir = d;

  Future<File> _file() async {
    _dir ??= Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'logs'),
    );
    await _dir!.create(recursive: true);
    return File(p.join(_dir!.path, 'errors.log'));
  }

  /// Installs the handlers. Errors are still printed to the console as
  /// before; they are also written to the log.
  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
      record(details.exception, details.stack, source: 'flutter');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
      record(error, stack, source: 'uncaught');
      return true;
    };
  }

  /// Appends one entry. Never throws.
  Future<void> record(
    Object error,
    StackTrace? stack, {
    String source = 'app',
  }) {
    final entry = StringBuffer()
      ..writeln('=== ${DateTime.now().toIso8601String()} [$source]')
      ..writeln(error)
      ..writeln(_trim(stack));
    return _writing = _writing.then((_) async {
      try {
        final f = await _file();
        if (await f.exists() && await f.length() > maxBytes) {
          final old = File('${f.path}.1');
          if (await old.exists()) await old.delete();
          await f.rename(old.path);
        }
        await File(
          f.path,
        ).writeAsString(entry.toString(), mode: FileMode.append, flush: true);
      } catch (e) {
        debugPrint('Could not write the error log: $e');
      }
    });
  }

  static String _trim(StackTrace? st) {
    if (st == null) return '';
    final lines = st.toString().split('\n');
    return lines.take(25).join('\n');
  }

  /// Newest entries last; includes the previous file if any.
  Future<String> read() async {
    await _writing;
    final f = await _file();
    final old = File('${f.path}.1');
    final b = StringBuffer();
    if (await old.exists()) b.write(await old.readAsString());
    if (await f.exists()) b.write(await f.readAsString());
    return b.toString();
  }

  /// Number of entries in the log.
  Future<int> count() async => '=== '.allMatches(await read()).length;

  /// A copy for sharing.
  Future<File> exportFile() async {
    final out = File(p.join(Directory.systemTemp.path, 'pos-error-log.txt'));
    await out.writeAsString(await read());
    return out;
  }

  Future<void> clear() async {
    await _writing;
    final f = await _file();
    for (final x in [f, File('${f.path}.1')]) {
      if (await x.exists()) await x.delete();
    }
  }
}
