import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/publication_card.dart';
import '../widgets/glass_card.dart';
import '../state_management/search_notifier.dart';
import '../state_management/shared_state.dart';
import 'detail_page.dart';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm Kiếm Đề Tài'),
        actions: [
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
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _triggerSearch(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập từ khóa (vd: Machine Learning, Quantum...)',
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        onPressed: _triggerSearch,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Vùng hiển thị kết quả (Dùng ValueListenableBuilder lắng nghe cập nhật trạng thái)
          Expanded(
            child: ValueListenableBuilder<SearchState>(
              valueListenable: widget.notifier.stateNotifier,
              builder: (context, state, _) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }

                if (state.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: GlassCard(
                        color: AppColors.error.withOpacity(0.15),
                        borderColor: AppColors.error.withOpacity(0.3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Đã xảy ra lỗi',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.errorMessage,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final list = state.publications;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.find_in_page_rounded,
                          size: 64,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy kết quả nào.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: list.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final pub = list[index];
                    return PublicationCard(
                      id: pub.id,
                      title: pub.title,
                      year: pub.publicationYear.toString(),
                      citationCount: pub.citationCount,
                      journalName: pub.journalName,
                      onTap: () {
                        // Điều hướng sang trang chi tiết
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(publication: pub),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
