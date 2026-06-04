import 'package:flutter/material.dart';
import '../services/openalex_api_service.dart';

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

  const SDGItem({
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

  HomeState({
    this.selectedDomain = 'Khoa học Vật lý',
    this.domains = const ['Khoa học Vật lý', 'Khoa học Y học', 'Khoa học Xã hội', 'Khoa học Sự sống'],
    List<FieldItem>? activeFields,
    List<GeographyItem>? geographyLeaderboard,
    List<SDGItem>? sdgs,
    List<AuthorItem>? authors,
    List<InstitutionItem>? institutions,
    this.isLoading = false,
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
    );
  }
}

class HomeNotifier {
  final ValueNotifier<HomeState> stateNotifier = ValueNotifier<HomeState>(HomeState());

  // Lưu trữ tĩnh dữ liệu các Fields thuộc từng nhóm Domain chính
  final Map<String, List<FieldItem>> _fieldsMap = {
    'Khoa học Vật lý': const [
      FieldItem(name: 'Computer Science', icon: Icons.computer_rounded, description: 'Khoa học máy tính, AI, Học máy'),
      FieldItem(name: 'Mathematics', icon: Icons.calculate_rounded, description: 'Toán học lý thuyết & ứng dụng'),
      FieldItem(name: 'Physics', icon: Icons.science_rounded, description: 'Vật lý lượng tử, Thiên văn, Cơ học'),
      FieldItem(name: 'Chemistry', icon: Icons.biotech_rounded, description: 'Hóa học hữu cơ, Hóa lý, Hóa sinh'),
      FieldItem(name: 'Engineering', icon: Icons.engineering_rounded, description: 'Kỹ thuật điện, Cơ khí, Vật liệu'),
    ],
    'Khoa học Y học': const [
      FieldItem(name: 'Medicine', icon: Icons.medical_services_rounded, description: 'Y khoa lâm sàng, Nội, Ngoại khoa'),
      FieldItem(name: 'Nursing', icon: Icons.healing_rounded, description: 'Điều dưỡng & chăm sóc sức khỏe'),
      FieldItem(name: 'Dentistry', icon: Icons.health_and_safety_rounded, description: 'Nha khoa & răng hàm mặt'),
      FieldItem(name: 'Pharmacology', icon: Icons.vaccines_rounded, description: 'Dược lý học & phát triển thuốc'),
    ],
    'Khoa học Xã hội': const [
      FieldItem(name: 'Psychology', icon: Icons.psychology_rounded, description: 'Tâm lý học hành vi & nhận thức'),
      FieldItem(name: 'Economics', icon: Icons.monetization_on_rounded, description: 'Kinh tế học, Tài chính vĩ mô'),
      FieldItem(name: 'Political Science', icon: Icons.gavel_rounded, description: 'Khoa học chính trị & chính sách công'),
      FieldItem(name: 'Education', icon: Icons.school_rounded, description: 'Giáo dục học & phương pháp giảng dạy'),
      FieldItem(name: 'Sociology', icon: Icons.groups_rounded, description: 'Xã hội học & văn hóa nhân chủng'),
    ],
    'Khoa học Sự sống': const [
      FieldItem(name: 'Biology', icon: Icons.eco_rounded, description: 'Sinh học đại cương & sinh thái'),
      FieldItem(name: 'Genetics', icon: Icons.grain_rounded, description: 'Di truyền học & sinh học phân tử'),
      FieldItem(name: 'Ecology', icon: Icons.forest_rounded, description: 'Sinh thái môi trường & bảo tồn'),
      FieldItem(name: 'Neuroscience', icon: Icons.insights_rounded, description: 'Thần kinh học & hệ thống hành vi'),
    ],
  };

  final OpenAlexApiService _apiService = OpenAlexApiService();

  HomeNotifier() {
    _initData();
    fetchTopAuthors();
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
      sdgs: const [
        SDGItem(number: 3, title: 'Good Health & Well-being', color: Color(0xFF4C9F38), icon: Icons.favorite_rounded),
        SDGItem(number: 4, title: 'Quality Education', color: Color(0xFFC7212F), icon: Icons.menu_book_rounded),
        SDGItem(number: 7, title: 'Affordable & Clean Energy', color: Color(0xFFF99D15), icon: Icons.wb_sunny_rounded),
        SDGItem(number: 9, title: 'Industry & Innovation', color: Color(0xFFF36D25), icon: Icons.precision_manufacturing_rounded),
        SDGItem(number: 13, title: 'Climate Action', color: Color(0xFF3F7E44), icon: Icons.thermostat_rounded),
        SDGItem(number: 15, title: 'Life on Land', color: Color(0xFF56C02B), icon: Icons.grass_rounded),
      ],
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
