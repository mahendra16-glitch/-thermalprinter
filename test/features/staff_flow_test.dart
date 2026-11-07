import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/domain/staff/staff_models.dart';
import 'package:thermalprinter/features/staff/permission_guard.dart';
import 'package:thermalprinter/features/staff/staff_gate.dart';
import 'package:thermalprinter/features/staff/staff_screen.dart';
import 'package:thermalprinter/screens/main_navigation_screen.dart';
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

  Future<void> typePin(WidgetTester tester, String pin, String submit) async {
    for (final d in pin.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, d).last);
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(FilledButton, submit).last);
    await settle(tester);
  }

  /// Unmounts the app so its database streams close before tearDown.
  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  }

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('set up the owner, see the recovery code once', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: StaffScreen()));
    await settle(tester);
    expect(find.text('Staff accounts are off'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Meera');
    await tester.tap(find.text('Set up owner account'));
    await settle(tester);
    await typePin(tester, '1111', 'Next');
    expect(find.textContaining('same digit'), findsOneWidget);
    await typePin(tester, '4826', 'Next');
    await typePin(tester, '4825', 'Save');
    expect(find.textContaining('were different'), findsOneWidget);
    await typePin(tester, '4826', 'Next');
    await typePin(tester, '4826', 'Save');

    expect(find.text('Owner recovery code'), findsWidgets);
    expect(find.textContaining('will not be shown again'), findsOneWidget);
    await tester.tap(find.text('I have written it down'));
    await settle(tester);

    expect(find.text('Meera (you)'), findsOneWidget);
    expect(find.text('PIN sign-in'), findsOneWidget);
    expect(storage.session.enforced, isTrue);
    expect(storage.session.current?.name, 'Meera');
    await done(tester);
  });

  testWidgets('locked app shows sign-in; wrong then right PIN', (tester) async {
    bigScreen(tester);
    await tester.runAsync(() async {
      await storage.staff.setUpOwner(name: 'Meera', pin: '4826');
      await storage.staff.addStaff(
        name: 'Ravi',
        role: StaffRole.waiter,
        pin: '2468',
      );
      await storage.staff.signOut();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => StaffGate(child: child!),
        home: const Scaffold(body: Text('THE APP')),
      ),
    );
    await settle(tester);
    expect(find.text('Who is using the app?'), findsOneWidget);
    expect(find.text('THE APP', skipOffstage: true), findsNothing);

    await tester.tap(find.text('Ravi'));
    await settle(tester);
    await typePin(tester, '9999', 'Sign in');
    expect(find.textContaining('Wrong PIN. 4 more tries'), findsOneWidget);
    await typePin(tester, '2468', 'Sign in');
    expect(find.text('THE APP'), findsOneWidget);
    expect(storage.session.current?.name, 'Ravi');

    await tester.runAsync(() => storage.staff.signOut());
    await settle(tester);
    expect(find.text('Who is using the app?'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a waiter needs approval for a discount', (tester) async {
    bigScreen(tester);
    await tester.runAsync(() async {
      await storage.staff.setUpOwner(name: 'Meera', pin: '4826');
      final w = await storage.staff.addStaff(
        name: 'Ravi',
        role: StaffRole.waiter,
        pin: '2468',
      );
      await storage.staff.signIn(w.id, '2468');
    });
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await allow(context, Permission.applyDiscount),
              child: const Text('Discount'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Discount'));
    await settle(tester);
    expect(find.text('Approval needed'), findsOneWidget);
    expect(
      find.textContaining('Ravi (Waiter / Order taker) may not give'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(result, isFalse);

    await tester.tap(find.text('Discount'));
    await settle(tester);
    await tester.tap(find.text('Meera'));
    await settle(tester);
    await typePin(tester, '0000', 'Allow');
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
    await typePin(tester, '4826', 'Allow');
    expect(result, isTrue);
    expect(find.text('Approval needed'), findsNothing);
    final rows = await tester.runAsync(() => db.select(db.auditLog).get());
    expect(rows!.map((r) => r.action), contains('permission.approved'));
    await done(tester);
  });

  testWidgets('tabs follow the role', (tester) async {
    bigScreen(tester);
    late StaffUser waiter;
    await tester.runAsync(() async {
      await storage.staff.setUpOwner(name: 'Meera', pin: '4826');
      waiter = await storage.staff.addStaff(
        name: 'Ravi',
        role: StaffRole.waiter,
        pin: '2468',
      );
      await storage.staff.signIn(waiter.id, '2468');
    });
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
    await settle(tester);
    final bar = find.byType(NavigationBar);
    expect(
      find.descendant(of: bar, matching: find.text('Tables')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('Menu')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('Reports')),
      findsNothing,
    );
    expect(
      find.descendant(of: bar, matching: find.text('Shift')),
      findsNothing,
    );
    expect(find.text('Ravi · Waiter / Order taker'), findsOneWidget);

    final owner = (await tester.runAsync(() => storage.staff.active()))!
        .firstWhere((u) => u.isOwner);
    await tester.runAsync(() => storage.staff.signIn(owner.id, '4826'));
    await settle(tester);
    expect(
      find.descendant(of: bar, matching: find.text('Reports')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.text('Shift')),
      findsOneWidget,
    );
    await done(tester);
  });
}
