enum ResearchTaxonomyLevel {
  domain,
  field,
  subfield,
  topic,
}

class ResearchTaxonomyNode {
  final String id;
  final String name;
  final int worksCount;
  final ResearchTaxonomyLevel level;

  const ResearchTaxonomyNode({
    required this.id,
    required this.name,
    required this.level,
    this.worksCount = 0,
  });

  bool get isValid => id.isNotEmpty && name.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResearchTaxonomyNode &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            level == other.level;
  }

  @override
  int get hashCode => Object.hash(id, level);
}

class ResearchTopic {
  final ResearchTaxonomyNode topic;
  final ResearchTaxonomyNode? domain;
  final ResearchTaxonomyNode? field;
  final ResearchTaxonomyNode? subfield;

  const ResearchTopic({
    required this.topic,
    this.domain,
    this.field,
    this.subfield,
  });

  factory ResearchTopic.fromJson(Map<String, dynamic> json) {
    return ResearchTopic(
      topic: ResearchTaxonomyNode(
        id: json['id']?.toString() ?? '',
        name: json['display_name']?.toString() ?? 'Unknown Topic',
        level: ResearchTaxonomyLevel.topic,
        worksCount: _parseInt(json['works_count']),
      ),
      domain: _nodeFromJson(json['domain'], ResearchTaxonomyLevel.domain),
      field: _nodeFromJson(json['field'], ResearchTaxonomyLevel.field),
      subfield: _nodeFromJson(json['subfield'], ResearchTaxonomyLevel.subfield),
    );
  }

  static ResearchTaxonomyNode? _nodeFromJson(
    Object? value,
    ResearchTaxonomyLevel level,
  ) {
    if (value is! Map) {
      return null;
    }

    final id = value['id']?.toString() ?? '';
    final name = value['display_name']?.toString() ?? '';
    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    return ResearchTaxonomyNode(
      id: id,
      name: name,
      level: level,
      worksCount: _parseInt(value['works_count']),
    );
  }

  static int _parseInt(Object? value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ResearchTaxonomySelection {
  final ResearchTaxonomyNode? domain;
  final ResearchTaxonomyNode? field;
  final ResearchTaxonomyNode? subfield;
  final ResearchTaxonomyNode? topic;

  const ResearchTaxonomySelection({
    this.domain,
    this.field,
    this.subfield,
    this.topic,
  });

  static const empty = ResearchTaxonomySelection();

  bool get hasSelection =>
      domain != null || field != null || subfield != null || topic != null;

  ResearchTaxonomyNode? get deepest =>
      topic ?? subfield ?? field ?? domain;

  String get displayLabel => deepest?.name ?? '';

  String get breadcrumb {
    final parts = [
      domain?.name,
      field?.name,
      subfield?.name,
      topic?.name,
    ].whereType<String>().where((item) => item.isNotEmpty).toList();
    return parts.join(' > ');
  }

  String? get worksFilter {
    if (topic != null) {
      return 'topics.id:${topic!.id}';
    }
    if (subfield != null) {
      return 'primary_topic.subfield.id:${subfield!.id}';
    }
    if (field != null) {
      return 'primary_topic.field.id:${field!.id}';
    }
    if (domain != null) {
      return 'primary_topic.domain.id:${domain!.id}';
    }
    return null;
  }
}
