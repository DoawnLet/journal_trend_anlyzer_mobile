import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/mock_firebase_service.dart';
import '../widgets/glass_card.dart';
import 'detail_page.dart';
import 'journals_page.dart';

/// Màn hình Chi tiết Tạp chí (Journal Detail Screen)
class JournalDetailPage extends StatelessWidget {
  final JournalStats journal;

  const JournalDetailPage({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết Tạp chí',
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
              // Tiêu đề tên tạp chí
              GlassCard(
                borderColor: const Color(0xFF80CBC4).withOpacity(0.3),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Color(0xFF80CBC4), size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        journal.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Khối chỉ số đo lường chi tiết
              Row(
                children: [
                  _buildStatBox('Tổng bài báo', journal.count.toString(), Icons.article_rounded),
                  const SizedBox(width: 10),
                  _buildStatBox('Tổng trích dẫn', journal.totalCitations.toString(), Icons.star_rounded),
                  const SizedBox(width: 10),
                  _buildStatBox('Trích dẫn TB', journal.avgCitations.toStringAsFixed(1), Icons.insights_rounded),
                ],
              ),
              const SizedBox(height: 28),

              // Danh sách bài báo thuộc tạp chí này
              Text(
                'Bài báo liên quan (${journal.publications.length})',
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
                itemCount: journal.publications.length,
                itemBuilder: (context, index) {
                  final paper = journal.publications[index];
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
                          '${paper.authors.join(', ')} • ${paper.publicationYear}',
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

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF80CBC4), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
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
