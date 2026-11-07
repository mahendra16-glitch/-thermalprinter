import 'package:flutter/foundation.dart';

import '../../core/util/clock.dart';
import 'staff_models.dart';

/// Who is using the app right now, and what they may do.
///
/// Staff login is **off** until the first owner account is made: then
/// [enforced] is false, [can] allows everything and records carry no staff
/// id (as before Phase 9). Once it is on, nothing is allowed until someone
/// signs in with their PIN.
class StaffSession extends ChangeNotifier {
  bool _enforced = false;
  StaffUser? _current;
  Set<Permission> _permissions = const {};
  DateTime _lastActivity = Clock.now();

  bool get enforced => _enforced;
  StaffUser? get current => _current;

  /// True when login is on and nobody is signed in.
  bool get locked => _enforced && _current == null;

  DateTime get lastActivity => _lastActivity;

  /// Whether the signed-in person may do [p]. Always true while staff login
  /// is off.
  bool can(Permission p) {
    if (!_enforced) return true;
    if (_current == null) return false;
    return _current!.isOwner || _permissions.contains(p);
  }

  /// Id written on records and audit rows (null while login is off).
  String? get staffId => _enforced ? _current?.id : null;

  /// Name written on records; empty while login is off.
  String get staffName => _enforced ? (_current?.name ?? '') : '';

  void touch() => _lastActivity = Clock.now();

  /// Called by the staff repository only.
  void apply({
    required bool enforced,
    StaffUser? user,
    Set<Permission> permissions = const {},
  }) {
    _enforced = enforced;
    _current = enforced ? user : null;
    _permissions = enforced ? Set.unmodifiable(permissions) : const {};
    _lastActivity = Clock.now();
    notifyListeners();
  }
}
