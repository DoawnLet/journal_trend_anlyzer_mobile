import '../models/research_taxonomy_model.dart';
import 'openalex_client.dart';

class TaxonomyApiService {
  final OpenAlexClient _client;

  TaxonomyApiService({OpenAlexClient? client})
      : _client = client ?? OpenAlexClient();

  Future<List<ResearchTopic>> fetchPopularTopics({int limit = 100}) async {
    final data = await _client.get('/topics', {
      'sort': 'works_count:desc',
      'per_page': limit.clamp(1, 100).toString(),
    });

    return _parseTopics(data);
  }

  Future<List<ResearchTopic>> fetchTopicCatalog({
    int maxPages = 45,
    int perPage = 100,
  }) async {
    final topics = <ResearchTopic>[];
    var cursor = '*';

    for (var page = 0; page < maxPages; page++) {
      final data = await _client.get('/topics', {
        'sort': 'works_count:desc',
        'per_page': perPage.clamp(1, 100).toString(),
        'cursor': cursor,
      });

      topics.addAll(_parseTopics(data));

      final meta = data is Map ? data['meta'] : null;
      final nextCursor = meta is Map ? meta['next_cursor']?.toString() : null;
      if (nextCursor == null || nextCursor.isEmpty || nextCursor == cursor) {
        break;
      }
      cursor = nextCursor;
    }

    return topics;
  }

  Future<List<ResearchTopic>> searchTopics(
    String query, {
    int limit = 50,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return fetchPopularTopics(limit: limit);
    }

    final data = await _client.get('/topics', {
      'search': cleanQuery,
      'per_page': limit.clamp(1, 100).toString(),
    });

    return _parseTopics(data);
  }

  List<ResearchTopic> _parseTopics(Object? data) {
    if (data is! Map) {
      return const [];
    }

    final results = data['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(ResearchTopic.fromJson)
        .where((topic) => topic.topic.isValid)
        .toList();
  }
}
