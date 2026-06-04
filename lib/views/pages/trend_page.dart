import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../state_management/trend_notifier.dart';
import '../state_management/shared_state.dart';
import '../services/openalex_api_service.dart';
import '../models/publication_model.dart';
import 'detail_page.dart';

/// Màn hình Biểu đồ xu hướng (Trend Analysis Page).
/// Trực quan hóa số lượng ấn phẩm qua các năm và hiển thị xếp hạng
/// các bài báo nổi tiếng nhất, tạp chí xuất sắc nhất, và tác giả tiêu biểu.
class TrendPage extends StatelessWidget {
  final TrendNotifier notifier;

  const TrendPage({super.key, required this.notifier});

  void _showTopicSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TopicSelectorBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xu Hướng & Phân Tích'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Thẻ chọn chủ đề phân tích nổi bật ở đầu trang ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<String>(
              valueListenable: SharedState.activeQueryNotifier,
              builder: (context, activeQuery, _) {
                return InkWell(
                  onTap: () => _showTopicSelector(context),
                  borderRadius: BorderRadius.circular(12),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.white.withOpacity(0.06),
                    borderColor: Colors.white.withOpacity(0.12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chủ đề đang phân tích (Chọn để thay đổi)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeQuery.isEmpty ? 'Artificial Intelligence' : activeQuery,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          color: Color(0xFF80CBC4),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: ListenableBuilder(
              listenable: notifier,
              builder: (context, _) {
                if (notifier.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }

                if (notifier.errorMessage != null) {
                  return _buildErrorState(theme, notifier.errorMessage!);
                }

                if (notifier.publications.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Mục 1: Biểu đồ đường phân bố số lượng bài viết ---
                      Text(
                        'Biểu đồ sản lượng theo năm',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTrendChart(theme),
                      const SizedBox(height: 24),

                // --- Mục 2: Top bài báo có trích dẫn nhiều nhất ---
                Text(
                  'Bài viết có lượt trích dẫn cao nhất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTopPapersList(context, theme),
                const SizedBox(height: 24),

                // --- Mục 3: Top Tạp chí & Tác giả ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Tạp chí',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTopJournalsList(context, theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Tác giả',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTopAuthorsList(context, theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
),
    );
  }

  Widget _buildTrendChart(ThemeData theme) {
    final dist = notifier.yearlyDistribution;
    if (dist.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Không đủ điểm dữ liệu lịch sử để vẽ biểu đồ.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Sắp xếp các năm và lấy tối đa 10 năm gần nhất có dữ liệu để tránh chen chúc nhãn
    final sortedYears = dist.keys.toList()..sort();
    final last10Years = sortedYears.length > 10
        ? sortedYears.sublist(sortedYears.length - 10)
        : sortedYears;

    final Map<int, int> filteredDist = {
      for (var year in last10Years) year: dist[year]!
    };

    final maxVal = filteredDist.values.isEmpty
        ? 0
        : filteredDist.values.reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal == 0 ? 10 : (maxVal * 1.15).ceilToDouble();

    final barGroups = filteredDist.entries.map((entry) {
      final index = filteredDist.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00796B), // Deep teal
                Color(0xFF80CBC4), // Mint teal
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    }).toList();

    return GlassCard(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    final interval = (maxY / 4).ceil();
                    if (interval > 0 && value.toInt() % interval != 0 && value != maxY) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      Formatters.formatCitationCount(value.toInt()),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= last10Years.length) return const SizedBox.shrink();
                    final year = last10Years[idx];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        year.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => const Color(0xFF1E293B).withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final year = last10Years[groupIndex];
                  final val = filteredDist[year]!;
                  return BarTooltipItem(
                    'Năm $year\n$val bài báo',
                    const TextStyle(
                      color: Color(0xFF80CBC4),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildTopPapersList(BuildContext context, ThemeData theme) {
    final list = notifier.topPublications;
    return Column(
      children: list.map((pub) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailPage(publication: pub)),
              );
            },
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pub.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatAuthors(pub.authors),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCitationCount(pub.citationCount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'trích dẫn',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopJournalsList(BuildContext context, ThemeData theme) {
    final list = notifier.topJournals;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        // Lọc danh sách bài báo thuộc tạp chí này
        final journalPubs = notifier.publications
            .where((pub) => pub.journalName == entry.key)
            .toList();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showWorksListBottomSheet(
                context,
                'Bài viết từ tạp chí:\n${entry.key}',
                journalPubs,
              );
            },
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value} bài',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopAuthorsList(BuildContext context, ThemeData theme) {
    final list = notifier.topAuthors;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        // Lọc danh sách bài báo mà tác giả này tham gia viết
        final authorPubs = notifier.publications
            .where((pub) => pub.authors.contains(entry.key))
            .toList();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _showWorksListBottomSheet(
                context,
                'Bài viết của tác giả:\n${entry.key}',
                authorPubs,
              );
            },
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${entry.value} bài',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
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
                'Lỗi tải biểu đồ',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Nhập từ khóa tìm kiếm để bắt đầu vẽ phân tích.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorksListBottomSheet(
    BuildContext context,
    String title,
    List<Publication> publications,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95), // Slate-900 kính mờ
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: publications.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Không tìm thấy bài viết nào.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: publications.length,
                        itemBuilder: (context, index) {
                          final pub = publications[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context); // Đóng bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPage(publication: pub),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: GlassCard(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.article_rounded,
                                        color: Color(0xFF80CBC4),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pub.title,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Năm ${pub.publicationYear} • ${Formatters.formatAuthors(pub.authors)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: Colors.white30,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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

  final List<String> _popularTopics = [
    'Artificial Intelligence',
    'Machine Learning',
    'Deep Learning',
    'Data Science',
    'Computer Vision',
    'Natural Language Processing',
    'Neural Networks',
    'Robotics',
  ];

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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularTopics.map((topic) {
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
