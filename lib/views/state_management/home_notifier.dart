import 'package:flutter/material.dart';
import '../models/research_taxonomy_model.dart';
import '../services/openalex_api_service.dart';
import '../services/taxonomy_api_service.dart';

class FieldItem {
  final String name;
  final IconData icon;
  final String description;

  const FieldItem({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class GeographyItem {
  final String name;
  final String type; // 'Châu lục' hoặc 'Quốc gia'
  final String publicationCount;
  final String growth;

  const GeographyItem({
    required this.name,
    required this.type,
    required this.publicationCount,
    required this.growth,
  });
}

class SDGItem {
  final int number;
  final String title;
  final Color color;
  final IconData icon;
  final int worksCount;
  final String searchQuery;
  final ResearchTaxonomySelection? taxonomySelection;

  const SDGItem({
    required this.number,
    required this.title,
    required this.color,
    required this.icon,
    this.worksCount = 0,
    this.searchQuery = '',
    this.taxonomySelection,
  });
}

class SdgSeed {
  final int number;
  final String title;
  final Color color;
  final IconData icon;

  const SdgSeed({
    required this.number,
    required this.title,
    required this.color,
    required this.icon,
  });
}

class InstitutionItem {
  final String name;
  final String country;
  final String type; // 'Trường Đại học' hoặc 'Viện nghiên cứu'
  final String worksCount;

  const InstitutionItem({
    required this.name,
    required this.country,
    required this.type,
    required this.worksCount,
  });
}

class AuthorItem {
  final String id;
  final String name;
  final String institution;
  final String worksCount;
  final String citedByCount;

  const AuthorItem({
    required this.id,
    required this.name,
    required this.institution,
    required this.worksCount,
    required this.citedByCount,
  });
}

class HomeState {
  final String selectedDomain;
  final List<String> domains;
  final List<FieldItem> activeFields;
  final List<GeographyItem> geographyLeaderboard;
  final List<SDGItem> sdgs;
  final List<AuthorItem> authors;
  final List<InstitutionItem> institutions;
  final bool isLoading;
  final bool isLoadingSdgs;

  HomeState({
    this.selectedDomain = 'Khoa học Vật lý',
    this.domains = const ['Khoa học Vật lý', 'Khoa học Y học', 'Khoa học Xã hội', 'Khoa học Sự sống'],
    List<FieldItem>? activeFields,
    List<GeographyItem>? geographyLeaderboard,
    List<SDGItem>? sdgs,
    List<AuthorItem>? authors,
    List<InstitutionItem>? institutions,
    this.isLoading = false,
    this.isLoadingSdgs = false,
  }) : activeFields = activeFields ?? const <FieldItem>[],
       geographyLeaderboard = geographyLeaderboard ?? const <GeographyItem>[],
       sdgs = sdgs ?? const <SDGItem>[],
       authors = authors ?? const <AuthorItem>[],
       institutions = institutions ?? const <InstitutionItem>[];

  HomeState copyWith({
    String? selectedDomain,
    List<String>? domains,
    List<FieldItem>? activeFields,
    List<GeographyItem>? geographyLeaderboard,
    List<SDGItem>? sdgs,
    List<AuthorItem>? authors,
    List<InstitutionItem>? institutions,
    bool? isLoading,
    bool? isLoadingSdgs,
  }) {
    return HomeState(
      selectedDomain: selectedDomain ?? this.selectedDomain,
      domains: domains ?? this.domains,
      activeFields: activeFields ?? this.activeFields,
      geographyLeaderboard: geographyLeaderboard ?? this.geographyLeaderboard,
      sdgs: sdgs ?? this.sdgs,
      authors: authors ?? this.authors,
      institutions: institutions ?? this.institutions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSdgs: isLoadingSdgs ?? this.isLoadingSdgs,
    );
  }
}

class HomeNotifier {
  final ValueNotifier<HomeState> stateNotifier = ValueNotifier<HomeState>(HomeState());

  // Lưu trữ tĩnh dữ liệu các Fields thuộc từng nhóm Domain chính
  final Map<String, List<FieldItem>> _fieldsMap = {
    'Khoa học Vật lý': const [
      FieldItem(name: 'Computer Science', icon: Icons.computer_rounded, description: 'computer_science_desc'),
      FieldItem(name: 'Mathematics', icon: Icons.calculate_rounded, description: 'mathematics_desc'),
      FieldItem(name: 'Physics', icon: Icons.science_rounded, description: 'physics_desc'),
      FieldItem(name: 'Chemistry', icon: Icons.biotech_rounded, description: 'chemistry_desc'),
      FieldItem(name: 'Engineering', icon: Icons.engineering_rounded, description: 'engineering_desc'),
    ],
    'Khoa học Y học': const [
      FieldItem(name: 'Medicine', icon: Icons.medical_services_rounded, description: 'medicine_desc'),
      FieldItem(name: 'Nursing', icon: Icons.healing_rounded, description: 'nursing_desc'),
      FieldItem(name: 'Dentistry', icon: Icons.health_and_safety_rounded, description: 'dentistry_desc'),
      FieldItem(name: 'Pharmacology', icon: Icons.vaccines_rounded, description: 'pharmacology_desc'),
    ],
    'Khoa học Xã hội': const [
      FieldItem(name: 'Psychology', icon: Icons.psychology_rounded, description: 'psychology_desc'),
      FieldItem(name: 'Economics', icon: Icons.monetization_on_rounded, description: 'economics_desc'),
      FieldItem(name: 'Political Science', icon: Icons.gavel_rounded, description: 'political_science_desc'),
      FieldItem(name: 'Education', icon: Icons.school_rounded, description: 'education_desc'),
      FieldItem(name: 'Sociology', icon: Icons.groups_rounded, description: 'sociology_desc'),
    ],
    'Khoa học Sự sống': const [
      FieldItem(name: 'Biology', icon: Icons.eco_rounded, description: 'biology_desc'),
      FieldItem(name: 'Genetics', icon: Icons.grain_rounded, description: 'genetics_desc'),
      FieldItem(name: 'Ecology', icon: Icons.forest_rounded, description: 'ecology_desc'),
      FieldItem(name: 'Neuroscience', icon: Icons.insights_rounded, description: 'neuroscience_desc'),
    ],
  };

  final OpenAlexApiService _apiService = OpenAlexApiService();
  final TaxonomyApiService _taxonomyApiService = TaxonomyApiService();
  static const List<SdgSeed> _sdgSeeds = [
    SdgSeed(
      number: 1,
      title: 'No Poverty',
      color: Color(0xFFE5243B),
      icon: Icons.volunteer_activism_rounded,
    ),
    SdgSeed(
      number: 2,
      title: 'Zero Hunger',
      color: Color(0xFFDDA63A),
      icon: Icons.restaurant_rounded,
    ),
    SdgSeed(
      number: 3,
      title: 'Good Health and Well-Being',
      color: Color(0xFF4C9F38),
      icon: Icons.favorite_rounded,
    ),
    SdgSeed(
      number: 4,
      title: 'Quality Education',
      color: Color(0xFFC5192D),
      icon: Icons.menu_book_rounded,
    ),
    SdgSeed(
      number: 5,
      title: 'Gender Equality',
      color: Color(0xFFFF3A21),
      icon: Icons.wc_rounded,
    ),
    SdgSeed(
      number: 6,
      title: 'Clean Water and Sanitation',
      color: Color(0xFF26BDE2),
      icon: Icons.water_drop_rounded,
    ),
    SdgSeed(
      number: 7,
      title: 'Affordable and Clean Energy',
      color: Color(0xFFFCC30B),
      icon: Icons.wb_sunny_rounded,
    ),
    SdgSeed(
      number: 8,
      title: 'Decent Work and Economic Growth',
      color: Color(0xFFA21942),
      icon: Icons.trending_up_rounded,
    ),
    SdgSeed(
      number: 9,
      title: 'Industry Innovation and Infrastructure',
      color: Color(0xFFF36D25),
      icon: Icons.precision_manufacturing_rounded,
    ),
    SdgSeed(
      number: 10,
      title: 'Reduced Inequalities',
      color: Color(0xFFDD1367),
      icon: Icons.balance_rounded,
    ),
    SdgSeed(
      number: 11,
      title: 'Sustainable Cities and Communities',
      color: Color(0xFFFD9D24),
      icon: Icons.location_city_rounded,
    ),
    SdgSeed(
      number: 12,
      title: 'Responsible Consumption and Production',
      color: Color(0xFFBF8B2E),
      icon: Icons.recycling_rounded,
    ),
    SdgSeed(
      number: 13,
      title: 'Climate Action',
      color: Color(0xFF3F7E44),
      icon: Icons.thermostat_rounded,
    ),
    SdgSeed(
      number: 14,
      title: 'Life Below Water',
      color: Color(0xFF0A97D9),
      icon: Icons.waves_rounded,
    ),
    SdgSeed(
      number: 15,
      title: 'Life on Land',
      color: Color(0xFF56C02B),
      icon: Icons.grass_rounded,
    ),
    SdgSeed(
      number: 16,
      title: 'Peace Justice and Strong Institutions',
      color: Color(0xFF00689D),
      icon: Icons.gavel_rounded,
    ),
    SdgSeed(
      number: 17,
      title: 'Partnerships for the Goals',
      color: Color(0xFF19486A),
      icon: Icons.handshake_rounded,
    ),
  ];

  HomeNotifier() {
    _initData();
    fetchTopAuthors();
    fetchSdgs();
  }

  void _initData() {
    stateNotifier.value = stateNotifier.value.copyWith(
      activeFields: _fieldsMap['Khoa học Vật lý'],
      geographyLeaderboard: const [
        GeographyItem(name: 'Châu Á', type: 'Châu lục', publicationCount: '35M+', growth: '+8.4%'),
        GeographyItem(name: 'Châu Âu', type: 'Châu lục', publicationCount: '28M+', growth: '+5.1%'),
        GeographyItem(name: 'Bắc Mỹ', type: 'Châu lục', publicationCount: '24M+', growth: '+4.8%'),
        GeographyItem(name: 'Hoa Kỳ', type: 'Quốc gia', publicationCount: '18.5M', growth: '+4.1%'),
        GeographyItem(name: 'Trung Quốc', type: 'Quốc gia', publicationCount: '14.2M', growth: '+9.2%'),
        GeographyItem(name: 'Vương Quốc Anh', type: 'Quốc gia', publicationCount: '5.4M', growth: '+3.9%'),
        GeographyItem(name: 'Đức', type: 'Quốc gia', publicationCount: '4.8M', growth: '+3.2%'),
      ],
      sdgs: const <SDGItem>[],
      authors: const <AuthorItem>[],
      institutions: const [
        InstitutionItem(name: 'Harvard University', country: 'Hoa Kỳ', type: 'Trường Đại học', worksCount: '820K'),
        InstitutionItem(name: 'Stanford University', country: 'Hoa Kỳ', type: 'Trường Đại học', worksCount: '540K'),
        InstitutionItem(name: 'MIT', country: 'Hoa Kỳ', type: 'Trường Đại học', worksCount: '490K'),
        InstitutionItem(name: 'University of Oxford', country: 'Vương Quốc Anh', type: 'Trường Đại học', worksCount: '450K'),
        InstitutionItem(name: 'Tsinghua University', country: 'Trung Quốc', type: 'Trường Đại học', worksCount: '380K'),
      ],
    );
  }

  Future<void> fetchTopAuthors() async {
    stateNotifier.value = stateNotifier.value.copyWith(isLoading: true);
    try {
      final data = await _apiService.getTopAuthors();
      final List results = data['results'] ?? [];
      
      final List<AuthorItem> fetchedAuthors = results.map<AuthorItem>((item) {
        final lastInst = item['last_known_institution'];
        final instName = lastInst != null ? (lastInst['display_name'] ?? 'N/A') : 'N/A';
        final country = lastInst != null ? (lastInst['country_code'] ?? '') : '';
        final fullInst = country.isNotEmpty ? '$instName ($country)' : instName;
        
        final works = item['works_count']?.toString() ?? '0';
        final cited = item['cited_by_count']?.toString() ?? '0';
        
        String formattedWorks = works;
        final intWorks = int.tryParse(works) ?? 0;
        if (intWorks >= 1000000) {
          formattedWorks = '${(intWorks / 1000000).toStringAsFixed(1)}M';
        } else if (intWorks >= 1000) {
          formattedWorks = '${(intWorks / 1000).toStringAsFixed(1)}K';
        }

        return AuthorItem(
          id: item['id'] ?? '',
          name: item['display_name'] ?? 'N/A',
          institution: fullInst,
          worksCount: formattedWorks,
          citedByCount: cited,
        );
      }).toList();

      stateNotifier.value = stateNotifier.value.copyWith(
        authors: fetchedAuthors,
        isLoading: false,
      );
    } catch (e) {
      stateNotifier.value = stateNotifier.value.copyWith(
        isLoading: false,
      );
      debugPrint('Failed to load top authors: $e');
    }
  }

  Future<void> fetchSdgs() async {
    stateNotifier.value = stateNotifier.value.copyWith(isLoadingSdgs: true);
    try {
      final resolvedSdgs = await Future.wait(
        _sdgSeeds.map(_resolveSdgSeed),
      );
      stateNotifier.value = stateNotifier.value.copyWith(
        sdgs: resolvedSdgs,
        isLoadingSdgs: false,
      );
    } catch (e) {
      stateNotifier.value = stateNotifier.value.copyWith(
        sdgs: _sdgSeeds
            .map(
              (seed) => SDGItem(
                number: seed.number,
                title: seed.title,
                color: seed.color,
                icon: seed.icon,
                searchQuery: seed.title,
              ),
            )
            .toList(),
        isLoadingSdgs: false,
      );
      debugPrint('Failed to load SDGs from OpenAlex topics: $e');
    }
  }

  Future<SDGItem> _resolveSdgSeed(SdgSeed seed) async {
    try {
      final topics = await _taxonomyApiService.searchTopics(seed.title, limit: 10);
      final matchedTopic = _findBestMatchingTopic(seed.title, topics);
      if (matchedTopic != null) {
        return SDGItem(
          number: seed.number,
          title: matchedTopic.topic.name,
          color: seed.color,
          icon: seed.icon,
          worksCount: matchedTopic.topic.worksCount,
          searchQuery: matchedTopic.topic.name,
          taxonomySelection: ResearchTaxonomySelection(
            domain: matchedTopic.domain,
            field: matchedTopic.field,
            subfield: matchedTopic.subfield,
            topic: matchedTopic.topic,
          ),
        );
      }
    } catch (_) {
      // Fall back to the curated SDG metadata below.
    }

    return SDGItem(
      number: seed.number,
      title: seed.title,
      color: seed.color,
      icon: seed.icon,
      searchQuery: seed.title,
    );
  }

  ResearchTopic? _findBestMatchingTopic(
    String expectedTitle,
    List<ResearchTopic> topics,
  ) {
    if (topics.isEmpty) {
      return null;
    }

    final normalizedExpected = _normalizeLabel(expectedTitle);
    for (final topic in topics) {
      if (_normalizeLabel(topic.topic.name) == normalizedExpected) {
        return topic;
      }
    }

    for (final topic in topics) {
      final normalizedName = _normalizeLabel(topic.topic.name);
      if (normalizedName.contains(normalizedExpected) ||
          normalizedExpected.contains(normalizedName)) {
        return topic;
      }
    }

    return topics.first;
  }

  String _normalizeLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  /// Thay đổi Domain đang hiển thị
  void changeDomain(String domain) {
    if (stateNotifier.value.selectedDomain == domain) return;

    stateNotifier.value = stateNotifier.value.copyWith(
      selectedDomain: domain,
      activeFields: _fieldsMap[domain] ?? const [],
    );
  }

  void dispose() {
    stateNotifier.dispose();
  }
}
