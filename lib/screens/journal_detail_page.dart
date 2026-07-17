import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/services/openalex_api_service.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Màn hình Chi tiết Tạp chí (Journal Detail Screen)
class JournalDetailPage extends StatefulWidget {
  final String journalId;
  final String journalName;
  final int worksCount;
  final int citedByCount;
  final String homepageUrl;

  const JournalDetailPage({
    super.key,
    required this.journalId,
    required this.journalName,
    required this.worksCount,
    required this.citedByCount,
    required this.homepageUrl,
  });

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  bool _isLoading = true;
  List<Publication> _publications = const [];
  final TextEditingController _topicSearchController = TextEditingController();
  String _topicQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPublications();
  }

  @override
  void dispose() {
    _topicSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPublications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tải tối đa 50 bài viết của tạp chí này, lọc theo chủ đề/từ khóa nếu có
      final data = await OpenAlexApiService().getWorksBySource(
        widget.journalId,
        query: _topicQuery,
        perPage: 50,
      );
      final List results = data['results'] ?? [];
      final list = results.map((json) => Publication.fromJson(json)).toList();

      setState(() {
        _publications = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải bài viết của tạp chí: $e");
      setState(() {
        _publications = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _launchHomepage() async {
    if (widget.homepageUrl.trim().isEmpty) return;
    try {
      final uri = Uri.parse(widget.homepageUrl.trim());
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Không thể mở liên kết trang chủ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Trích xuất các topics phổ biến nhất từ danh sách bài báo hiện tại
    final Map<String, int> topicFreq = {};
    for (final p in _publications) {
      for (final topic in p.topics) {
        final name = topic.trim();
        if (name.isNotEmpty) {
          topicFreq[name] = (topicFreq[name] ?? 0) + 1;
        }
      }
    }
    final sortedTopics = topicFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTopics = sortedTopics.take(6).map((e) => e.key).toList();

    // 2. Nhóm các bài báo theo Volume/Issue
    final Map<String, List<Publication>> volumeGroups = {};
    for (final p in _publications) {
      final vol = p.volume?.trim() ?? '';
      final iss = p.issue?.trim() ?? '';

      String key;
      if (vol.isNotEmpty && iss.isNotEmpty) {
        key = '${'volume_label'.tr().replaceAll('{volume}', vol)}, ${'issue_label'.tr().replaceAll('{issue}', iss)}';
      } else if (vol.isNotEmpty) {
        key = 'volume_label'.tr().replaceAll('{volume}', vol);
      } else if (iss.isNotEmpty) {
        key = 'issue_label'.tr().replaceAll('{issue}', iss);
      } else {
        key = 'n_a'.tr();
      }

      volumeGroups.putIfAbsent(key, () => []).add(p);
    }

    // Sắp xếp các Volume/Issue theo năm xuất bản mới nhất và ký tự của khóa
    final sortedGroupKeys = volumeGroups.keys.toList()
      ..sort((a, b) {
        final maxYearA = volumeGroups[a]!.fold<int>(0, (max, p) => p.publicationYear > max ? p.publicationYear : max);
        final maxYearB = volumeGroups[b]!.fold<int>(0, (max, p) => p.publicationYear > max ? p.publicationYear : max);
        if (maxYearA != maxYearB) {
          return maxYearB.compareTo(maxYearA); // Mới nhất lên đầu
        }
        return a.compareTo(b);
      });

    final avgCitations = widget.worksCount == 0 ? 0.0 : widget.citedByCount / widget.worksCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'journal_detail'.tr(),
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
              // Tiêu đề tên tạp chí và link homepage
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
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF80CBC4), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.journalName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.homepageUrl.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _launchHomepage,
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.link_rounded, color: Color(0xFF80CBC4), size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.homepageUrl,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF80CBC4),
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Khối chỉ số đo lường chi tiết
              Row(
                children: [
                  _buildStatBox('total_publications'.tr(), widget.worksCount.toString(), Icons.article_rounded),
                  const SizedBox(width: 10),
                  _buildStatBox('total_citations'.tr(), widget.citedByCount.toString(), Icons.star_rounded),
                  const SizedBox(width: 10),
                  _buildStatBox('avg_citations_short'.tr(), avgCitations.toStringAsFixed(1), Icons.insights_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Thanh tìm kiếm chủ đề / bài viết của tạp chí
              TextField(
                controller: _topicSearchController,
                onSubmitted: (value) {
                  setState(() {
                    _topicQuery = value.trim();
                  });
                  _fetchPublications();
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'search_topic_in_journal_hint'.tr(),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_topicSearchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                          onPressed: () {
                            _topicSearchController.clear();
                            setState(() {
                              _topicQuery = '';
                            });
                            _fetchPublications();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _topicQuery = _topicSearchController.text.trim();
                          });
                          _fetchPublications();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nội dung hiển thị chính (Đang tải / Có kết quả / Không có kết quả)
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: CircularProgressIndicator(color: Color(0xFF80CBC4)),
                  ),
                )
              else ...[
                // Khu vực hiển thị Topics của Tạp chí
                if (topTopics.isNotEmpty) ...[
                  Text(
                    'journal_topics'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topTopics.map((topic) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.2)),
                        ),
                        child: Text(
                          topic,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF80CBC4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Danh sách bài báo nhóm theo Volume/Issue
                Text(
                  'recent_volumes'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                if (_publications.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: Colors.white30),
                          const SizedBox(height: 12),
                          Text(
                            'no_publications_found'.tr(),
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final groupKey = sortedGroupKeys[index];
                      final papers = volumeGroups[groupKey]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: const Color(0xFF80CBC4),
                            collapsedIconColor: Colors.white70,
                            title: Text(
                              groupKey,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${papers.length} ${'articles'.tr()}',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                            ),
                            childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                            children: papers.map((paper) {
                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  title: Text(
                                    paper.title,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${paper.authors.join(', ')} • ${paper.publicationYear}',
                                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF80CBC4).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF80CBC4).withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${paper.citationCount}',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF80CBC4),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, color: Color(0xFF80CBC4), size: 10),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
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
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF80CBC4).withOpacity(0.1),
              ),
              child: Icon(icon, color: const Color(0xFF80CBC4), size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
