import 'package:flutter/material.dart';

import '../../models/publication_model.dart';
import '../../../core/utils/formatters.dart';

class MostInfluentialPaperCard extends StatelessWidget {
  final Publication? publication;
  final ValueChanged<Publication>? onTap;

  const MostInfluentialPaperCard({
    super.key,
    required this.publication,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paper = publication;
    if (paper == null) {
      return const SizedBox.shrink();
    }

    return _PaperTile(
      rankLabel: 'Top',
      paper: paper,
      onTap: onTap == null ? null : () => onTap!(paper),
    );
  }
}

class TopInfluentialPapersList extends StatelessWidget {
  final List<Publication> publications;
  final ValueChanged<Publication>? onTap;

  const TopInfluentialPapersList({
    super.key,
    required this.publications,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return const Text(
        'Không có paper để xếp hạng.',
        style: TextStyle(color: Colors.white60),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < publications.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PaperTile(
              rankLabel: '${index + 1}',
              paper: publications[index],
              onTap: onTap == null ? null : () => onTap!(publications[index]),
            ),
          ),
      ],
    );
  }
}

class _PaperTile extends StatelessWidget {
  final String rankLabel;
  final Publication paper;
  final VoidCallback? onTap;

  const _PaperTile({
    required this.rankLabel,
    required this.paper,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rankLabel,
                  style: const TextStyle(
                    color: Color(0xFF80CBC4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${paper.publicationYear == 0 ? 'N/A' : paper.publicationYear} • ${paper.journalName.isEmpty ? 'Unknown source' : paper.journalName}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatCitationCount(paper.citationCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
