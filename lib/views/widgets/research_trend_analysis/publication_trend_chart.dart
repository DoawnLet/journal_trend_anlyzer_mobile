import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/translation.dart';

class PublicationTrendChart extends StatelessWidget {
  final Map<int, int> trendByYear;

  const PublicationTrendChart({super.key, required this.trendByYear});

  @override
  Widget build(BuildContext context) {
    if (trendByYear.isEmpty) {
      return _EmptyChart(message: 'no_publication_trend_data'.tr());
    }

    final entries = trendByYear.entries.toList();
    final maxY = entries
        .map((entry) => entry.value)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF0F364A).withOpacity(0.9),
              tooltipBorder: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0),
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${entries[groupIndex].key}\n',
                  GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toInt()} ${'articles'.tr()}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF80CBC4),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }

                  // Tự động tính toán khoảng cách nhãn dựa trên số lượng năm để tránh dính chữ
                  int labelInterval = 1;
                  if (entries.length > 20) {
                    labelInterval = 5;
                  } else if (entries.length > 14) {
                    labelInterval = 4;
                  } else if (entries.length > 8) {
                    labelInterval = 3;
                  } else if (entries.length > 5) {
                    labelInterval = 2;
                  }

                  final isLast = index == entries.length - 1;
                  final isSpaced = index % labelInterval == 0;
                  final isTooCloseToLast = (entries.length - 1 - index) < (labelInterval * 0.75);

                  if (!isLast && (!isSpaced || isTooCloseToLast)) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[index].key.toString(),
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < entries.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: entries[index].value.toDouble(),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF00ACC1),
                        Color(0xFF80CBC4),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white60),
        textAlign: TextAlign.center,
      ),
    );
  }
}
