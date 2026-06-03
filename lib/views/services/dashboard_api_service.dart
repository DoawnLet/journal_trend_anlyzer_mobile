import '../models/publication_model.dart';
import 'openalex_client.dart';

/// Dịch vụ gọi API OpenAlex phục vụ cho phân tích Dashboard.
class DashboardApiService {
  final OpenAlexClient _client;

  DashboardApiService({OpenAlexClient? client}) : _client = client ?? OpenAlexClient();

  /// Kéo tập dữ liệu lớn phục vụ tính toán dashboard cục bộ (Requirement 4.7)
  Future<List<Publication>> fetchDashboardPublications(String query, {int perPage = 50}) async {
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
}
