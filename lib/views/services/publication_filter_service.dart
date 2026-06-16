import '../models/publication_filter_model.dart';
import '../models/publication_model.dart';

class PublicationFilterService {
  static List<Publication> applyLocalFilters(
    List<Publication> publications,
    PublicationFilter filter,
  ) {
    return publications.where((paper) {
      final matchAuthor = filter.selectedAuthors.isEmpty ||
          paper.authors.any(filter.selectedAuthors.contains);

      final journal = paper.journalName.trim();
      final matchJournal = filter.selectedJournals.isEmpty ||
          filter.selectedJournals.contains(journal);

      final taxonomy = filter.taxonomy;
      final matchDomain =
          taxonomy.domain == null || paper.domain == taxonomy.domain!.name;
      final matchField =
          taxonomy.field == null || paper.field == taxonomy.field!.name;
      final matchSubfield =
          taxonomy.subfield == null || paper.subfield == taxonomy.subfield!.name;
      final matchTopic = taxonomy.topic == null ||
          paper.primaryTopic == taxonomy.topic!.name ||
          paper.topics.contains(taxonomy.topic!.name);

      return matchAuthor &&
          matchJournal &&
          matchDomain &&
          matchField &&
          matchSubfield &&
          matchTopic;
    }).toList();
  }
}
