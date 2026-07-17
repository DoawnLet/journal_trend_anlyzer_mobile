import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:journal_trend_analysis_mb/models/publication_filter_model.dart';
import 'package:journal_trend_analysis_mb/services/openalex_query_builder.dart';

class OpenAlexApiService {
  final String _baseUrl = "https://api.openalex.org";
  final String _mailto = "minhvtbd12345@fpt.edu.vn"; // Polite Pool Access

  /// Hàm trợ giúp thực hiện GET kèm theo các header bắt buộc (User-Agent)
  Future<http.Response> _get(Uri uri) async {
    return await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'JournalTrendAnalyzerMobile/1.0',
      },
    );
  }

  /// Pipeline 1: Fetch prominent Authors to display on HomePage
  Future<Map<String, dynamic>> getTopAuthors() async {
    try {
      // Fetching authors sorted by cited_by_count to display impactful researchers
      final String urlString = "$_baseUrl/authors?sort=cited_by_count:desc&per_page=10&mailto=$_mailto";
      final url = Uri.parse(urlString);
      final response = await _get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body); // Return map holding metadata and results array
      } else {
        throw Exception('OpenAlex Authors Fetch Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to communicate with OpenAlex Authors endpoint: $e');
    }
  }

  /// Pipeline 2: Fetch Works filtered precisely by the complete Author URL ID
  Future<Map<String, dynamic>> getWorksByAuthor(String authorFullId) async {
    try {
      final String rawFilterQuery = "authorships.author.id:$authorFullId";
      final String encodedFilter = Uri.encodeComponent(rawFilterQuery);
      
      final String urlString = "$_baseUrl/works?filter=$encodedFilter&per_page=20&mailto=$_mailto";
      final url = Uri.parse(urlString);
      final response = await _get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OpenAlex Works Filter Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to compile works list for the specified author: $e');
    }
  }

  /// Search authors by text query (or fetch default popular if query is empty)
  Future<List<Map<String, dynamic>>> searchAuthors(String query) async {
    try {
      final String urlString;
      if (query.trim().isEmpty) {
        urlString = "$_baseUrl/authors?per_page=5&sort=cited_by_count:desc&mailto=$_mailto";
      } else {
        urlString = "$_baseUrl/authors?search=${Uri.encodeComponent(query.trim())}&per_page=5&mailto=$_mailto";
      }
      final response = await _get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'] ?? '',
          'display_name': item['display_name'] ?? 'N/A',
        }).toList();
      }
      return const [];
    } catch (e) {
      return const [];
    }
  }

  /// Search concepts by text query (or fetch default popular if query is empty)
  Future<List<Map<String, dynamic>>> searchConcepts(String query) async {
    try {
      final String urlString;
      if (query.trim().isEmpty) {
        urlString = "$_baseUrl/concepts?per_page=5&sort=works_count:desc&mailto=$_mailto";
      } else {
        urlString = "$_baseUrl/concepts?search=${Uri.encodeComponent(query.trim())}&per_page=5&mailto=$_mailto";
      }
      final response = await _get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'] ?? '',
          'display_name': item['display_name'] ?? 'N/A',
        }).toList();
      }
      return const [];
    } catch (e) {
      return const [];
    }
  }

  /// Search topics by text query (or fetch default if query is empty)
  Future<List<Map<String, dynamic>>> searchTopics(String query) async {
    try {
      final String urlString;
      if (query.trim().isEmpty) {
        urlString = "$_baseUrl/topics?per_page=5&mailto=$_mailto";
      } else {
        urlString = "$_baseUrl/topics?search=${Uri.encodeComponent(query.trim())}&per_page=5&mailto=$_mailto";
      }
      final response = await _get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'] ?? '',
          'display_name': item['display_name'] ?? 'N/A',
        }).toList();
      }
      return const [];
    } catch (e) {
      return const [];
    }
  }

  /// Fetch popular topics dynamically
  Future<List<String>> getPopularTopics({int limit = 8}) async {
    try {
      final String urlString = "$_baseUrl/topics?sort=works_count:desc&per_page=$limit&mailto=$_mailto";
      final response = await _get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results
            .map<String>((item) => item['display_name'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Pipeline 3: Fetch Works filtered by multiple parameters and sorting
  Future<Map<String, dynamic>> getWorksByPublicationFilter(
    PublicationFilter filter, {
    int perPage = 50,
  }) async {
    try {
      final uri = OpenAlexQueryBuilder.buildWorksUri(
        filter,
        perPage: perPage,
        mailto: _mailto,
      );
      final response = await _get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OpenAlex Works Filtered Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch filtered works list: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllWorksByPublicationFilter(
    PublicationFilter filter, {
    int perPage = 200,
  }) async {
    try {
      final allResults = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      var cursor = '*';

      while (cursor.isNotEmpty) {
        final uri = OpenAlexQueryBuilder.buildWorksUri(
          filter,
          perPage: perPage.clamp(1, 200),
          mailto: _mailto,
          cursor: cursor,
        );
        final response = await _get(uri);

        if (response.statusCode != 200) {
          throw Exception('OpenAlex Works Cursor Error: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (results.isEmpty) {
          break;
        }

        for (final item in results) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final id = item['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.add(id)) {
            allResults.add(item);
          }
        }

        final meta = data is Map ? data['meta'] : null;
        final nextCursor = meta is Map ? meta['next_cursor']?.toString() : null;
        if (nextCursor == null || nextCursor.isEmpty || nextCursor == cursor) {
          break;
        }
        cursor = nextCursor;
      }

      return allResults;
    } catch (e) {
      throw Exception('Failed to fetch all filtered works list: $e');
    }
  }

  Future<Map<String, dynamic>> getWorksFiltered({
    String query = '',
    String? authorId,
    String? conceptId,
    String? topicId,
    String? taxonomyFilter,
    String? sourceId,
    String? institutionId,
    String? funderId,
    int? yearFrom,
    int? yearTo,
    String? publicationType,
    bool? isOpenAccess,
    int? minCitationCount,
    String? sortBy,
    int perPage = 20,
  }) async {
    try {
      final List<String> filters = [];
      if (authorId != null && authorId.isNotEmpty) {
        filters.add("authorships.author.id:$authorId");
      }
      if (conceptId != null && conceptId.isNotEmpty) {
        filters.add("concepts.id:$conceptId");
      }
      if (topicId != null && topicId.isNotEmpty) {
        filters.add("primary_topic.id:$topicId");
      }
      if (taxonomyFilter != null && taxonomyFilter.isNotEmpty) {
        filters.add(taxonomyFilter);
      }
      if (sourceId != null && sourceId.isNotEmpty) {
        filters.add("primary_location.source.id:$sourceId");
      }
      if (institutionId != null && institutionId.isNotEmpty) {
        filters.add("authorships.institutions.id:$institutionId");
      }
      if (funderId != null && funderId.isNotEmpty) {
        filters.add("grants.funder:$funderId");
      }
      if (yearFrom != null || yearTo != null) {
        filters.add("publication_year:${yearFrom ?? ''}-${yearTo ?? ''}");
      }
      if (publicationType != null && publicationType.isNotEmpty) {
        filters.add("type:$publicationType");
      }
      if (isOpenAccess != null) {
        filters.add("is_oa:$isOpenAccess");
      }
      if (minCitationCount != null) {
        filters.add("cited_by_count:>$minCitationCount");
      }

      final Map<String, String> queryParams = {
        'per_page': perPage.toString(),
        'mailto': _mailto,
      };

      if (query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }

      if (filters.isNotEmpty) {
        queryParams['filter'] = filters.join(',');
      }

      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort'] = sortBy;
      }

      final uri = Uri.parse("$_baseUrl/works").replace(queryParameters: queryParams);
      final response = await _get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OpenAlex Works Filtered Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch filtered works list: $e');
    }
  }

  /// Search academic journals/sources from OpenAlex API
  Future<List<Map<String, dynamic>>> searchSources(String query) async {
    try {
      final String urlString;
      if (query.trim().isEmpty) {
        urlString = "$_baseUrl/sources?per_page=15&sort=works_count:desc&mailto=$_mailto";
      } else {
        urlString = "$_baseUrl/sources?search=${Uri.encodeComponent(query.trim())}&per_page=15&mailto=$_mailto";
      }
      final response = await _get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map<Map<String, dynamic>>((item) => {
          'id': item['id'] ?? '',
          'display_name': item['display_name'] ?? 'Unknown Journal',
          'works_count': item['works_count'] ?? 0,
          'cited_by_count': item['cited_by_count'] ?? 0,
          'homepage_url': item['homepage_url'] ?? '',
          'host_organization_name': item['host_organization_name'] ?? '',
        }).toList();
      }
      return const [];
    } catch (e) {
      return const [];
    }
  }

  /// Fetch publications/works belonging to a source, with an optional search query for topic search
  Future<Map<String, dynamic>> getWorksBySource(String sourceId, {String query = '', int perPage = 50}) async {
    try {
      final List<String> filters = ["primary_location.source.id:$sourceId"];
      final Map<String, String> queryParams = {
        'per_page': perPage.toString(),
        'mailto': _mailto,
        'filter': filters.join(','),
      };
      if (query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }
      final uri = Uri.parse("$_baseUrl/works").replace(queryParameters: queryParams);
      final response = await _get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OpenAlex Works By Source Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch works by source: $e');
    }
  }
}
