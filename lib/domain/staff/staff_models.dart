/// Staff roles. The owner can always do everything; the others get the
/// permissions set for their role (see [defaultRolePermissions]).
enum StaffRole { owner, manager, cashier, waiter, kitchen }

extension StaffRoleX on StaffRole {
  String get label => switch (this) {
    StaffRole.owner => 'Owner / Admin',
    StaffRole.manager => 'Manager',
    StaffRole.cashier => 'Cashier',
    StaffRole.waiter => 'Waiter / Order taker',
    StaffRole.kitchen => 'Kitchen',
  };

  static StaffRole parse(String s) => StaffRole.values.firstWhere(
    (r) => r.name == s,
    orElse: () => StaffRole.waiter,
  );
}

/// Things a role may or may not do.
enum Permission {
  viewMenu,
  editMenu,
  takeOrders,
  applyDiscount,
  cancelOrder,
  finalizeBill,
  voidBill,
  recordPayment,
  reversePayment,
  viewReports,
  manageShift,
  recordExpense,
  changePrinterSettings,
  changeSettings,
  backupRestore,
  manageStaff,
}

extension PermissionX on Permission {
  String get label => switch (this) {
    Permission.viewMenu => 'View menu',
    Permission.editMenu => 'Edit menu',
    Permission.takeOrders => 'Take orders',
    Permission.applyDiscount => 'Give discounts',
    Permission.cancelOrder => 'Cancel orders and sent items',
    Permission.finalizeBill => 'Make bills',
    Permission.voidBill => 'Void bills',
    Permission.recordPayment => 'Take payments',
    Permission.reversePayment => 'Reverse payments / refunds',
    Permission.viewReports => 'View reports',
    Permission.manageShift => 'Open / close shift, cash in and out',
    Permission.recordExpense => 'Record expenses',
    Permission.changePrinterSettings => 'Change printer settings',
    Permission.changeSettings => 'Change business, billing and table settings',
    Permission.backupRestore => 'Backup and restore',
    Permission.manageStaff => 'Manage staff and permissions',
  };

  /// What the person is trying to do, for "X can't …" messages.
  String get action => switch (this) {
    Permission.viewMenu => 'view the menu',
    Permission.editMenu => 'edit the menu',
    Permission.takeOrders => 'take or change orders',
    Permission.applyDiscount => 'give a discount',
    Permission.cancelOrder => 'cancel orders or sent items',
    Permission.finalizeBill => 'make a bill',
    Permission.voidBill => 'void a bill',
    Permission.recordPayment => 'take a payment',
    Permission.reversePayment => 'reverse a payment',
    Permission.viewReports => 'view reports',
    Permission.manageShift => 'open or close a shift or move cash',
    Permission.recordExpense => 'record an expense',
    Permission.changePrinterSettings => 'change printer settings',
    Permission.changeSettings => 'change settings',
    Permission.backupRestore => 'back up or restore data',
    Permission.manageStaff => 'manage staff',
  };

  static Permission? tryParse(String s) {
    for (final p in Permission.values) {
      if (p.name == s) return p;
    }
    return null;
  }
}

/// Permissions each role starts with. The owner always has all of them and
/// cannot be changed; the others can be changed under Staff > Roles.
const Map<StaffRole, Set<Permission>> defaultRolePermissions = {
  StaffRole.manager: {
    Permission.viewMenu,
    Permission.editMenu,
    Permission.takeOrders,
    Permission.applyDiscount,
    Permission.cancelOrder,
    Permission.finalizeBill,
    Permission.voidBill,
    Permission.recordPayment,
    Permission.reversePayment,
    Permission.viewReports,
    Permission.manageShift,
    Permission.recordExpense,
    Permission.changePrinterSettings,
    Permission.changeSettings,
  },
  StaffRole.cashier: {
    Permission.viewMenu,
    Permission.takeOrders,
    Permission.finalizeBill,
    Permission.recordPayment,
    Permission.manageShift,
    Permission.recordExpense,
  },
  StaffRole.waiter: {Permission.viewMenu, Permission.takeOrders},
  StaffRole.kitchen: {Permission.viewMenu},
};

class StaffUser {
  final String id;
  final String name;
  final StaffRole role;
  final bool active;
  final int failedAttempts;

  /// Local time; no PIN is accepted before it.
  final DateTime? lockedUntil;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const StaffUser({
    required this.id,
    required this.name,
    required this.role,
    required this.active,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.lastLoginAt,
    required this.createdAt,
  });

  bool get isOwner => role == StaffRole.owner;

  bool isLockedAt(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);
}

/// PIN rules: 4 to 8 digits, not all the same digit and not a straight run
/// like 1234 or 9876.
class PinPolicy {
  PinPolicy._();

  static const int minLength = 4;
  static const int maxLength = 8;

  /// Null when [pin] is acceptable, otherwise the reason.
  static String? problem(String pin) {
    if (!RegExp(r'^\d+$').hasMatch(pin)) return 'Use digits only.';
    if (pin.length < minLength || pin.length > maxLength) {
      return 'Use $minLength to $maxLength digits.';
    }
    if (pin.split('').toSet().length == 1) {
      return 'Don\'t use the same digit for the whole PIN.';
    }
    var up = true, down = true;
    for (var i = 1; i < pin.length; i++) {
      final d = pin.codeUnitAt(i) - pin.codeUnitAt(i - 1);
      if (d != 1) up = false;
      if (d != -1) down = false;
    }
    if (up || down) return 'Don\'t use a straight run like 1234.';
    return null;
  }
}

/// Wrong-PIN limits. After [freeAttempts] wrong PINs in a row the account
/// is locked; each further wrong PIN doubles the wait, up to [maxLock].
class PinLockout {
  PinLockout._();

  static const int freeAttempts = 5;
  static const Duration firstLock = Duration(seconds: 30);
  static const Duration maxLock = Duration(minutes: 15);

  /// How long to lock after [failures] wrong PINs in a row (zero: no lock).
  static Duration lockFor(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    final steps = failures - freeAttempts;
    var d = firstLock;
    for (var i = 0; i < steps && d < maxLock; i++) {
      d *= 2;
    }
    return d > maxLock ? maxLock : d;
  }
}

/// Result of checking a PIN.
class PinCheck {
  final StaffUser? user;
  final String? error;

  /// Set when the account is locked.
  final DateTime? lockedUntil;

  const PinCheck.ok(StaffUser this.user) : error = null, lockedUntil = null;
  const PinCheck.failed(this.error, {this.lockedUntil}) : user = null;

  bool get ok => user != null;
}
