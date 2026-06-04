import 'package:flutter/material.dart';
import '../state_management/search_notifier.dart';

/// Widget hiển thị danh sách các bộ lọc đang được kích hoạt dưới dạng InputChip.
class SearchActiveFilters extends StatelessWidget {
  final SearchNotifier notifier;

  const SearchActiveFilters({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<SearchState>(
      valueListenable: notifier.stateNotifier,
      builder: (context, state, _) {
        final hasAuthor = state.selectedAuthorName != null;
        final hasConcept = state.selectedConceptName != null;
        final hasTopic = state.selectedTopicName != null;
        final hasSort = state.sortBy != null;

        if (!hasAuthor && !hasConcept && !hasTopic && !hasSort) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (hasAuthor)
                  InputChip(
                    label: Text(
                      'Tác giả: ${state.selectedAuthorName}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    onDeleted: () => notifier.clearAuthorFilter(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                  ),
                if (hasConcept)
                  InputChip(
                    label: Text(
                      'Khái niệm: ${state.selectedConceptName}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    onDeleted: () => notifier.clearConceptFilter(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                  ),
                if (hasTopic)
                  InputChip(
                    label: Text(
                      'Chủ đề: ${state.selectedTopicName}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    onDeleted: () => notifier.clearTopicFilter(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                  ),
                if (hasSort)
                  InputChip(
                    label: Text(
                      state.sortBy == 'publication_date:desc' ? 'Sắp xếp: Mới nhất' : 'Sắp xếp: Cũ nhất',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    onDeleted: () => notifier.clearSortBy(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
