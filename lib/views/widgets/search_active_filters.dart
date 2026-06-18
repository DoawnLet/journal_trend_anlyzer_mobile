import 'package:flutter/material.dart';

import '../../core/utils/translation.dart';
import '../models/publication_filter_model.dart';
import '../state_management/search_notifier.dart';
import '../state_management/shared_state.dart';

class SearchActiveFilters extends StatelessWidget {
  final SearchNotifier notifier;

  const SearchActiveFilters({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<PublicationFilter>(
      valueListenable: SharedState.publicationFilterNotifier,
      builder: (context, filter, _) {
        if (!filter.hasActiveFilters) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (filter.fromYear != null || filter.toYear != null)
                  _chip(
                    context,
                    label: filter.fromYear != null && filter.toYear != null
                        ? '${filter.fromYear}-${filter.toYear}'
                        : filter.fromYear != null
                            ? '${'from'.tr()} ${filter.fromYear}'
                            : '${'to'.tr()} ${filter.toYear}',
                    onDeleted: notifier.clearYearRange,
                  ),
                if (filter.minCitations != null)
                  _chip(
                    context,
                    label: '${filter.minCitations}+ ${'citations'.tr()}',
                    onDeleted: () => notifier.setMinCitations(null),
                  ),
                if (filter.openAccessOnly)
                  _chip(
                    context,
                    label: 'open_access_status'.tr(),
                    onDeleted: () => notifier.setOpenAccessOnly(false),
                  ),
                if (filter.publicationType != 'all')
                  _chip(
                    context,
                    label: filter.publicationType.tr(),
                    onDeleted: () => notifier.setPublicationType('all'),
                  ),
                if (filter.sortBy != 'relevance')
                  _chip(
                    context,
                    label: '${'sort_by_label'.tr()}: ${filter.sortLabelKey.tr().toLowerCase()}',
                    onDeleted: notifier.clearSortBy,
                  ),
                if (filter.taxonomy.hasSelection)
                  _chip(
                    context,
                    label: filter.taxonomy.deepest != null ? filter.taxonomy.deepest!.name.tr() : '',
                    onDeleted: () {
                      final current = SharedState.publicationFilterNotifier.value;
                      SharedState.setPublicationFilter(
                        current.copyWith(clearTaxonomy: true),
                      );
                      SharedState.clearResearchTaxonomy();
                    },
                  ),
                for (final author in filter.selectedAuthors)
                  _chip(
                    context,
                    label: '${'author_prefix'.tr()}: $author',
                    onDeleted: () {
                      final next = [...filter.selectedAuthors]..remove(author);
                      final current = SharedState.publicationFilterNotifier.value;
                      SharedState.setPublicationFilter(
                        current.copyWith(selectedAuthors: next),
                      );
                    },
                  ),
                for (final journal in filter.selectedJournals)
                  _chip(
                    context,
                    label: '${'journal_prefix'.tr()}: $journal',
                    onDeleted: () {
                      final next = [...filter.selectedJournals]..remove(journal);
                      notifier.setJournalFilter(next);
                    },
                  ),
                for (final topic in filter.selectedTopics)
                  _chip(
                    context,
                    label: 'Topic: $topic',
                    onDeleted: () {
                      final next = [...filter.selectedTopics]..remove(topic);
                      final current = SharedState.publicationFilterNotifier.value;
                      SharedState.setPublicationFilter(
                        current.copyWith(selectedTopics: next),
                      );
                    },
                  ),
                TextButton.icon(
                  onPressed: notifier.clearAllFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 16),
                  label: Text('clear_all'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF80CBC4),
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required VoidCallback onDeleted,
  }) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
      deleteIcon: const Icon(
        Icons.close_rounded,
        size: 14,
        color: Colors.white70,
      ),
      onDeleted: onDeleted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
    );
  }
}
