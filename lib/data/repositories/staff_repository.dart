import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/errors.dart';
import '../../core/security/pin_hasher.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/staff/staff_models.dart';
import '../../domain/staff/staff_session.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';
import 'settings_repository.dart';

/// Result of setting up the first owner, or of using / renewing the
/// recovery code. [recoveryCode] is shown once and never stored in plain
/// text.
class RecoveryCodeResult {
  final StaffUser owner;
  final String recoveryCode;

  const RecoveryCodeResult(this.owner, this.recoveryCode);
}

/// Local staff accounts, PIN sign-in and role permissions. Works fully
/// offline. PINs and the recovery code are kept only as salted PBKDF2
/// hashes ([PinHasher]).
class StaffRepository {
  final AppDatabase _db;
  final AuditRepository _audit;
  final SettingsRepository _settings;
  final PinHasher _hasher;

  StaffRepository(this._db, this._audit, this._settings, {PinHasher? hasher})
    : _hasher = hasher ?? const PinHasher();

  static const String keyLoginEnabled = 'staff.login_enabled';
  static const String keyRecovery = 'staff.recovery';
  static const String keyRecoveryFailures = 'staff.recovery_failures';
  static const String keyAutoLockMinutes = 'staff.auto_lock_minutes';

  static const int defaultAutoLockMinutes = 10;
  static const List<int> autoLockChoices = [0, 2, 5, 10, 15, 30, 60];

  StaffSession get session => _audit.session;

  // --- Reading -------------------------------------------------------------

  static StaffUser _user(StaffUserRow r) => StaffUser(
    id: r.id,
    name: r.name,
    role: StaffRoleX.parse(r.role),
    active: r.active,
    failedAttempts: r.failedAttempts,
    lockedUntil: r.lockedUntil == null ? null : Clock.toLocal(r.lockedUntil!),
    lastLoginAt: r.lastLoginAt == null ? null : Clock.toLocal(r.lastLoginAt!),
    createdAt: Clock.toLocal(r.createdAt),
  );

  SimpleSelectStatement<$StaffUsersTable, StaffUserRow> _ordered() =>
      _db.select(_db.staffUsers)..orderBy([
        (t) => OrderingTerm.desc(t.active),
        (t) => OrderingTerm.asc(t.name.collate(Collate.noCase)),
      ]);

  Future<List<StaffUser>> all() async =>
      (await _ordered().get()).map(_user).toList();

  Stream<List<StaffUser>> watchAll() =>
      _ordered().watch().map((rows) => rows.map(_user).toList());

  Future<List<StaffUser>> active() async =>
      (await all()).where((u) => u.active).toList();

