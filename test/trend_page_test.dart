import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis_mb/views/pages/trend_page.dart';
import 'package:journal_trend_analysis_mb/views/state_management/trend_notifier.dart';
import 'package:journal_trend_analysis_mb/views/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/views/services/trend_api_service.dart';
import 'package:journal_trend_analysis_mb/views/state_management/shared_state.dart';

class FakeTrendApiService implements TrendApiService {
  final List<Publication> publications = const [
    Publication(
      id: '1',
      title: 'Test Publication 1',
      publicationYear: 2022,
      citationCount: 100,
      doi: 'https://doi.org/10.1000/test1',
      journalName: 'Test Journal A',
      authors: ['Author X', 'Author Y'],
      abstractText: 'This is abstract 1',
      concepts: ['Concept A'],
      topics: ['Topic A'],
    ),
    Publication(
      id: '2',
      title: 'Test Publication 2',
      publicationYear: 2023,
      citationCount: 50,
      journalName: 'Test Journal B',
      authors: ['Author Z'],
      abstractText: 'This is abstract 2',
      concepts: ['Concept B'],
      topics: ['Topic B'],
    ),
  ];

  @override
  Future<Map<int, int>> fetchPublicationsGroupByYear(String query) async {
    return {2021: 10, 2022: 20, 2023: 15};
  }

  @override
  Future<List<Publication>> fetchTopInfluentialPublications(String query, {int perPage = 20}) async {
    return publications;
  }

  @override
  Future<List<MapEntry<String, int>>> fetchTopResearchJournals(
    String query, {
    int perPage = 200,
    int limit = 5,
  }) async {
    return const [
      MapEntry('Test Journal A', 1),
      MapEntry('Test Journal B', 1),
    ];
  }

  @override
  Future<List<MapEntry<String, int>>> fetchTopContributingAuthors(
    String query, {
    int perPage = 200,
    int limit = 5,
  }) async {
    return const [
      MapEntry('Author X', 1),
      MapEntry('Author Z', 1),
    ];
  }

  @override
  Future<List<Publication>> fetchPublicationSample(
    String query, {
    required int perPage,
  }) async {
    return publications;
  }
}

void main() {
  testWidgets('TrendPage displays domains and trending topics, and responds to taps', (WidgetTester tester) async {
    final fakeService = FakeTrendApiService();
    final notifier = TrendNotifier(apiService: fakeService);

    // Set initial query to empty
    SharedState.activeQueryNotifier.value = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrendPage(notifier: notifier),
        ),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Verify domain cards are shown
    expect(find.text('Khám phá theo lĩnh vực'), findsOneWidget);
    expect(find.text('Khoa học Vật lý & Máy tính'), findsOneWidget);
    expect(find.text('Khoa học Sự sống & Sinh học'), findsOneWidget);

    // Tap on a domain card (e.g. Life Sciences - "Khoa học Sự sống & Sinh học")
    await tester.tap(find.text('Khoa học Sự sống & Sinh học'));
    await tester.pumpAndSettle();

    // Verify state query changed to "Life Sciences"
    expect(SharedState.activeQueryNotifier.value, equals('Life Sciences'));
  });
}
