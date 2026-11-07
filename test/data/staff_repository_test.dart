import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/errors.dart';
import 'package:thermalprinter/core/security/pin_hasher.dart';
import 'package:thermalprinter/core/util/clock.dart';
import 'package:thermalprinter/core/util/money.dart';
import 'package:thermalprinter/data/db/app_database.dart';
import 'package:thermalprinter/data/repositories/order_repository.dart';
import 'package:thermalprinter/data/repositories/payment_repository.dart';
import 'package:thermalprinter/data/repositories/staff_repository.dart';
import 'package:thermalprinter/domain/menu/item_configuration.dart';
import 'package:thermalprinter/domain/menu/menu_models.dart';
import 'package:thermalprinter/domain/orders/order_models.dart';
import 'package:thermalprinter/domain/payments/payment_models.dart';
import 'package:thermalprinter/domain/reports/report_models.dart';
import 'package:thermalprinter/domain/staff/staff_models.dart';
import 'package:thermalprinter/services/storage_service.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;
  late StaffRepository staff;
  var n = 0;
  String rid() => 'req${n++}';

  Matcher rejects(String text) => throwsA(
    isA<ValidationException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  setUp(() {
    db = openTestDatabase();
    storage = StorageService.forTesting(db);
    staff = storage.staff;
  });
  tearDown(() async {
    Clock.now = DateTime.now;
    StorageService.resetForTesting();
    await db.close();
  });

  Future<List<String>> auditActions() async =>
      (await db.select(db.auditLog).get()).map((r) => r.action).toList();

  group('PIN rules and hashing', () {
    test('PIN policy', () {
      expect(PinPolicy.problem('2580'), isNull);
      expect(PinPolicy.problem('13579135'), isNull);
      expect(PinPolicy.problem('123'), contains('4 to 8'));
      expect(PinPolicy.problem('123456789'), contains('4 to 8'));
      expect(PinPolicy.problem('12a4'), contains('digits'));
      expect(PinPolicy.problem('1111'), contains('same digit'));
      expect(PinPolicy.problem('1234'), contains('straight run'));
      expect(PinPolicy.problem('9876'), contains('straight run'));
    });

    test('hash is salted, verifies, and rejects a wrong PIN', () async {
      const h = PinHasher(iterations: 1000, useIsolate: false);
      final a = await h.hash('2580');
      final b = await h.hash('2580');
      expect(a.hash, isNot(b.hash), reason: 'random salt');
      expect(a.hash, isNot(contains('2580')));
      expect(await h.verify('2580', a), isTrue);
      expect(await h.verify('2581', a), isFalse);
    });

    test('default hasher runs on an isolate', () async {
      const h = PinHasher(iterations: 2000);
      final a = await h.hash('4826');
      expect(await h.verify('4826', a), isTrue);
    });

    test('lock-out grows and is capped', () {
      expect(PinLockout.lockFor(4), Duration.zero);
      expect(PinLockout.lockFor(5), const Duration(seconds: 30));
      expect(PinLockout.lockFor(6), const Duration(minutes: 1));
      expect(PinLockout.lockFor(50), PinLockout.maxLock);
    });

    test('recovery code format', () {
      final c = PinHasher.newRecoveryCode();
      expect(c, matches(RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
      expect(
        PinHasher.normalizeRecoveryCode(' abcd-efgh jkl2 '),
        'ABCDEFGHJKL2',
      );
    });
  });

  test('login is off until the first owner is set up', () async {
    await staff.init();
    expect(storage.session.enforced, isFalse);
    expect(storage.session.can(Permission.manageStaff), isTrue);
    expect(
      () => staff.addStaff(name: 'Ravi', role: StaffRole.waiter, pin: '2580'),
      rejects('owner account first'),
    );

    final res = await staff.setUpOwner(name: ' Meera ', pin: '4826');
    expect(res.owner.name, 'Meera');
    expect(res.owner.role, StaffRole.owner);
    expect(res.recoveryCode, hasLength(14));
    expect(storage.session.enforced, isTrue);
    expect(storage.session.current?.id, res.owner.id);
    expect(storage.session.can(Permission.manageStaff), isTrue);

    final row = await db.select(db.staffUsers).getSingle();
    expect(row.pinHash, isNot(contains('4826')));
    expect(row.pinSalt, isNotEmpty);
    final settings = await db.select(db.appSettings).get();
    expect(
      settings.map((s) => s.value).join(),
      isNot(contains(res.recoveryCode.replaceAll('-', ''))),
      reason: 'recovery code is stored hashed only',
    );
    expect(
      () => staff.setUpOwner(name: 'Other', pin: '4826'),
      rejects('already set up'),
    );
    expect(await auditActions(), contains('staff.setup'));
  });

  test('sign in, roles and permissions', () async {
    final owner = (await staff.setUpOwner(name: 'Meera', pin: '4826')).owner;
    final cashier = await staff.addStaff(
      name: 'Asha',
      role: StaffRole.cashier,
      pin: '1357',
    );
    final waiter = await staff.addStaff(
      name: 'Ravi',
      role: StaffRole.waiter,
      pin: '2468',
    );
    expect(
      () => staff.addStaff(name: 'asha', role: StaffRole.waiter, pin: '9753'),
      rejects('already a staff account called asha'),
    );
    expect(
      () => staff.addStaff(name: 'Kiran', role: StaffRole.waiter, pin: '1234'),
      rejects('straight run'),
    );

    await staff.signOut();
    expect(storage.session.locked, isTrue);
    expect(storage.session.can(Permission.takeOrders), isFalse);

    final res = await staff.signIn(waiter.id, '2468');
    expect(res.ok, isTrue);
    expect(storage.session.can(Permission.takeOrders), isTrue);
    expect(storage.session.can(Permission.applyDiscount), isFalse);
    expect(storage.session.can(Permission.viewReports), isFalse);
    expect(
      () => staff.addStaff(name: 'X', role: StaffRole.waiter, pin: '9753'),
      throwsA(isA<PermissionDeniedException>()),
    );

    await staff.signIn(cashier.id, '1357');
    expect(storage.session.current?.name, 'Asha');
    expect(storage.session.can(Permission.recordPayment), isTrue);
    expect(storage.session.can(Permission.reversePayment), isFalse);

    // Manager-style approval: the owner allows one reversal.
    expect(
      (await staff.approve(waiter.id, '2468', Permission.reversePayment)).error,
      contains('may not'),
    );
    final ok = await staff.approve(owner.id, '4826', Permission.reversePayment);
    expect(ok.ok, isTrue);
    expect(storage.session.current?.name, 'Asha', reason: 'still Asha');
    final approved = (await db.select(db.auditLog).get()).lastWhere(
      (r) => r.action == 'permission.approved',
    );
    expect(approved.staffId, cashier.id);
    expect(approved.detailsJson, contains(owner.id));

    // The owner changes what cashiers may do; Asha's session follows.
    await staff.signIn(owner.id, '4826');
    await staff.setRolePermission(
      StaffRole.cashier,
      Permission.reversePayment,
      true,
    );
    expect(
      () => staff.setRolePermission(
        StaffRole.owner,
        Permission.viewReports,
        false,
      ),
      rejects('always do everything'),
    );
    await staff.signIn(cashier.id, '1357');
    expect(storage.session.can(Permission.reversePayment), isTrue);
    await staff.signIn(owner.id, '4826');
    await staff.resetRole(StaffRole.cashier);
    expect(
      (await staff.permissionsFor(StaffRole.cashier)),
      defaultRolePermissions[StaffRole.cashier],
    );
  });

  test('wrong PINs lock the account; a reset unlocks it', () async {
    final start = DateTime(2026, 11, 7, 12);
    Clock.now = () => start;
    await staff.setUpOwner(name: 'Meera', pin: '4826');
    final w = await staff.addStaff(
      name: 'Ravi',
      role: StaffRole.waiter,
      pin: '2468',
    );
    await staff.signOut();
    for (var i = 1; i < PinLockout.freeAttempts; i++) {
      final r = await staff.signIn(w.id, '0000');
      expect(r.ok, isFalse);
      expect(r.error, contains('Wrong PIN'));
    }
    final locked = await staff.signIn(w.id, '0000');
    expect(locked.error, contains('Locked for 30 s'));
    // Even the right PIN is refused while locked.
    final refused = await staff.signIn(w.id, '2468');
    expect(refused.ok, isFalse);
    expect(refused.lockedUntil, isNotNull);

    Clock.now = () => start.add(const Duration(seconds: 31));
    expect((await staff.signIn(w.id, '0000')).error, contains('1 min'));
    Clock.now = () => start.add(const Duration(minutes: 5));
    expect((await staff.signIn(w.id, '2468')).ok, isTrue);
    expect((await staff.byId(w.id))!.failedAttempts, 0);

    final actions = await auditActions();
    expect(actions, contains('staff.pin_wrong'));
    expect(actions, contains('staff.locked'));
    expect(actions, contains('staff.signed_in'));

    // Locked again, then the owner sets a new PIN, which also unlocks.
    await staff.signOut();
    for (var i = 0; i < PinLockout.freeAttempts; i++) {
      await staff.signIn(w.id, '0000');
    }
    final owner = (await staff.active()).firstWhere((u) => u.isOwner);
    await staff.signIn(owner.id, '4826');
    await staff.resetPin(w.id, '8642');
    expect((await staff.signIn(w.id, '8642')).ok, isTrue);
  });

  test('the last owner cannot be removed or demoted', () async {
    final owner = (await staff.setUpOwner(name: 'Meera', pin: '4826')).owner;
    expect(() => staff.setActive(owner.id, false), rejects('only owner'));
    expect(
      () => staff.updateStaff(owner.id, role: StaffRole.manager),
      rejects('only owner'),
    );
    final m = await staff.addStaff(
      name: 'Dev',
      role: StaffRole.manager,
      pin: '1593',
    );
    await staff.setRolePermission(
      StaffRole.manager,
      Permission.manageStaff,
      true,
    );
    await staff.signIn(m.id, '1593');
    // A manager with Manage staff still cannot touch owner accounts.
    expect(() => staff.resetPin(owner.id, '7531'), rejects('Only an owner'));
    expect(
      () => staff.addStaff(name: 'Boss', role: StaffRole.owner, pin: '7531'),
      rejects('Only an owner'),
    );
    final w = await staff.addStaff(
      name: 'Ravi',
      role: StaffRole.waiter,
      pin: '2468',
    );
    await staff.setActive(w.id, false, reason: 'left the job');
    expect((await staff.signIn(w.id, '2468')).error, contains('not active'));
    expect((await staff.whoCan(Permission.manageStaff)).map((u) => u.name), [
      'Dev',
      'Meera',
    ]);
    // Accounts are never deleted.
    expect(await db.select(db.staffUsers).get(), hasLength(3));
  });

  test('changing my PIN needs the old one', () async {
    await staff.setUpOwner(name: 'Meera', pin: '4826');
    expect(() => staff.changeOwnPin('0000', '7531'), rejects('Wrong PIN'));
    await staff.changeOwnPin('4826', '7531');
    final me = storage.session.current!;
    await staff.signOut();
    expect((await staff.signIn(me.id, '4826')).ok, isFalse);
    expect((await staff.signIn(me.id, '7531')).ok, isTrue);
  });

  test('owner recovery code sets a new PIN once', () async {
    final res = await staff.setUpOwner(name: 'Meera', pin: '4826');
    await staff.signOut();
    expect(
      () => staff.recoverOwner(
        ownerId: res.owner.id,
        code: 'AAAA-BBBB-CCCC',
        newPin: '7531',
      ),
      rejects('not right'),
    );
    final again = await staff.recoverOwner(
      ownerId: res.owner.id,
      code: res.recoveryCode.toLowerCase(),
      newPin: '7531',
    );
    expect(again.recoveryCode, isNot(res.recoveryCode));
    expect(storage.session.locked, isTrue, reason: 'signs in as usual after');
    expect((await staff.signIn(res.owner.id, '7531')).ok, isTrue);
    await staff.signOut();
    expect(
      () => staff.recoverOwner(
        ownerId: res.owner.id,
        code: res.recoveryCode,
        newPin: '9517',
      ),
      rejects('not right'),
      reason: 'the used code stops working',
    );
    expect(await auditActions(), contains('staff.recovered'));
  });

  test('turning login off keeps accounts and allows everything', () async {
    await staff.setUpOwner(name: 'Meera', pin: '4826');
    await staff.setLoginEnabled(false);
    expect(storage.session.enforced, isFalse);
    expect(storage.session.can(Permission.reversePayment), isTrue);
    await staff.init();
    expect(storage.session.enforced, isFalse);
    expect(await staff.all(), hasLength(1));
  });

  test('records and audit rows carry the signed-in staff member', () async {
    final owner = (await staff.setUpOwner(name: 'Meera', pin: '4826')).owner;
    final cashier = await staff.addStaff(
      name: 'Asha',
      role: StaffRole.cashier,
      pin: '1357',
    );
    await staff.signIn(cashier.id, '1357');

    const thali = MenuItem(
      id: 'thali',
      categoryId: 'c',
      name: 'Thali',
      basePrice: Money(20000),
    );
    await storage.menu.saveCategory(const MenuCategory(id: 'c', name: 'All'));
    await storage.menu.saveItem(thali);
    final orderId = await storage.orders.createOrder(
      NewOrderRequest(clientRequestId: rid(), type: OrderType.takeaway),
    );
    await storage.orders.addItem(
      orderId,
      configureItem(item: thali, groups: const {}, selected: const {}),
    );
    final billId = await storage.bills.finalize(
      orderId,
      clientRequestId: rid(),
      allowUnsent: true,
      print: false,
    );
    final shiftId = await storage.shifts.open(
      openingCash: const Money(10000),
      staffName: 'typed name is ignored',
      clientRequestId: rid(),
    );
    await storage.payments.record(
      PaymentRequest(
        billId: billId,
        method: PaymentMethod.cash,
        amount: const Money(20000),
        clientRequestId: rid(),
      ),
    );

    final order = await (db.select(
      db.orders,
    )..where((t) => t.id.equals(orderId))).getSingle();
    expect(order.staffId, cashier.id);
    expect(order.staffName, 'Asha');
    final bill = await (db.select(
      db.bills,
    )..where((t) => t.id.equals(billId))).getSingle();
    expect(bill.staffName, 'Asha');
    final pay = await db.select(db.payments).getSingle();
    expect(pay.staffId, cashier.id);
    expect(pay.staffName, 'Asha');
    final shift = await (db.select(
      db.cashShifts,
    )..where((t) => t.id.equals(shiftId))).getSingle();
    expect(shift.openedBy, 'Asha');
    expect(shift.openedById, cashier.id);

    final audit = await db.select(db.auditLog).get();
    final created = audit.firstWhere((r) => r.action == 'order.created');
    expect(created.staffId, cashier.id);
    final setup = audit.firstWhere((r) => r.action == 'staff.setup');
    expect(setup.staffId, owner.id);

    // Reports group sales by the signed-in staff name.
    final report = await storage.reports.build(
      ReportPeriod.day(await storage.orders.currentBusinessDate()),
    );
    expect(report.byStaff.single.label, 'Asha');
  });
}
