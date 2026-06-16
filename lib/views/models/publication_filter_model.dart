import 'research_taxonomy_model.dart';

class PublicationFilter {
  final String keyword;
  final int? fromYear;
  final int? toYear;
  final int? minCitations;
  final bool openAccessOnly;
  final String sortBy;
  final String publicationType;
  final List<String> selectedAuthors;
  final List<String> selectedJournals;
  final ResearchTaxonomySelection taxonomy;

  const PublicationFilter({
    this.keyword = '',
    this.fromYear,
    this.toYear,
    this.minCitations,
    this.openAccessOnly = false,
    this.sortBy = 'relevance',
    this.publicationType = 'all',
    this.selectedAuthors = const [],
    this.selectedJournals = const [],
    this.taxonomy = ResearchTaxonomySelection.empty,
  });

  static const empty = PublicationFilter();

  bool get hasActiveFilters =>
      fromYear != null ||
      toYear != null ||
      minCitations != null ||
      openAccessOnly ||
      sortBy != 'relevance' ||
      publicationType != 'all' ||
      selectedAuthors.isNotEmpty ||
      selectedJournals.isNotEmpty ||
      taxonomy.hasSelection;

  int get activeFilterCount {
    var count = 0;
    if (fromYear != null || toYear != null) count++;
    if (minCitations != null) count++;
    if (openAccessOnly) count++;
    if (sortBy != 'relevance') count++;
    if (publicationType != 'all') count++;
    if (selectedAuthors.isNotEmpty) count++;
    if (selectedJournals.isNotEmpty) count++;
    if (taxonomy.hasSelection) count++;
    return count;
  }

  bool get hasApiLevelFilters =>
      fromYear != null ||
      toYear != null ||
      minCitations != null ||
      openAccessOnly ||
      sortBy != 'relevance' ||
      publicationType != 'all' ||
      taxonomy.hasSelection;

  bool get hasLocalFilters =>
      selectedAuthors.isNotEmpty ||
      selectedJournals.isNotEmpty ||
      taxonomy.hasSelection;

  String? get openAlexSort {
    switch (sortBy) {
      case 'most_cited':
        return 'cited_by_count:desc';
      case 'newest':
        return 'publication_date:desc';
      case 'oldest':
        return 'publication_date:asc';
      default:
        return null;
    }
  }

  String get sortLabel {
    switch (sortBy) {
      case 'most_cited':
        return 'Trích dẫn cao nhất';
      case 'newest':
        return 'Mới nhất';
      case 'oldest':
        return 'Cũ nhất';
      default:
        return 'Liên quan nhất';
    }
  }

  String get yearLabel {
    if (fromYear == null && toYear == null) return 'Tất cả';
    if (fromYear != null && toYear != null) return '$fromYear-$toYear';
    if (fromYear != null) return 'Từ $fromYear';
    return 'Đến $toYear';
  }

  PublicationFilter copyWith({
    String? keyword,
    int? fromYear,
    int? toYear,
    int? minCitations,
    bool? openAccessOnly,
    String? sortBy,
    String? publicationType,
    List<String>? selectedAuthors,
    List<String>? selectedJournals,
    ResearchTaxonomySelection? taxonomy,
    bool clearYear = false,
    bool clearCitations = false,
    bool clearTaxonomy = false,
  }) {
    return PublicationFilter(
      keyword: keyword ?? this.keyword,
      fromYear: clearYear ? null : (fromYear ?? this.fromYear),
      toYear: clearYear ? null : (toYear ?? this.toYear),
      minCitations: clearCitations ? null : (minCitations ?? this.minCitations),
      openAccessOnly: openAccessOnly ?? this.openAccessOnly,
      sortBy: sortBy ?? this.sortBy,
      publicationType: publicationType ?? this.publicationType,
      selectedAuthors: selectedAuthors ?? this.selectedAuthors,
      selectedJournals: selectedJournals ?? this.selectedJournals,
      taxonomy: clearTaxonomy
          ? ResearchTaxonomySelection.empty
          : (taxonomy ?? this.taxonomy),
    );
  }

  PublicationFilter reset({String? keyword}) {
    return PublicationFilter(keyword: keyword ?? this.keyword);
  }
}
