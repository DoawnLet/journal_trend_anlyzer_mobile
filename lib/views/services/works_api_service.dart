import '../models/publication_model.dart';
import '../models/research_scope_model.dart';
import 'openalex_client.dart';
import 'openalex_query_builder.dart';

class WorksApiService {
  final OpenAlexClient _client;

  WorksApiService({OpenAlexClient? client})
      : _client = client ?? OpenAlexClient();

  Future<List<Publication>> listWorks({
    ResearchScope scope = ResearchScope.empty,
    String? query,
    String? filter,
    String? sort,
    int perPage = 20,
  }) async {
    if (!(scope.hasSearchableInput || (query?.trim().isNotEmpty ?? false))) {
      return const [];
    }

    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(
        scope: scope,
        query: query,
        filter: filter,
        sort: sort,
        perPage: perPage,
      ),
    );

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }

  Future<int> countWorks({ResearchScope scope = ResearchScope.empty}) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(scope: scope, perPage: 1),
    );

    final meta = data['meta'];
    final count = meta is Map ? meta['count'] : null;
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }
}
