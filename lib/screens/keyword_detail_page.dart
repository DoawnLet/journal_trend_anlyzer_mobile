import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/widgets/works_list_bottom_sheet.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/publication_trend_chart.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';
import 'package:journal_trend_analysis_mb/screens/keywords_page.dart';

/// Lớp đại diện cho tác giả đóng góp cho từ khóa này
class AuthorKeywordStats {
  final String name;
  final int count;

  const AuthorKeywordStats({required this.name, required this.count});
}

/// Màn hình Chi tiết Từ khóa (Keyword Detail Screen)
class KeywordDetailPage extends StatefulWidget {
  final KeywordStats keywordStats;

  const KeywordDetailPage({super.key, required this.keywordStats});

  @override
  State<KeywordDetailPage> createState() => _KeywordDetailPageState();
}

class _KeywordDetailPageState extends State<KeywordDetailPage> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final publications = widget.keywordStats.publications;

    // 1. Tính toán xu hướng xuất bản theo năm cho từ khóa này
    final Map<int, int> trendByYear = {};
    for (final p in publications) {
      if (p.publicationYear > 0) {
        trendByYear[p.publicationYear] = (trendByYear[p.publicationYear] ?? 0) + 1;
      }
    }
    final sortedYears = trendByYear.keys.toList()..sort();
    final sortedTrend = <int, int>{};
    for (final year in sortedYears) {
      sortedTrend[year] = trendByYear[year]!;
    }

    // 2. Tính toán các Tạp chí liên quan
    final Map<String, int> journalCounts = {};
    for (final p in publications) {
      final name = p.journalName.trim().isEmpty ? 'unknown_journal'.tr() : p.journalName;
      journalCounts[name] = (journalCounts[name] ?? 0) + 1;
    }
    final relatedJournals = journalCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Tính toán và xếp hạng tác giả đóng góp (Sắp xếp giảm dần)
    final Map<String, int> authorCounts = {};
    for (final p in publications) {
      for (final author in p.authors) {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      }
    }
    final List<AuthorKeywordStats> rankedAuthors = authorCounts.entries
        .map((entry) => AuthorKeywordStats(name: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)); // Sắp xếp giảm dần theo số lượng công bố

    // 4. Phân trang bài báo liên quan
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < publications.length)
        ? startIndex + _itemsPerPage
        : publications.length;
    final currentPublications = publications.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'keyword_detail'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF102828), const Color(0xFF0C1D1D)]
                : [const Color(0xFF235C5C), const Color(0xFF1A4747)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên Từ khóa & Tần suất
              GlassCard(
                borderColor: const Color(0xFF80CBC4).withOpacity(0.3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF80CBC4).withOpacity(0.1),
                      ),
                      child: const Icon(Icons.tag_rounded, color: Color(0xFF80CBC4), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.keywordStats.keyword,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'appearance_frequency'.tr().replaceAll('{count}', widget.keywordStats.count.toString()),
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Biểu đồ xu hướng xuất bản của từ khóa
              Text(
                'yearly_publication_trend'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: PublicationTrendChart(trendByYear: sortedTrend),
              ),
              const SizedBox(height: 24),

              // Xếp hạng tác giả đóng góp hàng đầu
              Text(
                'top_contributing_authors'.tr(),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildRankedAuthorsSection(rankedAuthors),
              const SizedBox(height: 24),

              // Tạp chí liên quan hàng đầu
              if (relatedJournals.isNotEmpty) ...[
                Text(
                  'related_journals'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _buildRelatedJournalsSection(relatedJournals),
                const SizedBox(height: 24),
              ],

              // Bài báo liên quan
              Text(
                '${'related_publications'.tr()} (${publications.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentPublications.length,
                itemBuilder: (context, index) {
                  final paper = currentPublications[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        paper.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '${paper.authors.isNotEmpty ? paper.authors.first : "N/A"} • ${paper.publicationYear} • ${paper.journalName.trim().isEmpty ? 'unknown_journal'.tr() : paper.journalName}',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF80CBC4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${paper.citationCount}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF80CBC4),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Color(0xFF80CBC4), size: 12),
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

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(publication: paper),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPaginationControls(publications.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalItems) {
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    // Xác định các số trang cần hiển thị để tránh tràn màn hình (pixel overflow)
    final List<int> pagesToShow = [];
    if (totalPages <= 5) {
      pagesToShow.addAll(List.generate(totalPages, (i) => i));
    } else {
      // Luôn hiển thị trang đầu tiên
      pagesToShow.add(0);

      int start = _currentPage - 1;
      int end = _currentPage + 1;

      if (start <= 1) {
        start = 1;
        end = 3;
      }
      if (end >= totalPages - 2) {
        end = totalPages - 2;
        start = totalPages - 4;
      }

      for (int i = start; i <= end; i++) {
        pagesToShow.add(i);
      }

      // Luôn hiển thị trang cuối cùng
      pagesToShow.add(totalPages - 1);
    }

    final List<Widget> pageButtons = [];
    for (int i = 0; i < pagesToShow.length; i++) {
      final index = pagesToShow[i];
      
      // Thêm dấu ba chấm (...) nếu có khoảng cách giữa các trang
      if (i > 0 && index - pagesToShow[i - 1] > 1) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Container(
              width: 24,
              height: 38,
              alignment: Alignment.center,
              child: Text(
                '...',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }

      final isSelected = index == _currentPage;
      pageButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _currentPage = index;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF80CBC4)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF80CBC4).withOpacity(0.8)
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black87 : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút quay lại trang trước
          _buildPageButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          const SizedBox(width: 12),
          // Các nút số trang và dấu ba chấm
          ...pageButtons,
          const SizedBox(width: 12),
          // Nút tới trang tiếp theo
          _buildPageButton(
            icon: Icons.chevron_right_rounded,
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
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onPressed}) {
    final isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isEnabled ? Colors.white70 : Colors.white24,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildRankedAuthorsSection(List<AuthorKeywordStats> list) {
    if (list.isEmpty) {
      return GlassCard(
        child: Center(
          child: Text(
            'no_author_data'.tr(),
            style: const TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    final topList = list.take(5).toList();
    final maxAuthorCount = topList.first.count;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(topList.length, (i) {
          final author = topList[i];
          Color rankColor;
          Color rankBgColor;
          switch (i) {
            case 0:
              rankColor = const Color(0xFFFFD700); // Gold
              rankBgColor = const Color(0xFFFFD700).withOpacity(0.15);
              break;
            case 1:
              rankColor = const Color(0xFFC0C0C0); // Silver
              rankBgColor = const Color(0xFFC0C0C0).withOpacity(0.15);
              break;
            case 2:
              rankColor = const Color(0xFFCD7F32); // Bronze
              rankBgColor = const Color(0xFFCD7F32).withOpacity(0.15);
              break;
            default:
              rankColor = const Color(0xFF80CBC4); // Teal
              rankBgColor = const Color(0xFF80CBC4).withOpacity(0.1);
          }

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final authorPubs = widget.keywordStats.publications
                  .where((pub) => pub.authors.contains(author.name))
                  .toList();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => WorksListBottomSheet(
                  title: '${'articles_by_author'.tr()}:\n${author.name}',
                  publications: authorPubs,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rankBgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (i + 1).toString(),
                      style: GoogleFonts.outfit(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.name,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Thanh thanh đo tỷ lệ đóng góp trực quan của Tác giả (Ranking bar chart concept)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 4,
                            width: 140,
                            child: LinearProgressIndicator(
                              value: maxAuthorCount == 0 ? 0.0 : author.count / maxAuthorCount,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(rankColor.withOpacity(0.85)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${author.count} ${'articles'.tr()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF80CBC4),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRelatedJournalsSection(List<MapEntry<String, int>> list) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    final topList = list.take(3).toList();
    final maxJournalCount = topList.first.value;

    return Column(
      children: topList.map((entry) {
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
                final journalPubs = widget.keywordStats.publications
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Thanh đo tỷ lệ bài đăng của Tạp chí
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 3,
                              width: 120,
                              child: LinearProgressIndicator(
                                value: maxJournalCount == 0 ? 0.0 : entry.value / maxJournalCount,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF80CBC4).withOpacity(0.7)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${entry.value} ${'articles'.tr()}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
