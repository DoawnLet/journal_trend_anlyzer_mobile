import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:journal_trend_analysis_mb/theme/app_colors.dart';
import 'package:journal_trend_analysis_mb/utils/formatters.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/widgets/research_taxonomy_selector.dart';
import 'package:journal_trend_analysis_mb/widgets/works_list_bottom_sheet.dart';
import 'package:journal_trend_analysis_mb/viewmodels/trend_notifier.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/services/openalex_api_service.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';

/// Màn hình Biểu đồ xu hướng (Trend Analysis Page).
/// Trực quan hóa số lượng bài báo qua các năm và hiển thị xếp hạng
/// các bài báo nổi tiếng nhất, tạp chí xuất sắc nhất, và tác giả tiêu biểu.
class TrendPage extends StatefulWidget {
  final TrendNotifier notifier;

  const TrendPage({super.key, required this.notifier});

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  final OpenAlexApiService _apiService = OpenAlexApiService();
  List<String> _trendingTopics = [];
  bool _isLoadingTrending = false;

  final List<Map<String, dynamic>> _domains = [
    {
      'name': 'Physical Sciences',
      'label': 'Khoa học Vật lý & Máy tính',
      'gradient': const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.computer_rounded,
    },
    {
      'name': 'Life Sciences',
      'label': 'Khoa học Sự sống & Sinh học',
      'gradient': const LinearGradient(
        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.eco_rounded,
    },
    {
      'name': 'Health Sciences',
      'label': 'Y tế & Khoa học Sức khỏe',
      'gradient': const LinearGradient(
        colors: [Color(0xFFD38312), Color(0xFFA83279)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.medical_services_rounded,
    },
    {
      'name': 'Social Sciences',
      'label': 'Khoa học Xã hội & Nhân văn',
      'gradient': const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.people_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchTrendingTopics();
  }

  Future<void> _fetchTrendingTopics() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTrending = true;
    });
    try {
      final topics = await _apiService.getPopularTopics(limit: 8);
      if (mounted) {
        setState(() {
          _trendingTopics = topics;
        });
      }
    } catch (_) {
      // Fallback khi API lỗi
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
      }
    }
  }

  void _showTopicSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResearchTaxonomySelector(),
    );
  }

  Future<void> _refreshTrend() async {
    await widget.notifier.fetchTrendData(
      SharedState.activeQueryNotifier.value,
      showLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('xu_huong_va_phan_tich'.tr()),
        actions: [
          ListenableBuilder(
            listenable: SharedState.languageNotifier,
            builder: (context, _) {
              final lang = SharedState.languageNotifier.value;
              return TextButton(
                onPressed: SharedState.toggleLanguage,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: SharedState.themeModeNotifier,
            builder: (context, _) {
              final isDark = SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                tooltip: isDark ? 'switch_to_light_mode'.tr() : 'switch_to_dark_mode'.tr(),
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
                final scope = SharedState.activeResearchScopeNotifier.value;
                final activeLabel = scope.hasStructuredFilters
                    ? scope.breadcrumb
                    : (activeQuery.isEmpty ? 'Artificial Intelligence' : activeQuery);
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
                                scope.hasStructuredFilters
                                    ? 'research_scope_openalex'.tr()
                                    : 'chu_de_dang_phan_tich'.tr(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeLabel,
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
            child: RefreshIndicator(
              color: const Color(0xFF80CBC4),
              backgroundColor: const Color(0xFF1E4646),
              onRefresh: _refreshTrend,
              child: ListenableBuilder(
                listenable: widget.notifier,
                builder: (context, _) {
                if (widget.notifier.isLoading) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 420,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (widget.notifier.errorMessage != null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 420,
                        child: _buildErrorState(
                          theme,
                          widget.notifier.errorMessage!,
                        ),
                      ),
                    ],
                  );
                }

                if (!widget.notifier.hasData) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 420,
                        child: _buildEmptyState(theme),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Lĩnh vực gợi ý khám phá ---
                      Text(
                        'explore_by_field'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 72,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _domains.length,
                          itemBuilder: (context, index) {
                            final domain = _domains[index];
                            final isSelected = SharedState.activeQueryNotifier.value == domain['name'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    SharedState.setKeyword(domain['name']);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 190,
                                    decoration: BoxDecoration(
                                      gradient: domain['gradient'] as Gradient,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF80CBC4) : Colors.white.withOpacity(0.12),
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(domain['icon'] as IconData, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            (domain['label'] as String).tr(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // --- Gợi ý chủ đề nóng ---
                      Text(
                        'trending_topics'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _isLoadingTrending
                          ? const SizedBox(height: 40)
                          : _trendingTopics.isEmpty
                              ? SizedBox(
                                  height: 40,
                                  child: Center(
                                    child: Text(
                                      'no_trending_topics'.tr(),
                                      style: const TextStyle(color: Colors.white30, fontSize: 11),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: _trendingTopics.map((topic) {
                                      final isSelected = SharedState.activeQueryNotifier.value == topic;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ActionChip(
                                          label: Text(
                                            topic,
                                            style: TextStyle(
                                              color: isSelected ? Colors.black : Colors.white70,
                                              fontSize: 11,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          backgroundColor: isSelected
                                              ? const Color(0xFF80CBC4)
                                              : Colors.white.withOpacity(0.06),
                                          side: BorderSide(
                                            color: isSelected ? const Color(0xFF80CBC4) : Colors.white.withOpacity(0.12),
                                          ),
                                          onPressed: () {
                                            SharedState.setKeyword(topic);
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                      const SizedBox(height: 24),

                      // --- Mục 1: Biểu đồ đường phân bố số lượng bài viết ---
                      Text(
                        'yearly_production_chart'.tr(),
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
                        'most_cited_publications'.tr(),
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
                                  'top_journals'.tr(),
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
                                  'top_authors'.tr(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(ThemeData theme) {
    final dist = widget.notifier.yearlyDistribution;
    if (dist.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'not_enough_trend_data'.tr(),
            style: const TextStyle(color: Colors.white70),
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
                    '${'chart_tooltip_year'.tr()} $year\n$val ${'chart_tooltip_articles'.tr()}',
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
    final list = widget.notifier.topPublications;
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
                        'trich_dan'.tr(),
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
    final list = widget.notifier.topJournals;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final journalPubs =
                  await widget.notifier.fetchPublicationsForJournal(entry);
              if (!context.mounted) return;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WorksListBottomSheet(
                  title: '${'articles_from_journal'.tr()}:\n${entry.name}',
                  publications: journalPubs,
                ),
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
                      entry.name,
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
                      '${entry.count} ${'article_count'.tr()}',
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
    final list = widget.notifier.topAuthors;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final authorPubs =
                  await widget.notifier.fetchPublicationsForAuthor(entry);
              if (!context.mounted) return;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WorksListBottomSheet(
                  title: '${'articles_by_author'.tr()}:\n${entry.name}',
                  publications: authorPubs,
                ),
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
                      entry.name,
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
                      '${entry.count} ${'article_count'.tr()}',
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
                'error_loading_chart'.tr(),
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
    final activeQuery = SharedState.activeQueryNotifier.value.trim();
    final message = activeQuery.isEmpty
        ? 'search_prompt_trend'.tr()
        : 'no_trend_data_for'.tr().replaceAll('{topic}', activeQuery);

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
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
