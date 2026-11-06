import '../../core/util/money.dart';

enum PaymentMethod { cash, upi, card, other }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.upi => 'UPI',
    PaymentMethod.card => 'Card',
    PaymentMethod.other => 'Other',
  };

  /// The app cannot check these with a bank: staff confirm they arrived.
  bool get needsStaffConfirmation => this != PaymentMethod.cash;

  static PaymentMethod parse(String? s) =>
      PaymentMethod.values.where((e) => e.name == s).firstOrNull ??
      PaymentMethod.other;
}

enum PaymentKind { payment, reversal }

/// Bill payment status, always derived from the ledger.
enum PaymentStatus { unpaid, partlyPaid, paid }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.unpaid => 'Unpaid',
    PaymentStatus.partlyPaid => 'Part paid',
    PaymentStatus.paid => 'Paid',
  };
}

/// `confirmation` value for UPI, card and other: staff checked, not the bank.
const String staffConfirmed = 'staffConfirmed';

/// One immutable ledger entry.
class LedgerEntry {
  final String id;
  final String billId;
  final String orderId;
  final PaymentKind kind;
  final PaymentMethod method;
  final String methodName;
  final Money amount;
  final Money? tendered;
  final Money? change;
  final String reference;
  final String confirmation;
  final String? reversesPaymentId;
  final String reason;
  final String staffName;
  final String businessDate;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.billId,
    required this.orderId,
    required this.kind,
    required this.method,
    this.methodName = '',
    required this.amount,
    this.tendered,
    this.change,
    this.reference = '',
    this.confirmation = '',
    this.reversesPaymentId,
    this.reason = '',
    this.staffName = '',
    required this.businessDate,
    required this.createdAt,
  });

  bool get isReversal => kind == PaymentKind.reversal;

  /// + for a payment, − for a reversal.
  Money get signedAmount => isReversal ? -amount : amount;

  /// "Cash", "UPI", "Other (Swiggy)".
  String get methodLabel =>
      method == PaymentMethod.other && methodName.isNotEmpty
      ? methodName
      : method.label;
}

/// What a bill has received, from its ledger entries.
class BillPaymentSummary {
  final Money total;
  final List<LedgerEntry> entries;

  const BillPaymentSummary(this.total, this.entries);

  Money get paid => entries.fold(Money.zero, (s, e) => s + e.signedAmount);

  Money get balance => total - paid;

  PaymentStatus get status => paid.paise <= 0
      ? PaymentStatus.unpaid
      : paid.paise < total.paise
      ? PaymentStatus.partlyPaid
      : PaymentStatus.paid;

  /// Payment ids that have been reversed.
  Set<String> get reversedIds => {
    for (final e in entries)
      if (e.reversesPaymentId != null) e.reversesPaymentId!,
  };

  /// Payments that still count (not reversed).
  List<LedgerEntry> get livePayments => entries
      .where((e) => !e.isReversal && !reversedIds.contains(e.id))
      .toList();
}

/// Net amount per method (payments minus reversals) for a set of entries.
Map<String, Money> netByMethod(Iterable<LedgerEntry> entries) {
  final out = <String, Money>{};
  for (final e in entries) {
    out[e.methodLabel] = (out[e.methodLabel] ?? Money.zero) + e.signedAmount;
  }
  return out;
}

/// A UPI "pay" link for a QR code. Scanning it only fills in the customer's
/// UPI app; it proves nothing about payment.
String upiPayLink({
  required String upiId,
  required String payeeName,
  required Money amount,
  required String note,
}) {
  final rupees =
      '${amount.paise ~/ 100}.${(amount.paise % 100).toString().padLeft(2, '0')}';
  final q = {
    'pa': upiId.trim(),
    if (payeeName.trim().isNotEmpty) 'pn': payeeName.trim(),
    'am': rupees,
    'cu': 'INR',
    if (note.isNotEmpty) 'tn': note,
  };
  return 'upi://pay?${q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
}
