/// Lớp mô tả thông tin chi tiết một bài viết khoa học (Work) từ OpenAlex API.
class Publication {
  final String id;
  final String title;
  final int publicationYear;
  final int citationCount;
  final String? doi;
  final String journalName;
  final List<String> authors;
  final String abstractText;
  final List<String> concepts;
  final List<String> topics;
  final bool isOpenAccess;
  final String? publicationType;
  final String? primaryTopic;
  final String? subfield;
  final String? field;
  final String? domain;

  const Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citationCount,
    this.doi,
    required this.journalName,
    required this.authors,
    required this.abstractText,
    required this.concepts,
    required this.topics,
    this.isOpenAccess = false,
    this.publicationType,
    this.primaryTopic,
    this.subfield,
    this.field,
    this.domain,
  });

  /// Khởi tạo đối tượng Publication từ cấu trúc JSON trả về của OpenAlex API.
  factory Publication.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ parse dữ liệu nhà xuất bản từ endpoint /publishers
    if (json.containsKey('display_name') && !json.containsKey('title')) {
      final List<String> alternateNames = [];
      if (json['alternate_names'] is List) {
        for (var name in json['alternate_names']) {
          alternateNames.add(name.toString());
        }
      }

      String country = 'N/A';
      if (json['country_codes'] is List && (json['country_codes'] as List).isNotEmpty) {
        country = (json['country_codes'] as List).join(', ').toUpperCase();
      }

      final homepage = json['homepage_url']?.toString();
      final worksCount = json['works_count'] ?? 0;
      final citations = json['cited_by_count'] ?? 0;

      final desc = 'Tên nhà xuất bản: ${json['display_name']}.\n'
          'Quốc gia: $country.\n'
          'Tổng số bài báo đã công bố: $worksCount.\n'
          'Tổng số trích dẫn: $citations.\n'
          'Tên viết tắt/khác: ${alternateNames.isNotEmpty ? alternateNames.join(', ') : 'Không có'}.\n'
          'Trang chủ: ${homepage ?? 'Không có'}.';

      return Publication(
        id: json['id'] ?? '',
        title: json['display_name'] ?? 'Untitled Publisher',
        publicationYear: worksCount,
        citationCount: citations,
        doi: homepage,
        journalName: 'Nhà xuất bản (QG: $country)',
        authors: alternateNames.isNotEmpty ? alternateNames : ['OpenAlex Publisher'],
        abstractText: desc,
        concepts: const [],
        topics: const [],
        publicationType: 'publisher',
      );
    }

    // 1. Phân tích danh sách tác giả từ 'authorships'
    final List<String> parsedAuthors = [];
    if (json['authorships'] is List) {
      for (var auth in json['authorships']) {
        final authorName = auth['author']?['display_name'];
        if (authorName != null) {
          parsedAuthors.add(authorName.toString());
        }
      }
    }

    // 2. Phân tích tên tạp chí/nơi công bố (primary_location -> source -> display_name)
    String parsedJournal = 'Unknown Journal';
    final primaryLoc = json['primary_location'];
    if (primaryLoc != null && primaryLoc['source'] != null) {
      final name = primaryLoc['source']['display_name'];
      if (name != null) {
        parsedJournal = name.toString();
      }
    }

    // 3. Tái dựng nội dung tóm tắt (Abstract) từ 'abstract_inverted_index' của OpenAlex
    String parsedAbstract = 'Không có tóm tắt.';
    final index = json['abstract_inverted_index'];
    if (index is Map<String, dynamic>) {
      parsedAbstract = _reconstructAbstract(index);
    }

    // 4. Phân tích Concepts
    final List<String> parsedConcepts = [];
    if (json['concepts'] is List) {
      for (var concept in json['concepts']) {
        final name = concept['display_name'];
        if (name != null) {
          parsedConcepts.add(name.toString());
        }
      }
    }

    // 5. Phân tích Topics
    final List<String> parsedTopics = [];
    if (json['topics'] is List) {
      for (var topic in json['topics']) {
        final name = topic['display_name'];
        if (name != null) {
          parsedTopics.add(name.toString());
        }
      }
    }
    final primaryTopic = json['primary_topic'];
    String? parsedPrimaryTopic;
    String? parsedSubfield;
    String? parsedField;
    String? parsedDomain;
    if (primaryTopic is Map) {
      final name = primaryTopic['display_name'];
      if (name != null) {
        final nameStr = name.toString();
        parsedPrimaryTopic = nameStr;
        if (!parsedTopics.contains(nameStr)) {
          parsedTopics.insert(0, nameStr);
        }
      }
      final subfield = primaryTopic['subfield'];
      final field = primaryTopic['field'];
      final domain = primaryTopic['domain'];
      if (subfield is Map) {
        parsedSubfield = subfield['display_name']?.toString();
      }
      if (field is Map) {
        parsedField = field['display_name']?.toString();
      }
      if (domain is Map) {
        parsedDomain = domain['display_name']?.toString();
      }
    }

    return Publication(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Publication',
      publicationYear: json['publication_year'] ?? 0,
      citationCount: json['cited_by_count'] ?? 0,
      doi: json['doi'],
      journalName: parsedJournal,
      authors: parsedAuthors,
      abstractText: parsedAbstract,
      concepts: parsedConcepts,
      topics: parsedTopics,
      isOpenAccess: json['open_access'] is Map
          ? json['open_access']['is_oa'] == true
          : false,
      publicationType: json['type']?.toString(),
      primaryTopic: parsedPrimaryTopic,
      subfield: parsedSubfield,
      field: parsedField,
      domain: parsedDomain,
    );
  }

  /// Thuật toán tái tạo đoạn tóm tắt đầy đủ từ chỉ mục đảo ngược (Inverted Index) của OpenAlex.
  /// OpenAlex mã hóa Abstract dưới dạng: {"word": [positions...]} vì lý do bản quyền.
  static String _reconstructAbstract(Map<String, dynamic> index) {
    if (index.isEmpty) {
      return 'Không có tóm tắt.';
    }

    final Map<int, String> positionToWord = {};
    index.forEach((word, positions) {
      if (positions is List) {
        for (var pos in positions) {
          if (pos is int) {
            positionToWord[pos] = word;
          }
        }
      }
    });

    if (positionToWord.isEmpty) {
      return 'Không có tóm tắt.';
    }

    // Sắp xếp các từ theo vị trí của chúng
    final sortedKeys = positionToWord.keys.toList()..sort();
    final int maxPos = sortedKeys.last;

    final List<String> wordsList = List.generate(maxPos + 1, (index) {
      return positionToWord[index] ?? '';
    });

    return wordsList.join(' ').trim();
  }
}
