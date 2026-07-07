import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
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
  int _chartMetricIndex = 0;
  int _currentPage = 0;

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

                // 3. Phân trang dữ liệu dựa trên Remote Config làm kích thước trang (Page Size)
                final pageSize = MockFirebaseService.instance.maxJournalsDisplayed > 0
                    ? MockFirebaseService.instance.maxJournalsDisplayed
                    : 5;
                final totalPages = (journalList.length / pageSize).ceil();

                // Đảm bảo trang hiện tại nằm trong khoảng hợp lệ
                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }
                if (_currentPage < 0) {
                  _currentPage = 0;
                }

                final startIndex = _currentPage * pageSize;
                final endIndex = (startIndex + pageSize) > journalList.length
                    ? journalList.length
                    : (startIndex + pageSize);
                final displayedJournals = journalList.isEmpty ? <JournalStats>[] : journalList.sublist(startIndex, endIndex);

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
                        _chartMetricIndex == 0
                            ? 'Biểu đồ đóng góp sản lượng'
                            : (_chartMetricIndex == 1
                                ? 'Biểu đồ phân bố trích dẫn'
                                : 'Biểu đồ trích dẫn trung bình'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMetricTab(0, 'articles'.tr(), Icons.article_rounded),
                          const SizedBox(width: 8),
                          _buildMetricTab(1, 'citations'.tr(), Icons.star_rounded),
                          const SizedBox(width: 8),
                          _buildMetricTab(2, 'avg_citations_short'.tr(), Icons.insights_rounded),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildContributionChart(journalList),
                      const SizedBox(height: 24),

                      // Danh sách Tạp chí Hàng đầu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top tạp chí (${startIndex + 1} - $endIndex trên $totalJournalsCount)',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Remote Config Limit: $pageSize',
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
                          return _buildJournalItem(journal, startIndex + index + 1);
                        },
                      ),
                      if (totalPages > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                              onPressed: _currentPage > 0
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Trang ${_currentPage + 1} / $totalPages',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                              onPressed: _currentPage < totalPages - 1
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
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

  Widget _buildMetricTab(int index, String label, IconData icon) {
    final selected = _chartMetricIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _chartMetricIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF80CBC4) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF80CBC4) : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? const Color(0xFF123838) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: selected ? const Color(0xFF123838) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionChart(List<JournalStats> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    // Sắp xếp giảm dần từ cao xuống thấp như yêu cầu
    final sortedList = List<JournalStats>.from(list);
    if (_chartMetricIndex == 0) {
      sortedList.sort((a, b) => b.count.compareTo(a.count));
    } else if (_chartMetricIndex == 1) {
      sortedList.sort((a, b) => b.totalCitations.compareTo(a.totalCitations));
    } else {
      sortedList.sort((a, b) => b.avgCitations.compareTo(a.avgCitations));
    }

    double maxRawVal = 0.0;
    for (final item in sortedList) {
      final v = _chartMetricIndex == 0
          ? item.count.toDouble()
          : (_chartMetricIndex == 1
              ? item.totalCitations.toDouble()
              : item.avgCitations);
      if (v > maxRawVal) maxRawVal = v;
    }

    // Nếu giá trị lớn nhất vượt quá 100 (như chỉ số trích dẫn), áp dụng log10 scale để không bị nuốt cột nhỏ
    final bool useLogScale = maxRawVal > 100;
    double log10(num x) => math.log(x) / math.ln10;

    final double maxYVal = useLogScale 
        ? log10(maxRawVal + 1) * 1.15 
        : (maxRawVal == 0 ? 1.0 : maxRawVal * 1.2);

    final double chartWidth = sortedList.length * 48.0 < 340.0 ? 340.0 : sortedList.length * 48.0;

    return GlassCard(
      borderRadius: 16,
      color: Colors.white.withOpacity(0.06),
      borderColor: Colors.white.withOpacity(0.12),
      borderWidth: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: 210, // Tăng chiều cao để tooltip không bị cắt bởi ScrollView
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0), // Chừa khoảng trống phía trên cho tooltip
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxYVal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF0F364A).withOpacity(0.9),
                      tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final rawItem = sortedList[groupIndex];
                      String metricLabel = '';
                      if (_chartMetricIndex == 0) {
                        metricLabel = '${rawItem.count} ${'articles'.tr()}';
                      } else if (_chartMetricIndex == 1) {
                        metricLabel = '${rawItem.totalCitations} ${'citations'.tr()}';
                      } else {
                        metricLabel = '${rawItem.avgCitations.toStringAsFixed(1)} ${'avg_citations_short'.tr()}';
                      }

                      return BarTooltipItem(
                        '${sortedList[groupIndex].name}\n',
                        GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: metricLabel,
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
                      interval: useLogScale ? 1.0 : null,
                      getTitlesWidget: (val, meta) {
                        if (useLogScale) {
                          final intPower = val.round();
                          if ((val - intPower).abs() > 0.05) return const SizedBox.shrink();
                          
                          final double realVal = math.pow(10, intPower).toDouble();
                          String text;
                          if (realVal >= 1000000) {
                            text = '${(realVal / 1000000).toStringAsFixed(0)}M';
                          } else if (realVal >= 1000) {
                            text = '${(realVal / 1000).toStringAsFixed(0)}K';
                          } else {
                            text = realVal.toStringAsFixed(0);
                          }
                          
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              text,
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          );
                        } else {
                          final text = _chartMetricIndex == 2 ? val.toStringAsFixed(1) : val.toInt().toString();
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text(
                              text,
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index < 0 || index >= sortedList.length) return const SizedBox.shrink();
                        final name = sortedList[index].name;
                        final shortName = name.length > 12 ? '${name.substring(0, 9)}..' : name;
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
                barGroups: List.generate(sortedList.length, (i) {
                  final rawY = _chartMetricIndex == 0
                      ? sortedList[i].count.toDouble()
                      : (_chartMetricIndex == 1
                          ? sortedList[i].totalCitations.toDouble()
                          : sortedList[i].avgCitations);
                  final yVal = useLogScale ? log10(rawY + 1) : rawY;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: yVal,
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
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.article_outlined, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${journal.count}',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.star_outline_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    '${journal.totalCitations}',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    journal.avgCitations.toStringAsFixed(1),
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
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
