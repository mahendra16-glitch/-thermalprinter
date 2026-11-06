import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/features/shifts/shift_screen.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;

  setUp(() {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
  });
  tearDown(() async {
    StorageService.resetForTesting();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('open a shift, then close it short with a reason', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ShiftScreen()));
    await settle(tester);
    expect(find.text('No shift open'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Open shift').first);
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Cash in the drawer now'),
      '1000',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Asha');
    await tester.tap(find.widgetWithText(FilledButton, 'Open shift').last);
    await settle(tester);
    expect(find.text('Expected in drawer'), findsOneWidget);
    expect(find.text('₹1,000.00'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Close shift').first);
    await settle(tester);
    await tester.tap(find.text('Enter total'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Cash counted'),
      '990',
    );
    await tester.pump();
    expect(find.text('Short'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Ravi');

    Future<void> confirmClose() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Close shift').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Close shift').last);
      await settle(tester);
    }

    await confirmClose();
    expect(find.textContaining('Enter a reason'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason for the difference (required)'),
      'Change error',
    );
    await confirmClose();
    expect(find.text('No shift open'), findsOneWidget);

    final shifts = (await tester.runAsync(
      () => storage.shifts.recentShifts(),
    ))!;
    expect(shifts.single.variance, const Money(-1000));
    expect(shifts.single.varianceReason, 'Change error');
  });
}
