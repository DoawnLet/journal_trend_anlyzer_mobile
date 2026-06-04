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
  final String searchQuery;
  final String? selectedPublisherId;
  final String? selectedPublisherName;

  SearchState({
    this.publications = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.searchQuery = '',
    this.selectedPublisherId,
    this.selectedPublisherName,
  });

  SearchState copyWith({
    List<Publication>? publications,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedPublisherId,
    String? selectedPublisherName,
    bool clearPublisherId = false,
    bool clearPublisherName = false,
  }) {
    return SearchState(
      publications: publications ?? this.publications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPublisherId: clearPublisherId ? null : (selectedPublisherId ?? this.selectedPublisherId),
      selectedPublisherName: clearPublisherName ? null : (selectedPublisherName ?? this.selectedPublisherName),
    );
  }
}

class SearchNotifier {
  final SearchApiService _apiService = SearchApiService();
  
  // Biến trạng thái duy nhất dùng để lắng nghe ở UI
  final ValueNotifier<SearchState> stateNotifier = ValueNotifier(SearchState());

  SearchState get state => stateNotifier.value;
  set state(SearchState newValue) => stateNotifier.value = newValue;

  SearchNotifier() {
    // Đăng ký lắng nghe sự thay đổi của từ khóa tìm kiếm toàn cục
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    // Kích hoạt tìm kiếm ban đầu
    executeWorksFetchPipeline();
  }

  void _onQueryChanged() {
    final newQuery = SharedState.activeQueryNotifier.value;
    
    if (newQuery.startsWith('Publisher: ')) {
      final name = newQuery.substring('Publisher: '.length).trim();
      if (state.selectedPublisherName == name) {
        return; // Đã được xử lý bởi setPublisherFilter
      }
      
      // Khôi phục ID nếu được thay đổi trực tiếp từ bên ngoài
      String? pubId;
      switch (name.toLowerCase()) {
        case 'elsevier':
          pubId = 'https://openalex.org/P4310320990';
          break;
        case 'springer nature':
          pubId = 'https://openalex.org/P4310319965';
          break;
        case 'wiley-blackwell':
        case 'wiley':
          pubId = 'https://openalex.org/P4310320595';
          break;
        case 'ieee':
          pubId = 'https://openalex.org/P4310319808';
          break;
        case 'taylor & francis':
          pubId = 'https://openalex.org/P4310320547';
          break;
      }
      if (pubId != null) {
        state = state.copyWith(
          selectedPublisherId: pubId,
          selectedPublisherName: name,
          searchQuery: '',
        );
        executeWorksFetchPipeline();
      }
      return;
    }

    if (state.selectedPublisherId != null || state.searchQuery != newQuery) {
      state = state.copyWith(
        searchQuery: newQuery,
        clearPublisherId: true,
        clearPublisherName: true,
      );
      executeWorksFetchPipeline();
    }
  }

  Future<void> executeWorksFetchPipeline() async {
    // Kích hoạt trạng thái Loading trên UI
    state = state.copyWith(
      isLoading: true,
      errorMessage: '',
    );

    try {
      // Gọi Service để kết nối API OpenAlex
      final parsedPublications = await _apiService.fetchWorks(
        query: state.searchQuery,
        publisherId: state.selectedPublisherId,
      );

      // Cập nhật trạng thái thành công
      state = state.copyWith(
        publications: parsedPublications,
        isLoading: false,
      );
    } catch (e) {
      // Đẩy thông báo lỗi thân thiện ra ngoài UI nếu gặp sự cố
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorTranslator.translate(e),
      );
    }
  }

  // Tương thích ngược với các cuộc gọi trực tiếp cũ
  Future<void> executeSearch(String keyword) async {
    SharedState.activeQueryNotifier.value = keyword;
  }

  void setPublisherFilter(String id, String name) {
    state = state.copyWith(
      selectedPublisherId: id,
      selectedPublisherName: name,
      searchQuery: '', // Flush traditional query strings to avoid conflict
    );
    SharedState.activeQueryNotifier.value = 'Publisher: $name';
    executeWorksFetchPipeline(); // Trigger immediate HTTP dispatch
  }

  void clearPublisherFilter() {
    state = state.copyWith(
      clearPublisherId: true,
      clearPublisherName: true,
      searchQuery: '',
    );
    SharedState.activeQueryNotifier.value = '';
    executeWorksFetchPipeline();
  }

  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    stateNotifier.dispose();
  }
}
