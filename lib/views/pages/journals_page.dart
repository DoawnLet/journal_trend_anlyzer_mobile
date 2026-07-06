import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/mock_firebase_service.dart';
import '../../core/utils/translation.dart';
import '../models/publication_model.dart';
import '../state_management/shared_state.dart';
import '../widgets/glass_card.dart';
import 'journal_detail_page.dart';

/// Lớp lưu trữ thông tin tạp chí tổng hợp
class JournalStats {
  final String name;
  final int count;
  final int totalCitations;
  final List<Publication> publications;

  double get avgCitations => count == 0 ? 0.0 : totalCitations / count;

  const JournalStats({
    required this.name,
    required this.count,
    required this.totalCitations,
    required this.publications,
  });
}

/// Màn hình Phân tích Tạp chí (Journals Screen)
class JournalsPage extends StatefulWidget {
  const JournalsPage({super.key});

  @override
  State<JournalsPage> createState() => _JournalsPageState();
}

class _JournalsPageState extends State<JournalsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'journals_tab'.tr(),
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
        // Lắng nghe sự thay đổi của danh sách bài báo toàn cục
        child: ValueListenableBuilder<List<Publication>>(
          valueListenable: SharedState.filteredPublicationsNotifier,
          builder: (context, publications, _) {
            // Lắng nghe thêm Remote Config để cập nhật số lượng dòng giới hạn hiển thị
            return ListenableBuilder(
              listenable: MockFirebaseService.instance,
              builder: (context, _) {
                if (publications.isEmpty) {
                  return _buildEmptyState();
                }

                // 1. Nhóm bài viết theo tạp chí
                final Map<String, List<Publication>> grouped = {};
                for (final p in publications) {
                  final name = p.journalName.trim().isEmpty ? 'unknown_journal'.tr() : p.journalName;
                  grouped.putIfAbsent(name, () => []).add(p);
                }

                // 2. Chuyển thành danh sách JournalStats và sắp xếp giảm dần theo số lượng bài viết
                final List<JournalStats> journalList = grouped.entries.map((entry) {
                  final totalCites = entry.value.fold<int>(0, (sum, paper) => sum + paper.citationCount);
                  return JournalStats(
                    name: entry.key,
                    count: entry.value.length,
                    totalCitations: totalCites,
                    publications: entry.value,
                  );
                }).toList()
                  ..sort((a, b) => b.count.compareTo(a.count));

                // 3. Áp dụng giới hạn hiển thị từ Remote Config
                final limit = MockFirebaseService.instance.maxJournalsDisplayed;
                final displayedJournals = journalList.take(limit).toList();

                // 4. Tính toán thống kê vĩ mô
                final totalJournalsCount = journalList.length;
                final avgArticlesPerJournal = totalJournalsCount == 0 ? 0.0 : publications.length / totalJournalsCount;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chỉ số vĩ mô
                      _buildMacroMetrics(totalJournalsCount, avgArticlesPerJournal),
                      const SizedBox(height: 24),

                      // Biểu đồ đóng góp Tạp chí
                      Text(
                        'Biểu đồ đóng góp sản lượng',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildContributionChart(displayedJournals),
                      const SizedBox(height: 24),

                      // Danh sách Tạp chí Hàng đầu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top tạp chí (${displayedJournals.length}/$totalJournalsCount)',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Remote Config Limit: $limit',
                            style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedJournals.length,
                        itemBuilder: (context, index) {
                          final journal = displayedJournals[index];
                          return _buildJournalItem(journal, index + 1);
                        },
                      ),
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
          const Icon(Icons.library_books_rounded, size: 64, color: Colors.white30),
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

  Widget _buildMacroMetrics(int totalJournals, double avgArticles) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF80CBC4).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF80CBC4), size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  totalJournals.toString(),
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tổng số tạp chí',
                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF80CBC4).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.assessment_rounded, color: Color(0xFF80CBC4), size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  avgArticles.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bài viết TB / Tạp chí',
                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContributionChart(List<JournalStats> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    final maxVal = list.first.count.toDouble();

    return GlassCard(
      borderRadius: 16,
      color: Colors.white.withOpacity(0.06),
      borderColor: Colors.white.withOpacity(0.12),
      borderWidth: 1.0,
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal == 0 ? 1.0 : maxVal * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => const Color(0xFF0F364A).withOpacity(0.9),
                tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0),
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${list[groupIndex].name}\n',
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
                    if (index < 0 || index >= list.length) return const SizedBox.shrink();
                    final name = list[index].name;
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
            barGroups: List.generate(list.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: list[i].count.toDouble(),
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
    );
  }

  Widget _buildJournalItem(JournalStats journal, int rank) {
    Color rankColor;
    Color badgeBgColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        badgeBgColor = const Color(0xFFFFD700).withOpacity(0.15);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        badgeBgColor = const Color(0xFFC0C0C0).withOpacity(0.15);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        badgeBgColor = const Color(0xFFCD7F32).withOpacity(0.15);
        break;
      default:
        rankColor = const Color(0xFF80CBC4); // Teal
        badgeBgColor = const Color(0xFF80CBC4).withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: badgeBgColor,
            shape: BoxShape.circle,
            border: Border.all(color: rankColor.withOpacity(0.3), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            rank.toString(),
            style: GoogleFonts.outfit(
              textStyle: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          journal.name,
          style: GoogleFonts.outfit(
            textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Số bài báo: ${journal.count} bài • Số trích dẫn: ${journal.totalCitations}',
            style: GoogleFonts.inter(
              textStyle: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        onTap: () {
          // Ghi nhận sự kiện xem tạp chí
          MockFirebaseService.instance.logAnalyticsEvent(
            name: 'view_journal',
            parameters: {'journal_name': journal.name},
          );

          // Điều hướng sang chi tiết tạp chí
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailPage(journal: journal),
            ),
          );
        },
      ),
    );
  }
}
