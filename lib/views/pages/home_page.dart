import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/translation.dart';
import '../../core/services/mock_firebase_service.dart';
import '../models/publication_model.dart';
import '../state_management/search_notifier.dart';
import '../state_management/home_notifier.dart';
import '../state_management/shared_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/research_trend_analysis/publication_trend_chart.dart';
import '../widgets/research_trend_analysis/metric_card_grid.dart';
import 'detail_page.dart';

/// Màn hình Trang chủ (Home Screen) - Bảng điều khiển phân tích tổng quan đề tài nghiên cứu
class HomePage extends StatefulWidget {
  final HomeNotifier notifier;
  final SearchNotifier searchNotifier;

  const HomePage({
    super.key,
    required this.notifier,
    required this.searchNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _searchController;
  final List<String> _quickTopics = const [
    'Artificial Intelligence',
    'Deep Learning',
    'Quantum Computing',
    'Climate Change',
    'Machine Learning',
    'Blockchain',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: SharedState.activeQueryNotifier.value);
    SharedState.activeQueryNotifier.addListener(_onGlobalQueryChanged);
    
    // Nếu chưa có từ khóa nào hoạt động, đặt mặc định là "Artificial Intelligence"
    if (SharedState.activeQueryNotifier.value.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerSearch('Artificial Intelligence');
      });
    }
  }

  @override
  void dispose() {
    SharedState.activeQueryNotifier.removeListener(_onGlobalQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onGlobalQueryChanged() {
    if (mounted) {
      final query = SharedState.activeQueryNotifier.value;
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    }
  }

  void _triggerSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Ghi nhận sự kiện Analytics
      MockFirebaseService.instance.logAnalyticsEvent(
        name: 'search_topic',
        parameters: {'keyword': query.trim()},
      );

      SharedState.setKeyword(query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'research_home'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút chuyển đổi ngôn ngữ
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
          // Nút chuyển đổi giao diện sáng tối
          ListenableBuilder(
            listenable: SharedState.themeModeNotifier,
            builder: (context, _) {
              final isDarkTheme = SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () {
                  SharedState.themeModeNotifier.value =
                      isDarkTheme ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
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
        child: Column(
          children: [
            // Thanh Tìm kiếm (Search Bar)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                borderRadius: 16,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white70),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _triggerSearch(value),
                        decoration: InputDecoration(
                          hintText: 'quick_search_hint'.tr(),
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Thân trang (Nội dung Dashboard)
            Expanded(
              child: ValueListenableBuilder<SearchState>(
                valueListenable: widget.searchNotifier.stateNotifier,
                builder: (context, searchState, _) {
                  if (searchState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF80CBC4)),
                    );
                  }

                  if (searchState.errorMessage.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          searchState.errorMessage,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final publications = searchState.publications;

                  if (publications.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Tính toán các chỉ số thống kê từ danh sách bài viết nhận được
                  final totalPubs = publications.length;
                  
                  final totalCitations = publications.fold<int>(
                    0, (sum, paper) => sum + paper.citationCount,
                  );
                  final avgCitations = totalPubs == 0 ? 0.0 : totalCitations / totalPubs;

                  // Tính Peak Year
                  final yearCounts = <int, int>{};
                  for (final p in publications) {
                    if (p.publicationYear > 0) {
                      yearCounts[p.publicationYear] = (yearCounts[p.publicationYear] ?? 0) + 1;
                    }
                  }
                  var peakYear = 0;
                  var maxYearCount = 0;
                  yearCounts.forEach((year, count) {
                    if (count > maxYearCount) {
                      maxYearCount = count;
                      peakYear = year;
                    }
                  });

                  // Tính Top Journal
                  final journalCounts = <String, int>{};
                  for (final p in publications) {
                    if (p.journalName.isNotEmpty && p.journalName != 'Unknown Journal') {
                      journalCounts[p.journalName] = (journalCounts[p.journalName] ?? 0) + 1;
                    }
                  }
                  var topJournal = 'N/A';
                  var maxJournalCount = 0;
                  journalCounts.forEach((name, count) {
                    if (count > maxJournalCount) {
                      maxJournalCount = count;
                      topJournal = name;
                    }
                  });

                  // Tính Top Author
                  final authorCounts = <String, int>{};
                  for (final p in publications) {
                    for (final author in p.authors) {
                      authorCounts[author] = (authorCounts[author] ?? 0) + 1;
                    }
                  }
                  var topAuthor = 'N/A';
                  var maxAuthorCount = 0;
                  authorCounts.forEach((name, count) {
                    if (count > maxAuthorCount) {
                      maxAuthorCount = count;
                      topAuthor = name;
                    }
                  });

                  // Bài báo ảnh hưởng nhất (Lượt trích dẫn cao nhất)
                  Publication? mostInfluentialPaper;
                  if (publications.isNotEmpty) {
                    mostInfluentialPaper = publications.reduce(
                      (curr, next) => curr.citationCount > next.citationCount ? curr : next,
                    );
                  }

                  // Chuẩn bị dữ liệu vẽ biểu đồ xu hướng
                  final sortedYears = yearCounts.keys.toList()..sort();
                  final trendByYear = <int, int>{};
                  for (final year in sortedYears) {
                    trendByYear[year] = yearCounts[year]!;
                  }

                  // Tạo danh sách các MetricCardData
                  final metrics = [
                    MetricCardData(
                      label: 'total_publications'.tr(),
                      value: totalPubs.toString(),
                      icon: Icons.book_rounded,
                    ),
                    MetricCardData(
                      label: 'average_citations'.tr(),
                      value: avgCitations.toStringAsFixed(1),
                      icon: Icons.insights_rounded,
                    ),
                    MetricCardData(
                      label: 'most_active_year'.tr(),
                      value: peakYear > 0 ? peakYear.toString() : 'N/A',
                      icon: Icons.calendar_month_rounded,
                    ),
                    MetricCardData(
                      label: 'top_author'.tr(),
                      value: topAuthor,
                      icon: Icons.person_rounded,
                    ),
                    MetricCardData(
                      label: 'top_journal'.tr(),
                      value: topJournal,
                      icon: Icons.menu_book_rounded,
                    ),
                  ];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chủ đề đang xem
                        Row(
                          children: [
                            const Icon(Icons.topic_rounded, color: Color(0xFF80CBC4), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${'active_analysis_keyword_prefix'.tr()}"${SharedState.activeQueryNotifier.value}"',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Grid các chỉ số đo lường
                        MetricCardGrid(metrics: metrics),
                        const SizedBox(height: 24),

                        // Biểu đồ xu hướng số lượng bài báo
                        Text(
                          'publication_trend'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: PublicationTrendChart(trendByYear: trendByYear),
                        ),
                        const SizedBox(height: 24),

                        // Bài báo ảnh hưởng nhất
                        if (mostInfluentialPaper != null) ...[
                          Text(
                            'most_influential_paper_title'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildInfluentialPaperCard(mostInfluentialPaper, theme),
                          const SizedBox(height: 24),
                        ],

                        // Danh sách kết quả nghiên cứu
                        Text(
                          'top_influential_papers'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: publications.length > 5 ? 5 : publications.length,
                          itemBuilder: (context, index) {
                            final paper = publications[index];
                            return _buildPublicationItem(paper, theme);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.analytics_outlined, size: 64, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            'dashboard_empty_prompt'.tr(),
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Danh sách chủ đề phổ biến đề xuất
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Chủ đề phổ biến:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTopics.map((topic) {
              return ActionChip(
                label: Text(topic),
                backgroundColor: Colors.white.withOpacity(0.08),
                labelStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                onPressed: () => _triggerSearch(topic),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluentialPaperCard(Publication paper, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // Điều hướng sang chi tiết bài báo
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetailPage(publication: paper),
          ),
        );
      },
      child: GlassCard(
        borderColor: const Color(0xFF80CBC4).withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Đóng góp trích dẫn nhiều nhất (${paper.citationCount} trích dẫn)',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              paper.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              paper.authors.join(', '),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    paper.journalName,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  paper.publicationYear.toString(),
                  style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicationItem(Publication paper, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          paper.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${paper.authors.isNotEmpty ? paper.authors.first : "Unknown"} - ${paper.publicationYear} - ${paper.journalName}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF80CBC4).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${paper.citationCount} 🌟',
            style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          // Ghi nhận sự kiện xem bài báo
          MockFirebaseService.instance.logAnalyticsEvent(
            name: 'view_publication',
            parameters: {
              'publication_title': paper.title,
              'publication_year': paper.publicationYear,
            },
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailPage(publication: paper),
            ),
          );
        },
      ),
    );
  }
}
