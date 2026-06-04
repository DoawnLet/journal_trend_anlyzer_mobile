import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../widgets/search_filter_bottom_sheet.dart';
import '../widgets/search_input_field.dart';
import '../widgets/search_active_filters.dart';
import '../widgets/search_results_list.dart';
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
    SharedState.activeQueryNotifier.value = query;
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(notifier: widget.notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Kiếm Đề Tài'),
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
              child: SizedBox(
                height: _isSearchVisible ? 88.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchInputField(
                    controller: _searchController,
                    onSearchTriggered: _triggerSearch,
                  ),
                ),
              ),
            ),
          ),
          
          // Active Filter Chips
          SearchActiveFilters(notifier: widget.notifier),

          // Vùng hiển thị kết quả
          Expanded(
            child: SearchResultsList(
              notifier: widget.notifier,
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }
}
