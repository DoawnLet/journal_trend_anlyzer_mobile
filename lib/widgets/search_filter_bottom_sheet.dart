import 'package:flutter/material.dart';
import 'dart:async';

import 'package:journal_trend_analysis_mb/models/publication_filter_model.dart';
import 'package:journal_trend_analysis_mb/services/filter_option_builder.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/viewmodels/search_notifier.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/widgets/research_taxonomy_selector.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchNotifier notifier;

  const SearchFilterBottomSheet({super.key, required this.notifier});

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  String _authorQuery = '';
  String _journalQuery = '';
  late PublicationFilter _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = SharedState.publicationFilterNotifier.value;
  }

  Future<void> _showTaxonomySelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResearchTaxonomySelector(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E4646),
      child: Column(
        children: [
          _Header(
            activeCount: _localFilter.activeFilterCount,
            onClose: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              children: [
                _Section(
                  title: 'publication_year'.tr(),
                  icon: Icons.calendar_month_rounded,
                  child: _YearFilter(
                    filter: _localFilter,
                    onChanged: (from, to) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          fromYear: from,
                          toYear: to,
                          clearYear: from == null && to == null,
                        );
                      });
                    },
                    onClear: () {
                      setState(() {
                        _localFilter = _localFilter.copyWith(clearYear: true);
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'citation_count'.tr(),
                  icon: Icons.format_quote_rounded,
                  child: _CitationFilter(
                    value: _localFilter.minCitations,
                    onChanged: (val) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          minCitations: val,
                          clearCitations: val == null,
                        );
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'sort_by'.tr(),
                  icon: Icons.sort_rounded,
                  child: _SortFilter(
                    value: _localFilter.sortBy,
                    onChanged: (value) {
                      setState(() {
                        final sortKey = switch (value) {
                          'most_cited' => 'most_cited',
                          'newest' => 'newest',
                          'oldest' => 'oldest',
                          _ => 'relevance',
                        };
                        _localFilter = _localFilter.copyWith(sortBy: sortKey);
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'open_access'.tr(),
                  icon: Icons.lock_open_rounded,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _localFilter.openAccessOnly,
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(openAccessOnly: value);
                      });
                    },
                    title: Text(
                      'open_access_only'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'API-level filter: is_oa:true',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    activeColor: const Color(0xFF80CBC4),
                  ),
                ),
                _Section(
                  title: 'publication_type'.tr(),
                  icon: Icons.category_rounded,
                  child: _TypeFilter(
                    value: _localFilter.publicationType,
                    onChanged: (value) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(publicationType: value);
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'authors'.tr(),
                  icon: Icons.person_rounded,
                  child: _LocalOptionFilter(
                    hint: 'search_author_hint'.tr(),
                    selectedValues: _localFilter.selectedAuthors,
                    options: FilterOptionBuilder.buildAuthorOptions(
                      widget.notifier.state.originalPublications,
                    ),
                    query: _authorQuery,
                    onQueryChanged: (value) =>
                        setState(() => _authorQuery = value),
                    onChanged: (values) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(selectedAuthors: values);
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'journal_prefix'.tr(),
                  icon: Icons.menu_book_rounded,
                  child: _LocalOptionFilter(
                    hint: 'search_journal_hint'.tr(),
                    selectedValues: _localFilter.selectedJournals,
                    options: FilterOptionBuilder.buildJournalOptions(
                      widget.notifier.state.originalPublications,
                    ),
                    query: _journalQuery,
                    onQueryChanged: (value) =>
                        setState(() => _journalQuery = value),
                    onChanged: (values) {
                      setState(() {
                        _localFilter = _localFilter.copyWith(selectedJournals: values);
                      });
                    },
                  ),
                ),
                _Section(
                  title: 'research_fields'.tr(),
                  icon: Icons.account_tree_rounded,
                  child: InkWell(
                    onTap: () async {
                      await _showTaxonomySelector();
                      setState(() {
                        _localFilter = _localFilter.copyWith(
                          taxonomy: SharedState.publicationFilterNotifier.value.taxonomy,
                        );
                      });
                    },
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
                              _localFilter.taxonomy.hasSelection
                                  ? _localFilter.taxonomy.breadcrumb
                                  : 'select_taxonomy_desc'.tr(),
                              style: TextStyle(
                                color: _localFilter.taxonomy.hasSelection
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
            onReset: () {
              setState(() {
                _localFilter = PublicationFilter.empty.copyWith(keyword: _localFilter.keyword);
              });
            },
            onApply: () {
              SharedState.setPublicationFilter(_localFilter);
              Navigator.maybePop(context);
            },
          ),
        ],
      ),
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
                Text(
                  'advanced_filters'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'active_filters_applied'.tr().replaceAll('{count}', '$activeCount'),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'close_button'.tr(),
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

class _YearFilter extends StatefulWidget {
  final PublicationFilter filter;
  final void Function(int? from, int? to) onChanged;
  final VoidCallback onClear;

  const _YearFilter({
    required this.filter,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_YearFilter> createState() => _YearFilterState();
}

class _YearFilterState extends State<_YearFilter> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(
      text: widget.filter.fromYear != null ? widget.filter.fromYear.toString() : '',
    );
    _toController = TextEditingController(
      text: widget.filter.toYear != null ? widget.filter.toYear.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant _YearFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.fromYear != oldWidget.filter.fromYear) {
      final valText = widget.filter.fromYear != null ? widget.filter.fromYear.toString() : '';
      if (_fromController.text != valText) {
        _fromController.text = valText;
      }
    }
    if (widget.filter.toYear != oldWidget.filter.toYear) {
      final valText = widget.filter.toYear != null ? widget.filter.toYear.toString() : '';
      if (_toController.text != valText) {
        _toController.text = valText;
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final fromText = _fromController.text.trim();
      final toText = _toController.text.trim();

      final isFromValid = fromText.isEmpty || (fromText.length == 4 && int.tryParse(fromText) != null);
      final isToValid = toText.isEmpty || (toText.length == 4 && int.tryParse(toText) != null);

      if (isFromValid && isToValid) {
        final from = int.tryParse(fromText);
        final to = int.tryParse(toText);
        widget.onChanged(from, to);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice('all_years'.tr(), widget.filter.fromYear == null && widget.filter.toYear == null, () {
              _debounce?.cancel();
              _fromController.clear();
              _toController.clear();
              widget.onClear();
            }),
            _choice('last_3_years'.tr(), widget.filter.fromYear == now - 2 && widget.filter.toYear == now, () {
              _debounce?.cancel();
              widget.onChanged(now - 2, now);
            }),
            _choice('last_5_years'.tr(), widget.filter.fromYear == now - 4 && widget.filter.toYear == now, () {
              _debounce?.cancel();
              widget.onChanged(now - 4, now);
            }),
            _choice('last_10_years'.tr(), widget.filter.fromYear == now - 9 && widget.filter.toYear == now, () {
              _debounce?.cancel();
              widget.onChanged(now - 9, now);
            }),
            _choice('2020-2024', widget.filter.fromYear == 2020 && widget.filter.toYear == 2024, () {
              _debounce?.cancel();
              widget.onChanged(2020, 2024);
            }),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'custom_range'.tr(),
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fromController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'from'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                  ),
                ),
                onChanged: (_) => _onChanged(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('—', style: TextStyle(color: Colors.white54)),
            ),
            Expanded(
              child: TextField(
                controller: _toController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'to'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF80CBC4)),
                  ),
                ),
                onChanged: (_) => _onChanged(),
              ),
            ),
          ],
        ),
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

class _CitationFilter extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _CitationFilter({required this.value, required this.onChanged});

  @override
  State<_CitationFilter> createState() => _CitationFilterState();
}

class _CitationFilterState extends State<_CitationFilter> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final presets = <int?>[null, 10, 50, 100, 500];
    final isPreset = presets.contains(widget.value);
    _controller = TextEditingController(
      text: (!isPreset && widget.value != null) ? widget.value.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant _CitationFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final presets = <int?>[null, 10, 50, 100, 500];
    final isPreset = presets.contains(widget.value);
    if (widget.value != oldWidget.value) {
      if (!isPreset && widget.value != null) {
        final valText = widget.value.toString();
        if (_controller.text != valText) {
          _controller.text = valText;
        }
      } else if (widget.value == null || isPreset) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = <int?>[null, 10, 50, 100, 500];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in presets)
              ChoiceChip(
                label: Text(
                  item == null ? 'any_citations'.tr() : '$item+',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: widget.value == item,
                onSelected: (_) {
                  _debounce?.cancel();
                  _controller.clear();
                  widget.onChanged(item);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'custom_minimum'.tr(),
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'min_citations_label'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF80CBC4)),
            ),
          ),
          onChanged: (text) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 600), () {
              final val = int.tryParse(text.trim());
              widget.onChanged(val);
            });
          },
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
    final options = {
      'relevance': 'relevance'.tr(),
      'most_cited': 'most_cited'.tr(),
      'newest': 'newest'.tr(),
      'oldest': 'oldest'.tr(),
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
    final options = {
      'all': 'all'.tr(),
      'article': 'article'.tr(),
      'review': 'review'.tr(),
      'conference-paper': 'conference_paper'.tr(),
      'book-chapter': 'book_chapter'.tr(),
      'preprint': 'preprint'.tr(),
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'no_options_available'.tr(),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
              label: Text('reset_button'.tr()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check_rounded),
              label: Text('apply_filters'.tr()),
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
