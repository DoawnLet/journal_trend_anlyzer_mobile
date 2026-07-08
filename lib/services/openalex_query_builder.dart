import 'package:journal_trend_analysis_mb/models/publication_filter_model.dart';
import 'package:journal_trend_analysis_mb/models/research_scope_model.dart';

class OpenAlexQueryBuilder {
  static Map<String, String> worksParams({
    ResearchScope scope = ResearchScope.empty,
    String? query,
    String? filter,
    String? sort,
    String? groupBy,
    int perPage = 20,
  }) {
    final filters = <String>[];

    final taxonomyFilter = scope.taxonomy.worksFilter;
    if (taxonomyFilter != null && taxonomyFilter.isNotEmpty) {
      filters.add(taxonomyFilter);
    }
    if (scope.authorId != null && scope.authorId!.isNotEmpty) {
      filters.add('authorships.author.id:${scope.authorId}');
    }
    if (scope.sourceId != null && scope.sourceId!.isNotEmpty) {
      filters.add('primary_location.source.id:${scope.sourceId}');
    }
    if (scope.institutionId != null && scope.institutionId!.isNotEmpty) {
      filters.add('authorships.institutions.id:${scope.institutionId}');
    }
    if (scope.funderId != null && scope.funderId!.isNotEmpty) {
      filters.add('grants.funder:${scope.funderId}');
    }
    if (scope.yearFrom != null) {
      filters.add('from_publication_date:${scope.yearFrom}-01-01');
    }
    if (scope.yearTo != null) {
      filters.add('to_publication_date:${scope.yearTo}-12-31');
    }
    if (scope.publicationType != null && scope.publicationType!.isNotEmpty) {
      filters.add('type:${scope.publicationType}');
    }
    if (scope.isOpenAccess != null) {
      filters.add('is_oa:${scope.isOpenAccess}');
    }
    if (scope.minCitationCount != null) {
      filters.add('cited_by_count:>${scope.minCitationCount}');
    }
    if (filter != null && filter.trim().isNotEmpty) {
      filters.add(filter.trim());
    }

    final params = <String, String>{
      'per_page': perPage.toString(),
    };

    final cleanQuery =
        scope.hasStructuredFilters ? scope.keyword.trim() : query?.trim();
    if (cleanQuery != null && cleanQuery.isNotEmpty) {
      params['search'] = cleanQuery;
    }
    if (filters.isNotEmpty) {
      params['filter'] = filters.join(',');
    }
    if (sort != null && sort.isNotEmpty) {
      params['sort'] = sort;
    }
    if (groupBy != null && groupBy.isNotEmpty) {
      params['group_by'] = groupBy;
    }

    return params;
  }

  static Uri buildWorksUri(
    PublicationFilter filter, {
    int perPage = 50,
    String mailto = 'minhvtbd12345@fpt.edu.vn',
    String? cursor,
  }) {
    final filters = <String>[];

    if (filter.fromYear != null) {
      filters.add('from_publication_date:${filter.fromYear}-01-01');
    }
    if (filter.toYear != null) {
      filters.add('to_publication_date:${filter.toYear}-12-31');
    }
    if (filter.minCitations != null && filter.minCitations! > 0) {
      filters.add('cited_by_count:>${filter.minCitations}');
    }
    if (filter.openAccessOnly) {
      filters.add('is_oa:true');
    }
    if (filter.publicationType != 'all') {
      filters.add('type:${filter.publicationType}');
    }
    final taxonomyFilter = filter.taxonomy.worksFilter;
    if (taxonomyFilter != null && taxonomyFilter.isNotEmpty) {
      filters.add(taxonomyFilter);
    }

    final queryParameters = <String, String>{
      'per_page': perPage.toString(),
      'mailto': mailto,
    };

    if (filter.keyword.trim().isNotEmpty) {
      queryParameters['search'] = filter.keyword.trim();
    }
    if (filters.isNotEmpty) {
      queryParameters['filter'] = filters.join(',');
    }
    final sort = filter.openAlexSort;
    if (sort != null) {
      queryParameters['sort'] = sort;
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    return Uri.https('api.openalex.org', '/works', queryParameters);
  }
}
