import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
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
      SharedState.activeQueryNotifier.value = query;
      // 2. Chuyển hướng tab sang SearchPage (Index 1)
      SharedState.activeTabNotifier.value = 1;
      
      // Reset trạng thái ô tìm kiếm trên trang chủ
      setState(() {
        _isSearching = false;
        _headerSearchController.clear();
      });
    }
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
                  hintText: 'Tìm kiếm nhanh bài viết...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : const Text('Journal Trend Analyzer'),
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
              tooltip: 'Tìm kiếm nhanh',
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
            listenable: SharedState.themeModeNotifier,
            builder: (context, _) {
              final isDark = SharedState.themeModeNotifier.value == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                tooltip: isDark ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối',
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
                // Khối chào mừng (Welcome Header)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bản Đồ Tri Thức Học Thuật',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Khám phá hệ sinh thái thông tin khoa học OpenAlex dữ liệu thực',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Phân mục 1: Khám phá theo lĩnh vực (Domain & Fields)
                _buildSectionHeader(theme, 'Lĩnh Vực Nghiên Cứu', Icons.account_tree_rounded),
                _buildDomainSelector(context, state),
                _buildFieldsSlider(context, state),

                const SizedBox(height: 20),

                // Phân mục 2: Tác động theo mục tiêu phát triển bền vững (SDGs)
                _buildSectionHeader(theme, 'Mục Tiêu Phát Triển Bền Vững (SDGs)', Icons.public_rounded),
                _buildSDGsSlider(context, state),

                const SizedBox(height: 20),

                // Phân mục 3: Bản đồ địa lý học thuật (Geography Leaderboard)
                _buildSectionHeader(theme, 'Đơn Vị Địa Lý Học Thuật Nổi Bật', Icons.map_rounded),
                _buildGeographyLeaderboard(theme, state),

                const SizedBox(height: 20),

                // Phân mục 4: Các Nhà Xuất Bản & Viện Nghiên Cứu Lớn (Publishers & Institutions)
                _buildSectionHeader(theme, 'Các Trung Tâm Tri Thức Lớn', Icons.domain_rounded),
                _buildHubsTabs(theme, state),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dựng tiêu đề chung cho các phân mục
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
                      domain.replaceAll('Khoa học ', ''),
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
                  SharedState.activeQueryNotifier.value = field.name;
                  SharedState.activeTabNotifier.value = 3;
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
                        field.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  /// Trình chiếu ngang danh sách các SDG của Liên Hợp Quốc
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
                  SharedState.activeQueryNotifier.value = 'Sustainable Development Goal ${sdg.number}';
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
                          geo.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          geo.type,
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
              tabs: const [
                Tab(text: 'Tác giả', icon: Icon(Icons.person_rounded, size: 18)),
                Tab(text: 'Viện & Trường', icon: Icon(Icons.school_rounded, size: 18)),
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
      return const Center(
        child: Text(
          'Không có dữ liệu tác giả.',
          style: TextStyle(color: Colors.white70),
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
                const Text(
                  'ấn phẩm',
                  style: TextStyle(color: Colors.white30, fontSize: 8),
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
              '${inst.type} • ${inst.country}',
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
                const Text(
                  'ấn phẩm',
                  style: TextStyle(color: Colors.white30, fontSize: 8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
