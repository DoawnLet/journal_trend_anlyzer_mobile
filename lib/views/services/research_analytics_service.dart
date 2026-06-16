import '../models/citation_bucket_model.dart';
import '../models/publication_model.dart';
import '../models/ranking_item_model.dart';
import '../models/research_trend_summary_model.dart';

class ResearchAnalyticsResult {
  final ResearchTrendSummary summary;
  final Map<int, int> trendByYear;
  final List<Publication> topInfluentialPapers;
  final List<RankingItemModel> topJournals;
  final List<RankingItemModel> topAuthors;
  final List<RankingItemModel> topFields;
  final List<RankingItemModel> topSubfields;
  final List<RankingItemModel> topTopics;
  final List<CitationBucketModel> citationDistribution;
  final List<String> keyInsights;

  const ResearchAnalyticsResult({
    required this.summary,
    required this.trendByYear,
    required this.topInfluentialPapers,
    required this.topJournals,
    required this.topAuthors,
    required this.topFields,
    required this.topSubfields,
    required this.topTopics,
    required this.citationDistribution,
    required this.keyInsights,
  });
}

class ResearchAnalyticsService {
  ResearchAnalyticsResult analyze({
    required String topic,
    required List<Publication> publications,
  }) {
    final trendByYear = calculateTrendByYear(publications);
    final topPapers = getTopInfluentialPapers(publications);
    final topJournals = getTopJournals(publications);
    final topAuthors = getTopAuthors(publications);
    final topFields = getTopFields(publications);
    final topSubfields = getTopSubfields(publications);
    final topTopics = getTopTopics(publications);
    final summary = ResearchTrendSummary(
      totalPublications: calculateTotalPublications(publications),
      totalCitations: calculateTotalCitations(publications),
      averageCitations: calculateAverageCitations(publications),
      mostActiveYear: findMostActiveYear(trendByYear),
      growthRate: calculateGrowthRate(trendByYear),
      trendStatus: calculateTrendStatus(trendByYear),
      mostInfluentialPaper: findMostInfluentialPaper(publications),
      topJournal: topJournals.isEmpty ? null : topJournals.first.name,
      topAuthor: topAuthors.isEmpty ? null : topAuthors.first.name,
    );

    return ResearchAnalyticsResult(
      summary: summary,
      trendByYear: trendByYear,
      topInfluentialPapers: topPapers,
      topJournals: topJournals,
      topAuthors: topAuthors,
      topFields: topFields,
      topSubfields: topSubfields,
      topTopics: topTopics,
      citationDistribution: calculateCitationDistribution(publications),
      keyInsights: generateVietnameseKeyInsights(
        topic: topic,
        summary: summary,
        trendByYear: trendByYear,
      ),
    );
  }

  int calculateTotalPublications(List<Publication> publications) {
    return publications.length;
  }

  int calculateTotalCitations(List<Publication> publications) {
    return publications.fold<int>(
      0,
      (sum, paper) => sum + paper.citationCount,
    );
  }

  double calculateAverageCitations(List<Publication> publications) {
    if (publications.isEmpty) {
      return 0;
    }
    return calculateTotalCitations(publications) / publications.length;
  }

