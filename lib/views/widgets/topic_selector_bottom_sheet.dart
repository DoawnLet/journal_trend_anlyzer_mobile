import 'package:flutter/material.dart';
import '../services/openalex_api_service.dart';
import '../state_management/shared_state.dart';

/// Bottom sheet giúp tìm kiếm và chọn nhanh chủ đề phân tích xu hướng.
class TopicSelectorBottomSheet extends StatefulWidget {
  const TopicSelectorBottomSheet({super.key});

  @override
  State<TopicSelectorBottomSheet> createState() => _TopicSelectorBottomSheetState();
}

class _TopicSelectorBottomSheetState extends State<TopicSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final OpenAlexApiService _apiService = OpenAlexApiService();

  List<Map<String, dynamic>> _topicSuggestions = [];
  bool _isSearching = false;

  List<String> _popularTopics = [];
  bool _isLoadingPopular = false;

  final List<String> _fallbackTopics = const [
    'Artificial Intelligence',
    'Machine Learning',
    'Deep Learning',
    'Data Science',
    'Computer Vision',
    'Natural Language Processing',
    'Neural Networks',
    'Robotics',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPopularTopics();
  }

  Future<void> _fetchPopularTopics() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPopular = true;
    });
    try {
      final topics = await _apiService.getPopularTopics(limit: 8);
      if (mounted) {
        setState(() {
          _popularTopics = topics;
        });
      }
    } catch (_) {
      // Bỏ qua lỗi và dùng fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPopular = false;
        });
      }
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _topicSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _apiService.searchTopics(query);
      if (mounted) {
        setState(() {
          _topicSuggestions = results;
        });
      }
    } catch (_) {
      // Bỏ qua lỗi
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95), // Slate-900 với độ mờ cao
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo nhỏ ở đầu
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề & nút đóng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn Chủ Đề Phân Tích',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ô tìm kiếm chủ đề
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa chủ đề (vd: Deep Learning)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Các chủ đề phổ biến
            Text(
              'Chủ đề phổ biến',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingPopular
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF80CBC4)),
                        ),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_popularTopics.isNotEmpty ? _popularTopics : _fallbackTopics).map((topic) {
                      final isSelected = SharedState.activeQueryNotifier.value == topic ||
                          (SharedState.activeQueryNotifier.value.isEmpty && topic == 'Artificial Intelligence');
                      return ActionChip(
                        label: Text(
                          topic,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? const Color(0xFF80CBC4)
                            : Colors.white.withOpacity(0.06),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF80CBC4) : Colors.white.withOpacity(0.1),
                        ),
                        onPressed: () {
                          SharedState.activeQueryNotifier.value = topic;
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 16),

            // Gợi ý danh sách kết quả tìm kiếm từ API
            if (_topicSuggestions.isNotEmpty) ...[
              Text(
                'Gợi ý kết quả tìm kiếm',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topicSuggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.white.withOpacity(0.08),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final sug = _topicSuggestions[index];
                    final name = sug['display_name'] ?? '';
                    return ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
                      onTap: () {
                        SharedState.activeQueryNotifier.value = name;
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Không tìm thấy chủ đề nào phù hợp.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
