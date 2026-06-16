import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/openalex_api_service.dart';
import 'shared_state.dart';

// Class gom cụm trạng thái
class SearchState {
  final List<Publication> publications;
  final bool isLoading;
  final String errorMessage;
  final String searchQuery;
  final String? selectedAuthorId;
  final String? selectedAuthorName;
  final String? selectedConceptId;
  final String? selectedConceptName;
  final String? selectedTopicId;
  final String? selectedTopicName;
  final String? sortBy; // 'publication_date:desc', 'publication_date:asc', or null

  SearchState({
    this.publications = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.searchQuery = '',
    this.selectedAuthorId,
    this.selectedAuthorName,
    this.selectedConceptId,
    this.selectedConceptName,
    this.selectedTopicId,
    this.selectedTopicName,
    this.sortBy,
  });

  SearchState copyWith({
    List<Publication>? publications,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedAuthorId,
    String? selectedAuthorName,
    String? selectedConceptId,
    String? selectedConceptName,
    String? selectedTopicId,
    String? selectedTopicName,
    String? sortBy,
    bool clearAuthorId = false,
    bool clearAuthorName = false,
    bool clearConceptId = false,
    bool clearConceptName = false,
    bool clearTopicId = false,
    bool clearTopicName = false,
    bool clearSortBy = false,
  }) {
    return SearchState(
      publications: publications ?? this.publications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAuthorId: clearAuthorId ? null : (selectedAuthorId ?? this.selectedAuthorId),
      selectedAuthorName: clearAuthorName ? null : (selectedAuthorName ?? this.selectedAuthorName),
      selectedConceptId: clearConceptId ? null : (selectedConceptId ?? this.selectedConceptId),
      selectedConceptName: clearConceptName ? null : (selectedConceptName ?? this.selectedConceptName),
      selectedTopicId: clearTopicId ? null : (selectedTopicId ?? this.selectedTopicId),
      selectedTopicName: clearTopicName ? null : (selectedTopicName ?? this.selectedTopicName),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
    );
  }
}

class SearchNotifier {
  final OpenAlexApiService _openAlexApiService = OpenAlexApiService();
  
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
    
    if (newQuery.startsWith('Author: ')) {
      final name = newQuery.substring('Author: '.length).trim();
      if (state.selectedAuthorName == name) {
        return; // Đã được xử lý bởi setAuthorFilter
      }
      return;
    }

    if (state.selectedConceptName == newQuery) {
      return; // Đã được xử lý bởi setConceptFilter
    }

    if (state.selectedTopicName == newQuery) {
      return; // Đã được xử lý bởi setTopicFilter
    }

    if (state.selectedAuthorId != null || 
        state.selectedConceptId != null ||
        state.selectedTopicId != null ||
        state.searchQuery != newQuery) {
      state = state.copyWith(
        searchQuery: newQuery,
        clearAuthorId: true,
        clearAuthorName: true,
        clearConceptId: true,
        clearConceptName: true,
        clearTopicId: true,
        clearTopicName: true,
      );
      executeWorksFetchPipeline();
    }
  }

  Future<void> executeWorksFetchPipeline({bool showLoading = true}) async {
    // Kích hoạt trạng thái Loading trên UI
    state = state.copyWith(
      isLoading: showLoading ? true : state.isLoading,
      errorMessage: '',
    );

    try {
      final data = await _openAlexApiService.getWorksFiltered(
        query: state.searchQuery,
        authorId: state.selectedAuthorId,
        conceptId: state.selectedConceptId,
        topicId: state.selectedTopicId,
        sortBy: state.sortBy,
      );
      final List results = data['results'] ?? [];
      final parsedPublications = results.map((json) => Publication.fromJson(json)).toList();

      // Cập nhật trạng thái thành công
      state = state.copyWith(
        publications: parsedPublications,
        isLoading: showLoading ? false : state.isLoading,
      );
    } catch (e) {
      // Đẩy thông báo lỗi thân thiện ra ngoài UI nếu gặp sự cố
      state = state.copyWith(
        isLoading: showLoading ? false : state.isLoading,
        errorMessage: ErrorTranslator.translate(e),
      );
    }
  }

  // Tương thích ngược với các cuộc gọi trực tiếp cũ
  Future<void> executeSearch(String keyword) async {
    SharedState.activeQueryNotifier.value = keyword;
  }

  void setAuthorFilter(String id, String name) {
    state = state.copyWith(
      selectedAuthorId: id,
      selectedAuthorName: name,
      searchQuery: '', // Flush traditional query strings to avoid conflict
    );
    SharedState.activeQueryNotifier.value = 'Author: $name';
    executeWorksFetchPipeline(); // Trigger immediate HTTP dispatch
  }

  void clearAuthorFilter() {
    state = state.copyWith(
      clearAuthorId: true,
      clearAuthorName: true,
      searchQuery: '',
    );
    SharedState.activeQueryNotifier.value = '';
    executeWorksFetchPipeline();
  }

  void setConceptFilter(String id, String name) {
    state = state.copyWith(
      selectedConceptId: id,
      selectedConceptName: name,
    );
    SharedState.activeQueryNotifier.value = name;
    executeWorksFetchPipeline();
  }

  void clearConceptFilter() {
    state = state.copyWith(
      clearConceptId: true,
      clearConceptName: true,
      searchQuery: '',
    );
    SharedState.activeQueryNotifier.value = '';
    executeWorksFetchPipeline();
  }

  void setTopicFilter(String id, String name) {
    state = state.copyWith(
      selectedTopicId: id,
      selectedTopicName: name,
    );
    SharedState.activeQueryNotifier.value = name;
    executeWorksFetchPipeline();
  }

  void clearTopicFilter() {
    state = state.copyWith(
      clearTopicId: true,
      clearTopicName: true,
      searchQuery: '',
    );
    SharedState.activeQueryNotifier.value = '';
    executeWorksFetchPipeline();
  }

  void setSortBy(String? sort) {
    state = state.copyWith(
      sortBy: sort,
    );
    executeWorksFetchPipeline();
  }

  void clearSortBy() {
    state = state.copyWith(
      clearSortBy: true,
    );
    executeWorksFetchPipeline();
  }

  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    stateNotifier.dispose();
  }
}
