import 'package:flutter_test/flutter_test.dart';
import 'package:thermalprinter/main.dart';

void main() {
  testWidgets('ThermalPrinterApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ThermalPrinterApp());
    expect(find.byType(ThermalPrinterApp), findsOneWidget);
  });
}
