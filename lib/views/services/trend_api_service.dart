import '../models/publication_model.dart';
import 'openalex_client.dart';

/// Dịch vụ gọi API OpenAlex phục vụ cho phân tích Xu hướng.
class TrendApiService {
  final OpenAlexClient _client;

  TrendApiService({OpenAlexClient? client}) : _client = client ?? OpenAlexClient();

  /// Gom nhóm số lượng ấn phẩm theo năm từ API (Requirement 4.3)
  Future<Map<int, int>> fetchPublicationsGroupByYear(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const {};
    }

    final data = await _client.get('/works', {
      'search': cleanQuery,
      'group_by': 'publication_year',
    });

    final List groupByList = data['group_by'] ?? [];
    final Map<int, int> distribution = {};

    for (var item in groupByList) {
      if (item is Map) {
        final yearStr = item['key'];
        final countVal = item['count'];
        if (yearStr != null && countVal != null) {
          final year = int.tryParse(yearStr.toString());
          final count = int.tryParse(countVal.toString());
          if (year != null && count != null && year > 0) {
            distribution[year] = count;
          }
        }
      }
    }

    // Sắp xếp tăng dần theo năm
    return Map.fromEntries(
      distribution.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Lấy danh sách bài báo trích dẫn cao nhất (Requirement 4.4)
  Future<List<Publication>> fetchTopInfluentialPublications(String query, {int perPage = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final data = await _client.get('/works', {
      'search': cleanQuery,
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
    });

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }
}
