import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAlexApiService {
  final String _baseUrl = "https://api.openalex.org";
  final String _mailto = "minhvtbd12345@fpt.edu.vn"; // Polite Pool Access

  /// Pipeline 1: Fetch prominent Authors to display on HomePage
  Future<Map<String, dynamic>> getTopAuthors() async {
    try {
      // Fetching authors sorted by cited_by_count to display impactful researchers
      final String urlString = "$_baseUrl/authors?sort=cited_by_count:desc&per_page=10&mailto=$_mailto";
      final url = Uri.parse(urlString);
      final response = await http.get(url);

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
      final response = await http.get(url);

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
      final response = await http.get(Uri.parse(urlString));
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
      final response = await http.get(Uri.parse(urlString));
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
      final response = await http.get(Uri.parse(urlString));
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

  /// Pipeline 3: Fetch Works filtered by multiple parameters and sorting
  Future<Map<String, dynamic>> getWorksFiltered({
    String query = '',
    String? authorId,
    String? conceptId,
    String? topicId,
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
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OpenAlex Works Filtered Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch filtered works list: $e');
    }
  }
}
