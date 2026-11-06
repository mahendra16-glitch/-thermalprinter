import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/core/util/money.dart';

void main() {
  test('parse accepts common inputs', () {
    expect(Money.parse('500'), const Money(50000));
    expect(Money.parse('1,234.5'), const Money(123450));
    expect(Money.parse('₹ 12.05'), const Money(1205));
    expect(Money.parse('0.1'), const Money(10));
    expect(Money.parse('-20'), const Money(-2000));
  });

  test('parse rejects invalid input', () {
    for (final s in ['', 'abc', '1.234', '1.2.3', '₹']) {
      expect(Money.parse(s), isNull, reason: s);
    }
  });

  test('integer arithmetic has no float drift', () {
    expect(Money.parse('0.1')! + Money.parse('0.2')!, Money.parse('0.3'));
  });

  test('format uses Indian digit grouping', () {
    expect(const Money(0).format(), '₹0.00');
    expect(const Money(50000).format(), '₹500.00');
    expect(const Money(12345678).format(), '₹1,23,456.78');
    expect(const Money(1234567890).format(), '₹1,23,45,678.90');
    expect(const Money(-150).format(), '-₹1.50');
    expect(const Money(100000).format(symbol: false), '1,000.00');
  });
}
