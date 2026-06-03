import '../models/publication_model.dart';
import 'openalex_client.dart';

/// Dịch vụ gọi API OpenAlex phục vụ cho Tìm kiếm bài báo.
class SearchApiService {
  final OpenAlexClient _client;

  SearchApiService({OpenAlexClient? client}) : _client = client ?? OpenAlexClient();

  /// Tìm kiếm danh sách bài báo theo từ khóa (Requirement 4.1 & 4.2)
  Future<List<Publication>> fetchPublications(String query, {int perPage = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const [];
    }

    final data = await _client.get('/publishers', {
      'search': cleanQuery,
      'per_page': perPage.toString(),
    });

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }
}
