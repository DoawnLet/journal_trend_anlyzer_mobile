import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/search_advanced_filter_drawer.dart';
import '../widgets/search_input_field.dart';
import '../widgets/search_active_filters.dart';
import '../widgets/search_results_list.dart';
import '../models/research_scope_model.dart';
import '../state_management/search_notifier.dart';
import '../state_management/shared_state.dart';

/// Màn hình tìm kiếm đề tài (Search Page).
/// Cung cấp ô nhập liệu và hiển thị danh sách kết quả bài viết từ OpenAlex API.
class SearchPage extends StatefulWidget {
  final SearchNotifier notifier;

  const SearchPage({super.key, required this.notifier});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    // Đồng bộ ô nhập liệu với từ khóa toàn cục ban đầu
    _searchController = TextEditingController(text: SharedState.activeQueryNotifier.value);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    SharedState.activeQueryNotifier.addListener(_onActiveQueryChanged);
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onActiveQueryChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onActiveQueryChanged() {
    if (mounted) {
      final newValue = SharedState.activeQueryNotifier.value;
      if (_searchController.text != newValue) {
        _searchController.text = newValue;
      }
    }
  }

  void _scrollListener() {
    // Luôn hiển thị thanh tìm kiếm khi cuộn lên sát đầu trang
    if (_scrollController.position.pixels <= 10) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
      }
      return;
    }

    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isSearchVisible) {
        setState(() {
          _isSearchVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isSearchVisible) {
        setState(() {
          _isSearchVisible = true;
        });
      }
    }
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    // Cập nhật từ khóa tìm kiếm toàn cục, tự động kích hoạt Notifier tải dữ liệu
    SharedState.setKeyword(query);
  }

  Future<void> _refreshSearch() async {
    await widget.notifier.executeWorksFetchPipeline(showLoading: false);
  }

  void _showFilterBottomSheet(BuildContext context) {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SearchAdvancedFilterDrawer(notifier: widget.notifier),
      appBar: AppBar(
        title: const Text('Research Publications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            tooltip: 'Bộ lọc & Sắp xếp',
            onPressed: () => _showFilterBottomSheet(context),
          ),
          ListenableBuilder(
            listenable: SharedState.themeModeNotifier,
            builder: (context, _) {
              final isDark = SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                tooltip: isDark ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối',
                onPressed: () {
                  SharedState.themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isSearchVisible
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildResearchSearchHeader(theme),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SearchInputField(
                            controller: _searchController,
                            onSearchTriggered: _triggerSearch,
                          ),
                        ),
                        _buildSearchSummaryV2(theme),
                        SearchActiveFilters(notifier: widget.notifier),
                        _buildResultToolbar(theme),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Vùng hiển thị kết quả
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF80CBC4),
              backgroundColor: const Color(0xFF1E4646),
              onRefresh: _refreshSearch,
              child: SearchResultsList(
                notifier: widget.notifier,
                scrollController: _scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchSearchHeader(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: SharedState.activeResearchScopeNotifier,
      builder: (context, scope, _) {
        final scopeLabel = scope.displayLabel.isEmpty
            ? 'Chưa chọn topic'
            : scope.breadcrumb;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.manage_search_rounded,
                    color: Color(0xFF80CBC4),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tìm publication để phân tích',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kết quả tìm kiếm sẽ là đầu vào cho trend chart, citation distribution, top papers, journals và authors.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Scope: $scopeLabel',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showFilterBottomSheet(context),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Filter'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF80CBC4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSummaryV2(ThemeData theme) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: widget.notifier.stateNotifier,
      builder: (context, state, _) {
        final scope = SharedState.activeResearchScopeNotifier.value;
        final query = _summaryQueryV2(state, scope);
        final count = state.publications.length;

        if (query.isEmpty && count == 0 && !scope.hasStructuredFilters) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count kết quả cho "$query"',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: 'Sắp xếp: ${_sortLabelV2(state.sortBy)}'),
                  _SummaryChip(label: 'Năm: ${_yearLabelV2(scope)}'),
                  if (state.selectedAuthorName != null)
                    _SummaryChip(label: 'Tác giả: ${state.selectedAuthorName}'),
                  if (state.selectedConceptName != null)
                    _SummaryChip(label: 'Concept: ${state.selectedConceptName}'),
                  if (state.selectedTopicName != null)
                    _SummaryChip(label: 'Topic: ${state.selectedTopicName}'),
                  if (scope.isOpenAccess == true)
                    const _SummaryChip(label: 'Open Access'),
                  if (scope.publicationType != null)
                    _SummaryChip(label: 'Loại: ${scope.publicationType}'),
                  if (scope.minCitationCount != null)
                    _SummaryChip(
                      label: 'Trích dẫn tối thiểu: ${scope.minCitationCount}',
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _summaryQueryV2(SearchState state, ResearchScope scope) {
    final displayLabel = scope.displayLabel.trim();
    if (displayLabel.isNotEmpty) {
      return displayLabel;
    }
    if (state.selectedAuthorName?.trim().isNotEmpty == true) {
      return state.selectedAuthorName!.trim();
    }
    if (state.selectedConceptName?.trim().isNotEmpty == true) {
      return state.selectedConceptName!.trim();
    }
    if (state.selectedTopicName?.trim().isNotEmpty == true) {
      return state.selectedTopicName!.trim();
    }
    if (state.searchQuery.trim().isNotEmpty) {
      return state.searchQuery.trim();
    }
    final activeQuery = SharedState.activeQueryNotifier.value.trim();
    return activeQuery.isEmpty ? 'Tất cả' : activeQuery;
  }

  String _sortLabelV2(String? sortBy) {
    switch (sortBy) {
      case 'publication_date:desc':
        return 'Mới nhất';
      case 'publication_date:asc':
        return 'Cũ nhất';
      case 'cited_by_count:desc':
        return 'Trích dẫn cao nhất';
      default:
        return 'Liên quan nhất';
    }
  }

  String _yearLabelV2(ResearchScope scope) {
    final yearFrom = scope.yearFrom;
    final yearTo = scope.yearTo;
    if (yearFrom == null && yearTo == null) {
      return 'Tất cả';
    }
    if (yearFrom != null && yearTo != null) {
      return '$yearFrom-$yearTo';
    }
    if (yearFrom != null) {
      return 'Từ $yearFrom';
    }
    return 'Đến $yearTo';
  }

  // ignore: unused_element
  Widget _buildSearchSummary(ThemeData theme) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: widget.notifier.stateNotifier,
      builder: (context, state, _) {
        final scope = SharedState.activeResearchScopeNotifier.value;
        final query = _summaryQuery(state, scope);
        final sort = _sortLabel(state.sortBy);
        final year = _yearLabel(scope);
        final count = state.publications.length;

        if (query.isEmpty && count == 0 && !scope.hasStructuredFilters) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count kết quả cho “${query.isEmpty ? 'Tất cả' : query}”',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: 'Sắp xếp: $sort'),
                  _SummaryChip(label: 'Năm: $year'),
                  if (scope.isOpenAccess == true)
                    const _SummaryChip(label: 'Open Access'),
                  if (scope.publicationType != null)
                    _SummaryChip(label: 'Loại: ${scope.publicationType}'),
                  if (scope.minCitationCount != null)
                    _SummaryChip(label: 'Min citations: ${scope.minCitationCount}'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _summaryQuery(SearchState state, dynamic scope) {
    final displayLabel = scope.displayLabel?.toString() ?? '';
    if (displayLabel.trim().isNotEmpty) {
      return displayLabel.trim();
    }
    if (state.searchQuery.trim().isNotEmpty) {
      return state.searchQuery.trim();
    }
    return SharedState.activeQueryNotifier.value.trim();
  }

  String _sortLabel(String? sortBy) {
    switch (sortBy) {
      case 'publication_date:desc':
        return 'Mới nhất';
      case 'publication_date:asc':
        return 'Cũ nhất';
      case 'cited_by_count:desc':
        return 'Trích dẫn cao nhất';
      default:
        return 'Liên quan nhất';
    }
  }

  String _yearLabel(dynamic scope) {
    final yearFrom = scope.yearFrom;
    final yearTo = scope.yearTo;
    if (yearFrom == null && yearTo == null) {
      return 'Tất cả';
    }
    if (yearFrom != null && yearTo != null) {
      return '$yearFrom-$yearTo';
    }
    if (yearFrom != null) {
      return 'Từ $yearFrom';
    }
    return 'Đến $yearTo';
  }

  Widget _buildResultToolbar(ThemeData theme) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: widget.notifier.stateNotifier,
      builder: (context, state, _) {
        if (state.isLoading ||
            state.errorMessage.isNotEmpty ||
            state.publications.isEmpty) {
          return const SizedBox.shrink();
        }

        final count = state.publications.length;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count publications ready for analysis',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  SharedState.activeTabNotifier.value = 2;
                },
                icon: const Icon(Icons.insights_rounded, size: 16),
                label: const Text('Analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF80CBC4),
                  foregroundColor: const Color(0xFF0B2545),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;

  const _SummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
