import 'package:flutter_test/flutter_test.dart';
import 'package:eco_campus/main.dart';

void main() {
  testWidgets('EcoCampus smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoCampusApp());
    expect(find.byType(EcoCampusApp), findsOneWidget);
  });
}