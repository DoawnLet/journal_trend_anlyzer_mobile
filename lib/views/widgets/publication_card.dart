import 'package:flutter/material.dart';
import '../../core/utils/translation.dart';
import 'glass_card.dart';

/// Thẻ hiển thị tóm tắt bài báo khoa học.
/// Sử dụng phong cách GlassCard và bố cục hiển thị đầy đủ thông tin:
/// Tiêu đề, Năm xuất bản, Số lượt trích dẫn, và Tên tạp chí/nơi công bố.
class PublicationCard extends StatelessWidget {
  final String id;
  final String title;
  final String year;
  final int citationCount;
  final String journalName;
  final bool isOpenAccess;
  final String? publicationType;
  final String? primaryAuthor;
  final List<String> topics;
  final List<String> concepts;
  final VoidCallback? onTap;

  const PublicationCard({
    super.key,
    required this.id,
    required this.title,
    required this.year,
    required this.citationCount,
    required this.journalName,
    this.isOpenAccess = false,
    this.publicationType,
    this.primaryAuthor,
    this.topics = const [],
    this.concepts = const [],
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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: isOpenAccess
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      label: isOpenAccess
                          ? 'open_access_status'.tr()
                          : 'closed_access_status'.tr(),
                      color: isOpenAccess
                          ? const Color(0xFF80CBC4)
                          : Colors.white70,
                    ),
                    _MetaChip(
                      icon: Icons.category_rounded,
                      label: _formatType(publicationType).tr(),
                      color: Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

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
                        journalName.isNotEmpty
                            ? journalName
                            : 'unknown_journal'.tr(),
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

                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${'primary_author_label'.tr()}: ${primaryAuthor?.isNotEmpty == true ? primaryAuthor : 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTopicConcepts(theme),
                const SizedBox(height: 12),

                // Dòng chứa năm xuất bản và số lượt trích dẫn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Năm xuất bản (Dưới dạng tag chip nhỏ)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                            '$citationCount ${'trich_dan'.tr()}',
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

  Widget _buildTopicConcepts(ThemeData theme) {
    final values = <String>[
      ...topics.take(2),
      ...concepts.take(2),
    ].where((value) => value.trim().isNotEmpty).toSet().take(4).toList();

    if (values.isEmpty) {
      return Text(
        'Topic/Concept: N/A',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF80CBC4).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF80CBC4).withOpacity(0.24),
            ),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatType(String? type) {
    final cleanType = type?.trim();
    if (cleanType == null || cleanType.isEmpty) {
      return 'Unknown type';
    }
    return cleanType
        .split('-')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
