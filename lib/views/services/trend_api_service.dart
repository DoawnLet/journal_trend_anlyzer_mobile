import '../models/publication_model.dart';
import '../models/trend_rank_item_model.dart';
import 'openalex_client.dart';

class TrendApiService {
  final OpenAlexClient _client;

  TrendApiService({OpenAlexClient? client}) : _client = client ?? OpenAlexClient();

  Future<Map<int, int>> fetchPublicationsGroupByYear(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const {};
    }

    try {
      final data = await _client.get('/works', {
        'search': cleanQuery,
        'group_by': 'publication_year',
      });

      final List groupByList = data['group_by'] ?? [];
      final distribution = <int, int>{};

      for (final item in groupByList) {
        if (item is! Map) {
          continue;
        }

        final year = int.tryParse(item['key']?.toString() ?? '');
        final count = int.tryParse(item['count']?.toString() ?? '');
        if (year != null && count != null && year > 0) {
          distribution[year] = count;
        }
      }

      if (distribution.isNotEmpty) {
        return _sortYearDistribution(distribution);
      }
    } catch (_) {
      // Fallback below: use a small works sample and group locally.
    }

    return _fetchPublicationsGroupByYearFromSample(cleanQuery);
  }

  Future<List<Publication>> fetchTopInfluentialPublications(
    String query, {
    int perPage = 20,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    try {
      final data = await _client.get('/works', {
        'search': cleanQuery,
        'sort': 'cited_by_count:desc',
        'per_page': perPage.toString(),
      });

      final List results = data['results'] ?? [];
      return results.map((json) => Publication.fromJson(json)).toList();
    } catch (_) {
      final publications = await fetchPublicationSample(cleanQuery, perPage: 50);
      final sorted = List<Publication>.from(publications)
        ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
      return sorted.take(perPage).toList();
    }
  }

  Future<List<TrendRankItem>> fetchTopResearchJournals(
    String query, {
    int perPage = 200,
    int limit = 5,
  }) async {
    final grouped = await _tryFetchGroupedRanking(
      query,
      groupBy: 'primary_location.source.id',
      limit: limit,
    );
    if (grouped.isNotEmpty) {
      return grouped;
    }

    final publications = await fetchPublicationSample(query, perPage: perPage);
    final journalMap = <String, int>{};

    for (final publication in publications) {
      final journalName = publication.journalName.trim();
      if (journalName.isEmpty || journalName == 'Unknown Journal') {
        continue;
      }
      journalMap[journalName] = (journalMap[journalName] ?? 0) + 1;
    }

    return _sortedTopItems(journalMap, limit);
  }

  Future<List<TrendRankItem>> fetchTopContributingAuthors(
    String query, {
    int perPage = 200,
    int limit = 5,
  }) async {
    final grouped = await _tryFetchGroupedRanking(
      query,
      groupBy: 'authorships.author.id',
      limit: limit,
    );
    if (grouped.isNotEmpty) {
      return grouped;
    }

    final publications = await fetchPublicationSample(query, perPage: perPage);
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

    return _sortedTopItems(authorMap, limit);
  }

  Future<List<Publication>> fetchPublicationsByJournalId(
    String query,
    String journalId, {
    int perPage = 20,
  }) {
    return _fetchPublicationsByFilter(
      query,
      'primary_location.source.id:$journalId',
      perPage: perPage,
    );
  }

  Future<List<Publication>> fetchPublicationsByAuthorId(
    String query,
    String authorId, {
    int perPage = 20,
  }) {
    return _fetchPublicationsByFilter(
      query,
      'authorships.author.id:$authorId',
      perPage: perPage,
    );
  }

  Future<List<Publication>> fetchPublicationSample(
    String query, {
    required int perPage,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final data = await _client.get('/works', {
      'search': cleanQuery,
      'per_page': perPage.toString(),
    });

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }

  Future<Map<int, int>> _fetchPublicationsGroupByYearFromSample(
    String query,
  ) async {
    final publications = await fetchPublicationSample(query, perPage: 50);
    final distribution = <int, int>{};

    for (final publication in publications) {
      final year = publication.publicationYear;
      if (year <= 0) {
        continue;
      }
      distribution[year] = (distribution[year] ?? 0) + 1;
    }

    return _sortYearDistribution(distribution);
  }

  Map<int, int> _sortYearDistribution(Map<int, int> distribution) {
    return Map.fromEntries(
      distribution.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<List<TrendRankItem>> _tryFetchGroupedRanking(
    String query, {
    required String groupBy,
    required int limit,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    try {
      final data = await _client.get('/works', {
        'search': cleanQuery,
        'group_by': groupBy,
      });

      final List groupByList = data['group_by'] ?? [];
      final entries = <TrendRankItem>[];

      for (final item in groupByList) {
        if (item is! Map) {
          continue;
        }

        final id = item['key']?.toString();
        final name = (item['key_display_name'] ?? item['key'])?.toString();
        final count = int.tryParse(item['count']?.toString() ?? '');
        if (id == null ||
            id.isEmpty ||
            name == null ||
            name.isEmpty ||
            name == 'null' ||
            count == null ||
            count <= 0) {
          continue;
        }
        entries.add(TrendRankItem(id: id, name: name, count: count));
      }

      entries.sort((a, b) => b.count.compareTo(a.count));
      return entries.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  List<TrendRankItem> _sortedTopItems(
    Map<String, int> counts,
    int limit,
  ) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((entry) => TrendRankItem(
              id: entry.key,
              name: entry.key,
              count: entry.value,
            ))
        .toList();
  }

  Future<List<Publication>> _fetchPublicationsByFilter(
    String query,
    String filter, {
    required int perPage,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final data = await _client.get('/works', {
      'search': cleanQuery,
      'filter': filter,
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
    });

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }
}
