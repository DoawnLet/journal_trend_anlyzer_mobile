import 'package:flutter/material.dart';

import 'package:journal_trend_analysis_mb/utils/error_translator.dart';
import 'package:journal_trend_analysis_mb/models/publication_filter_model.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/models/research_taxonomy_model.dart';
import 'package:journal_trend_analysis_mb/services/openalex_api_service.dart';
import 'package:journal_trend_analysis_mb/services/publication_filter_service.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';

class SearchState {
  final List<Publication> publications;
  final List<Publication> originalPublications;
  final bool isLoading;
  final String errorMessage;
  final String searchQuery;
  final String? selectedAuthorId;
  final String? selectedAuthorName;
  final String? selectedConceptId;
  final String? selectedConceptName;
  final String? selectedTopicId;
  final String? selectedTopicName;
  final String? sortBy;
  final PublicationFilter filter;
  final int totalPublicationsCount;

  const SearchState({
    this.publications = const [],
    this.originalPublications = const [],
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
    this.filter = PublicationFilter.empty,
    this.totalPublicationsCount = 0,
  });

  SearchState copyWith({
    List<Publication>? publications,
    List<Publication>? originalPublications,
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
    PublicationFilter? filter,
    int? totalPublicationsCount,
    bool clearAuthor = false,
    bool clearConcept = false,
    bool clearTopic = false,
    bool clearSortBy = false,
  }) {
    return SearchState(
      publications: publications ?? this.publications,
      originalPublications: originalPublications ?? this.originalPublications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAuthorId: clearAuthor ? null : (selectedAuthorId ?? this.selectedAuthorId),
      selectedAuthorName:
          clearAuthor ? null : (selectedAuthorName ?? this.selectedAuthorName),
      selectedConceptId:
          clearConcept ? null : (selectedConceptId ?? this.selectedConceptId),
      selectedConceptName: clearConcept
          ? null
          : (selectedConceptName ?? this.selectedConceptName),
      selectedTopicId: clearTopic ? null : (selectedTopicId ?? this.selectedTopicId),
      selectedTopicName:
          clearTopic ? null : (selectedTopicName ?? this.selectedTopicName),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      filter: filter ?? this.filter,
      totalPublicationsCount: totalPublicationsCount ?? this.totalPublicationsCount,
    );
  }
}

class SearchNotifier {
  final OpenAlexApiService _openAlexApiService = OpenAlexApiService();
  bool _syncingFilter = false;

  final ValueNotifier<SearchState> stateNotifier =
      ValueNotifier<SearchState>(const SearchState());

  SearchState get state => stateNotifier.value;
  set state(SearchState newValue) => stateNotifier.value = newValue;

  SearchNotifier() {
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    SharedState.activeResearchScopeNotifier.addListener(_onResearchScopeChanged);
    SharedState.publicationFilterNotifier.addListener(_onFilterChanged);
    executeWorksFetchPipeline();
  }

