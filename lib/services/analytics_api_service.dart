import 'package:journal_trend_analysis_mb/models/research_scope_model.dart';
import 'package:journal_trend_analysis_mb/models/trend_rank_item_model.dart';
import 'package:journal_trend_analysis_mb/services/openalex_client.dart';
import 'package:journal_trend_analysis_mb/services/openalex_query_builder.dart';

class AnalyticsApiService {
  final OpenAlexClient _client;

  AnalyticsApiService({OpenAlexClient? client})
      : _client = client ?? OpenAlexClient();

  Future<Map<int, int>> publicationsByYear(ResearchScope scope) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(
        scope: scope,
        groupBy: 'publication_year',
      ),
    );

    final output = <int, int>{};
    final List groupBy = data['group_by'] ?? [];
    for (final item in groupBy) {
      if (item is! Map) {
        continue;
      }
      final year = int.tryParse(item['key']?.toString() ?? '');
      final count = int.tryParse(item['count']?.toString() ?? '');
      if (year != null && count != null && year > 0) {
        output[year] = count;
      }
    }

    return Map.fromEntries(
      output.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<List<TrendRankItem>> topSources(
    ResearchScope scope, {
    int limit = 10,
  }) {
    return groupedRanking(
      scope,
      groupBy: 'primary_location.source.id',
      limit: limit,
    );
  }

  Future<List<TrendRankItem>> topAuthors(
    ResearchScope scope, {
    int limit = 10,
  }) {
    return groupedRanking(scope, groupBy: 'authorships.author.id', limit: limit);
  }

  Future<List<TrendRankItem>> topInstitutions(
    ResearchScope scope, {
    int limit = 10,
  }) {
    return groupedRanking(
      scope,
      groupBy: 'authorships.institutions.id',
      limit: limit,
    );
  }

  Future<List<TrendRankItem>> topFunders(
    ResearchScope scope, {
    int limit = 10,
  }) {
    return groupedRanking(scope, groupBy: 'grants.funder', limit: limit);
  }

  Future<List<TrendRankItem>> groupedRanking(
    ResearchScope scope, {
    required String groupBy,
    int limit = 10,
  }) async {
    final data = await _client.get(
      '/works',
      OpenAlexQueryBuilder.worksParams(scope: scope, groupBy: groupBy),
    );

    final List groupByList = data['group_by'] ?? [];
    final items = <TrendRankItem>[];
    for (final item in groupByList) {
      if (item is! Map) {
        continue;
      }
      final id = item['key']?.toString() ?? '';
      final name = (item['key_display_name'] ?? item['key'])?.toString() ?? '';
      final count = int.tryParse(item['count']?.toString() ?? '') ?? 0;
      if (id.isNotEmpty && name.isNotEmpty && name != 'null' && count > 0) {
        items.add(TrendRankItem(id: id, name: name, count: count));
      }
    }

    items.sort((a, b) => b.count.compareTo(a.count));
    return items.take(limit).toList();
  }
}
