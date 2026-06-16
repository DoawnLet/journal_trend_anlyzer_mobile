import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/dashboard_stats_model.dart';
import '../models/publication_model.dart';
import '../services/dashboard_api_service.dart';
import 'shared_state.dart';

class DashboardNotifier extends ChangeNotifier {
  final DashboardApiService _apiService;

  DashboardStats _stats = DashboardStats.empty;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardNotifier({DashboardApiService? apiService})
      : _apiService = apiService ?? DashboardApiService() {
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    fetchDashboardData(SharedState.activeQueryNotifier.value);
  }

  List<Publication> get publications => _stats.samplePublications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData =>
      _stats.totalPublications > 0 ||
      _stats.mostInfluentialPaper != null ||
      _stats.samplePublications.isNotEmpty;

  int get totalPublications => _stats.totalPublications;
  double get averageCitations => _stats.averageCitations;
  int get mostActiveYear => _stats.mostActiveYear;
  String get topJournalName => _stats.topJournalName;
  int get topJournalCount => _stats.topJournalCount;
  String get topAuthorName => _stats.topAuthorName;
  int get topAuthorCount => _stats.topAuthorCount;
  Publication? get mostInfluentialPaper => _stats.mostInfluentialPaper;

  void _onQueryChanged() {
    fetchDashboardData(SharedState.activeQueryNotifier.value);
  }

  Future<void> fetchDashboardData(String query, {bool showLoading = true}) async {
    final cleanQuery =
        query.trim().isEmpty ? 'Artificial Intelligence' : query.trim();

    _isLoading = showLoading ? true : _isLoading;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _apiService.fetchDashboardStats(cleanQuery);
    } catch (e) {
      _errorMessage = ErrorTranslator.translate(e);
      _stats = DashboardStats.empty;
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    super.dispose();
  }
}
