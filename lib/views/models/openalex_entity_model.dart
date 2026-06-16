class OpenAlexEntity {
  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;
  final String? description;

  const OpenAlexEntity({
    required this.id,
    required this.displayName,
    this.worksCount = 0,
    this.citedByCount = 0,
    this.description,
  });

  factory OpenAlexEntity.fromJson(Map<String, dynamic> json) {
    return OpenAlexEntity(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'N/A',
      worksCount: int.tryParse(json['works_count']?.toString() ?? '') ?? 0,
      citedByCount: int.tryParse(json['cited_by_count']?.toString() ?? '') ?? 0,
      description: json['description']?.toString(),
    );
  }
}
