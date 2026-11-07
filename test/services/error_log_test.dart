import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/services/error_log.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_errlog');
    ErrorLog.instance.directory = tmp;
    await ErrorLog.instance.clear();
  });
  tearDown(() => tmp.delete(recursive: true));

  test('records, reads, rotates and clears', () async {
    final log = ErrorLog.instance;
    expect(await log.count(), 0);
    await log.record(StateError('printer gone'), StackTrace.current);
    await log.record('second', null, source: 'startup');
    final text = await log.read();
    expect(text, contains('Bad state: printer gone'));
    expect(text, contains('[startup]'));
    expect(await log.count(), 2);

    // Past the size limit the file rolls over; both parts are still read.
    final big = 'x' * 1024;
    for (var i = 0; i < 300; i++) {
      await log.record(big, null);
    }
    expect(File('${tmp.path}/errors.log.1').existsSync(), isTrue);
    expect(await log.count(), greaterThan(200));
    expect((await log.exportFile()).lengthSync(), greaterThan(0));

    await log.clear();
    expect(await log.count(), 0);
  });
}
