import 'package:journal_trend_analysis_mb/models/dashboard_stats_model.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/models/research_scope_model.dart';
import 'package:journal_trend_analysis_mb/services/openalex_client.dart';
import 'package:journal_trend_analysis_mb/services/openalex_query_builder.dart';

class DashboardApiService {
  final OpenAlexClient _client;

  DashboardApiService({OpenAlexClient? client})
      : _client = client ?? OpenAlexClient();

  Future<DashboardStats> fetchDashboardStats(
    String query, {
    ResearchScope scope = ResearchScope.empty,
    int samplePerPage = 50,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty && !scope.hasSearchableInput) {
      return DashboardStats.empty;
    }

    final results = await Future.wait([
      _fetchMetaCount(cleanQuery, scope: scope).catchError((_) => 0),
      _fetchMostActiveYear(cleanQuery, scope: scope).catchError((_) => 0),
      _fetchMostInfluentialPaper(cleanQuery, scope: scope)
          .catchError((_) => null),
      _fetchGroupedRanking(
        cleanQuery,
        scope: scope,
        groupBy: 'primary_location.source.id',
      )
          .catchError((_) => const MapEntry('N/A', 0)),
      _fetchGroupedRanking(
        cleanQuery,
        scope: scope,
        groupBy: 'authorships.author.id',
      )
          .catchError((_) => const MapEntry('N/A', 0)),
      fetchDashboardPublications(
        cleanQuery,
        scope: scope,
        perPage: samplePerPage,
      )
          .catchError((_) => <Publication>[]),
    ]);

    final totalPublications = results[0] as int;
    final mostActiveYear = results[1] as int;
    final mostInfluentialPaper = results[2] as Publication?;
    var topJournal = results[3] as MapEntry<String, int>;
    var topAuthor = results[4] as MapEntry<String, int>;
    final publications = results[5] as List<Publication>;

    if (topJournal.value == 0) {
      topJournal = _findTopJournal(publications);
    }
    if (topAuthor.value == 0) {
      topAuthor = _findTopAuthor(publications);
    }

    return DashboardStats(
      totalPublications: totalPublications,
      averageCitations: _calculateAverageCitations(publications),
      mostActiveYear: mostActiveYear,
      topJournalName: topJournal.key,
      topJournalCount: topJournal.value,
      topAuthorName: topAuthor.key,
      topAuthorCount: topAuthor.value,
      mostInfluentialPaper: mostInfluentialPaper,
      samplePublications: publications,
    );
  }

  Future<List<Publication>> fetchDashboardPublications(
    String query, {
    ResearchScope scope = ResearchScope.empty,
    int perPage = 50,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty && !scope.hasSearchableInput) {
      return const [];
    }

    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(
        scope: scope,
        query: cleanQuery,
        perPage: perPage,
      ),
    );

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }

  Future<int> _fetchMetaCount(
    String query, {
    ResearchScope scope = ResearchScope.empty,
  }) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(scope: scope, query: query, perPage: 1),
    );

    final meta = data['meta'];
    final count = meta is Map ? meta['count'] : null;
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  Future<int> _fetchMostActiveYear(
    String query, {
    ResearchScope scope = ResearchScope.empty,
  }) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(
        scope: scope,
        query: query,
        groupBy: 'publication_year',
      ),
    );

    final List groupByList = data['group_by'] ?? [];
    var year = 0;
    var maxCount = 0;

    for (final item in groupByList) {
      if (item is! Map) {
        continue;
      }

      final parsedYear = int.tryParse(item['key']?.toString() ?? '');
      final parsedCount = int.tryParse(item['count']?.toString() ?? '');
      if (parsedYear != null &&
          parsedYear > 0 &&
          parsedCount != null &&
          parsedCount > maxCount) {
        year = parsedYear;
        maxCount = parsedCount;
      }
    }

    return year;
  }

  Future<Publication?> _fetchMostInfluentialPaper(
    String query, {
    ResearchScope scope = ResearchScope.empty,
  }) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(
        scope: scope,
        query: query,
        sort: 'cited_by_count:desc',
        perPage: 1,
      ),
    );

    final List results = data['results'] ?? [];
    if (results.isEmpty) {
      return null;
    }

    return Publication.fromJson(results.first);
  }

  Future<MapEntry<String, int>> _fetchGroupedRanking(
    String query, {
    ResearchScope scope = ResearchScope.empty,
    required String groupBy,
  }) async {
    try {
      final data = await _client.get(
        '/works',
        OpenAlexQueryBuilder.worksParams(
          scope: scope,
          query: query,
          groupBy: groupBy,
        ),
      );

      final List groupByList = data['group_by'] ?? [];
      for (final item in groupByList) {
        if (item is! Map) {
          continue;
        }

        final name = (item['key_display_name'] ?? item['key'])?.toString();
        final count = int.tryParse(item['count']?.toString() ?? '');
        if (name == null ||
            name.isEmpty ||
            name == 'null' ||
            count == null ||
            count <= 0) {
          continue;
        }

        return MapEntry(name, count);
      }
    } catch (_) {
      // Fallback to local grouping from the sample below.
    }

    return const MapEntry('N/A', 0);
  }

  double _calculateAverageCitations(List<Publication> publications) {
    if (publications.isEmpty) {
      return 0;
    }

    final sum = publications.fold<int>(
      0,
      (total, publication) => total + publication.citationCount,
    );
    return sum / publications.length;
  }

  MapEntry<String, int> _findTopJournal(List<Publication> publications) {
    final journalMap = <String, int>{};
    for (final publication in publications) {
      final journalName = publication.journalName.trim();
      if (journalName.isEmpty || journalName == 'Unknown Journal') {
        continue;
      }
      journalMap[journalName] = (journalMap[journalName] ?? 0) + 1;
    }

    if (journalMap.isEmpty) {
      return const MapEntry('N/A', 0);
    }

    final entries = journalMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  MapEntry<String, int> _findTopAuthor(List<Publication> publications) {
    final authorMap = <String, int>{};
    for (final publication in publications) {
      for (final author in publication.authors) {
        final authorName = author.trim();
        if (authorName.isEmpty) {
          continue;
        }
        authorMap[authorName] = (authorMap[authorName] ?? 0) + 1;
      }
    }

    if (authorMap.isEmpty) {
      return const MapEntry('N/A', 0);
    }

    final entries = authorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }
}
