import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../pages/detail_page.dart';
import '../state_management/search_notifier.dart';
import 'glass_card.dart';
import 'publication_card.dart';

/// Widget kết xuất danh sách kết quả tìm kiếm bài báo từ trạng thái của SearchNotifier.
class SearchResultsList extends StatelessWidget {
  final SearchNotifier notifier;
  final ScrollController scrollController;

  const SearchResultsList({
    super.key,
    required this.notifier,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<SearchState>(
      valueListenable: notifier.stateNotifier,
      builder: (context, state, _) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        }

        if (state.errorMessage.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: GlassCard(
                color: AppColors.error.withOpacity(0.15),
                borderColor: AppColors.error.withOpacity(0.3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Đã xảy ra lỗi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final list = state.publications;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.find_in_page_rounded,
                  size: 64,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy kết quả nào.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: list.length,
          padding: const EdgeInsets.only(bottom: 24),
          itemBuilder: (context, index) {
            final pub = list[index];
            return PublicationCard(
              id: pub.id,
              title: pub.title,
              year: pub.publicationYear.toString(),
              citationCount: pub.citationCount,
              journalName: pub.journalName,
              onTap: () {
                // Điều hướng sang trang chi tiết
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(publication: pub),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
