/// An amount of Indian Rupees stored as integer paise.
///
/// Never use `double` for stored money: 0.1 + 0.2 != 0.3. Convert at the edge
/// (user input, display) with [Money.parse] and [Money.format].
class Money implements Comparable<Money> {
  final int paise;

  const Money(this.paise);

  static const Money zero = Money(0);

  factory Money.rupees(int rupees) => Money(rupees * 100);

  /// Parses user input such as `"500"`, `"1,234.5"`, `"₹ 12.05"`.
  /// Returns null when the text is not a valid amount with at most 2 decimals.
  static Money? parse(String input) {
    var s = input.trim().replaceAll(',', '').replaceAll('₹', '').trim();
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('-')) {
      negative = true;
      s = s.substring(1).trim();
    }
    final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(s);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final frac = (match.group(2) ?? '').padRight(2, '0');
    final paise = whole * 100 + (frac.isEmpty ? 0 : int.parse(frac));
    return Money(negative ? -paise : paise);
  }

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator -() => Money(-paise);
  Money operator *(int factor) => Money(paise * factor);

  bool get isNegative => paise < 0;
  bool get isZero => paise == 0;

  /// Formats with Indian digit grouping, e.g. `₹1,23,456.78`.
  String format({bool symbol = true}) {
    final abs = paise.abs();
    final rupees = abs ~/ 100;
    final frac = (abs % 100).toString().padLeft(2, '0');
    final sign = paise < 0 ? '-' : '';
    return '$sign${symbol ? '₹' : ''}${_groupIndian(rupees)}.$frac';
  }

  static String _groupIndian(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) => other is Money && other.paise == paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();
}
