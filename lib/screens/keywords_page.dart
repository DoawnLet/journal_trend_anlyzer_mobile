import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/screens/keyword_detail_page.dart';

/// Lớp đại diện cho thông tin thống kê của một Keyword
class KeywordStats {
  final String keyword;
  final int count;
  final List<Publication> publications;

  const KeywordStats({
    required this.keyword,
    required this.count,
    required this.publications,
  });
}

/// Màn hình Từ khóa (Keywords Screen)
class KeywordsPage extends StatefulWidget {
  const KeywordsPage({super.key});

  @override
  State<KeywordsPage> createState() => _KeywordsPageState();
}

class _KeywordsPageState extends State<KeywordsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'keywords_tab'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF102828), const Color(0xFF0C1D1D)]
                : [const Color(0xFF235C5C), const Color(0xFF1A4747)],
          ),
        ),
        child: ListenableBuilder(
          listenable: SharedState.languageNotifier,
          builder: (context, _) {
            return ValueListenableBuilder<List<Publication>>(
              valueListenable: SharedState.filteredPublicationsNotifier,
              builder: (context, publications, _) {
                return ListenableBuilder(
                  listenable: MockFirebaseService.instance,
                  builder: (context, _) {
                    if (publications.isEmpty) {
                      return _buildEmptyState();
                    }

                    // 1. Phân tích trích xuất tất cả Concepts/Topics làm Keyword và tính tần số
                    final Map<String, List<Publication>> keywordGroup = {};
                    for (final p in publications) {
                      final List<String> allKeys = [...p.concepts, ...p.topics];
                      for (final key in allKeys) {
                        final normalizedKey = key.trim();
                        if (normalizedKey.isNotEmpty) {
                          keywordGroup.putIfAbsent(normalizedKey, () => []).add(p);
                        }
                      }
                    }

                    // 2. Sắp xếp danh sách theo số lượng bài viết giảm dần
                    final List<KeywordStats> allStats = keywordGroup.entries.map((entry) {
                      return KeywordStats(
                        keyword: entry.key,
                        count: entry.value.length,
                        publications: entry.value,
                      );
                    }).toList()
                      ..sort((a, b) => b.count.compareTo(a.count));

                    // 3. Giới hạn số lượng từ khóa hiển thị bằng Remote Config
                    final limit = MockFirebaseService.instance.maxKeywordsDisplayed;
                    final displayedStats = allStats.take(limit).toList();

                    // Phân chia: 50% top đầu làm "Most Frequent", số còn lại làm "Trending"
                    final midpoint = (displayedStats.length / 2).ceil();
                    final frequentKeywords = displayedStats.take(midpoint).toList();
                    final trendingKeywords = displayedStats.skip(midpoint).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0), // Tránh đè lên thanh bottom navigation
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề số liệu từ khóa
                          _buildHeaderStats(
                            allStats.length,
                            SharedState.totalPublicationsCountNotifier.value > 0
                                ? SharedState.totalPublicationsCountNotifier.value
                                : publications.length,
                          ),
                          const SizedBox(height: 24),

                          // Biểu đồ tần suất Từ khóa
                          Text(
                            'keyword_frequency_chart'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildFrequencyChart(displayedStats.take(6).toList()),
                          const SizedBox(height: 24),

                          // Section 1: Most Frequent Keywords
                          _buildKeywordsSection('most_frequent_keywords'.tr(), frequentKeywords, limit, allStats.length),
                          const SizedBox(height: 24),

                          // Section 2: Trending Keywords
                          if (trendingKeywords.isNotEmpty) ...[
                            _buildKeywordsSection('trending_keywords'.tr(), trendingKeywords, limit, allStats.length, isTrending: true),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tag_rounded, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            'dashboard_empty_prompt'.tr(),
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(int totalKeywords, int totalPubs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.09),
            Colors.white.withOpacity(0.03),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF80CBC4).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.tag_rounded, color: Color(0xFF80CBC4), size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  totalKeywords.toString(),
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(color: Color(0xFF80CBC4), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Text('total_keywords'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF80CBC4).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.book_rounded, color: Color(0xFF80CBC4), size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  totalPubs.toString(),
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(color: Color(0xFF80CBC4), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 2),
                Text('total_publications'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(List<KeywordStats> topList) {
    if (topList.isEmpty) return const SizedBox.shrink();

    final maxVal = topList.first.count.toDouble();

    return GlassCard(
      borderRadius: 16,
      color: Colors.white.withOpacity(0.06),
      borderColor: Colors.white.withOpacity(0.12),
      borderWidth: 1.0,
      child: SizedBox(
        height: 210, // Tăng chiều cao để tránh tooltip bị cắt bởi ScrollView
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0), // Chừa khoảng trống phía trên cho tooltip
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal == 0 ? 1.0 : maxVal * 1.25,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => const Color(0xFF0F364A).withOpacity(0.9),
                  tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0),
                  tooltipBorderRadius: BorderRadius.circular(8),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${topList[groupIndex].keyword}\n',
                      GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${rod.toY.toInt()} ${'articles'.tr()}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF80CBC4),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withOpacity(0.08),
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (val, meta) {
                      // Ẩn nhãn trùng lặp ở đỉnh biểu đồ
                      if (val == meta.max || val.toInt() >= meta.max.toInt()) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          val.toInt().toString(),
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final index = val.toInt();
                      if (index < 0 || index >= topList.length) return const SizedBox.shrink();
                      final name = topList[index].keyword;
                      final shortName = name.length > 8 ? '${name.substring(0, 6)}..' : name;
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          shortName,
                          style: const TextStyle(color: Colors.white54, fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(topList.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: topList[i].count.toDouble(),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF00ACC1),
                          Color(0xFF80CBC4),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeywordsSection(
    String title,
    List<KeywordStats> list,
    int limit,
    int totalCount, {
    bool isTrending = false,
  }) {
    final accentColor = isTrending ? const Color(0xFFFFB300) : const Color(0xFF80CBC4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTrending ? const Color(0xFFFFB300) : Colors.white,
              ),
            ),
            if (!isTrending)
              Text(
                'Remote Config: $limit',
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.map((item) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Ghi nhận sự kiện xem từ khóa
                  MockFirebaseService.instance.logAnalyticsEvent(
                    name: 'view_keyword',
                    parameters: {'keyword': item.keyword},
                  );

                  // Điều hướng sang chi tiết từ khóa
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KeywordDetailPage(keywordStats: item),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrending ? Icons.trending_up_rounded : Icons.label_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.keyword,
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item.count})',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: accentColor.withOpacity(0.8),
                            fontSize: 12,
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
        ),
      ],
    );
  }
}
