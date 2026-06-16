import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/citation_bucket_model.dart';

class CitationDistributionChart extends StatelessWidget {
  final List<CitationBucketModel> buckets;

  const CitationDistributionChart({super.key, required this.buckets});

  @override
  Widget build(BuildContext context) {
    final maxY = buckets
        .map((bucket) => bucket.count)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();

    if (buckets.isEmpty || maxY == 0) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Không có dữ liệu citation distribution.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
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
                  if (index < 0 || index >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      buckets[index].label,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < buckets.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: buckets[index].count.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFFFB74D),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
