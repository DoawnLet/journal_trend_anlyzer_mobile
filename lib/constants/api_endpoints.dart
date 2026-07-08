import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lớp chứa các hằng số liên quan đến Endpoint của OpenAlex API.
class ApiEndpoints {
  ApiEndpoints._();

  /// URL cơ sở của OpenAlex API
  static const String baseUrl = 'https://api.openalex.org';

  /// Email học thuật của sinh viên FPT (Polite Pool Optimization)
  static String get academicMail =>
      dotenv.get('ACADEMIC_MAIL', fallback: 'your_student_email@fpt.edu.vn');

  /// API Key của OpenAlex để tăng giới hạn tín dụng gọi API
  static String get apiKey => dotenv.get('OPENALEX_API_KEY', fallback: '');
}
