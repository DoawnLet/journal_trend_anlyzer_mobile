import 'package:flutter/material.dart';

import '../models/publication_filter_model.dart';
import '../services/filter_option_builder.dart';
import '../state_management/shared_state.dart';
import '../state_management/search_notifier.dart';
import 'research_taxonomy_selector.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchNotifier notifier;

  const SearchFilterBottomSheet({super.key, required this.notifier});

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  String _authorQuery = '';
  String _journalQuery = '';

  void _showTaxonomySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResearchTaxonomySelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PublicationFilter>(
      valueListenable: SharedState.publicationFilterNotifier,
      builder: (context, filter, _) {
        return Container(
          color: const Color(0xFF1E4646),
          child: Column(
            children: [
              _Header(
                activeCount: filter.activeFilterCount,
                onClose: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  children: [
                    _Section(
                      title: 'Year',
                      icon: Icons.calendar_month_rounded,
                      child: _YearFilter(
                        filter: filter,
                        notifier: widget.notifier,
                      ),
                    ),
                    _Section(
                      title: 'Citations',
                      icon: Icons.format_quote_rounded,
                      child: _CitationFilter(
                        value: filter.minCitations,
                        onChanged: widget.notifier.setMinCitations,
                      ),
                    ),
                    _Section(
                      title: 'Sort by',
                      icon: Icons.sort_rounded,
                      child: _SortFilter(
                        value: filter.sortBy,
                        onChanged: (value) {
                          widget.notifier.setSortBy(switch (value) {
                            'most_cited' => 'cited_by_count:desc',
                            'newest' => 'publication_date:desc',
                            'oldest' => 'publication_date:asc',
                            _ => null,
                          });
                        },
                      ),
                    ),
                    _Section(
                      title: 'Open Access',
                      icon: Icons.lock_open_rounded,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: filter.openAccessOnly,
                        onChanged: widget.notifier.setOpenAccessOnly,
                        title: const Text(
                          'Open Access only',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'API-level filter: is_oa:true',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        activeColor: const Color(0xFF80CBC4),
                      ),
                    ),
                    _Section(
                      title: 'Publication Type',
                      icon: Icons.category_rounded,
                      child: _TypeFilter(
                        value: filter.publicationType,
                        onChanged: widget.notifier.setPublicationType,
                      ),
                    ),
                    _Section(
                      title: 'Authors',
                      icon: Icons.person_rounded,
                      child: _LocalOptionFilter(
                        hint: 'Search author...',
                        selectedValues: filter.selectedAuthors,
                        options: FilterOptionBuilder.buildAuthorOptions(
                          widget.notifier.state.originalPublications,
                        ),
                        query: _authorQuery,
                        onQueryChanged: (value) =>
                            setState(() => _authorQuery = value),
                        onChanged: (values) {
                          final current = SharedState.publicationFilterNotifier.value;
                          SharedState.setPublicationFilter(
                            current.copyWith(selectedAuthors: values),
                          );
                        },
                      ),
                    ),
                    _Section(
                      title: 'Journal / Source',
                      icon: Icons.menu_book_rounded,
                      child: _LocalOptionFilter(
                        hint: 'Search source...',
                        selectedValues: filter.selectedJournals,
                        options: FilterOptionBuilder.buildJournalOptions(
                          widget.notifier.state.originalPublications,
                        ),
                        query: _journalQuery,
                        onQueryChanged: (value) =>
                            setState(() => _journalQuery = value),
                        onChanged: widget.notifier.setJournalFilter,
                      ),
                    ),
                    _Section(
                      title: 'Research Field',
                      icon: Icons.account_tree_rounded,
                      child: InkWell(
                        onTap: _showTaxonomySelector,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  filter.taxonomy.hasSelection
                                      ? filter.taxonomy.breadcrumb
                                      : 'Chọn Domain > Field > Subfield > Topic',
                                  style: TextStyle(
                                    color: filter.taxonomy.hasSelection
                                        ? Colors.white
                                        : Colors.white54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              _Footer(
                onReset: widget.notifier.clearAllFilters,
                onApply: () => Navigator.maybePop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int activeCount;
  final VoidCallback onClose;

  const _Header({required this.activeCount, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: Color(0xFF80CBC4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advanced Research Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$activeCount filter đang áp dụng',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF80CBC4)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _YearFilter extends StatelessWidget {
  final PublicationFilter filter;
  final SearchNotifier notifier;

  const _YearFilter({required this.filter, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _choice('All years', filter.fromYear == null && filter.toYear == null,
            notifier.clearYearRange),
        _choice('Last 3 years', filter.fromYear == now - 2,
            () => notifier.setYearRange(now - 2, now)),
        _choice('Last 5 years', filter.fromYear == now - 4,
            () => notifier.setYearRange(now - 4, now)),
        _choice('Last 10 years', filter.fromYear == now - 9,
            () => notifier.setYearRange(now - 9, now)),
        _choice('2020-2024', filter.fromYear == 2020 && filter.toYear == 2024,
            () => notifier.setYearRange(2020, 2024)),
      ],
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _CitationFilter extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _CitationFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final values = <int?>[null, 10, 50, 100, 500];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in values)
          ChoiceChip(
            label: Text(
              item == null ? 'Any citations' : '$item+',
              style: const TextStyle(fontSize: 12),
            ),
            selected: value == item,
            onSelected: (_) => onChanged(item),
          ),
      ],
    );
  }
}

class _SortFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SortFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = {
      'relevance': 'Relevance',
      'most_cited': 'Most cited',
      'newest': 'Newest',
      'oldest': 'Oldest',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options.entries)
          ChoiceChip(
            label: Text(option.value, style: const TextStyle(fontSize: 12)),
            selected: value == option.key,
            onSelected: (_) => onChanged(option.key),
          ),
      ],
    );
  }
}

class _TypeFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = {
      'all': 'All',
      'article': 'Article',
      'review': 'Review',
      'conference-paper': 'Conference',
      'book-chapter': 'Book chapter',
      'preprint': 'Preprint',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options.entries)
          ChoiceChip(
            label: Text(option.value, style: const TextStyle(fontSize: 12)),
            selected: value == option.key,
            onSelected: (_) => onChanged(option.key),
          ),
      ],
    );
  }
}

class _LocalOptionFilter extends StatelessWidget {
  final String hint;
  final List<String> selectedValues;
  final Map<String, int> options;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<List<String>> onChanged;

  const _LocalOptionFilter({
    required this.hint,
    required this.selectedValues,
    required this.options,
    required this.query,
    required this.onQueryChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = options.entries
        .where((entry) =>
            entry.key.toLowerCase().contains(query.trim().toLowerCase()))
        .take(10)
        .toList();

    return Column(
      children: [
        TextField(
          onChanged: onQueryChanged,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chưa có option từ kết quả hiện tại.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        else
          ...filtered.map((entry) {
            final selected = selectedValues.contains(entry.key);
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: selected,
              activeColor: const Color(0xFF80CBC4),
              onChanged: (_) {
                final next = [...selectedValues];
                if (selected) {
                  next.remove(entry.key);
                } else {
                  next.add(entry.key);
                }
                onChanged(next);
              },
              title: Text(
                entry.key,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              secondary: Text(
                '${entry.value}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            );
          }),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onApply;

  const _Footer({required this.onReset, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF173D3D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF80CBC4),
                foregroundColor: const Color(0xFF0B2545),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
