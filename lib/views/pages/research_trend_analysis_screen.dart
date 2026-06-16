import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../models/publication_model.dart';
import '../services/research_analytics_service.dart';
import '../state_management/shared_state.dart';
import '../state_management/trend_notifier.dart';
import '../widgets/research_taxonomy_selector.dart';
import '../widgets/research_trend_analysis/analysis_state_views.dart';
import '../widgets/research_trend_analysis/citation_distribution_chart.dart';
import '../widgets/research_trend_analysis/key_insights_card.dart';
import '../widgets/research_trend_analysis/metric_card_grid.dart';
import '../widgets/research_trend_analysis/paper_widgets.dart';
import '../widgets/research_trend_analysis/publication_trend_chart.dart';
import '../widgets/research_trend_analysis/ranked_list.dart';
import '../widgets/research_trend_analysis/topic_summary_header.dart';
import 'detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Trend Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_rounded),
            tooltip: 'Chọn taxonomy OpenAlex',
            onPressed: _openTaxonomySelector,
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
                  _sectionTitle('Overview'),
                  MetricCardGrid(
                    metrics: [
                      MetricCardData(
                        label: 'Total Publications',
                        value: summary.totalPublications.toString(),
                        icon: Icons.article_rounded,
                      ),
                      MetricCardData(
                        label: 'Average Citations',
                        value: summary.averageCitations.toStringAsFixed(1),
                        icon: Icons.format_quote_rounded,
                      ),
                      MetricCardData(
                        label: 'Total Citations',
                        value:
                            Formatters.formatCitationCount(summary.totalCitations),
                        icon: Icons.functions_rounded,
                      ),
                      MetricCardData(
                        label: 'Most Active Year',
                        value: summary.mostActiveYear?.toString() ?? 'N/A',
                        icon: Icons.calendar_month_rounded,
                      ),
                      MetricCardData(
                        label: 'Top Journal',
                        value: summary.topJournal ?? 'N/A',
                        icon: Icons.menu_book_rounded,
                      ),
                      MetricCardData(
                        label: 'Top Author',
                        value: summary.topAuthor ?? 'N/A',
                        icon: Icons.person_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Publication Trend'),
                  PublicationTrendChart(trendByYear: analytics.trendByYear),
                  const SizedBox(height: 12),
                  _buildTrendSummary(summary.trendStatus, summary.growthRate),
                  const SizedBox(height: 22),
                  _sectionTitle('Key Insights'),
                  KeyInsightsCard(insights: analytics.keyInsights),
                  const SizedBox(height: 22),
                  _sectionTitle('Research Impact'),
                  MostInfluentialPaperCard(
                    publication: summary.mostInfluentialPaper,
                    onTap: _openPublication,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Top Influential Papers'),
                  TopInfluentialPapersList(
                    publications: analytics.topInfluentialPapers,
                    onTap: _openPublication,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Citation Distribution'),
                  CitationDistributionChart(
                    buckets: analytics.citationDistribution,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Research Landscape'),
                  _subSectionTitle('Top Journals / Sources'),
                  RankedList(items: analytics.topJournals),
                  const SizedBox(height: 16),
                  _subSectionTitle('Top Authors'),
                  RankedList(items: analytics.topAuthors),
                  if (analytics.topFields.isNotEmpty ||
                      analytics.topSubfields.isNotEmpty ||
                      analytics.topTopics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subSectionTitle('Top Fields / Topics'),
                    if (analytics.topFields.isNotEmpty)
                      RankedList(items: analytics.topFields),
                    if (analytics.topSubfields.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RankedList(items: analytics.topSubfields),
                    ],
                    if (analytics.topTopics.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      RankedList(items: analytics.topTopics),
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
      chips.add('Open Access');
    }
    if (scope.minCitationCount != null) {
      chips.add('Min citations: ${scope.minCitationCount}');
    }
    if (scope.publicationType != null) {
      chips.add(scope.publicationType!);
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
        ? 'N/A'
        : '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';
    return Row(
      children: [
        Expanded(child: _summaryPill('Growth Rate', growth)),
        const SizedBox(width: 10),
        Expanded(child: _summaryPill('Trend Status', status)),
      ],
    );
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
