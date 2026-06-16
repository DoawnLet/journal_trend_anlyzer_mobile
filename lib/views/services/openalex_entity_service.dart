import '../models/openalex_entity_model.dart';
import 'openalex_client.dart';

class OpenAlexEntityService {
  final OpenAlexClient _client;

  OpenAlexEntityService({OpenAlexClient? client})
      : _client = client ?? OpenAlexClient();

  Future<List<OpenAlexEntity>> searchAuthors(String query, {int limit = 10}) {
    return _searchEntity('/authors', query, limit: limit);
  }

  Future<List<OpenAlexEntity>> searchSources(String query, {int limit = 10}) {
    return _searchEntity('/sources', query, limit: limit);
  }

  Future<List<OpenAlexEntity>> searchInstitutions(
    String query, {
    int limit = 10,
  }) {
    return _searchEntity('/institutions', query, limit: limit);
  }

  Future<List<OpenAlexEntity>> searchFunders(String query, {int limit = 10}) {
    return _searchEntity('/funders', query, limit: limit);
  }

  Future<List<OpenAlexEntity>> searchPublishers(
    String query, {
    int limit = 10,
  }) {
    return _searchEntity('/publishers', query, limit: limit);
  }

  Future<List<OpenAlexEntity>> _searchEntity(
    String path,
    String query, {
    required int limit,
  }) async {
    final cleanQuery = query.trim();
    final params = <String, String>{
      'per_page': limit.clamp(1, 100).toString(),
      if (cleanQuery.isNotEmpty) 'search': cleanQuery,
      if (cleanQuery.isEmpty) 'sort': 'works_count:desc',
    };

    final data = await _client.get(path, params);
    final List results = data['results'] ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(OpenAlexEntity.fromJson)
        .where((entity) => entity.id.isNotEmpty)
        .toList();
  }
}
