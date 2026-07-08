import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:journal_trend_analysis_mb/constants/api_endpoints.dart';

/// Lớp nền xử lý kết nối HTTP thô với máy chủ api.openalex.org.
/// Tập trung cấu hình timeout, Polite Pool (mailto), User-Agent và kiểm tra Status Code.
class OpenAlexClient {
  final http.Client _client;

  OpenAlexClient({http.Client? client}) : _client = client ?? http.Client();

  /// Thực thi một yêu cầu GET an toàn tới API OpenAlex.
  Future<dynamic> get(String path, Map<String, String> queryParams) async {
    // Tự động bổ sung email học thuật cho Polite Pool
    final finalParams = Map<String, String>.from(queryParams);
    if (!finalParams.containsKey('mailto')) {
      finalParams['mailto'] = ApiEndpoints.academicMail;
    }

    // Tự động bổ sung api_key nếu được cấu hình trong .env
    final key = ApiEndpoints.apiKey;
    if (key.isNotEmpty && !finalParams.containsKey('api_key')) {
      finalParams['api_key'] = key;
    }

    final url = Uri.https('api.openalex.org', path, finalParams);

    final response = await _client.get(
      url,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'JournalTrendAnalyzerMobile/1.0',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw HttpException('HTTP ${response.statusCode}');
    }
  }
}
