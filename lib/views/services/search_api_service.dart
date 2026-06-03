import '../models/publication_model.dart';
import 'openalex_client.dart';

/// Dịch vụ gọi API OpenAlex phục vụ cho Tìm kiếm bài báo.
class SearchApiService {
  final OpenAlexClient _client;

  SearchApiService({OpenAlexClient? client}) : _client = client ?? OpenAlexClient();

  /// Tìm kiếm danh sách bài báo theo từ khóa (Requirement 4.1 & 4.2)
  /// Nếu từ khóa rỗng, tải danh sách bài báo chung từ /works.
  Future<List<Publication>> fetchWorks(String query, {int perPage = 20}) async {
    final cleanQuery = query.trim();
    
    final Map<String, String> queryParams = {
      'per_page': perPage.toString(),
    };
    if (cleanQuery.isNotEmpty) {
      queryParams['search'] = cleanQuery;
    }

    final data = await _client.get('/works', queryParams);

    final List results = data['results'] ?? [];
    return results.map((json) => Publication.fromJson(json)).toList();
  }
}
