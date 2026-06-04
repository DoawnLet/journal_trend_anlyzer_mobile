import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/dashboard_api_service.dart';
import 'shared_state.dart';

/// Bộ quản lý trạng thái Dashboard chiến lược.
/// Nhận từ khóa tìm kiếm toàn cục, tự động tải dữ liệu từ API và tính toán
/// các chỉ số tổng hợp (tổng số bài, trích dẫn trung bình, năm hoạt động mạnh nhất,
/// tác giả nổi bật, tạp chí đứng đầu, bài báo có ảnh hưởng lớn nhất).
class DashboardNotifier extends ChangeNotifier {
  final DashboardApiService _apiService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Các chỉ số tính toán (Quy tắc: Không viết logic xử lý dữ liệu ở View)
  int _totalPublications = 0;
  double _averageCitations = 0.0;
  int _mostActiveYear = 0;

  // Các thực thể nổi bật (Outliers)
  String _topJournalName = 'Không có dữ liệu';
  int _topJournalCount = 0;
  String _topAuthorName = 'Không có dữ liệu';
  int _topAuthorCount = 0;
  Publication? _mostInfluentialPaper;

  DashboardNotifier({DashboardApiService? apiService})
      : _apiService = apiService ?? DashboardApiService() {
    SharedState.activeQueryNotifier.addListener(_onQueryChanged);
    fetchDashboardData(SharedState.activeQueryNotifier.value);
  }

  List<Publication> get publications => _publications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalPublications => _totalPublications;
  double get averageCitations => _averageCitations;
  int get mostActiveYear => _mostActiveYear;
  String get topJournalName => _topJournalName;
  int get topJournalCount => _topJournalCount;
  String get topAuthorName => _topAuthorName;
  int get topAuthorCount => _topAuthorCount;
  Publication? get mostInfluentialPaper => _mostInfluentialPaper;

  void _onQueryChanged() {
    fetchDashboardData(SharedState.activeQueryNotifier.value);
  }

  /// Tải dữ liệu phục vụ Dashboard (hoặc mặc định nếu trống)
  Future<void> fetchDashboardData(String query) async {
    final cleanQuery = query.trim().isEmpty ? 'Artificial Intelligence' : query.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _publications = await _apiService.fetchDashboardPublications(cleanQuery, perPage: 50);
      _processCalculations();
    } catch (e) {
      _errorMessage = ErrorTranslator.translate(e);
      _publications = const [];
      _clearCalculations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thực hiện tính toán chỉ số tổng hợp
  void _processCalculations() {
    if (_publications.isEmpty) {
      _clearCalculations();
      return;
    }

    // 1. Tổng số bài báo
    _totalPublications = _publications.length;

    // 2. Điểm trích dẫn trung bình
    int sumCitations = 0;
    for (var pub in _publications) {
      sumCitations += pub.citationCount;
    }
    _averageCitations = _totalPublications > 0 ? sumCitations / _totalPublications : 0.0;

    // 3. Năm công bố tích cực nhất
    final yearMap = <int, int>{};
    for (var pub in _publications) {
      if (pub.publicationYear > 0) {
        yearMap[pub.publicationYear] = (yearMap[pub.publicationYear] ?? 0) + 1;
      }
    }
    if (yearMap.isNotEmpty) {
      _mostActiveYear = yearMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    } else {
      _mostActiveYear = 0;
    }

    // 4. Tạp chí có số bài viết nhiều nhất (Top Journal Outlier)
    final journalMap = <String, int>{};
    for (var pub in _publications) {
      if (pub.journalName.isNotEmpty && pub.journalName != 'Unknown Journal') {
        journalMap[pub.journalName] = (journalMap[pub.journalName] ?? 0) + 1;
      }
    }
    if (journalMap.isNotEmpty) {
      final topJournalEntry = journalMap.entries.reduce((a, b) => a.value > b.value ? a : b);
      _topJournalName = topJournalEntry.key;
      _topJournalCount = topJournalEntry.value;
    } else {
      _topJournalName = 'Không có dữ liệu';
      _topJournalCount = 0;
    }

    // 5. Tác giả xuất bản nhiều nhất (Top Author Outlier)
    final authorMap = <String, int>{};
    for (var pub in _publications) {
      for (var author in pub.authors) {
        if (author.isNotEmpty) {
          authorMap[author] = (authorMap[author] ?? 0) + 1;
        }
      }
    }
    if (authorMap.isNotEmpty) {
      final topAuthorEntry = authorMap.entries.reduce((a, b) => a.value > b.value ? a : b);
      _topAuthorName = topAuthorEntry.key;
      _topAuthorCount = topAuthorEntry.value;
    } else {
      _topAuthorName = 'Không có dữ liệu';
      _topAuthorCount = 0;
    }

    // 6. Bài viết có số trích dẫn cao nhất (Most Influential Paper Outlier)
    if (_publications.isNotEmpty) {
      _mostInfluentialPaper = _publications.reduce((a, b) => a.citationCount > b.citationCount ? a : b);
    } else {
      _mostInfluentialPaper = null;
    }
  }

  void _clearCalculations() {
    _totalPublications = 0;
    _averageCitations = 0.0;
    _mostActiveYear = 0;
    _topJournalName = 'N/A';
    _topJournalCount = 0;
    _topAuthorName = 'N/A';
    _topAuthorCount = 0;
    _mostInfluentialPaper = null;
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onQueryChanged);
    super.dispose();
  }
}
