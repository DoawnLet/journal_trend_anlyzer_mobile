import 'package:flutter/material.dart';

class KeyInsightsCard extends StatelessWidget {
  final List<String> insights;

  const KeyInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final items = insights.isEmpty
        ? const ['Chưa đủ dữ liệu để tạo insight.']
        : insights;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final insight in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Color(0xFF80CBC4), fontSize: 15),
                  ),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
