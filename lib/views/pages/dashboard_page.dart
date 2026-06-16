import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../widgets/analytic_box.dart';
import '../widgets/publication_card.dart';
import '../widgets/works_list_bottom_sheet.dart';
import '../state_management/dashboard_notifier.dart';
import '../state_management/shared_state.dart';
import 'detail_page.dart';

/// Màn hình Phân tích tổng quan (Research Dashboard Page).
/// Tổng hợp và trực quan hóa các chỉ số thống kê vĩ mô của chủ đề nghiên cứu:
/// Tổng sản lượng, Chỉ số trích dẫn trung bình, Năm bùng nổ, Tác giả/Tạp chí hàng đầu.
class DashboardPage extends StatelessWidget {
  final DashboardNotifier notifier;

  const DashboardPage({super.key, required this.notifier});

  Future<void> _refreshDashboard() async {
    await notifier.fetchDashboardData(
      SharedState.activeQueryNotifier.value,
      showLoading: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân Tích Tổng Quan'),
        actions: [
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
      body: RefreshIndicator(
        color: const Color(0xFF80CBC4),
        backgroundColor: const Color(0xFF1E4646),
        onRefresh: _refreshDashboard,
        child: ListenableBuilder(
          listenable: notifier,
          builder: (context, _) {
          if (notifier.isLoading) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 420,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }

          if (notifier.errorMessage != null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 420,
                  child: _buildErrorState(theme, notifier.errorMessage!),
                ),
              ],
            );
          }

          if (!notifier.hasData) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 420,
                  child: _buildEmptyState(theme),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Tiêu đề chủ đề đang hoạt động ---
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    children: [
                      const TextSpan(text: 'bạn đang thực hiện phân tích theo từ khóa: '),
                      TextSpan(
                        text: SharedState.activeQueryNotifier.value.isEmpty
                            ? 'Artificial Intelligence'
                            : SharedState.activeQueryNotifier.value,
                        style: const TextStyle(
                          color: Color(0xFF80CBC4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- 1. Lưới hiển thị 4 chỉ số thống kê vĩ mô ---
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    AnalyticBox(
                      label: 'Tổng số công bố',
                      value: notifier.totalPublications.toString(),
                      icon: Icons.article_rounded,
                      trendText: 'Quy mô',
                    ),
                    AnalyticBox(
                      label: 'Trích dẫn TB',
                      value: notifier.averageCitations.toStringAsFixed(1),
                      icon: Icons.format_quote_rounded,
                      trendText: 'Ảnh hưởng',
                    ),
                    AnalyticBox(
                      label: 'Năm tích cực nhất',
                      value: notifier.mostActiveYear == 0 ? 'N/A' : notifier.mostActiveYear.toString(),
                      icon: Icons.calendar_month_rounded,
                      trendText: 'Bùng nổ',
                    ),
                    AnalyticBox(
                      label: 'Bài báo ảnh hưởng',
                      value: notifier.mostInfluentialPaper != null
                          ? Formatters.formatCitationCount(notifier.mostInfluentialPaper!.citationCount)
                          : '0',
                      icon: Icons.star_rounded,
                      trendText: 'Max Cites',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 2. Khối hiển thị Outlier: Tạp chí nổi bật ---
                Text(
                  'Tạp chí xuất bản nhiều nhất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOutlierCard(
                  theme: theme,
                  title: notifier.topJournalName,
                  subtitle: 'Đóng góp ${notifier.topJournalCount} bài báo khoa học',
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF80CBC4),
                  onTap: () {
                    if (notifier.topJournalName == 'Không có dữ liệu' ||
                        notifier.topJournalName == 'N/A' ||
                        notifier.topJournalName.isEmpty) {
                      return;
                    }
                    final journalPubs = notifier.publications
                        .where((pub) => pub.journalName == notifier.topJournalName)
                        .toList();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => WorksListBottomSheet(
                        title: 'Bài viết từ tạp chí:\n${notifier.topJournalName}',
                        publications: journalPubs,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- 3. Khối hiển thị Outlier: Tác giả tiêu biểu ---
                Text(
                  'Tác giả đóng góp nhiều nhất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOutlierCard(
                  theme: theme,
                  title: notifier.topAuthorName,
                  subtitle: 'Số lượng tác phẩm: ${notifier.topAuthorCount} bài viết',
                  icon: Icons.person_pin_rounded,
                  iconColor: const Color(0xFF80CBC4),
                  onTap: () {
                    if (notifier.topAuthorName == 'Không có dữ liệu' ||
                        notifier.topAuthorName == 'N/A' ||
                        notifier.topAuthorName.isEmpty) {
                      return;
                    }
                    final authorPubs = notifier.publications
                        .where((pub) => pub.authors.contains(notifier.topAuthorName))
                        .toList();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => WorksListBottomSheet(
                        title: 'Bài viết của tác giả:\n${notifier.topAuthorName}',
                        publications: authorPubs,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                if (notifier.mostInfluentialPaper != null) ...[
                  Text(
                    'Bài báo có sức ảnh hưởng nhất',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PublicationCard(
                    id: notifier.mostInfluentialPaper!.id,
                    title: notifier.mostInfluentialPaper!.title,
                    year: notifier.mostInfluentialPaper!.publicationYear.toString(),
                    citationCount: notifier.mostInfluentialPaper!.citationCount,
                    journalName: notifier.mostInfluentialPaper!.journalName,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(publication: notifier.mostInfluentialPaper!),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildOutlierCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white30,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: GlassCard(
          color: AppColors.error.withOpacity(0.15),
          borderColor: AppColors.error.withOpacity(0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Lỗi dữ liệu Dashboard',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Nhập từ khóa để thực hiện phân tích tổng quan.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
