import 'package:flutter/material.dart';

import 'package:journal_trend_analysis_mb/utils/formatters.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/models/research_taxonomy_model.dart';
import 'package:journal_trend_analysis_mb/services/taxonomy_api_service.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';

class ResearchTaxonomySelector extends StatefulWidget {
  const ResearchTaxonomySelector({super.key});

  @override
  State<ResearchTaxonomySelector> createState() =>
      _ResearchTaxonomySelectorState();
}

class _ResearchTaxonomySelectorState extends State<ResearchTaxonomySelector> {
  final _apiService = TaxonomyApiService();
  final _searchController = TextEditingController();

  List<ResearchTopic> _topics = const [];
  bool _isLoading = true;
  String? _errorMessage;

  ResearchTaxonomyNode? _selectedDomain;
  ResearchTaxonomyNode? _selectedField;
  ResearchTaxonomyNode? _selectedSubfield;
  ResearchTaxonomyNode? _selectedTopic;

  @override
  void initState() {
    super.initState();
    final current = SharedState.activeTaxonomyNotifier.value;
    _selectedDomain = current.domain;
    _selectedField = current.field;
    _selectedSubfield = current.subfield;
    _selectedTopic = current.topic;
    _loadPopularTopics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularTopics() async {
    await _loadTopics(() => _apiService.fetchPopularTopics(limit: 100));
  }

  Future<void> _loadFullCatalog() async {
    await _loadTopics(() => _apiService.fetchTopicCatalog(maxPages: 45));
  }

  Future<void> _searchTopics(String query) async {
    await _loadTopics(() => _apiService.searchTopics(query, limit: 100));
  }

  Future<void> _loadTopics(Future<List<ResearchTopic>> Function() loader) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topics = await loader();
      if (!mounted) {
        return;
      }
      setState(() {
        _topics = topics;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'error_loading_taxonomy'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ResearchTaxonomyNode> get _domains {
    return _uniqueNodes(_topics.map((topic) => topic.domain).whereType());
  }

  List<ResearchTaxonomyNode> get _fields {
    return _uniqueNodes(_topics
        .where((topic) => _selectedDomain == null || topic.domain == _selectedDomain)
        .map((topic) => topic.field)
        .whereType());
  }

  List<ResearchTaxonomyNode> get _subfields {
    return _uniqueNodes(_topics
        .where((topic) => _selectedDomain == null || topic.domain == _selectedDomain)
        .where((topic) => _selectedField == null || topic.field == _selectedField)
        .map((topic) => topic.subfield)
        .whereType());
  }

  List<ResearchTaxonomyNode> get _topicNodes {
    return _uniqueNodes(_topics
        .where((topic) => _selectedDomain == null || topic.domain == _selectedDomain)
        .where((topic) => _selectedField == null || topic.field == _selectedField)
        .where((topic) =>
            _selectedSubfield == null || topic.subfield == _selectedSubfield)
        .map((topic) => topic.topic));
  }

  List<ResearchTaxonomyNode> _uniqueNodes(
    Iterable<ResearchTaxonomyNode> nodes,
  ) {
    final seen = <String>{};
    final unique = <ResearchTaxonomyNode>[];
    for (final node in nodes) {
      final key = '${node.level.name}:${node.id}';
      if (node.isValid && seen.add(key)) {
        unique.add(node);
      }
    }
    unique.sort((a, b) => b.worksCount.compareTo(a.worksCount));
    return unique;
  }

  void _applySelection() {
    final selection = ResearchTaxonomySelection(
      domain: _selectedDomain,
      field: _selectedField,
      subfield: _selectedSubfield,
      topic: _selectedTopic,
    );

    if (!selection.hasSelection) {
      SharedState.clearResearchTaxonomy();
    } else {
      SharedState.setResearchTaxonomy(selection);
    }
    Navigator.pop(context);
  }

  void _clearSelection() {
    setState(() {
      _selectedDomain = null;
      _selectedField = null;
      _selectedSubfield = null;
      _selectedTopic = null;
    });
    SharedState.clearResearchTaxonomy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E4646),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'research_taxonomy_tree'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchTopics,
              decoration: InputDecoration(
                hintText: 'search_taxonomy_hint'.tr(),
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: Colors.white60),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white70),
                  onPressed: () => _searchTopics(_searchController.text),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildBreadcrumb(theme),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadPopularTopics,
                  icon: const Icon(Icons.trending_up_rounded, size: 18),
                  label: const Text('Popular'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadFullCatalog,
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  label: Text('load_catalog'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF80CBC4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _buildSection(
                              title: 'Domain',
                              nodes: _domains,
                              selected: _selectedDomain,
                              onSelected: (node) {
                                setState(() {
                                  _selectedDomain = node;
                                  _selectedField = null;
                                  _selectedSubfield = null;
                                  _selectedTopic = null;
                                });
                              },
                            ),
                            _buildSection(
                              title: 'Field',
                              nodes: _fields,
                              selected: _selectedField,
                              onSelected: (node) {
                                setState(() {
                                  _selectedField = node;
                                  _selectedSubfield = null;
                                  _selectedTopic = null;
                                });
                              },
                            ),
                            _buildSection(
                              title: 'Subfield',
                              nodes: _subfields,
                              selected: _selectedSubfield,
                              onSelected: (node) {
                                setState(() {
                                  _selectedSubfield = node;
                                  _selectedTopic = null;
                                });
                              },
                            ),
                            _buildSection(
                              title: 'Topic',
                              nodes: _topicNodes,
                              selected: _selectedTopic,
                              onSelected: (node) {
                                setState(() {
                                  _selectedTopic = node;
                                  final matched = _topics.firstWhere(
                                    (topic) => topic.topic == node,
                                    orElse: () => ResearchTopic(topic: node),
                                  );
                                  _selectedDomain =
                                      matched.domain ?? _selectedDomain;
                                  _selectedField = matched.field ?? _selectedField;
                                  _selectedSubfield =
                                      matched.subfield ?? _selectedSubfield;
                                });
                              },
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clear_rounded),
                    label: Text('clear_selection'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _clearSelection,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: Text('apply'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      foregroundColor: const Color(0xFF123838),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _applySelection,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(ThemeData theme) {
    final selection = ResearchTaxonomySelection(
      domain: _selectedDomain,
      field: _selectedField,
      subfield: _selectedSubfield,
      topic: _selectedTopic,
    );

    final parts = [
      _selectedDomain?.name.tr(),
      _selectedField?.name.tr(),
      _selectedSubfield?.name.tr(),
      _selectedTopic?.name.tr(),
    ].whereType<String>().where((item) => item.isNotEmpty).toList();
    final breadcrumb = parts.join(' > ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        selection.hasSelection
            ? breadcrumb
            : 'no_taxonomy_selected'.tr(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: selection.hasSelection ? Colors.white : Colors.white54,
          fontWeight: selection.hasSelection ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<ResearchTaxonomyNode> nodes,
    required ResearchTaxonomyNode? selected,
    required ValueChanged<ResearchTaxonomyNode> onSelected,
  }) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nodes.take(18).map((node) {
              final isSelected = node == selected;
              return ChoiceChip(
                selected: isSelected,
                label: Text(
                  node.worksCount > 0
                      ? '${node.name.tr()} (${Formatters.formatCitationCount(node.worksCount)})'
                      : node.name.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF123838) : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                selectedColor: const Color(0xFF80CBC4),
                backgroundColor: Colors.white.withOpacity(0.07),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF80CBC4)
                      : Colors.white.withOpacity(0.12),
                ),
                onSelected: (_) => onSelected(node),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
