import 'package:flutter/material.dart';

import '../../../core/utils/translation.dart';
import '../../models/ranking_item_model.dart';

class RankedList extends StatelessWidget {
  final List<RankingItemModel> items;
  final String emptyMessage;
  final ValueChanged<RankingItemModel>? onItemTap;

  const RankedList({
    super.key,
    required this.items,
    this.emptyMessage = 'Khong co du lieu xep hang.',
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyMessage == 'Khong co du lieu xep hang.'
            ? 'no_ranking_data'.tr()
            : emptyMessage,
        style: const TextStyle(color: Colors.white60),
      );
    }

    final maxCount = items.first.count == 0 ? 1 : items.first.count;
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RankedRow(
              rank: index + 1,
              item: items[index],
              maxCount: maxCount,
              onTap: onItemTap == null ? null : () => onItemTap!(items[index]),
            ),
          ),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final RankingItemModel item;
  final int maxCount;
  final VoidCallback? onTap;

  const _RankedRow({
    required this.rank,
    required this.item,
    required this.maxCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widthFactor = (item.count / maxCount).clamp(0.08, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$rank.',
                    style: const TextStyle(
                      color: Color(0xFF80CBC4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.count}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: widthFactor,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF80CBC4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
