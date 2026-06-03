import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/search_api_service.dart';
import 'shared_state.dart';

/// Bộ quản lý trạng thái Tìm kiếm bài báo khoa học.
/// Lắng nghe từ khóa toàn cục và tự động gọi API cập nhật kết quả.
class SearchNotifier extends ChangeNotifier {
  final SearchApiService _apiService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  SearchNotifier({SearchApiService? apiService})
      : _apiService = apiService ?? SearchApiService() {
    // Đăng ký lắng nghe sự thay đổi của từ khóa tìm kiếm toàn cục
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    // Kích hoạt tìm kiếm ban đầu
    search(SharedState.activeQueryNotifier.value);
  }

  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onQueryChanged() {
    search(SharedState.activeQueryNotifier.value);
  }

  /// Thực thi tìm kiếm gọi OpenAlex API
  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _publications = await _apiService.fetchPublications(cleanQuery);
    } catch (e) {
      _errorMessage = ErrorTranslator.translate(e);
      _publications = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    super.dispose();
  }
}
