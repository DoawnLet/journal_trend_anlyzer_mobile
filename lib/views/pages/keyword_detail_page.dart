import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/translation.dart';
import '../../core/services/mock_firebase_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/research_trend_analysis/publication_trend_chart.dart';
import 'detail_page.dart';
import 'keywords_page.dart';

/// Lớp đại diện cho tác giả đóng góp cho từ khóa này
class AuthorKeywordStats {
  final String name;
  final int count;

  const AuthorKeywordStats({required this.name, required this.count});
}

/// Màn hình Chi tiết Từ khóa (Keyword Detail Screen)
class KeywordDetailPage extends StatelessWidget {
  final KeywordStats keywordStats;

  const KeywordDetailPage({super.key, required this.keywordStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final publications = keywordStats.publications;

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

    // 3. Tính toán và xếp hạng tác giả đóng góp (Xắp xếp giảm dần theo sản lượng bài báo)
    final Map<String, int> authorCounts = {};
    for (final p in publications) {
      for (final author in p.authors) {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      }
    }
    final List<AuthorKeywordStats> rankedAuthors = authorCounts.entries
        .map((entry) => AuthorKeywordStats(name: entry.key, count: entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)); // Giảm dần theo số lượng bài viết

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết Từ khóa',
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
              // Tên Từ khóa
              GlassCard(
                borderColor: const Color(0xFF80CBC4).withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.tag_rounded, color: Color(0xFF80CBC4), size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            keywordStats.keyword,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tần suất xuất hiện: ${keywordStats.count} lần',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
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
                'Xu hướng công bố theo năm',
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

              // Xếp hạng tác giả đóng góp hàng đầu (Ranked Authors - descending)
              Text(
                'Tác giả đóng góp hàng đầu',
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
              Text(
                'Tạp chí liên quan',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              _buildRelatedJournalsSection(relatedJournals),
              const SizedBox(height: 24),

              // Bài báo liên quan
              Text(
                'Bài viết liên quan (${publications.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
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
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${paper.authors.isNotEmpty ? paper.authors.first : "N/A"} • ${paper.publicationYear} • ${paper.journalName}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
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
                          style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 11, fontWeight: FontWeight.bold),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankedAuthorsSection(List<AuthorKeywordStats> list) {
    if (list.isEmpty) {
      return const GlassCard(child: Center(child: Text('Không có dữ liệu tác giả', style: TextStyle(color: Colors.white60))));
    }

    final topList = list.take(5).toList();

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: List.generate(topList.length, (i) {
          final author = topList[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
            child: Row(
              children: [
                // Số thứ tự xếp hạng
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.amber.withOpacity(0.2) : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (i + 1).toString(),
                    style: TextStyle(
                      color: i == 0 ? Colors.amber : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    author.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${author.count} bài viết',
                  style: const TextStyle(color: Color(0xFF80CBC4), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
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

    return Column(
      children: topList.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${entry.value} bài',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
