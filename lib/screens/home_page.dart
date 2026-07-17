import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/viewmodels/search_notifier.dart';
import 'package:journal_trend_analysis_mb/viewmodels/auth_notifier.dart';
import 'package:provider/provider.dart';
import 'package:journal_trend_analysis_mb/viewmodels/home_notifier.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/publication_trend_chart.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/metric_card_grid.dart';
import 'package:journal_trend_analysis_mb/widgets/search_filter_bottom_sheet.dart';
import 'package:journal_trend_analysis_mb/widgets/works_list_bottom_sheet.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';
import 'package:journal_trend_analysis_mb/services/taxonomy_api_service.dart';
import 'package:journal_trend_analysis_mb/models/research_taxonomy_model.dart';

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
  List<ResearchTopic> _taxonomyTopics = [];
  bool _isLoadingTaxonomy = false;
  String? _taxonomyError;
  ResearchTaxonomyNode? _selectedDomain;
  ResearchTaxonomyNode? _selectedField;
  ResearchTaxonomyNode? _selectedSubfield;

  final List<Map<String, dynamic>> _domainPresets = [
    {
      'name': 'Physical Sciences',
      'gradient': const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.computer_rounded,
    },
    {
      'name': 'Life Sciences',
      'gradient': const LinearGradient(
        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.eco_rounded,
    },
    {
      'name': 'Health Sciences',
      'gradient': const LinearGradient(
        colors: [Color(0xFFD38312), Color(0xFFA83279)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'icon': Icons.medical_services_rounded,
    },
    {
      'name': 'Social Sciences',
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
    _searchController = TextEditingController(text: SharedState.activeQueryNotifier.value);
    SharedState.activeQueryNotifier.addListener(_onGlobalQueryChanged);
    _loadTaxonomy();
  }

  Future<void> _loadTaxonomy() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTaxonomy = true;
      _taxonomyError = null;
    });
    try {
      final api = TaxonomyApiService();
      final topics = await api.fetchPopularTopics(limit: 100);
      if (mounted) {
        setState(() {
          _taxonomyTopics = topics;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _taxonomyError = 'Không thể tải cấu trúc phân cấp chủ đề.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTaxonomy = false;
        });
      }
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
      if (query.trim().isEmpty) {
        setState(() {
          _selectedDomain = null;
          _selectedField = null;
          _selectedSubfield = null;
        });
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                borderRadius: 20,
                color: Colors.white.withOpacity(0.08),
                borderColor: Colors.white.withOpacity(0.15),
                borderWidth: 1.0,
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
                          _searchController.clear();
                          SharedState.setKeyword('');
                        },
                      ),
                    ListenableBuilder(
                      listenable: SharedState.publicationFilterNotifier,
                      builder: (context, _) {
                        final filter = SharedState.publicationFilterNotifier.value;
                        final activeCount = filter.activeFilterCount;
                        
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                              tooltip: 'filter_and_sort'.tr(),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SearchFilterBottomSheet(
                                    notifier: widget.searchNotifier,
                                  ),
                                );
                              },
                            ),
                            if (activeCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    '$activeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
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

                  if (SharedState.activeQueryNotifier.value.trim().isEmpty || publications.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Tính toán các chỉ số thống kê từ danh sách bài viết nhận được
                  final totalPubs = searchState.totalPublicationsCount > 0
                      ? searchState.totalPublicationsCount
                      : publications.length;
                  
                  final totalCitations = publications.fold<int>(
                    0, (sum, paper) => sum + paper.citationCount,
                  );
                  final avgCitations = publications.isEmpty ? 0.0 : totalCitations / publications.length;

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

                  // Lấy danh sách Top Journals (top 5)
                  final sortedJournals = journalCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topJournalsList = sortedJournals.take(5).toList();

                  // Lấy danh sách Top Authors (top 5)
                  final sortedAuthors = authorCounts.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topAuthorsList = sortedAuthors.take(5).toList();

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
                            const SizedBox(width: 8),
                             TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                SharedState.setKeyword('');
                              },
                              icon: const Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white),
                              label: Text(
                                'back_to_filter'.tr(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: const Color(0xFF80CBC4).withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: const Color(0xFF80CBC4).withOpacity(0.5),
                                    width: 1.0,
                                  ),
                                ),
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

                        // Top Tạp chí (Top Journals)
                        if (topJournalsList.isNotEmpty) ...[
                          Text(
                            'top_journals'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: List.generate(topJournalsList.length, (index) {
                                final entry = topJournalsList[index];
                                final isLast = index == topJournalsList.length - 1;
                                return Column(
                                  children: [
                                    _buildTopJournalItem(
                                      entry.key,
                                      entry.value,
                                      theme,
                                      () {
                                        final journalPubs = publications
                                            .where((pub) => pub.journalName == entry.key)
                                            .toList();
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => WorksListBottomSheet(
                                            title: '${'articles_from_journal'.tr()}:\n${entry.key}',
                                            publications: journalPubs,
                                          ),
                                        );
                                      },
                                    ),
                                    if (!isLast)
                                      Divider(
                                        color: Colors.white.withOpacity(0.08),
                                        height: 1,
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Top Tác giả (Top Authors)
                        if (topAuthorsList.isNotEmpty) ...[
                          Text(
                            'top_authors'.tr(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: List.generate(topAuthorsList.length, (index) {
                                final entry = topAuthorsList[index];
                                final isLast = index == topAuthorsList.length - 1;
                                return Column(
                                  children: [
                                    _buildTopAuthorItem(
                                      entry.key,
                                      entry.value,
                                      theme,
                                      () {
                                        final authorPubs = publications
                                            .where((pub) => pub.authors.contains(entry.key))
                                            .toList();
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => WorksListBottomSheet(
                                            title: '${'articles_by_author'.tr()}:\n${entry.key}',
                                            publications: authorPubs,
                                          ),
                                        );
                                      },
                                    ),
                                    if (!isLast)
                                      Divider(
                                        color: Colors.white.withOpacity(0.08),
                                        height: 1,
                                      ),
                                  ],
                                );
                              }),
                            ),
                          ),
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
    if (_isLoadingTaxonomy) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60.0),
          child: CircularProgressIndicator(color: Color(0xFF80CBC4)),
        ),
      );
    }

    if (_taxonomyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_taxonomyError!, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTaxonomy,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF80CBC4)),
                child: const Text('Thử lại', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final breadcrumb = _buildTaxonomyBreadcrumb();

    Widget stepWidget;

    if (_selectedDomain == null) {
      // Step 1: Chọn Domain (4 domains preset)
      stepWidget = SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _domainPresets.length,
          itemBuilder: (context, index) {
            final preset = _domainPresets[index];
            final String name = preset['name'];
            final String label = _getDomainLabel(name);
            final gradient = preset['gradient'] as Gradient;
            final icon = preset['icon'] as IconData;

            return Container(
              width: 140,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == _domainPresets.length - 1 ? 0 : 6,
              ),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final domainNode = _uniqueNodes(_taxonomyTopics.map((t) => t.domain).whereType())
                        .firstWhere(
                          (d) => d.name == name,
                          orElse: () => ResearchTaxonomyNode(id: name, name: name, level: ResearchTaxonomyLevel.domain, worksCount: 0),
                        );
                    setState(() {
                      _selectedDomain = domainNode;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 28),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else if (_selectedField == null) {
      // Step 2: Chọn Field
      final fields = _uniqueNodes(_taxonomyTopics
          .where((topic) => topic.domain?.name == _selectedDomain!.name)
          .map((topic) => topic.field)
          .whereType());

      if (fields.isEmpty) {
        stepWidget = const Center(
          child: Text('Không có lĩnh vực nào trong chủ đề này.', style: TextStyle(color: Colors.white60)),
        );
      } else {
        stepWidget = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: fields.length,
          itemBuilder: (context, index) {
            final field = fields[index];
            return GlassCard(
              borderRadius: 12,
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedField = field;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Center(
                      child: Text(
                        field.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    } else if (_selectedSubfield == null) {
      // Step 3: Chọn Subfield
      final subfields = _uniqueNodes(_taxonomyTopics
          .where((topic) => topic.field?.name == _selectedField!.name)
          .map((topic) => topic.subfield)
          .whereType());

      if (subfields.isEmpty) {
        stepWidget = const Center(
          child: Text('Không có chuyên ngành nào trong lĩnh vực này.', style: TextStyle(color: Colors.white60)),
        );
      } else {
        stepWidget = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: subfields.length,
          itemBuilder: (context, index) {
            final subfield = subfields[index];
            return GlassCard(
              borderRadius: 12,
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedSubfield = subfield;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Center(
                      child: Text(
                        subfield.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    } else {
      // Step 4: Chọn Topic
      final topics = _uniqueNodes(_taxonomyTopics
          .where((topic) => topic.subfield?.name == _selectedSubfield!.name)
          .map((topic) => topic.topic)
          .whereType());

      if (topics.isEmpty) {
        stepWidget = const Center(
          child: Text('Không có chủ đề nghiên cứu nào phù hợp.', style: TextStyle(color: Colors.white60)),
        );
      } else {
        stepWidget = ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _triggerSearch(topic.name);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            topic.name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Color(0xFF80CBC4), size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    }

    final auth = Provider.of<AuthNotifier>(context);
    final user = auth.currentUser;
    final userName = user?.displayName ?? 'Duy Trần';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            SharedState.languageNotifier.value == 'vi'
                ? 'Chào mừng, $userName!'
                : 'Welcome, $userName!',
            style: GoogleFonts.outfit(
              color: const Color(0xFF80CBC4),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedDomain == null 
                ? 'Chọn chủ đề theo Domain:' 
                : 'Khám phá cây phân loại chủ đề OpenAlex:',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: breadcrumb),
              if (_selectedDomain != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDomain = null;
                      _selectedField = null;
                      _selectedSubfield = null;
                    });
                  },
                  icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.redAccent),
                  label: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 1),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final targetNode = _selectedSubfield ?? _selectedField ?? _selectedDomain;
                    if (targetNode != null) {
                      _triggerSearch(targetNode.name);
                    }
                  },
                  icon: const Icon(Icons.done_rounded, size: 14, color: Colors.black),
                  label: const Text('Áp dụng', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: const Color(0xFF80CBC4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          stepWidget,
          if (_selectedDomain == null) ...[
            const SizedBox(height: 32),
            _buildTopResearchSection(theme),
            const SizedBox(height: 32),
            _buildRecentlyViewedSection(theme),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTaxonomyBreadcrumb() {
    final List<Widget> items = [];
    items.add(
      GestureDetector(
        onTap: () {
          setState(() {
            _selectedDomain = null;
            _selectedField = null;
            _selectedSubfield = null;
          });
        },
        child: const Text('Tất cả', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ),
    );

    if (_selectedDomain != null) {
      items.add(const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 14));
      items.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedField = null;
              _selectedSubfield = null;
            });
          },
          child: Text(
            _getDomainLabel(_selectedDomain!.name),
            style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_selectedField != null) {
      items.add(const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 14));
      items.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubfield = null;
            });
          },
          child: Text(
            _selectedField!.name,
            style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_selectedSubfield != null) {
      items.add(const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 14));
      items.add(
        Text(
          _selectedSubfield!.name,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: items,
      ),
    );
  }

  String _getDomainLabel(String name) {
    if (SharedState.languageNotifier.value == 'vi') {
      switch (name) {
        case 'Physical Sciences':
          return 'Khoa học Tự nhiên & Vật lý';
        case 'Life Sciences':
          return 'Khoa học Sự sống & Sinh học';
        case 'Health Sciences':
          return 'Y tế & Khoa học Sức khỏe';
        case 'Social Sciences':
          return 'Khoa học Xã hội & Nhân văn';
        default:
          return name;
      }
    } else {
      return name;
    }
  }

  List<ResearchTaxonomyNode> _uniqueNodes(Iterable<ResearchTaxonomyNode> nodes) {
    final seen = <String>{};
    final unique = <ResearchTaxonomyNode>[];
    for (final node in nodes) {
      final key = '${node.level.name}:${node.id}';
      if (node.isValid && seen.add(key)) {
        unique.add(node);
      }
    }
    unique.sort((a, b) => b.worksCount.compareTo(a.worksCount));
    return unique;
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
        borderRadius: 18,
        color: const Color(0xFF163E3E).withOpacity(0.4),
        borderColor: const Color(0xFFFFB300).withOpacity(0.45),
        borderWidth: 1.2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đóng góp trích dẫn nhiều nhất (${paper.citationCount} trích dẫn)',
                    style: GoogleFonts.outfit(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              paper.title,
              style: GoogleFonts.outfit(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              paper.authors.join(', '),
              style: GoogleFonts.inter(
                textStyle: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    paper.journalName,
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  paper.publicationYear.toString(),
                  style: GoogleFonts.outfit(
                    textStyle: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: const Color(0xFF80CBC4),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(
                    paper.title,
                    style: GoogleFonts.outfit(
                      textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '${paper.authors.isNotEmpty ? paper.authors.first : "Unknown"} - ${paper.publicationYear} - ${paper.journalName}',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF80CBC4).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF80CBC4), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${paper.citationCount}',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopJournalItem(String name, int count, ThemeData theme, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count ${'articles'.tr()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF80CBC4),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAuthorItem(String name, int count, ThemeData theme, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count ${'articles'.tr()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF80CBC4),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopResearchSection(ThemeData theme) {
    final topics = _uniqueNodes(_taxonomyTopics.map((t) => t.topic).whereType()).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: Color(0xFF80CBC4), size: 18),
            const SizedBox(width: 8),
            Text(
              SharedState.languageNotifier.value == 'vi' ? 'Nghiên cứu hàng đầu' : 'Top Research',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (topics.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                SharedState.languageNotifier.value == 'vi'
                    ? 'Chưa có dữ liệu chủ đề thịnh hành.'
                    : 'No trending topics data yet.',
                style: const TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ),
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: List.generate(topics.length, (index) {
                final topic = topics[index];
                final isLast = index == topics.length - 1;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _triggerSearch(topic.name);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF80CBC4).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF80CBC4),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic.name,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white30, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(color: Colors.white.withOpacity(0.08), height: 1),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentlyViewedSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xFF80CBC4), size: 18),
            const SizedBox(width: 8),
            Text(
              SharedState.languageNotifier.value == 'vi' ? 'Xem gần đây' : 'Recently Viewed',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<Publication>>(
          valueListenable: SharedState.recentlyViewedNotifier,
          builder: (context, recentlyViewed, _) {
            if (recentlyViewed.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Center(
                  child: Text(
                    SharedState.languageNotifier.value == 'vi'
                        ? 'Chưa xem bài viết nào gần đây.'
                        : 'No recently viewed publications yet.',
                    style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                  ),
                ),
              );
            }

            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: List.generate(recentlyViewed.length, (index) {
                  final paper = recentlyViewed[index];
                  final isLast = index == recentlyViewed.length - 1;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(publication: paper),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        paper.title,
                                        style: GoogleFonts.outfit(
                                          textStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${paper.authors.isNotEmpty ? paper.authors.first : "N/A"} • ${paper.publicationYear} • ${paper.journalName.trim().isEmpty ? 'unknown_journal'.tr() : paper.journalName}',
                                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(color: Colors.white.withOpacity(0.08), height: 1),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}
