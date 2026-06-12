import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../models/publication_model.dart';
import '../state_management/shared_state.dart';

/// Màn hình chi tiết bài báo.
class DetailPage extends StatelessWidget {
  final Publication publication;

  const DetailPage({super.key, required this.publication});

  Future<void> _openDoiLink(BuildContext context, String doiUrl) async {
    final cleanDoi = doiUrl.trim();
    if (cleanDoi.isEmpty) {
      _showDoiError(context, 'Liên kết DOI không hợp lệ.');
      return;
    }

    final uri = _normalizeDoiUri(cleanDoi);
    if (uri == null) {
      _showDoiError(context, 'Liên kết DOI không hợp lệ.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) {
        return;
      }

      if (!launched) {
        _showDoiError(context, 'Không tìm thấy ứng dụng có thể mở liên kết.');
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      _showDoiError(context, 'Không thể mở liên kết DOI: $e');
    }
  }

  Uri? _normalizeDoiUri(String doiUrl) {
    final parsedUri = Uri.tryParse(doiUrl);
    if (parsedUri != null && parsedUri.hasScheme) {
      return parsedUri;
    }

    final doiPath = doiUrl
        .replaceFirst(RegExp(r'^doi:\s*', caseSensitive: false), '')
        .replaceFirst(
          RegExp(r'^https?://(dx\.)?doi\.org/', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^(dx\.)?doi\.org/', caseSensitive: false), '');

    return Uri.https('doi.org', doiPath);
  }

  void _showDoiError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Bài Báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              publication.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.people_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tác giả:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (publication.authors.isEmpty)
                          Text(
                            'Không rõ tác giả',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 6.0,
                            children: publication.authors.map((author) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  author,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text('Năm: ${publication.publicationYear}'),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text('${publication.citationCount} trích dẫn'),
                ),
                if (publication.journalName.isNotEmpty)
                  Chip(
                    avatar: const Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(publication.journalName),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (publication.doi != null && publication.doi!.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: () => _openDoiLink(context, publication.doi!),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Mở liên kết DOI'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (publication.concepts.isNotEmpty) ...[
              Text(
                'Khái niệm (Concepts)',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: publication.concepts.map((concept) {
                  return ActionChip(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    label: Text(
                      concept,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      SharedState.activeQueryNotifier.value = concept;
                      SharedState.activeTabNotifier.value = 2;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            if (publication.topics.isNotEmpty) ...[
              Text(
                'Chủ đề (Topics)',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 6.0,
                children: publication.topics.map((topic) {
                  return ActionChip(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    label: Text(
                      topic,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      SharedState.activeQueryNotifier.value = topic;
                      SharedState.activeTabNotifier.value = 2;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Tóm tắt (Abstract)',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                publication.abstractText.isNotEmpty
                    ? publication.abstractText
                    : 'Bài báo này không cung cấp bản tóm tắt.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
