import 'package:flutter/material.dart';
import 'package:journal_trend_analysis_mb/utils/error_translator.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/models/trend_rank_item_model.dart';
import 'package:journal_trend_analysis_mb/services/trend_api_service.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';

class TrendNotifier extends ChangeNotifier {
  final TrendApiService _apiService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<int, int> _yearlyDistribution = {};
  List<Publication> _topPublications = [];
  List<TrendRankItem> _topJournals = [];
  List<TrendRankItem> _topAuthors = [];

  TrendNotifier({TrendApiService? apiService})
      : _apiService = apiService ?? TrendApiService() {
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    SharedState.activeResearchScopeNotifier.addListener(_onResearchScopeChanged);
    SharedState.filteredPublicationsNotifier
        .addListener(_onFilteredPublicationsChanged);
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<int, int> get yearlyDistribution => _yearlyDistribution;
  List<Publication> get topPublications => _topPublications;
  List<TrendRankItem> get topJournals => _topJournals;
  List<TrendRankItem> get topAuthors => _topAuthors;
  bool get hasData =>
      _yearlyDistribution.isNotEmpty ||
      _topPublications.isNotEmpty ||
      _topJournals.isNotEmpty ||
      _topAuthors.isNotEmpty ||
      _publications.isNotEmpty;

  void _onQueryChanged() {
    final scope = SharedState.activeResearchScopeNotifier.value;
    if (scope.hasStructuredFilters &&
        scope.displayLabel == SharedState.activeQueryNotifier.value) {
      return;
    }
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  void _onResearchScopeChanged() {
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  void _onFilteredPublicationsChanged() {
    final filtered = SharedState.filteredPublicationsNotifier.value;
    if (filtered.isEmpty) {
      return;
    }

    _publications = filtered;
    _topPublications = List<Publication>.from(filtered)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    _topPublications = _topPublications.take(5).toList();
    _topJournals = _buildTopJournalsFromPublications(filtered);
    _topAuthors = _buildTopAuthorsFromPublications(filtered);
    _yearlyDistribution = _buildYearlyDistributionFromPublications(filtered);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchTrendData(String query, {bool showLoading = true}) async {
    final scope = SharedState.activeResearchScopeNotifier.value;
    final cleanQuery = scope.hasStructuredFilters
        ? scope.keyword
        : (query.trim().isEmpty ? 'Artificial Intelligence' : query.trim());

    _isLoading = showLoading ? true : _isLoading;
    _errorMessage = null;
    notifyListeners();

    try {
      final coreResults = await Future.wait([
        _apiService.fetchPublicationsGroupByYear(cleanQuery, scope: scope),
        _apiService.fetchTopInfluentialPublications(
          cleanQuery,
          scope: scope,
          perPage: 20,
        ),
      ]);

      _yearlyDistribution = coreResults[0] as Map<int, int>;
      _topPublications =
          (coreResults[1] as List<Publication>).take(5).toList();
      _publications = _topPublications;

      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }

      final secondaryResults = await Future.wait([
        _apiService
            .fetchPublicationSample(cleanQuery, scope: scope, perPage: 50)
            .catchError((_) => <Publication>[]),
        _apiService
            .fetchTopResearchJournals(
              cleanQuery,
              scope: scope,
              perPage: 50,
            )
            .catchError((_) => <TrendRankItem>[]),
        _apiService
            .fetchTopContributingAuthors(
              cleanQuery,
              scope: scope,
              perPage: 50,
            )
            .catchError((_) => <TrendRankItem>[]),
      ]);

      final samplePublications = secondaryResults[0] as List<Publication>;
      if (samplePublications.isNotEmpty) {
        _publications = samplePublications;
        _topJournals = _buildTopJournalsFromPublications(samplePublications);
        _topAuthors = _buildTopAuthorsFromPublications(samplePublications);
      } else {
        _topJournals = _rankItemsFromResult(secondaryResults[1]);
        _topAuthors = _rankItemsFromResult(secondaryResults[2]);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorTranslator.translate(e);
      _publications = const [];
      _clearCalculations();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _clearCalculations() {
    _yearlyDistribution = const {};
    _topPublications = const [];
    _topJournals = const [];
    _topAuthors = const [];
  }

  Future<List<Publication>> fetchPublicationsForJournal(
    TrendRankItem journal,
  ) async {
    final query = SharedState.activeQueryNotifier.value.trim().isEmpty
        ? 'Artificial Intelligence'
        : SharedState.activeQueryNotifier.value.trim();
    final scope = SharedState.activeResearchScopeNotifier.value;
    final cleanQuery = scope.hasStructuredFilters ? scope.keyword : query;

    final localMatches = _publications
        .where((publication) => publication.journalName == journal.name)
        .toList();
    if (localMatches.isNotEmpty && journal.id == journal.name) {
      return localMatches;
    }

    try {
      final remoteMatches = await _apiService.fetchPublicationsByJournalId(
        cleanQuery,
        journal.id,
        scope: scope,
      );
      if (remoteMatches.isNotEmpty) {
        return remoteMatches;
      }
    } catch (_) {
      // Fall back to local matches below.
    }

    return localMatches;
  }

  Future<List<Publication>> fetchPublicationsForAuthor(
    TrendRankItem author,
  ) async {
    final query = SharedState.activeQueryNotifier.value.trim().isEmpty
        ? 'Artificial Intelligence'
        : SharedState.activeQueryNotifier.value.trim();
    final scope = SharedState.activeResearchScopeNotifier.value;
    final cleanQuery = scope.hasStructuredFilters ? scope.keyword : query;

    final localMatches = _publications
        .where((publication) => publication.authors.contains(author.name))
        .toList();
    if (localMatches.isNotEmpty && author.id == author.name) {
      return localMatches;
    }

    try {
      final remoteMatches = await _apiService.fetchPublicationsByAuthorId(
        cleanQuery,
        author.id,
        scope: scope,
      );
      if (remoteMatches.isNotEmpty) {
        return remoteMatches;
      }
    } catch (_) {
      // Fall back to local matches below.
    }

    return localMatches;
  }

  List<TrendRankItem> _buildTopJournalsFromPublications(
    List<Publication> publications,
  ) {
    final journalMap = <String, int>{};
    for (final publication in publications) {
      final journalName = publication.journalName.trim();
      if (journalName.isEmpty || journalName == 'Unknown Journal') {
        continue;
      }
      journalMap[journalName] = (journalMap[journalName] ?? 0) + 1;
    }

    return _topEntries(journalMap);
  }

  List<TrendRankItem> _buildTopAuthorsFromPublications(
    List<Publication> publications,
  ) {
    final authorMap = <String, int>{};
    for (final publication in publications) {
      for (final author in publication.authors) {
        final authorName = author.trim();
        if (authorName.isEmpty) {
          continue;
        }
        authorMap[authorName] = (authorMap[authorName] ?? 0) + 1;
      }
    }

    return _topEntries(authorMap);
  }

  Map<int, int> _buildYearlyDistributionFromPublications(
    List<Publication> publications,
  ) {
    final yearMap = <int, int>{};
    for (final publication in publications) {
      final year = publication.publicationYear;
      if (year <= 0) {
        continue;
      }
      yearMap[year] = (yearMap[year] ?? 0) + 1;
    }

    final entries = yearMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(entries);
  }

  List<TrendRankItem> _topEntries(Map<String, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((entry) => TrendRankItem(
              id: entry.key,
              name: entry.key,
              count: entry.value,
            ))
        .toList();
  }

  List<TrendRankItem> _rankItemsFromResult(Object? result) {
    if (result is! List) {
      return const [];
    }

    return result
        .where((item) => item is TrendRankItem || item is MapEntry)
        .map((item) {
          if (item is TrendRankItem) {
            return item;
          }

          final legacyEntry = item as MapEntry;
          final name = legacyEntry.key.toString();
          final count = int.tryParse(legacyEntry.value.toString()) ?? 0;
          return TrendRankItem(id: name, name: name, count: count);
        })
        .toList();
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    SharedState.activeResearchScopeNotifier.removeListener(_onResearchScopeChanged);
    SharedState.filteredPublicationsNotifier
        .removeListener(_onFilteredPublicationsChanged);
    super.dispose();
  }
}
