import 'package:flutter/material.dart';
import 'package:journal_trend_analysis_mb/theme/app_colors.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';

/// Hộp hiển thị số liệu phân tích thống kê trên Dashboard (AnalyticStatBox).
/// Thiết kế tối giản, trực quan hóa các chỉ số quan trọng như:
/// Tổng số bài báo, Số trích dẫn trung bình, Năm xuất bản tích cực nhất.
class AnalyticBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? trendText;
  final bool isPositiveTrend;

  const AnalyticBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trendText,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dòng chứa Icon đại diện và Trend (nếu có)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (trendText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositiveTrend 
                        ? const Color(0xFF80CBC4).withOpacity(0.2) 
                        : AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trendText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isPositiveTrend ? const Color(0xFF80CBC4) : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Số liệu thống kê chính (Cỡ to đại diện)
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Nhãn chú thích bên dưới
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
