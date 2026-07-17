import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/screens/journal_detail_page.dart';
import 'package:journal_trend_analysis_mb/services/openalex_api_service.dart';

/// Lớp lưu trữ thông tin tạp chí tổng hợp từ nguồn OpenAlex Sources
class JournalStats {
  final String id;
  final String name;
  final int count;
  final int totalCitations;
  final String homepageUrl;

  double get avgCitations => count == 0 ? 0.0 : totalCitations / count;

  const JournalStats({
    required this.id,
    required this.name,
    required this.count,
    required this.totalCitations,
    required this.homepageUrl,
  });

  factory JournalStats.fromMap(Map<String, dynamic> map) {
    return JournalStats(
      id: map['id'] ?? '',
      name: map['display_name'] ?? 'Unknown Journal',
      count: map['works_count'] ?? 0,
      totalCitations: map['cited_by_count'] ?? 0,
      homepageUrl: map['homepage_url'] ?? '',
    );
  }
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = SharedState.journalQueryNotifier.value;
    _searchQuery = SharedState.journalQueryNotifier.value;

    // Nếu chưa có dữ liệu tạp chí, thực hiện tải mặc định "Artificial Intelligence"
    if (SharedState.journalSourcesNotifier.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchJournalsData(
          _searchQuery.trim().isEmpty ? 'Artificial Intelligence' : _searchQuery
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJournalsData(String query) async {
    final trimmedQuery = query.trim();
    // Dùng query mặc định nếu chuỗi rỗng để tránh trả về màn hình trống
    final searchTarget = trimmedQuery.isEmpty ? 'Artificial Intelligence' : trimmedQuery;

    SharedState.journalLoadingNotifier.value = true;
    try {
      final results = await OpenAlexApiService().searchSources(searchTarget);

      SharedState.journalQueryNotifier.value = trimmedQuery;
      SharedState.journalSourcesNotifier.value = results;

      setState(() {
        _searchQuery = trimmedQuery;
        _currentPage = 0;
      });
    } catch (e) {
      debugPrint("Lỗi khi tải dữ liệu Tạp chí: $e");
      SharedState.journalSourcesNotifier.value = const [];
      setState(() {
        _searchQuery = trimmedQuery;
        _currentPage = 0;
      });
    } finally {
      SharedState.journalLoadingNotifier.value = false;
    }
  }

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
        child: ValueListenableBuilder<bool>(
          valueListenable: SharedState.journalLoadingNotifier,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF80CBC4)),
              );
            }

            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: SharedState.journalSourcesNotifier,
              builder: (context, rawSources, _) {
                return ListenableBuilder(
                  listenable: MockFirebaseService.instance,
                  builder: (context, _) {
                    final List<JournalStats> journalList = rawSources.map((map) => JournalStats.fromMap(map)).toList();

                    if (journalList.isEmpty) {
                      if (_searchController.text.trim().isNotEmpty) {
                        return _buildNoSearchResultsState();
                      }
                      return _buildEmptyState();
                    }

                    // Phân trang dữ liệu dựa trên Remote Config làm kích thước trang (Page Size)
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

                    // Tính toán thống kê vĩ mô
                    final totalJournalsCount = journalList.length;
                    final totalArticlesCount = journalList.fold<int>(0, (sum, j) => sum + j.count);
                    final avgArticlesPerJournal = totalJournalsCount == 0 ? 0.0 : totalArticlesCount / totalJournalsCount;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ô tìm kiếm tạp chí
                          _buildSearchField(),
                          const SizedBox(height: 12),

                          // Chỉ số vĩ mô
                          _buildMacroMetrics(totalJournalsCount, avgArticlesPerJournal),
                          const SizedBox(height: 24),

                          // Biểu đồ đóng góp Tạp chí
                          Text(
                            _chartMetricIndex == 0
                                ? 'journal_productivity_chart'.tr()
                                : (_chartMetricIndex == 1
                                    ? 'journal_citation_chart'.tr()
                                    : 'journal_avg_citation_chart'.tr()),
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
                                'top_journals_range'
                                    .tr()
                                    .replaceAll('{start}', (startIndex + 1).toString())
                                    .replaceAll('{end}', endIndex.toString())
                                    .replaceAll('{total}', totalJournalsCount.toString()),
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
                                  'page_indicator'
                                      .tr()
                                      .replaceAll('{current}', (_currentPage + 1).toString())
                                      .replaceAll('{total}', totalPages.toString()),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: (value) {
        _fetchJournalsData(value);
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'search_journals_hint'.tr(),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                onPressed: () {
                  _searchController.clear();
                  _fetchJournalsData('');
                },
              ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              onPressed: () {
                _fetchJournalsData(_searchController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 60),
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            'no_journals_found'.tr(),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _fetchJournalsData('');
            },
            child: Text('clear_all'.tr()),
          ),
        ],
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
            'no_journals_found'.tr(),
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
                Text(
                  'total_journals'.tr(),
                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
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
                Text(
                  'avg_articles_per_journal'.tr(),
                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
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

    // Sắp xếp giảm dần
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
            height: 210,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
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
        rankColor = const Color(0xFFFFD700);
        badgeBgColor = const Color(0xFFFFD700).withOpacity(0.15);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        badgeBgColor = const Color(0xFFC0C0C0).withOpacity(0.15);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        badgeBgColor = const Color(0xFFCD7F32).withOpacity(0.15);
        break;
      default:
        rankColor = const Color(0xFF80CBC4);
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

          // Điều hướng sang chi tiết tạp chí trực tuyến
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailPage(
                journalId: journal.id,
                journalName: journal.name,
                worksCount: journal.count,
                citedByCount: journal.totalCitations,
                homepageUrl: journal.homepageUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
