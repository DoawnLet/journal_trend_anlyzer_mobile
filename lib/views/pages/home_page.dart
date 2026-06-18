import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/translation.dart';
import '../widgets/glass_card.dart';
import '../widgets/research_taxonomy_selector.dart';
import '../state_management/home_notifier.dart';
import '../state_management/search_notifier.dart';
import '../state_management/shared_state.dart';

/// Màn hình khám phá chính (HomePage).
/// Đóng vai trò là bản đồ tri thức học thuật giúp định hướng truy cập nhanh đến các thực thể OpenAlex.
class HomePage extends StatefulWidget {
  final HomeNotifier notifier;
  final SearchNotifier searchNotifier;

  const HomePage({
    super.key,
    required this.notifier,
    required this.searchNotifier,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _headerSearchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _headerSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _headerSearchController.dispose();
    super.dispose();
  }

  /// Thực thi tìm kiếm nhanh từ thanh tiêu đề trang chủ
  void _executeHeaderSearch() {
    final query = _headerSearchController.text.trim();
    if (query.isNotEmpty) {
      // 1. Cập nhật từ khóa tìm kiếm toàn cục
      SharedState.setKeyword(query);
      // 2. Chuyển hướng tab sang SearchPage (Index 1)
      SharedState.activeTabNotifier.value = 1;
      
      // Reset trạng thái ô tìm kiếm trên trang chủ
      setState(() {
        _isSearching = false;
        _headerSearchController.clear();
      });
    }
  }

  void _showTaxonomySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ResearchTaxonomySelector(),
    );
  }

  void _startResearch(String topic) {
    SharedState.setKeyword(topic);
    SharedState.activeTabNotifier.value = 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _headerSearchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _executeHeaderSearch(),
                decoration: InputDecoration(
                  hintText: 'quick_search_hint'.tr(),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Text('research_home'.tr()),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _headerSearchController.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              tooltip: 'quick_search'.tr(),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                _headerSearchController.clear();
              },
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
              final isDark = SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
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
      body: ValueListenableBuilder<HomeState>(
        valueListenable: widget.notifier.stateNotifier,
        builder: (context, state, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResearchHero(theme),
                const SizedBox(height: 18),
                _buildSectionHeader(theme, 'explore'.tr(), Icons.rocket_launch_rounded),
                _buildResearchStartCards(theme),
                const SizedBox(height: 18),
                _buildSectionHeader(theme, 'quick_research_topics'.tr(), Icons.bolt_rounded),
                _buildQuickTopics(theme),
                const SizedBox(height: 18),
                const SizedBox(height: 18),
                
                const SizedBox(height: 18),
                // Khối chào mừng (Welcome Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'academic_knowledge_map'.tr(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'explore_ecosystem'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Phân mục 1: Khám phá theo lĩnh vực (Domain & Fields)
                _buildSectionHeader(theme, 'research_fields'.tr(), Icons.account_tree_rounded),
                _buildDomainSelector(context, state),
                _buildFieldsSlider(context, state),

                const SizedBox(height: 20),

                // Phân mục 2: Tác động theo mục tiêu phát triển bền vững (SDGs)
                _buildSectionHeader(theme, 'sustainable_development_goals'.tr(), Icons.public_rounded),
                _buildLiveSDGsSlider(context, state),

                const SizedBox(height: 20),

                // Phân mục 3: Bản đồ địa lý học thuật (Geography Leaderboard)
                _buildSectionHeader(theme, 'outstanding_geography'.tr(), Icons.map_rounded),
                _buildGeographyLeaderboard(theme, state),

                const SizedBox(height: 20),

                // Phân mục 4: Các Nhà Xuất Bản & Viện Nghiên Cứu Lớn (Publishers & Institutions)
                
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dựng tiêu đề chung cho các phân mục
  Widget _buildResearchHero(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        borderRadius: 14,
        color: Colors.white.withOpacity(0.08),
        borderColor: Colors.white.withOpacity(0.14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF80CBC4).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF80CBC4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'research_trend_analysis'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'home_hero_desc'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => SharedState.activeTabNotifier.value = 2,
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text('open_research'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      foregroundColor: AppColors.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _showTaxonomySelector,
                  icon: const Icon(Icons.account_tree_rounded),
                  tooltip: 'select_taxonomy'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchStartCards(ThemeData theme) {
    final items = [
      (
        icon: Icons.search_rounded,
        title: 'find_publication'.tr(),
        subtitle: 'search_works_desc'.tr(),
        action: () => SharedState.activeTabNotifier.value = 1,
      ),
      (
        icon: Icons.account_tree_rounded,
        title: 'select_taxonomy'.tr(),
        subtitle: 'select_taxonomy_desc'.tr(),
        action: _showTaxonomySelector,
      ),
      (
        icon: Icons.bar_chart_rounded,
        title: 'analyze_trend'.tr(),
        subtitle: 'trend_desc'.tr(),
        action: () => SharedState.activeTabNotifier.value = 2,
      ),
    ];


    return SizedBox(
      height: 165,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 210,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: item.action,
              child: GlassCard(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                color: Colors.white.withOpacity(0.06),
                borderColor: Colors.white.withOpacity(0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: const Color(0xFF80CBC4), size: 24),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickTopics(ThemeData theme) {
    const topics = [
      'Artificial Intelligence',
      'Machine Learning',
      'Climate Change',
      'Cancer Research',
      'Renewable Energy',
      'Public Health',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topics.map((topic) {
          return ActionChip(
            avatar: const Icon(Icons.auto_graph_rounded, size: 16),
            label: Text(topic),
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            backgroundColor: Colors.white.withOpacity(0.08),
            side: BorderSide(color: Colors.white.withOpacity(0.14)),
            onPressed: () => _startResearch(topic),
          );
        }).toList(),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTaxonomyOverview(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(14),
        color: Colors.white.withOpacity(0.06),
        borderColor: Colors.white.withOpacity(0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4 Domains -> 26 Fields -> 254 Subfields -> ~4.500 Topics',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dùng cây phân loại OpenAlex để thu hẹp research scope trước khi phân tích publication trend.',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showTaxonomySelector,
              icon: const Icon(Icons.account_tree_rounded),
              label: const Text('Chọn taxonomy OpenAlex'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF80CBC4),
                side: BorderSide(color: Colors.white.withOpacity(0.22)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAuthorsPreview(ThemeData theme, HomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 12,
        padding: const EdgeInsets.all(10),
        color: Colors.white.withOpacity(0.04),
        borderColor: Colors.white.withOpacity(0.12),
        child: SizedBox(
          height: 250,
          child: _buildAuthorsTab(theme, state),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF80CBC4), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Bộ chọn Domain bằng SegmentedButton
  Widget _buildDomainSelector(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF80CBC4),
                  selectedForegroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                segments: state.domains.map((domain) {
                  return ButtonSegment<String>(
                    value: domain,
                    label: Text(
                      domain.tr(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                selected: {state.selectedDomain},
                onSelectionChanged: (newSelection) {
                  widget.notifier.changeDomain(newSelection.first);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Trình chiếu danh sách Fields tương ứng dưới dạng các thẻ Glassmorphic nằm ngang
  Widget _buildFieldsSlider(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.activeFields.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final field = state.activeFields[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Đặt từ khóa lọc và chuyển hướng sang tab Dashboard (Index 3)
                  SharedState.setKeyword(field.name);
                  SharedState.activeTabNotifier.value = 2;
                },
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  color: Colors.white.withOpacity(0.06),
                  borderColor: Colors.white.withOpacity(0.12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(field.icon, color: const Color(0xFF80CBC4), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              field.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        field.description.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Trình chiếu ngang danh sách các SDG của Liên Hợp Quốc
  // ignore: unused_element
  Widget _buildSDGsSlider(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.sdgs.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final sdg = state.sdgs[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Đặt từ khóa là SDG + số mục tiêu, chuyển hướng sang Search (Index 1)
                  SharedState.setKeyword('Sustainable Development Goal ${sdg.number}');
                  SharedState.activeTabNotifier.value = 1;
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 16,
                  color: sdg.color.withOpacity(0.2),
                  borderColor: sdg.color.withOpacity(0.4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sdg.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sdg.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Goal ${sdg.number}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sdg.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 9.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Xây dựng phân mục leaderboards quốc gia & châu lục đóng góp nhiều công bố học thuật
  Widget _buildGeographyLeaderboard(ThemeData theme, HomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.white.withOpacity(0.04),
        borderColor: Colors.white.withOpacity(0.12),
        child: Column(
          children: state.geographyLeaderboard.map((geo) {
            final isLast = state.geographyLeaderboard.last == geo;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: geo.type == 'Châu lục'
                          ? const Color(0xFF80CBC4).withOpacity(0.15)
                          : Colors.amberAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      geo.type == 'Châu lục' ? Icons.language_rounded : Icons.flag_rounded,
                      color: geo.type == 'Châu lục' ? const Color(0xFF80CBC4) : Colors.amberAccent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          geo.name.tr(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          geo.type.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        geo.publicationCount,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          geo.growth,
                          style: const TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Dựng Tabs kiến trúc hiển thị các Tác giả & Viện trường tiêu biểu
  // ignore: unused_element
  Widget _buildHubsTabs(ThemeData theme, HomeState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 420,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: const Color(0xFF80CBC4),
              labelColor: const Color(0xFF80CBC4),
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.white.withOpacity(0.06),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'authors'.tr(), icon: const Icon(Icons.person_rounded, size: 18)),
                Tab(text: 'institutions'.tr(), icon: const Icon(Icons.school_rounded, size: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAuthorsTab(theme, state),
                  _buildInstitutionsTab(theme, state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab Danh sách các tác giả hàng đầu
  Widget _buildAuthorsTab(ThemeData theme, HomeState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }
    
    if (state.authors.isEmpty) {
      return Center(
        child: Text(
          'no_author_data'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: state.authors.length > 5 ? 5 : state.authors.length,
      itemBuilder: (context, index) {
        final author = state.authors[index];
        return Card(
          color: Colors.white.withOpacity(0.03),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            onTap: () {
              widget.searchNotifier.setAuthorFilter(author.id, author.name);
              SharedState.activeTabNotifier.value = 1;
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              radius: 14,
              child: Icon(Icons.person_rounded, color: Colors.white70, size: 14),
            ),
            title: Text(
              author.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              author.institution,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  author.worksCount,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'article_count'.tr(),
                  style: const TextStyle(color: Colors.white30, fontSize: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tab Danh sách các Viện / Trường đại học hàng đầu
  Widget _buildInstitutionsTab(ThemeData theme, HomeState state) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: state.institutions.length,
      itemBuilder: (context, index) {
        final inst = state.institutions[index];
        return Card(
          color: Colors.white.withOpacity(0.03),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              radius: 14,
              child: Icon(Icons.account_balance_rounded, color: Colors.white70, size: 14),
            ),
            title: Text(
              inst.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${inst.type.tr()} • ${inst.country.tr()}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  inst.worksCount,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'article_count'.tr(),
                  style: const TextStyle(color: Colors.white30, fontSize: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveSDGsSlider(BuildContext context, HomeState state) {
    final theme = Theme.of(context);

    if (state.isLoadingSdgs) {
      return const SizedBox(
        height: 90,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (state.sdgs.isEmpty) {
      return SizedBox(
        height: 90,
        child: Center(
          child: Text(
            'error_loading_sdg'.tr(),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.sdgs.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final sdg = state.sdgs[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (sdg.taxonomySelection != null) {
                    SharedState.setResearchTaxonomy(sdg.taxonomySelection!);
                  } else {
                    SharedState.setKeyword(
                      sdg.searchQuery.isEmpty ? sdg.title : sdg.searchQuery,
                    );
                  }
                  SharedState.activeTabNotifier.value = 1;
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 16,
                  color: sdg.color.withOpacity(0.2),
                  borderColor: sdg.color.withOpacity(0.4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: sdg.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(sdg.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Goal ${sdg.number}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (sdg.worksCount > 0)
                                  Text(
                                    Formatters.formatCitationCount(sdg.worksCount),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sdg.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 9.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
