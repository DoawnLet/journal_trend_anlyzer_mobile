import 'publication_model.dart';

class DashboardStats {
  final int totalPublications;
  final double averageCitations;
  final int mostActiveYear;
  final String topJournalName;
  final int topJournalCount;
  final String topAuthorName;
  final int topAuthorCount;
  final Publication? mostInfluentialPaper;
  final List<Publication> samplePublications;

  const DashboardStats({
    required this.totalPublications,
    required this.averageCitations,
    required this.mostActiveYear,
    required this.topJournalName,
    required this.topJournalCount,
    required this.topAuthorName,
    required this.topAuthorCount,
    required this.mostInfluentialPaper,
    required this.samplePublications,
  });

  static const empty = DashboardStats(
    totalPublications: 0,
    averageCitations: 0,
    mostActiveYear: 0,
    topJournalName: 'N/A',
    topJournalCount: 0,
    topAuthorName: 'N/A',
    topAuthorCount: 0,
    mostInfluentialPaper: null,
    samplePublications: [],
  );
}
