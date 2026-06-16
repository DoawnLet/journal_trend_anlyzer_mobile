import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/trend_api_service.dart';
import 'shared_state.dart';

class TrendNotifier extends ChangeNotifier {
  final TrendApiService _apiService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<int, int> _yearlyDistribution = {};
  List<Publication> _topPublications = [];
  List<MapEntry<String, int>> _topJournals = [];
  List<MapEntry<String, int>> _topAuthors = [];

  TrendNotifier({TrendApiService? apiService})
      : _apiService = apiService ?? TrendApiService() {
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<int, int> get yearlyDistribution => _yearlyDistribution;
  List<Publication> get topPublications => _topPublications;
  List<MapEntry<String, int>> get topJournals => _topJournals;
  List<MapEntry<String, int>> get topAuthors => _topAuthors;
  bool get hasData =>
      _yearlyDistribution.isNotEmpty ||
      _topPublications.isNotEmpty ||
      _topJournals.isNotEmpty ||
      _topAuthors.isNotEmpty ||
      _publications.isNotEmpty;

  void _onQueryChanged() {
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  Future<void> fetchTrendData(String query, {bool showLoading = true}) async {
    final cleanQuery =
        query.trim().isEmpty ? 'Artificial Intelligence' : query.trim();

    _isLoading = showLoading ? true : _isLoading;
    _errorMessage = null;
    notifyListeners();

    try {
      final coreResults = await Future.wait([
        _apiService.fetchPublicationsGroupByYear(cleanQuery),
        _apiService.fetchTopInfluentialPublications(cleanQuery, perPage: 20),
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
            .fetchPublicationSample(cleanQuery, perPage: 50)
            .catchError((_) => <Publication>[]),
        _apiService
            .fetchTopResearchJournals(cleanQuery, perPage: 50)
            .catchError((_) => <MapEntry<String, int>>[]),
        _apiService
            .fetchTopContributingAuthors(cleanQuery, perPage: 50)
            .catchError((_) => <MapEntry<String, int>>[]),
      ]);

      final samplePublications = secondaryResults[0] as List<Publication>;
      if (samplePublications.isNotEmpty) {
        _publications = samplePublications;
      }
      _topJournals = secondaryResults[1] as List<MapEntry<String, int>>;
      _topAuthors = secondaryResults[2] as List<MapEntry<String, int>>;
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

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    super.dispose();
  }
}
