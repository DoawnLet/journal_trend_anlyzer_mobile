import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Thẻ hiển thị tóm tắt bài báo khoa học.
/// Sử dụng phong cách GlassCard và bố cục hiển thị đầy đủ thông tin:
/// Tiêu đề, Năm xuất bản, Số lượt trích dẫn, và Tên tạp chí/nơi công bố.
class PublicationCard extends StatelessWidget {
  final String title;
  final String year;
  final int citationCount;
  final String journalName;
  final VoidCallback? onTap;

  const PublicationCard({
    super.key,
    required this.title,
    required this.year,
    required this.citationCount,
    required this.journalName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề bài báo
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Tên Tạp chí / Nhà xuất bản
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        journalName.isNotEmpty ? journalName : 'Unknown Journal',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Dòng chứa năm xuất bản và số lượt trích dẫn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Năm xuất bản (Dưới dạng tag chip nhỏ)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            year,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Số lượt trích dẫn
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$citationCount trích dẫn',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
