import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:journal_trend_analysis_mb/theme/app_colors.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';

/// Màn hình chi tiết bài báo.
class DetailPage extends StatelessWidget {
  final Publication publication;

  const DetailPage({super.key, required this.publication});

  Future<void> _openLink(BuildContext context, String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _showError(context, 'doi_link_invalid'.tr());
      return;
    }

    Uri? uri = Uri.tryParse(cleanUrl);
    if (uri == null || !uri.hasScheme) {
      uri = _normalizeDoiUri(cleanUrl);
    }

    if (uri == null) {
      _showError(context, 'doi_link_invalid'.tr());
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
        _showError(context, 'no_app_to_open_link'.tr());
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showError(context, '${'cannot_open_doi'.tr()}: $e');
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

  String _formatDoiDisplay(String doiUrl) {
    return doiUrl
        .trim()
        .replaceFirst(RegExp(r'^doi:\s*', caseSensitive: false), '')
        .replaceFirst(
          RegExp(r'^https?://(dx\.)?doi\.org/', caseSensitive: false),
          '',
        )
        .replaceFirst(RegExp(r'^(dx\.)?doi\.org/', caseSensitive: false), '');
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Thêm vào danh sách xem gần đây
    SharedState.addToRecentlyViewed(publication);

    return Scaffold(
      appBar: AppBar(
        title: Text('publication_detail'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          ValueListenableBuilder<List<Publication>>(
            valueListenable: SharedState.bookmarkedPublicationsNotifier,
            builder: (context, bookmarks, _) {
              final isBookmarked = bookmarks.any((p) => p.id == publication.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? const Color(0xFF80CBC4) : Colors.white,
                ),
                tooltip: 'Bookmark',
                onPressed: () {
                  SharedState.toggleBookmark(publication);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBookmarked
                            ? 'removed_from_bookmarks'.tr()
                            : 'added_to_bookmarks'.tr(),
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ],
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
                          'author_label'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (publication.authors.isEmpty)
                          Text(
                            'unknown_author'.tr(),
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
                  label: Text('${'year_label'.tr()}: ${publication.publicationYear}'),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text('${publication.citationCount} ${'citations'.tr()}'),
                ),
              ],
            ),
            if (publication.journalName.isNotEmpty) ...[
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'journal_prefix'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            publication.journalName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // --- DOI Section ---
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.fingerprint_rounded,
                            color: Color(0xFF80CBC4),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DOI',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (publication.doi != null && publication.doi!.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.copy_all_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'copy_doi'.tr(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: publication.doi!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('doi_copied'.tr()),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0, bottom: 8.0),
                    child: Text(
                      (publication.doi != null && publication.doi!.isNotEmpty)
                          ? _formatDoiDisplay(publication.doi!)
                          : 'not_available'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontStyle: (publication.doi == null || publication.doi!.isEmpty)
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- Access Links Section ---
            Text(
              'access_links'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                // Nút mở bài báo gốc
                if (publication.landingPageUrl != null || (publication.doi != null && publication.doi!.isNotEmpty))
                  ElevatedButton.icon(
                    onPressed: () {
                      final url = publication.landingPageUrl ?? publication.doi!;
                      _openLink(context, url);
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text('open_original_publication'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: Text('open_original_publication'.tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                // Nút mở bản PDF
                if (publication.pdfUrl != null && publication.pdfUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openLink(context, publication.pdfUrl!),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFFE57373)),
                    label: Text('view_pdf'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE57373), width: 1.5),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (publication.concepts.isNotEmpty) ...[
              Text(
                'concepts'.tr(),
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
                      SharedState.setKeyword(concept);
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
                'topics'.tr(),
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
                      SharedState.setKeyword(topic);
                      SharedState.activeTabNotifier.value = 2;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'abstract'.tr(),
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
                    : 'no_abstract_available'.tr(),
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