  void _onQueryChanged() {
    final keyword = SharedState.activeQueryNotifier.value.trim();
    final scope = SharedState.activeResearchScopeNotifier.value;
    if (scope.hasStructuredFilters && scope.displayLabel == keyword) {
      return;
    }

    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.reset(keyword: keyword));
  }

  void _onResearchScopeChanged() {
    final scope = SharedState.activeResearchScopeNotifier.value;
    if (!scope.hasStructuredFilters) {
      return;
    }

    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(
      current.copyWith(
        keyword: scope.keyword,
        taxonomy: scope.taxonomy,
        fromYear: scope.yearFrom,
        toYear: scope.yearTo,
        minCitations: scope.minCitationCount,
        openAccessOnly: scope.isOpenAccess == true,
        publicationType: scope.publicationType ?? current.publicationType,
      ),
    );
  }

  void _onFilterChanged() {
    if (_syncingFilter) {
      return;
    }

    final nextFilter = SharedState.publicationFilterNotifier.value;
    final previousFilter = state.filter;

    state = state.copyWith(
      filter: nextFilter,
      searchQuery: nextFilter.keyword,
      selectedAuthorName: nextFilter.selectedAuthors.isEmpty
          ? null
          : nextFilter.selectedAuthors.first,
      sortBy: nextFilter.openAlexSort,
      clearAuthor: nextFilter.selectedAuthors.isEmpty,
    );

    if (_requiresApiReload(previousFilter, nextFilter)) {
      executeWorksFetchPipeline();
    } else {
      _applyLocalFilters(nextFilter);
    }
  }

  bool _requiresApiReload(
    PublicationFilter previous,
    PublicationFilter next,
  ) {
    return previous.keyword != next.keyword ||
        previous.fromYear != next.fromYear ||
        previous.toYear != next.toYear ||
        previous.minCitations != next.minCitations ||
        previous.openAccessOnly != next.openAccessOnly ||
        previous.publicationType != next.publicationType ||
        previous.sortBy != next.sortBy ||
        previous.taxonomy != next.taxonomy ||
        (previous.fetchAllResults ?? false) != (next.fetchAllResults ?? false);
  }

  Future<void> executeWorksFetchPipeline({bool showLoading = true}) async {
    state = state.copyWith(
      isLoading: showLoading ? true : state.isLoading,
      errorMessage: '',
    );
    try {
      final filter = _effectiveFilter();
      final List results;
      int totalCount = 0;
      if (filter.fetchAllResults == true) {
        results = await _openAlexApiService.getAllWorksByPublicationFilter(
          filter,
        );
        totalCount = results.length;
      } else {
        final data = await _openAlexApiService.getWorksByPublicationFilter(filter);
        results = data['results'] ?? [];
        totalCount = data['meta']?['count'] ?? results.length;
      }
      final originalPublications =
          results.map((json) => Publication.fromJson(json)).toList();
      final filteredPublications =
          PublicationFilterService.applyLocalFilters(originalPublications, filter);

      SharedState.setOriginalPublications(originalPublications);
      SharedState.setFilteredPublications(filteredPublications);
      SharedState.setTotalPublicationsCount(totalCount);

      state = state.copyWith(
        publications: filteredPublications,
        originalPublications: originalPublications,
        isLoading: showLoading ? false : state.isLoading,
        filter: filter,
        totalPublicationsCount: totalCount,
        searchQuery: filter.keyword,
        selectedAuthorName:
            filter.selectedAuthors.isEmpty ? null : filter.selectedAuthors.first,
        sortBy: filter.openAlexSort,
        clearAuthor: filter.selectedAuthors.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: showLoading ? false : state.isLoading,
        errorMessage: ErrorTranslator.translate(e),
      );
    }
  }

  PublicationFilter _effectiveFilter() {
    final scope = SharedState.activeResearchScopeNotifier.value;
    final sharedFilter = SharedState.publicationFilterNotifier.value;
    return sharedFilter.copyWith(
      keyword: scope.hasStructuredFilters ? scope.keyword : sharedFilter.keyword,
      taxonomy:
          scope.taxonomy.hasSelection ? scope.taxonomy : sharedFilter.taxonomy,
      fromYear: scope.yearFrom ?? sharedFilter.fromYear,
      toYear: scope.yearTo ?? sharedFilter.toYear,
      minCitations: scope.minCitationCount ?? sharedFilter.minCitations,
      openAccessOnly: scope.isOpenAccess == true || sharedFilter.openAccessOnly,
      publicationType: scope.publicationType ?? sharedFilter.publicationType,
    );
  }

  void _applyLocalFilters(PublicationFilter filter) {
    final filteredPublications = PublicationFilterService.applyLocalFilters(
      state.originalPublications,
      filter,
    );
    SharedState.setFilteredPublications(filteredPublications);
    state = state.copyWith(
      publications: filteredPublications,
      filter: filter,
      isLoading: false,
      selectedAuthorName:
          filter.selectedAuthors.isEmpty ? null : filter.selectedAuthors.first,
      clearAuthor: filter.selectedAuthors.isEmpty,
    );
  }

  void _setSharedFilter(PublicationFilter filter) {
    _syncingFilter = true;
    SharedState.setPublicationFilter(filter);
    _syncingFilter = false;
    _onFilterChanged();
  }

  Future<void> executeSearch(String keyword) async {
    SharedState.setKeyword(keyword);
  }

  void setAuthorFilter(String id, String name) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(selectedAuthors: [name]));
  }

  void clearAuthorFilter() {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(selectedAuthors: const []));
  }

  void setConceptFilter(String id, String name) {
    SharedState.activeQueryNotifier.value = name;
    state = state.copyWith(
      selectedConceptId: id,
      selectedConceptName: name,
    );
  }

  void clearConceptFilter() {
    state = state.copyWith(clearConcept: true);
  }

  void setTopicFilter(String id, String name) {
    SharedState.activeQueryNotifier.value = name;
    state = state.copyWith(
      selectedTopicId: id,
      selectedTopicName: name,
    );
  }

  void clearTopicFilter() {
    state = state.copyWith(clearTopic: true);
  }

  void setSortBy(String? sort) {
    final current = SharedState.publicationFilterNotifier.value;
    final sortKey = switch (sort) {
      'cited_by_count:desc' => 'most_cited',
      'publication_date:desc' => 'newest',
      'publication_date:asc' => 'oldest',
      _ => 'relevance',
    };
    _setSharedFilter(current.copyWith(sortBy: sortKey));
  }

  void clearSortBy() {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(sortBy: 'relevance'));
  }

  void setYearRange(int? fromYear, int? toYear) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(fromYear: fromYear, toYear: toYear));
  }

  void clearYearRange() {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(clearYear: true));
  }

  void setMinCitations(int? value) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(
      current.copyWith(minCitations: value, clearCitations: value == null),
    );
  }

  void setOpenAccessOnly(bool value) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(openAccessOnly: value));
  }

  void setPublicationType(String value) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(publicationType: value));
  }

  void setJournalFilter(List<String> journals) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(selectedJournals: journals));
  }

  void setTaxonomyFilter(ResearchTaxonomySelection taxonomy) {
    final current = SharedState.publicationFilterNotifier.value;
    _setSharedFilter(current.copyWith(taxonomy: taxonomy));
  }

  void clearAllFilters() {
    final keyword = SharedState.publicationFilterNotifier.value.keyword;
    _setSharedFilter(PublicationFilter.empty.copyWith(keyword: keyword));
  }

  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    SharedState.activeResearchScopeNotifier.removeListener(_onResearchScopeChanged);
    SharedState.publicationFilterNotifier.removeListener(_onFilterChanged);
    stateNotifier.dispose();
  }
}
