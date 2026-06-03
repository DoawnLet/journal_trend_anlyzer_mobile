import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/search_api_service.dart';
import 'shared_state.dart';

// Class gom cụm trạng thái
class SearchState {
  final List<Publication> publications;
  final bool isLoading;
  final String errorMessage;

  SearchState({
    this.publications = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  SearchState copyWith({
    List<Publication>? publications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SearchState(
      publications: publications ?? this.publications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SearchNotifier {
  final SearchApiService _apiService = SearchApiService();
  
  // Biến trạng thái duy nhất dùng để lắng nghe ở UI
  final ValueNotifier<SearchState> stateNotifier = ValueNotifier(SearchState());

  SearchNotifier() {
    // Đăng ký lắng nghe sự thay đổi của từ khóa tìm kiếm toàn cục
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    // Kích hoạt tìm kiếm ban đầu
    executeSearch(SharedState.activeQueryNotifier.value);
  }

  void _onQueryChanged() {
    executeSearch(SharedState.activeQueryNotifier.value);
  }

  Future<void> executeSearch(String keyword) async {
    final cleanKeyword = keyword.trim();

    // Kích hoạt trạng thái Loading trên UI
    stateNotifier.value = stateNotifier.value.copyWith(
      isLoading: true,
      errorMessage: '',
    );

    try {
      // Gọi Service để kết nối API OpenAlex
      final parsedPublications = await _apiService.fetchWorks(cleanKeyword);

      // Cập nhật trạng thái thành công
      stateNotifier.value = stateNotifier.value.copyWith(
        publications: parsedPublications,
        isLoading: false,
      );
    } catch (e) {
      // Đẩy thông báo lỗi thân thiện ra ngoài UI nếu gặp sự cố
      stateNotifier.value = stateNotifier.value.copyWith(
        isLoading: false,
        errorMessage: ErrorTranslator.translate(e),
      );
    }
  }

  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    stateNotifier.dispose();
  }
}