  Map<int, int> calculateTrendByYear(List<Publication> publications) {
    final result = <int, int>{};
    for (final paper in publications) {
      final year = paper.publicationYear;
      if (year <= 0) {
        continue;
      }
      result[year] = (result[year] ?? 0) + 1;
    }

    final sortedEntries = result.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sortedEntries);
  }

  int? findMostActiveYear(Map<int, int> trendByYear) {
    if (trendByYear.isEmpty) {
      return null;
    }
    return trendByYear.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double? calculateGrowthRate(Map<int, int> trendByYear) {
    if (trendByYear.length < 2) {
      return null;
    }

    final years = trendByYear.keys.toList()..sort();
    final latestYear = years[years.length - 1];
    final previousYear = years[years.length - 2];
    final latestCount = trendByYear[latestYear] ?? 0;
    final previousCount = trendByYear[previousYear] ?? 0;
    if (previousCount == 0) {
      return null;
    }

    return ((latestCount - previousCount) / previousCount) * 100;
  }

  String calculateTrendStatus(Map<int, int> trendByYear) {
    if (trendByYear.length < 2) {
      return 'Not enough data';
    }

    final years = trendByYear.keys.toList()..sort();
    final latest = trendByYear[years.last] ?? 0;
    final previous = trendByYear[years[years.length - 2]] ?? 0;
    if (previous == 0 && latest > 0) {
      return 'Increasing';
    }

    final difference = latest - previous;
    final threshold = previous * 0.1;
    if (difference > threshold) {
      return 'Increasing';
    }
    if (difference.abs() <= threshold) {
      return 'Stable';
    }
    return 'Declining';
  }

  Publication? findMostInfluentialPaper(List<Publication> publications) {
    if (publications.isEmpty) {
      return null;
    }
    return publications.reduce(
      (a, b) => a.citationCount >= b.citationCount ? a : b,
    );
  }

  List<Publication> getTopInfluentialPapers(
    List<Publication> publications, {
    int limit = 5,
  }) {
    final sorted = [...publications]
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    return sorted.take(limit).toList();
  }

  List<RankingItemModel> getTopJournals(
    List<Publication> publications, {
    int limit = 5,
  }) {
    return _rankByValues(
      publications.map((paper) => paper.journalName),
      ignored: const {'Unknown Journal', 'Unknown source'},
      limit: limit,
    );
  }

  List<RankingItemModel> getTopAuthors(
    List<Publication> publications, {
    int limit = 5,
  }) {
    return _rankByValues(
      publications.expand((paper) => paper.authors),
      limit: limit,
    );
  }

  List<RankingItemModel> getTopFields(
    List<Publication> publications, {
    int limit = 5,
  }) {
    return _rankByValues(
      publications.map((paper) => paper.field),
      limit: limit,
    );
  }

  List<RankingItemModel> getTopSubfields(
    List<Publication> publications, {
    int limit = 5,
  }) {
    return _rankByValues(
      publications.map((paper) => paper.subfield),
      limit: limit,
    );
  }

  List<RankingItemModel> getTopTopics(
    List<Publication> publications, {
    int limit = 5,
  }) {
    final values = publications.expand((paper) {
      if (paper.primaryTopic != null && paper.primaryTopic!.trim().isNotEmpty) {
        return [paper.primaryTopic!];
      }
      return paper.topics;
    });
    return _rankByValues(values, limit: limit);
  }

  List<CitationBucketModel> calculateCitationDistribution(
    List<Publication> publications,
  ) {
    var zero = 0;
    var oneToTen = 0;
    var elevenToFifty = 0;
    var fiftyOneToHundred = 0;
    var overHundred = 0;

    for (final paper in publications) {
      final citations = paper.citationCount;
      if (citations == 0) {
        zero++;
      } else if (citations <= 10) {
        oneToTen++;
      } else if (citations <= 50) {
        elevenToFifty++;
      } else if (citations <= 100) {
        fiftyOneToHundred++;
      } else {
        overHundred++;
      }
    }

    return [
      CitationBucketModel(label: '0', count: zero),
      CitationBucketModel(label: '1-10', count: oneToTen),
      CitationBucketModel(label: '11-50', count: elevenToFifty),
      CitationBucketModel(label: '51-100', count: fiftyOneToHundred),
      CitationBucketModel(label: '100+', count: overHundred),
    ];
  }

  List<String> generateVietnameseKeyInsights({
    required String topic,
    required ResearchTrendSummary summary,
    required Map<int, int> trendByYear,
  }) {
    if (summary.totalPublications == 0) {
      return const ['Chưa đủ dữ liệu để tạo insight.'];
    }

    final insights = <String>[
      'Chủ đề "$topic" có ${summary.totalPublications} publication trong tập dữ liệu đang phân tích.',
      'Tổng số citation là ${summary.totalCitations}, trung bình ${summary.averageCitations.toStringAsFixed(1)} citation mỗi publication.',
    ];

    if (summary.mostActiveYear != null) {
      final count = trendByYear[summary.mostActiveYear] ?? 0;
      insights.add(
        'Hoạt động công bố cao nhất vào năm ${summary.mostActiveYear} với $count publication.',
      );
    }
    if (summary.trendStatus != 'Not enough data') {
      insights.add('Xu hướng hiện tại: ${_trendStatusVi(summary.trendStatus)}.');
    }
    if (summary.growthRate != null) {
      final sign = summary.growthRate! >= 0 ? '+' : '';
      insights.add(
        'Tốc độ tăng trưởng giữa hai năm gần nhất là $sign${summary.growthRate!.toStringAsFixed(1)}%.',
      );
    }
    if (summary.topJournal != null) {
      insights.add('${summary.topJournal} là journal/source xuất hiện nhiều nhất.');
    }
    if (summary.topAuthor != null) {
      insights.add('${summary.topAuthor} là tác giả đóng góp nhiều nhất.');
    }
    if (summary.mostInfluentialPaper != null) {
      insights.add(
        'Publication có ảnh hưởng nhất đạt ${summary.mostInfluentialPaper!.citationCount} citation.',
      );
    }

    return insights;
  }

  List<RankingItemModel> _rankByValues(
    Iterable<String?> values, {
    Set<String> ignored = const {},
    int limit = 5,
  }) {
    final counts = <String, int>{};
    for (final rawValue in values) {
      final value = rawValue?.trim();
      if (value == null || value.isEmpty || ignored.contains(value)) {
        continue;
      }
      counts[value] = (counts[value] ?? 0) + 1;
    }

    final items = counts.entries
        .map((entry) => RankingItemModel(name: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return items.take(limit).toList();
  }

  String _trendStatusVi(String status) {
    switch (status) {
      case 'Increasing':
        return 'đang tăng';
      case 'Stable':
        return 'ổn định';
      case 'Declining':
        return 'đang giảm';
      default:
        return 'chưa đủ dữ liệu';
    }
  }
}
