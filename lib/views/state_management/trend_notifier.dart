import 'package:flutter/material.dart';
import '../../core/utils/error_translator.dart';
import '../models/publication_model.dart';
import '../services/trend_api_service.dart';
import 'shared_state.dart';

/// Bộ quản lý trạng thái Xu hướng bài viết.
/// Thực hiện các thuật toán nhóm và sắp xếp dữ liệu (năm, số trích dẫn, tác giả, tạp chí)
/// để cung cấp dữ liệu sạch cho màn hình xu hướng vẽ biểu đồ và bảng xếp hạng.
class TrendNotifier extends ChangeNotifier {
  final TrendApiService _apiService;

  List<Publication> _publications = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Dữ liệu đã xử lý phục vụ biểu diễn trực quan
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

  void _onQueryChanged() {
    fetchTrendData(SharedState.activeQueryNotifier.value);
  }

  /// Tải dữ liệu xu hướng của từ khóa (hoặc mặc định nếu trống)
  Future<void> fetchTrendData(String query) async {
    final cleanQuery = query.trim().isEmpty ? 'Artificial Intelligence' : query.trim();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi song song API gom nhóm theo năm và API lấy danh sách bài báo nổi tiếng nhất
      final results = await Future.wait([
        _apiService.fetchPublicationsGroupByYear(cleanQuery),
        _apiService.fetchTopInfluentialPublications(cleanQuery, perPage: 20),
      ]);

      _yearlyDistribution = results[0] as Map<int, int>;
      _publications = results[1] as List<Publication>;

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

  /// Thuật toán xử lý và gom nhóm dữ liệu (Quy định: Không viết logic xử lý dữ liệu ở View)
  void _processCalculations() {
    // 1. Phân bố bài viết theo năm (nếu chưa được cung cấp từ API group_by)
    if (_yearlyDistribution.isEmpty) {
      final yearMap = <int, int>{};
      for (var pub in _publications) {
        if (pub.publicationYear > 0) {
          yearMap[pub.publicationYear] = (yearMap[pub.publicationYear] ?? 0) + 1;
        }
      }
      // Sắp xếp phân bố theo thứ tự năm tăng dần
      _yearlyDistribution = Map.fromEntries(
        yearMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
    }

    // 2. Top bài viết ảnh hưởng nhất (sắp xếp theo lượt trích dẫn giảm dần)
    final sortedPubs = List<Publication>.from(_publications)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    _topPublications = sortedPubs.take(5).toList();

    // 3. Top Tạp chí nghiên cứu đóng góp nhiều nhất
    final journalMap = <String, int>{};
    for (var pub in _publications) {
      if (pub.journalName.isNotEmpty && pub.journalName != 'Unknown Journal') {
        journalMap[pub.journalName] = (journalMap[pub.journalName] ?? 0) + 1;
      }
    }
    _topJournals = journalMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topJournals = _topJournals.take(5).toList();

    // 4. Top Tác giả đóng góp nhiều nhất
    final authorMap = <String, int>{};
    for (var pub in _publications) {
      for (var author in pub.authors) {
        if (author.isNotEmpty) {
          authorMap[author] = (authorMap[author] ?? 0) + 1;
        }
      }
    }
    _topAuthors = authorMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topAuthors = _topAuthors.take(5).toList();
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