  Future<StaffUser?> byId(String id) async {
    final r = await (_db.select(
      _db.staffUsers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _user(r);
  }

  Future<bool> hasAnyStaff() async {
    final n = await _db.staffUsers.count().getSingle();
    return n > 0;
  }

  Future<int> _activeOwnerCount() async {
    final n = await _db.staffUsers
        .count(where: (t) => t.active.equals(true) & t.role.equals('owner'))
        .getSingle();
    return n;
  }

  Future<bool> loginEnabled() async =>
      (await _settings.getRaw(keyLoginEnabled)) == 'true' &&
      await _activeOwnerCount() > 0;

  Future<int> autoLockMinutes() async {
    final raw = await _settings.getRaw(keyAutoLockMinutes);
    return int.tryParse(raw ?? '') ?? defaultAutoLockMinutes;
  }

  /// Permissions of every role except the owner (who has all).
  Future<Map<StaffRole, Set<Permission>>> rolePermissions() async {
    final rows = await _db.select(_db.rolePermissions).get();
    final map = {
      for (final r in StaffRole.values)
        if (r != StaffRole.owner) r: <Permission>{},
    };
    for (final row in rows) {
      final role = StaffRole.values.where((r) => r.name == row.role);
      final perm = PermissionX.tryParse(row.permission);
      if (role.isEmpty || perm == null || role.first == StaffRole.owner) {
        continue;
      }
      map[role.first]!.add(perm);
    }
    return map;
  }

  Stream<void> watchRolePermissions() =>
      _db.select(_db.rolePermissions).watch().map((_) {});

  Future<Set<Permission>> permissionsFor(StaffRole role) async {
    if (role == StaffRole.owner) return Permission.values.toSet();
    return (await rolePermissions())[role] ?? {};
  }

  /// Staff who may do [p] and could approve it with their PIN.
  Future<List<StaffUser>> whoCan(Permission p) async {
    final perms = await rolePermissions();
    return (await active())
        .where((u) => u.isOwner || (perms[u.role]?.contains(p) ?? false))
        .toList();
  }

  // --- Session -------------------------------------------------------------

  /// Reads whether login is on and signs everyone out. Call at start-up.
  Future<void> init() async {
    session.apply(enforced: await loginEnabled());
  }

  void _require(Permission p) {
    if (!session.can(p)) {
      final who = session.current?.name ?? 'Nobody signed in';
      throw PermissionDeniedException('$who may not ${p.action}.');
    }
  }

  void _requireOwner() {
    if (session.enforced && !(session.current?.isOwner ?? false)) {
      throw PermissionDeniedException('Only an owner can do this.');
    }
  }

  /// Checks [pin] for [staffId] without signing in (also used to approve a
  /// single action). Wrong PINs count towards the lock-out.
  Future<PinCheck> checkPin(
    String staffId,
    String pin, {
    String purpose = 'sign_in',
  }) async {
    final row = await (_db.select(
      _db.staffUsers,
    )..where((t) => t.id.equals(staffId))).getSingleOrNull();
    if (row == null || !row.active) {
      return const PinCheck.failed('This account is not active.');
    }
    final now = Clock.nowMs();
    if (row.lockedUntil != null && now < row.lockedUntil!) {
      return PinCheck.failed(
        'Too many wrong PINs. Try again later.',
        lockedUntil: Clock.toLocal(row.lockedUntil!),
      );
    }
    final ok = await _hasher.verify(
      pin,
      PinHash(row.pinHash, row.pinSalt, row.pinIterations),
    );
    if (ok) {
      await _db.transaction(() async {
        await (_db.update(
          _db.staffUsers,
        )..where((t) => t.id.equals(staffId))).write(
          StaffUsersCompanion(
            failedAttempts: const Value(0),
            lockedUntil: const Value(null),
            lastLoginAt: purpose == 'sign_in'
                ? Value(now)
                : const Value.absent(),
          ),
        );
      });
      return PinCheck.ok((await byId(staffId))!);
    }
    final failures = row.failedAttempts + 1;
    final lock = PinLockout.lockFor(failures);
    final until = lock == Duration.zero ? null : now + lock.inMilliseconds;
    await _db.transaction(() async {
      await (_db.update(
        _db.staffUsers,
      )..where((t) => t.id.equals(staffId))).write(
        StaffUsersCompanion(
          failedAttempts: Value(failures),
          lockedUntil: Value(until),
        ),
      );
      await _audit.record(
        action: until == null ? 'staff.pin_wrong' : 'staff.locked',
        entity: 'staff_users',
        entityId: staffId,
        staffId: staffId,
        details: {
          'name': row.name,
          'purpose': purpose,
          'failures': failures,
          if (until != null) 'lockedForSeconds': lock.inSeconds,
        },
      );
    });
    if (until != null) {
      return PinCheck.failed(
        'Too many wrong PINs. Locked for ${_duration(lock)}.',
        lockedUntil: Clock.toLocal(until),
      );
    }
    final left = PinLockout.freeAttempts - failures;
    return PinCheck.failed(
      'Wrong PIN. $left more ${left == 1 ? 'try' : 'tries'} before the '
      'account is locked for a while.',
    );
  }

  static String _duration(Duration d) => d.inMinutes >= 1
      ? '${d.inMinutes} min${d.inSeconds % 60 == 0 ? '' : ' ${d.inSeconds % 60} s'}'
      : '${d.inSeconds} s';

  Future<PinCheck> signIn(String staffId, String pin) async {
    final res = await checkPin(staffId, pin);
    if (!res.ok) return res;
    final user = res.user!;
    session.apply(
      enforced: await loginEnabled(),
      user: user,
      permissions: await permissionsFor(user.role),
    );
    await _audit.record(
      action: 'staff.signed_in',
      entity: 'staff_users',
      entityId: user.id,
      staffId: user.id,
      details: {'name': user.name, 'role': user.role.name},
    );
    return res;
  }

  /// [reason]: `manual`, `auto_lock` or `switch_user`.
  Future<void> signOut({String reason = 'manual'}) async {
    final user = session.current;
    if (user != null) {
      await _audit.record(
        action: 'staff.signed_out',
        entity: 'staff_users',
        entityId: user.id,
        staffId: user.id,
        details: {'name': user.name, 'reason': reason},
      );
    }
    session.apply(enforced: await loginEnabled());
  }

  /// Approves one action with someone else's PIN (e.g. a manager allows a
  /// cashier's discount). Returns the approver, or an error.
  Future<PinCheck> approve(
    String approverId,
    String pin,
    Permission p, {
    String? what,
  }) async {
    final res = await checkPin(approverId, pin, purpose: 'approve');
    if (!res.ok) return res;
    final approver = res.user!;
    if (!(await permissionsFor(approver.role)).contains(p)) {
      return PinCheck.failed('${approver.name} may not ${p.action} either.');
    }
    await _audit.record(
      action: 'permission.approved',
      entity: 'staff_users',
      entityId: approver.id,
      details: {
        'permission': p.name,
        'approvedBy': approver.id,
        'approvedByName': approver.name,
        'for': session.current?.id,
        'forName': session.current?.name,
        'what': ?what,
      },
    );
    return res;
  }

  Future<void> _refreshSession() async {
    final current = session.current;
    final enforced = await loginEnabled();
    if (current == null) {
      session.apply(enforced: enforced);
      return;
    }
    final fresh = await byId(current.id);
    if (fresh == null || !fresh.active) {
      session.apply(enforced: enforced);
      return;
    }
    session.apply(
      enforced: enforced,
      user: fresh,
      permissions: await permissionsFor(fresh.role),
    );
  }

  // --- Accounts ------------------------------------------------------------

  String _cleanName(String name) {
    final n = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (n.isEmpty) throw ValidationException('Enter a name.');
    if (n.length > 40) throw ValidationException('Keep the name short.');
    return n;
  }

  Future<void> _checkNameFree(String name, {String? exceptId}) async {
    final rows = await _db.select(_db.staffUsers).get();
    final clash = rows.any(
      (r) => r.id != exceptId && r.name.toLowerCase() == name.toLowerCase(),
    );
    if (clash) {
      throw ValidationException(
        'There is already a staff account called $name. Use another name, '
        'or turn the old account back on.',
      );
    }
  }

  void _checkPin(String pin) {
    final problem = PinPolicy.problem(pin);
    if (problem != null) throw ValidationException(problem);
  }

  Future<String> _storeRecoveryCode() async {
    final code = PinHasher.newRecoveryCode();
    final h = await _hasher.hash(PinHasher.normalizeRecoveryCode(code));
    await _settings.setRaw(keyRecovery, jsonEncode(h.toJson()), audit: false);
    await _settings.setRaw(keyRecoveryFailures, null, audit: false);
    return code;
  }

  /// Makes the first owner account and turns staff login on. Only allowed
  /// while there are no staff accounts at all. The owner is signed in.
  Future<RecoveryCodeResult> setUpOwner({
    required String name,
    required String pin,
  }) async {
    final clean = _cleanName(name);
    _checkPin(pin);
    if (await hasAnyStaff()) {
      throw ValidationException('Staff accounts are already set up.');
    }
    final h = await _hasher.hash(pin);
    final id = newId();
    final now = Clock.nowMs();
    late String code;
    await _db.transaction(() async {
      if (await hasAnyStaff()) {
        throw ValidationException('Staff accounts are already set up.');
      }
      await _db
          .into(_db.staffUsers)
          .insert(
            StaffUsersCompanion.insert(
              id: id,
              name: clean,
              role: StaffRole.owner.name,
              pinHash: h.hash,
              pinSalt: h.salt,
              pinIterations: h.iterations,
              lastLoginAt: Value(now),
              createdAt: now,
              updatedAt: now,
            ),
          );
      code = await _storeRecoveryCode();
      await _settings.setRaw(keyLoginEnabled, 'true', audit: false);
      await _audit.record(
        action: 'staff.setup',
        entity: 'staff_users',
        entityId: id,
        staffId: id,
        details: {'name': clean, 'role': 'owner'},
      );
    });
    final owner = (await byId(id))!;
    session.apply(
      enforced: true,
      user: owner,
      permissions: Permission.values.toSet(),
    );
    return RecoveryCodeResult(owner, code);
  }

  Future<StaffUser> addStaff({
    required String name,
    required StaffRole role,
    required String pin,
  }) async {
    _require(Permission.manageStaff);
    if (role == StaffRole.owner) _requireOwner();
    if (!await hasAnyStaff()) {
      throw ValidationException('Set up the owner account first.');
    }
    final clean = _cleanName(name);
    _checkPin(pin);
    await _checkNameFree(clean);
    final h = await _hasher.hash(pin);
    final id = newId();
    final now = Clock.nowMs();
    await _db.transaction(() async {
      await _checkNameFree(clean);
      await _db
          .into(_db.staffUsers)
          .insert(
            StaffUsersCompanion.insert(
              id: id,
              name: clean,
              role: role.name,
              pinHash: h.hash,
              pinSalt: h.salt,
              pinIterations: h.iterations,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _audit.record(
        action: 'staff.created',
        entity: 'staff_users',
        entityId: id,
        details: {'name': clean, 'role': role.name},
      );
    });
    return (await byId(id))!;
  }

  Future<StaffUserRow> _row(String id) async {
    final r = await (_db.select(
      _db.staffUsers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) throw ValidationException('Staff account not found.');
    return r;
  }

  /// Changes name and/or role. Owner accounts can only be changed by an
  /// owner, and the last active owner cannot stop being an owner.
  Future<void> updateStaff(String id, {String? name, StaffRole? role}) async {
    _require(Permission.manageStaff);
    await _db.transaction(() async {
      final r = await _row(id);
      final before = StaffRoleX.parse(r.role);
      if (before == StaffRole.owner || role == StaffRole.owner) {
        _requireOwner();
      }
      final clean = name == null ? r.name : _cleanName(name);
      if (clean != r.name) await _checkNameFree(clean, exceptId: id);
      final newRole = role ?? before;
      if (before == StaffRole.owner &&
          newRole != StaffRole.owner &&
          r.active &&
          await _activeOwnerCount() <= 1) {
        throw ValidationException(
          'This is the only owner. Make someone else an owner first.',
        );
      }
      if (clean == r.name && newRole == before) return;
      await (_db.update(_db.staffUsers)..where((t) => t.id.equals(id))).write(
        StaffUsersCompanion(
          name: Value(clean),
          role: Value(newRole.name),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: 'staff.updated',
        entity: 'staff_users',
        entityId: id,
        details: {
          if (clean != r.name) 'name': {'from': r.name, 'to': clean},
          if (newRole != before)
            'role': {'from': before.name, 'to': newRole.name},
        },
      );
    });
    await _refreshSession();
  }

  /// Turns an account off or back on. Accounts are never deleted, so old
  /// orders and payments still show who did them.
  Future<void> setActive(String id, bool active, {String reason = ''}) async {
    _require(Permission.manageStaff);
    await _db.transaction(() async {
      final r = await _row(id);
      if (r.active == active) return;
      final role = StaffRoleX.parse(r.role);
      if (role == StaffRole.owner) _requireOwner();
      if (!active &&
          role == StaffRole.owner &&
          await _activeOwnerCount() <= 1) {
        throw ValidationException(
          'This is the only owner and cannot be turned off.',
        );
      }
      await (_db.update(_db.staffUsers)..where((t) => t.id.equals(id))).write(
        StaffUsersCompanion(
          active: Value(active),
          failedAttempts: const Value(0),
          lockedUntil: const Value(null),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: active ? 'staff.reactivated' : 'staff.deactivated',
        entity: 'staff_users',
        entityId: id,
        details: {
          'name': r.name,
          if (reason.trim().isNotEmpty) 'reason': reason,
        },
      );
    });
    await _refreshSession();
  }

  /// Sets a new PIN for someone else (they forgot it). Also unlocks the
  /// account. Owner PINs can only be reset by an owner.
  Future<void> resetPin(String id, String newPin) async {
    _require(Permission.manageStaff);
    _checkPin(newPin);
    final r = await _row(id);
    if (StaffRoleX.parse(r.role) == StaffRole.owner) _requireOwner();
    await _writePin(id, newPin, 'staff.pin_reset', {'name': r.name});
  }

  /// The signed-in person changes their own PIN.
  Future<void> changeOwnPin(String oldPin, String newPin) async {
    final me = session.current;
    if (me == null) throw ValidationException('Sign in first.');
    _checkPin(newPin);
    final check = await checkPin(me.id, oldPin, purpose: 'change_pin');
    if (!check.ok) throw ValidationException(check.error!);
    if (oldPin == newPin) {
      throw ValidationException('The new PIN is the same as the old one.');
    }
    await _writePin(me.id, newPin, 'staff.pin_changed', {'name': me.name});
  }

  Future<void> _writePin(
    String id,
    String pin,
    String action,
    Map<String, Object?> details,
  ) async {
    final h = await _hasher.hash(pin);
    await _db.transaction(() async {
      await (_db.update(_db.staffUsers)..where((t) => t.id.equals(id))).write(
        StaffUsersCompanion(
          pinHash: Value(h.hash),
          pinSalt: Value(h.salt),
          pinIterations: Value(h.iterations),
          failedAttempts: const Value(0),
          lockedUntil: const Value(null),
          updatedAt: Value(Clock.nowMs()),
        ),
      );
      await _audit.record(
        action: action,
        entity: 'staff_users',
        entityId: id,
        details: details,
      );
    });
  }

  // --- Roles and settings --------------------------------------------------

  Future<void> setRolePermission(
    StaffRole role,
    Permission p,
    bool allowed,
  ) async {
    _require(Permission.manageStaff);
    if (role == StaffRole.owner) {
      throw ValidationException('The owner can always do everything.');
    }
    if (p == Permission.manageStaff) _requireOwner();
    await _db.transaction(() async {
      final current = (await rolePermissions())[role]!.contains(p);
      if (current == allowed) return;
      if (allowed) {
        await _db
            .into(_db.rolePermissions)
            .insert(
              RolePermissionsCompanion.insert(
                role: role.name,
                permission: p.name,
                updatedAt: Clock.nowMs(),
              ),
            );
      } else {
        await (_db.delete(_db.rolePermissions)..where(
              (t) => t.role.equals(role.name) & t.permission.equals(p.name),
            ))
            .go();
      }
      await _audit.record(
        action: allowed ? 'role.permission_granted' : 'role.permission_removed',
        entity: 'role_permissions',
        entityId: '${role.name}:${p.name}',
        details: {'role': role.name, 'permission': p.name},
      );
    });
    await _refreshSession();
  }

  /// Puts a role back to its starting permissions.
  Future<void> resetRole(StaffRole role) async {
    for (final p in Permission.values) {
      final want = defaultRolePermissions[role]?.contains(p) ?? false;
      if (p == Permission.manageStaff &&
          session.enforced &&
          !(session.current?.isOwner ?? false)) {
        continue;
      }
      await setRolePermission(role, p, want);
    }
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    _require(Permission.manageStaff);
    await _settings.setRaw(keyAutoLockMinutes, '$minutes');
  }

  /// Turns PIN sign-in off (everyone can do everything, records carry no
  /// staff) or back on. Owner only. Accounts are kept either way.
  Future<void> setLoginEnabled(bool enabled) async {
    _requireOwner();
    if (enabled && await _activeOwnerCount() == 0) {
      throw ValidationException('Set up an owner account first.');
    }
    await _settings.setRaw(keyLoginEnabled, enabled ? 'true' : 'false');
    if (!enabled) {
      session.apply(enforced: false);
    } else {
      await _refreshSession();
    }
  }

  // --- Recovery ------------------------------------------------------------

  /// Gives a new recovery code (the old one stops working). Owner only.
  Future<String> renewRecoveryCode() async {
    _requireOwner();
    final code = await _storeRecoveryCode();
    await _audit.record(
      action: 'staff.recovery_renewed',
      entity: 'staff_users',
    );
    return code;
  }

  /// When every owner has forgotten their PIN: the recovery code given at
  /// set-up sets a new PIN for [ownerId], who then signs in as usual. A new
  /// recovery code is returned; the used one stops working. Wrong codes count
  /// towards a lock-out like PINs do.
  Future<RecoveryCodeResult> recoverOwner({
    required String ownerId,
    required String code,
    required String newPin,
  }) async {
    _checkPin(newPin);
    final r = await _row(ownerId);
    if (StaffRoleX.parse(r.role) != StaffRole.owner || !r.active) {
      throw ValidationException('Pick an active owner account.');
    }
    final raw = await _settings.getRaw(keyRecovery);
    if (raw == null) {
      throw ValidationException('No recovery code is set up on this device.');
    }
    final fails = _RecoveryFailures.parse(
      await _settings.getRaw(keyRecoveryFailures),
    );
    final now = Clock.nowMs();
    if (fails.lockedUntil != null && now < fails.lockedUntil!) {
      throw ValidationException(
        'Too many wrong codes. Try again after '
        '${Clock.toLocal(fails.lockedUntil!).toString().substring(11, 16)}.',
      );
    }
    final ok = await _hasher.verify(
      PinHasher.normalizeRecoveryCode(code),
      PinHash.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );
    if (!ok) {
      final n = fails.count + 1;
      final lock = PinLockout.lockFor(n);
      await _settings.setRaw(
        keyRecoveryFailures,
        jsonEncode({
          'count': n,
          if (lock != Duration.zero) 'lockedUntil': now + lock.inMilliseconds,
        }),
        audit: false,
      );
      await _audit.record(
        action: 'staff.recovery_failed',
        entity: 'staff_users',
        entityId: ownerId,
        details: {'failures': n},
      );
      throw ValidationException('That recovery code is not right.');
    }
    await _writePin(ownerId, newPin, 'staff.recovered', {'name': r.name});
    final newCode = await _storeRecoveryCode();
    return RecoveryCodeResult((await byId(ownerId))!, newCode);
  }
}

class _RecoveryFailures {
  final int count;
  final int? lockedUntil;

  const _RecoveryFailures(this.count, this.lockedUntil);

  static _RecoveryFailures parse(String? raw) {
    if (raw == null) return const _RecoveryFailures(0, null);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return _RecoveryFailures(
      (j['count'] as int?) ?? 0,
      j['lockedUntil'] as int?,
    );
  }
}
