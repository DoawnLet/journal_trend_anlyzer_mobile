import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis_mb/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is displayed on startup
    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
