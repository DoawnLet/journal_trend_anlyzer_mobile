import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis_mb/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the App Bar contains the title of the home page
    expect(find.text('Research Home'), findsOneWidget);
  });
}
