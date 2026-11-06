import '../../core/util/money.dart';

enum ShiftStatus { open, closed }

enum CashMovementKind { addition, withdrawal }

extension CashMovementKindX on CashMovementKind {
  String get label =>
      this == CashMovementKind.addition ? 'Cash added' : 'Cash taken out';

  static CashMovementKind parse(String? s) => s == 'withdrawal'
      ? CashMovementKind.withdrawal
      : CashMovementKind.addition;
}

/// Where an expense was paid from. Only [cash] comes out of the drawer.
enum ExpenseSource { cash, upi, card, bank, other }

extension ExpenseSourceX on ExpenseSource {
  String get label => switch (this) {
    ExpenseSource.cash => 'Cash (drawer)',
    ExpenseSource.upi => 'UPI',
    ExpenseSource.card => 'Card',
    ExpenseSource.bank => 'Bank transfer',
    ExpenseSource.other => 'Other',
  };

  static ExpenseSource parse(String? s) =>
      ExpenseSource.values.where((e) => e.name == s).firstOrNull ??
      ExpenseSource.other;
}

/// Suggested expense categories; any text is allowed.
const defaultExpenseCategories = [
  'Vegetables',
  'Groceries',
  'Dairy',
  'Meat & fish',
  'Gas',
  'Staff advance',
  'Salary',
  'Rent',
  'Electricity',
  'Repairs',
  'Cleaning',
  'Packaging',
  'Transport',
  'Other',
];

/// Indian notes and coins, in paise, largest first.
const denominations = [50000, 20000, 10000, 5000, 2000, 1000, 500, 200, 100];

Money countDenominations(Map<int, int> counts) =>
    Money(counts.entries.fold(0, (s, e) => s + e.key * e.value));

class CashShift {
  final String id;
  final ShiftStatus status;
  final String businessDate;
  final Money openingCash;
  final String openedBy;
  final String openNote;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String closedBy;
  final Money? countedCash;
  final Money? expectedCash;
  final Money? variance;
  final String varianceReason;
  final String closeNote;

  const CashShift({
    required this.id,
    required this.status,
    required this.businessDate,
    required this.openingCash,
    required this.openedBy,
    this.openNote = '',
    required this.openedAt,
    this.closedAt,
    this.closedBy = '',
    this.countedCash,
    this.expectedCash,
    this.variance,
    this.varianceReason = '',
    this.closeNote = '',
  });

  bool get isOpen => status == ShiftStatus.open;
}

class CashMovement {
  final String id;
  final String shiftId;
  final CashMovementKind kind;
  final Money amount;
  final String reason;
  final String staffName;
  final DateTime createdAt;
  final DateTime? voidedAt;
  final String voidReason;

  const CashMovement({
    required this.id,
    required this.shiftId,
    required this.kind,
    required this.amount,
    required this.reason,
    this.staffName = '',
    required this.createdAt,
    this.voidedAt,
    this.voidReason = '',
  });

  bool get isVoided => voidedAt != null;
}

class Expense {
  final String id;
  final String? shiftId;
  final String category;
  final Money amount;
  final ExpenseSource paidFrom;
  final String note;
  final String staffName;
  final String businessDate;
  final DateTime createdAt;
  final DateTime? voidedAt;
  final String voidReason;

  const Expense({
    required this.id,
    this.shiftId,
    required this.category,
    required this.amount,
    required this.paidFrom,
    this.note = '',
    this.staffName = '',
    required this.businessDate,
    required this.createdAt,
    this.voidedAt,
    this.voidReason = '',
  });

  bool get isVoided => voidedAt != null;
}

/// Everything that moved through a shift, and the expected cash.
///
/// Expected cash = opening + cash sales − cash refunds + cash added
/// − cash taken out − cash expenses. UPI, card and other payments are
/// listed separately and never count as drawer cash.
class ShiftSummary {
  final Money openingCash;
  final Money cashSales;
  final Money cashRefunds;
  final Money cashAdded;
  final Money cashTakenOut;
  final Money cashExpenses;

  /// Net non-cash collections by method label (e.g. "UPI").
  final Map<String, Money> nonCash;

  /// Expenses paid from outside the drawer during the shift.
  final Money otherExpenses;
  final int paymentCount;
  final int billCount;

  const ShiftSummary({
    required this.openingCash,
    required this.cashSales,
    required this.cashRefunds,
    required this.cashAdded,
    required this.cashTakenOut,
    required this.cashExpenses,
    this.nonCash = const {},
    this.otherExpenses = Money.zero,
    this.paymentCount = 0,
    this.billCount = 0,
  });

  Money get expectedCash =>
      openingCash +
      cashSales -
      cashRefunds +
      cashAdded -
      cashTakenOut -
      cashExpenses;

  Money get nonCashTotal => nonCash.values.fold(Money.zero, (s, m) => s + m);

  /// Net collected in the shift, all methods.
  Money get netCollected => cashSales - cashRefunds + nonCashTotal;

  Map<String, Object?> toJson() => {
    'openingCash': openingCash.paise,
    'cashSales': cashSales.paise,
    'cashRefunds': cashRefunds.paise,
    'cashAdded': cashAdded.paise,
    'cashTakenOut': cashTakenOut.paise,
    'cashExpenses': cashExpenses.paise,
    'nonCash': {for (final e in nonCash.entries) e.key: e.value.paise},
    'otherExpenses': otherExpenses.paise,
    'paymentCount': paymentCount,
    'billCount': billCount,
    'expectedCash': expectedCash.paise,
  };

  factory ShiftSummary.fromJson(Map<String, dynamic> j) {
    Money m(String k) => Money((j[k] as num?)?.toInt() ?? 0);
    return ShiftSummary(
      openingCash: m('openingCash'),
      cashSales: m('cashSales'),
      cashRefunds: m('cashRefunds'),
      cashAdded: m('cashAdded'),
      cashTakenOut: m('cashTakenOut'),
      cashExpenses: m('cashExpenses'),
      nonCash: {
        for (final e in ((j['nonCash'] as Map?) ?? const {}).entries)
          e.key as String: Money((e.value as num).toInt()),
      },
      otherExpenses: m('otherExpenses'),
      paymentCount: (j['paymentCount'] as num?)?.toInt() ?? 0,
      billCount: (j['billCount'] as num?)?.toInt() ?? 0,
    );
  }
}
