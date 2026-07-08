import 'package:journal_trend_analysis_mb/models/publication_model.dart';

class ResearchTrendSummary {
  final int totalPublications;
  final int totalCitations;
  final double averageCitations;
  final int? mostActiveYear;
  final double? growthRate;
  final String trendStatus;
  final Publication? mostInfluentialPaper;
  final String? topJournal;
  final String? topAuthor;

  const ResearchTrendSummary({
    required this.totalPublications,
    required this.totalCitations,
    required this.averageCitations,
    this.mostActiveYear,
    this.growthRate,
    required this.trendStatus,
    this.mostInfluentialPaper,
    this.topJournal,
    this.topAuthor,
  });
}
