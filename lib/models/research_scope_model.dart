import 'package:journal_trend_analysis_mb/models/research_taxonomy_model.dart';

class ResearchScope {
  final String keyword;
  final ResearchTaxonomySelection taxonomy;
  final String? authorId;
  final String? authorName;
  final String? sourceId;
  final String? sourceName;
  final String? institutionId;
  final String? institutionName;
  final String? funderId;
  final String? funderName;
  final int? yearFrom;
  final int? yearTo;
  final String? publicationType;
  final bool? isOpenAccess;
  final int? minCitationCount;

  const ResearchScope({
    this.keyword = '',
    this.taxonomy = ResearchTaxonomySelection.empty,
    this.authorId,
    this.authorName,
    this.sourceId,
    this.sourceName,
    this.institutionId,
    this.institutionName,
    this.funderId,
    this.funderName,
    this.yearFrom,
    this.yearTo,
    this.publicationType,
    this.isOpenAccess,
    this.minCitationCount,
  });

  static const empty = ResearchScope();

  bool get hasStructuredFilters =>
      taxonomy.hasSelection ||
      _hasValue(authorId) ||
      _hasValue(sourceId) ||
      _hasValue(institutionId) ||
      _hasValue(funderId) ||
      yearFrom != null ||
      yearTo != null ||
      _hasValue(publicationType) ||
      isOpenAccess != null ||
      minCitationCount != null;

  bool get hasSearchableInput => keyword.trim().isNotEmpty || hasStructuredFilters;

  String get displayLabel {
    if (taxonomy.hasSelection) {
      return taxonomy.displayLabel;
    }
    if (_hasValue(sourceName)) {
      return sourceName!;
    }
    if (_hasValue(authorName)) {
      return authorName!;
    }
    if (_hasValue(institutionName)) {
      return institutionName!;
    }
    if (_hasValue(funderName)) {
      return funderName!;
    }
    return keyword.trim();
  }

  String get breadcrumb {
    if (taxonomy.hasSelection) {
      return taxonomy.breadcrumb;
    }
    return displayLabel;
  }

  String get effectiveSearchQuery {
    return hasStructuredFilters ? keyword.trim() : keyword.trim();
  }

  List<String> get worksFilters {
    final filters = <String>[];

    final taxonomyFilter = taxonomy.worksFilter;
    if (_hasValue(taxonomyFilter)) {
      filters.add(taxonomyFilter!);
    }
    if (_hasValue(authorId)) {
      filters.add('authorships.author.id:$authorId');
    }
    if (_hasValue(sourceId)) {
      filters.add('primary_location.source.id:$sourceId');
    }
    if (_hasValue(institutionId)) {
      filters.add('authorships.institutions.id:$institutionId');
    }
    if (_hasValue(funderId)) {
      filters.add('grants.funder:$funderId');
    }
    if (yearFrom != null || yearTo != null) {
      filters.add('publication_year:${yearFrom ?? ''}-${yearTo ?? ''}');
    }
    if (_hasValue(publicationType)) {
      filters.add('type:$publicationType');
    }
    if (isOpenAccess != null) {
      filters.add('is_oa:$isOpenAccess');
    }
    if (minCitationCount != null) {
      filters.add('cited_by_count:>$minCitationCount');
    }

    return filters;
  }

  String? get worksFilterQuery {
    final filters = worksFilters;
    return filters.isEmpty ? null : filters.join(',');
  }

  ResearchScope copyWith({
    String? keyword,
    ResearchTaxonomySelection? taxonomy,
    String? authorId,
    String? authorName,
    String? sourceId,
    String? sourceName,
    String? institutionId,
    String? institutionName,
    String? funderId,
    String? funderName,
    int? yearFrom,
    int? yearTo,
    String? publicationType,
    bool? isOpenAccess,
    int? minCitationCount,
    bool clearTaxonomy = false,
    bool clearAuthor = false,
    bool clearSource = false,
    bool clearInstitution = false,
    bool clearFunder = false,
    bool clearYearRange = false,
    bool clearPublicationType = false,
    bool clearOpenAccess = false,
    bool clearMinCitationCount = false,
  }) {
    return ResearchScope(
      keyword: keyword ?? this.keyword,
      taxonomy: clearTaxonomy ? ResearchTaxonomySelection.empty : (taxonomy ?? this.taxonomy),
      authorId: clearAuthor ? null : (authorId ?? this.authorId),
      authorName: clearAuthor ? null : (authorName ?? this.authorName),
      sourceId: clearSource ? null : (sourceId ?? this.sourceId),
      sourceName: clearSource ? null : (sourceName ?? this.sourceName),
      institutionId: clearInstitution ? null : (institutionId ?? this.institutionId),
      institutionName: clearInstitution ? null : (institutionName ?? this.institutionName),
      funderId: clearFunder ? null : (funderId ?? this.funderId),
      funderName: clearFunder ? null : (funderName ?? this.funderName),
      yearFrom: clearYearRange ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYearRange ? null : (yearTo ?? this.yearTo),
      publicationType:
          clearPublicationType ? null : (publicationType ?? this.publicationType),
      isOpenAccess: clearOpenAccess ? null : (isOpenAccess ?? this.isOpenAccess),
      minCitationCount: clearMinCitationCount
          ? null
          : (minCitationCount ?? this.minCitationCount),
    );
  }

  static bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
