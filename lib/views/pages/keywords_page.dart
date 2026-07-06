import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/mock_firebase_service.dart';
import '../../core/utils/translation.dart';
import '../models/publication_model.dart';
import '../state_management/shared_state.dart';
import '../widgets/glass_card.dart';
import 'keyword_detail_page.dart';

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
        child: ValueListenableBuilder<List<Publication>>(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề số liệu từ khóa
                      _buildHeaderStats(allStats.length, publications.length),
                      const SizedBox(height: 24),

                      // Biểu đồ tần suất Từ khóa
                      Text(
                        'Biểu đồ tần suất xuất hiện',
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
                      _buildKeywordsSection('Từ khóa phổ biến nhất', frequentKeywords, limit, allStats.length),
                      const SizedBox(height: 20),

                      // Section 2: Trending Keywords
                      if (trendingKeywords.isNotEmpty) ...[
                        _buildKeywordsSection('Từ khóa đang thịnh hành (Trending)', trendingKeywords, limit, allStats.length, isTrending: true),
                      ],
                    ],
                  ),
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                totalKeywords.toString(),
                style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Tổng số từ khóa', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          Container(width: 1, height: 30, color: Colors.white24),
          Column(
            children: [
              Text(
                totalPubs.toString(),
                style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Tổng số bài báo', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(List<KeywordStats> topList) {
    if (topList.isEmpty) return const SizedBox.shrink();

    final maxVal = topList.first.count.toDouble();

    return GlassCard(
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal == 0 ? 1.0 : maxVal * 1.2,
            barTouchData: BarTouchData(enabled: true),
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
                  reservedSize: 28,
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
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
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
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
                    width: 14,
                    color: const Color(0xFF80CBC4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isTrending ? const Color(0xFF80CBC4) : Colors.white,
              ),
            ),
            if (!isTrending)
              Text(
                'Remote Config: $limit',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((item) {
            return ActionChip(
              avatar: Icon(
                isTrending ? Icons.trending_up_rounded : Icons.label_rounded,
                size: 14,
                color: isTrending ? Colors.amber : const Color(0xFF80CBC4),
              ),
              label: Text('${item.keyword} (${item.count})'),
              backgroundColor: Colors.white.withOpacity(0.06),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.12)),
              ),
              onPressed: () {
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
            );
          }).toList(),
        ),
      ],
    );
  }
}
