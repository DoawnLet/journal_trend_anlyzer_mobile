import 'package:flutter/material.dart';

import 'package:journal_trend_analysis_mb/utils/formatters.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/models/ranking_item_model.dart';
import 'package:journal_trend_analysis_mb/services/research_analytics_service.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/viewmodels/trend_notifier.dart';
import 'package:journal_trend_analysis_mb/widgets/research_taxonomy_selector.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/analysis_state_views.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/citation_distribution_chart.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/key_insights_card.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/metric_card_grid.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/paper_widgets.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/publication_trend_chart.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/ranked_list.dart';
import 'package:journal_trend_analysis_mb/widgets/research_trend_analysis/topic_summary_header.dart';
import 'package:journal_trend_analysis_mb/screens/detail_page.dart';

class ResearchTrendAnalysisScreen extends StatefulWidget {
  final TrendNotifier notifier;

  const ResearchTrendAnalysisScreen({super.key, required this.notifier});

  @override
  State<ResearchTrendAnalysisScreen> createState() =>
      _ResearchTrendAnalysisScreenState();
}

class _ResearchTrendAnalysisScreenState
    extends State<ResearchTrendAnalysisScreen> {
  final ResearchAnalyticsService _analyticsService = ResearchAnalyticsService();

  Future<void> _refresh() async {
    await widget.notifier.fetchTrendData(
      SharedState.activeQueryNotifier.value,
      showLoading: false,
    );
  }

  void _openTaxonomySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResearchTaxonomySelector(),
    );
  }

  void _openPublication(Publication publication) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailPage(publication: publication),
      ),
    );
  }

  void _showRankedItemInSearch(
    RankingItemModel item,
    _LandscapeFilterType filterType,
  ) {
    final current = SharedState.publicationFilterNotifier.value;
    final nextFilter = switch (filterType) {
      _LandscapeFilterType.source => current.copyWith(
          selectedAuthors: const [],
          selectedJournals: [item.name],
          selectedTopics: const [],
          fetchAllResults: false,
        ),
      _LandscapeFilterType.author => current.copyWith(
          selectedAuthors: [item.name],
          selectedJournals: const [],
          selectedTopics: const [],
          fetchAllResults: false,
        ),
      _LandscapeFilterType.topic => current.copyWith(
          selectedAuthors: const [],
          selectedJournals: const [],
          selectedTopics: [item.name],
          fetchAllResults: false,
        ),
    };

    SharedState.setPublicationFilter(nextFilter);
    SharedState.activeTabNotifier.value = 1;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('xu_huong_va_phan_tich'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            tooltip: 'select_taxonomy'.tr(),
            onPressed: _openTaxonomySelector,
          ),
          ListenableBuilder(
            listenable: SharedState.languageNotifier,
            builder: (context, _) {
              final lang = SharedState.languageNotifier.value;
              return TextButton(
                onPressed: SharedState.toggleLanguage,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          ListenableBuilder(
            listenable: SharedState.themeModeNotifier,
            builder: (context, _) {
              final isDark =
                  SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                tooltip: isDark ? 'switch_to_light_mode'.tr() : 'switch_to_dark_mode'.tr(),
                onPressed: () {
                  SharedState.themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF80CBC4),
        backgroundColor: const Color(0xFF1E4646),
        onRefresh: _refresh,
        child: ListenableBuilder(
          listenable: widget.notifier,
          builder: (context, _) {
            if (widget.notifier.isLoading) {
              return const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(child: AnalysisLoadingView()),
                ],
              );
            }

            final error = widget.notifier.errorMessage;
            if (error != null) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(child: AnalysisErrorView(message: error)),
                ],
              );
            }

            final publications = widget.notifier.publications;
            if (publications.isEmpty) {
              return const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(child: AnalysisEmptyView()),
                ],
              );
            }

            final topic = _activeTopicLabel();
            final analytics = _analyticsService.analyze(
              topic: topic,
              publications: publications,
            );
            final summary = analytics.summary;
            final yearRange = _yearRange(analytics.trendByYear);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopicSummaryHeader(
                    topic: topic,
                    totalPublications: summary.totalPublications,
                    yearRange: yearRange,
                  ),
                  const SizedBox(height: 16),
                  _buildActiveFilterChips(),
                  const SizedBox(height: 16),
                  _sectionTitle('overview'.tr()),
                  MetricCardGrid(
                    metrics: [
                      MetricCardData(
                        label: 'total_publications'.tr(),
                        value: summary.totalPublications.toString(),
                        icon: Icons.article_rounded,
                      ),
                      MetricCardData(
                        label: 'average_citations'.tr(),
                        value: summary.averageCitations.toStringAsFixed(1),
                        icon: Icons.format_quote_rounded,
                      ),
                      MetricCardData(
                        label: 'total_citations'.tr(),
                        value:
                            Formatters.formatCitationCount(summary.totalCitations),
                        icon: Icons.functions_rounded,
                      ),
                      MetricCardData(
                        label: 'most_active_year'.tr(),
                        value: summary.mostActiveYear?.toString() ?? 'n_a'.tr(),
                        icon: Icons.calendar_month_rounded,
                      ),
                      MetricCardData(
                        label: 'top_journal'.tr(),
                        value: summary.topJournal ?? 'n_a'.tr(),
                        icon: Icons.menu_book_rounded,
                      ),
                      MetricCardData(
                        label: 'top_author'.tr(),
                        value: summary.topAuthor ?? 'n_a'.tr(),
                        icon: Icons.person_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('publication_trend'.tr()),
                  PublicationTrendChart(trendByYear: analytics.trendByYear),
                  const SizedBox(height: 12),
                  _buildTrendSummary(summary.trendStatus, summary.growthRate),
                  const SizedBox(height: 22),
                  _sectionTitle('key_insights'.tr()),
                  KeyInsightsCard(insights: analytics.keyInsights),
                  const SizedBox(height: 22),
                  _sectionTitle('research_impact'.tr()),
                  MostInfluentialPaperCard(
                    publication: summary.mostInfluentialPaper,
                    onTap: _openPublication,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('top_influential_papers'.tr()),
                  TopInfluentialPapersList(
                    publications: analytics.topInfluentialPapers,
                    onTap: _openPublication,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('citation_distribution'.tr()),
                  CitationDistributionChart(
                    buckets: analytics.citationDistribution,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('research_landscape'.tr()),
                  _subSectionTitle('top_journals_sources'.tr()),
                  RankedList(
                    items: analytics.topJournals,
                    onItemTap: (item) => _showRankedItemInSearch(
                      item,
                      _LandscapeFilterType.source,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _subSectionTitle('top_authors'.tr()),
                  RankedList(
                    items: analytics.topAuthors,
                    onItemTap: (item) => _showRankedItemInSearch(
                      item,
                      _LandscapeFilterType.author,
                    ),
                  ),
                  if (analytics.topFields.isNotEmpty ||
                      analytics.topSubfields.isNotEmpty ||
                      analytics.topTopics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subSectionTitle('top_fields_topics'.tr()),
                    if (analytics.topFields.isNotEmpty)
                      RankedList(items: analytics.topFields),
                    if (analytics.topSubfields.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RankedList(items: analytics.topSubfields),
                    ],
                    if (analytics.topTopics.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RankedList(
                        items: analytics.topTopics,
                        onItemTap: (item) => _showRankedItemInSearch(
                          item,
                          _LandscapeFilterType.topic,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final scope = SharedState.activeResearchScopeNotifier.value;
    final chips = <String>[];
    if (scope.taxonomy.hasSelection) {
      chips.add(scope.taxonomy.breadcrumb);
    }
    if (scope.yearFrom != null || scope.yearTo != null) {
      chips.add('${scope.yearFrom ?? ''}-${scope.yearTo ?? ''}');
    }
    if (scope.isOpenAccess == true) {
      chips.add('open_access'.tr());
    }
    if (scope.minCitationCount != null) {
      chips.add('${'min_citations_label'.tr()}: ${scope.minCitationCount}');
    }
    if (scope.publicationType != null) {
      chips.add(scope.publicationType!.tr());
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in chips)
          Chip(
            label: Text(
              chip,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: Colors.white.withOpacity(0.1),
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
      ],
    );
  }

  Widget _buildTrendSummary(String status, double? growthRate) {
    final growth = growthRate == null
        ? 'n_a'.tr()
        : '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';
    return Row(
      children: [
        Expanded(child: _summaryPill('growth_rate'.tr(), growth)),
        const SizedBox(width: 10),
        Expanded(child: _summaryPill('trend_status'.tr(), _translateTrendStatus(status))),
      ],
    );
  }

  String _translateTrendStatus(String status) {
    switch (status) {
      case 'Increasing':
        return 'increasing_status'.tr();
      case 'Stable':
        return 'stable_status'.tr();
      case 'Declining':
        return 'declining_status'.tr();
      default:
        return 'not_enough_data_status'.tr();
    }
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _subSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _activeTopicLabel() {
    final scope = SharedState.activeResearchScopeNotifier.value;
    if (scope.displayLabel.isNotEmpty) {
      return scope.displayLabel;
    }
    final query = SharedState.activeQueryNotifier.value.trim();
    return query.isEmpty ? 'Artificial Intelligence' : query;
  }

  String? _yearRange(Map<int, int> trendByYear) {
    if (trendByYear.isEmpty) {
      return null;
    }
    final years = trendByYear.keys.toList()..sort();
    if (years.first == years.last) {
      return '${years.first}';
    }
    return '${years.first}-${years.last}';
  }
}

enum _LandscapeFilterType { source, author, topic }
