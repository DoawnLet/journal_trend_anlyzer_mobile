import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../widgets/glass_card.dart';
import '../state_management/trend_notifier.dart';
import '../state_management/shared_state.dart';
import 'detail_page.dart';

/// Màn hình Biểu đồ xu hướng (Trend Analysis Page).
/// Trực quan hóa số lượng ấn phẩm qua các năm và hiển thị xếp hạng
/// các bài báo nổi tiếng nhất, tạp chí xuất sắc nhất, và tác giả tiêu biểu.
class TrendPage extends StatelessWidget {
  final TrendNotifier notifier;

  const TrendPage({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xu Hướng & Phân Tích'),
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
      body: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) {
          if (notifier.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          if (notifier.errorMessage != null) {
            return _buildErrorState(theme, notifier.errorMessage!);
          }

          if (notifier.publications.isEmpty) {
            return _buildEmptyState(theme);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Tiêu đề chủ đề đang phân tích ---
                Text(
                  'Chủ đề: "${SharedState.activeQueryNotifier.value}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // --- Mục 1: Biểu đồ đường phân bố số lượng bài viết ---
                Text(
                  'Biểu đồ sản lượng theo năm',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTrendChart(theme),
                const SizedBox(height: 24),

                // --- Mục 2: Top bài báo có trích dẫn nhiều nhất ---
                Text(
                  'Bài viết có lượt trích dẫn cao nhất',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTopPapersList(context, theme),
                const SizedBox(height: 24),

                // --- Mục 3: Top Tạp chí & Tác giả ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Tạp chí',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTopJournalsList(theme),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Tác giả',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTopAuthorsList(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendChart(ThemeData theme) {
    final dist = notifier.yearlyDistribution;
    if (dist.length < 2) {
      return const GlassCard(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Không đủ điểm dữ liệu lịch sử để vẽ biểu đồ.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final spots = dist.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    final years = dist.keys.toList();
    final counts = dist.values.toList();
    final double minX = years.first.toDouble();
    final double maxX = years.last.toDouble();
    final double maxY = (counts.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).ceilToDouble();

    return GlassCard(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value % 2 != 0 && value != maxY) return const SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: dist.length > 8 ? 2 : 1,
                  getTitlesWidget: (value, meta) {
                    final year = value.toInt();
                    if (!dist.containsKey(year)) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        year.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: minX,
            maxX: maxX,
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.white,
                barWidth: 3.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.background,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPapersList(BuildContext context, ThemeData theme) {
    final list = notifier.topPublications;
    return Column(
      children: list.map((pub) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailPage(publication: pub)),
              );
            },
            child: GlassCard(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pub.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatAuthors(pub.authors),
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCitationCount(pub.citationCount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'trích dẫn',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopJournalsList(ThemeData theme) {
    final list = notifier.topJournals;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        return GlassCard(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.value} bài',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopAuthorsList(ThemeData theme) {
    final list = notifier.topAuthors;
    if (list.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(12),
        child: Center(child: Text('N/A', style: TextStyle(color: Colors.white60))),
      );
    }

    return Column(
      children: list.map((entry) {
        return GlassCard(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.value} bài',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
                'Lỗi tải biểu đồ',
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
            Icons.insights_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Nhập từ khóa tìm kiếm để bắt đầu vẽ phân tích.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
