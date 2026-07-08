import 'package:journal_trend_analysis_mb/models/publication_model.dart';

class FilterOptionBuilder {
  static Map<String, int> buildAuthorOptions(List<Publication> publications) {
    return _rank(publications.expand((paper) => paper.authors));
  }

  static Map<String, int> buildJournalOptions(List<Publication> publications) {
    return _rank(publications.map((paper) => paper.journalName));
  }

  static Map<String, int> buildDomainOptions(List<Publication> publications) {
    return _rank(publications.map((paper) => paper.domain));
  }

  static Map<String, int> buildFieldOptions(List<Publication> publications) {
    return _rank(publications.map((paper) => paper.field));
  }

  static Map<String, int> buildSubfieldOptions(List<Publication> publications) {
    return _rank(publications.map((paper) => paper.subfield));
  }

  static Map<String, int> buildTopicOptions(List<Publication> publications) {
    return _rank(publications.expand((paper) {
      if (paper.primaryTopic != null && paper.primaryTopic!.trim().isNotEmpty) {
        return [paper.primaryTopic!];
      }
      return paper.topics;
    }));
  }

  static Map<String, int> _rank(Iterable<String?> values) {
    final counts = <String, int>{};
    for (final raw in values) {
      final value = raw?.trim();
      if (value == null ||
          value.isEmpty ||
          value == 'Unknown Journal' ||
          value == 'Unknown source') {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }
}
