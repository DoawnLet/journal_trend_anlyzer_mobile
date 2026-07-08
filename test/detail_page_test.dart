import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';

void main() {
  testWidgets('DetailPage displays DOI in compact format', (tester) async {
    const publication = Publication(
      id: 'https://openalex.org/W1',
      title: 'A test publication',
      publicationYear: 2024,
      citationCount: 12,
      doi: 'https://doi.org/10.1000/test-doi',
      journalName: 'Test Journal',
      authors: ['Test Author'],
      abstractText: 'A short abstract.',
      concepts: [],
      topics: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DetailPage(publication: publication),
      ),
    );

    expect(find.text('DOI'), findsOneWidget);
    expect(find.text('10.1000/test-doi'), findsOneWidget);
  });
}
