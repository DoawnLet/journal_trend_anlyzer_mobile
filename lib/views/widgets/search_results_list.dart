import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../pages/detail_page.dart';
import '../state_management/search_notifier.dart';
import 'glass_card.dart';
import 'publication_card.dart';

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
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(
                height: 420,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 14),
                      Text(
                        'Đang tải publications từ OpenAlex...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (state.errorMessage.isNotEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  height: 360,
                  child: Center(
                    child: GlassCard(
                      color: AppColors.error.withOpacity(0.15),
                      borderColor: AppColors.error.withOpacity(0.3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải publications',
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
                ),
              ),
            ],
          );
        }

        final list = state.publications;
        if (list.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 420,
                child: Center(
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
                        'No publications available for analysis.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try changing your topic or filters.',
                        style: TextStyle(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
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
              isOpenAccess: pub.isOpenAccess,
              publicationType: pub.publicationType,
              primaryAuthor: pub.authors.isEmpty ? null : pub.authors.first,
              topics: pub.topics,
              concepts: pub.concepts,
              onTap: () {
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
