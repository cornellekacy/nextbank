import 'package:flutter_test/flutter_test.dart';
import 'package:nextbank_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NextBankApp());
    expect(find.text('NextBank'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
