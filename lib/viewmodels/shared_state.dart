import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:journal_trend_analysis_mb/models/publication_filter_model.dart';
import 'package:journal_trend_analysis_mb/models/publication_model.dart';
import 'package:journal_trend_analysis_mb/models/research_scope_model.dart';
import 'package:journal_trend_analysis_mb/models/research_taxonomy_model.dart';

/// Lưu trữ trạng thái chia sẻ toàn cục giữa các trang.
/// Đảm bảo quy tắc duy nhất về trạng thái tìm kiếm (Unified State Rule).
class SharedState {
  SharedState._();

  /// Quản lý từ khóa tìm kiếm chủ đề đang hoạt động toàn cục.
  static final ValueNotifier<String> activeQueryNotifier = ValueNotifier<String>('');

  static final ValueNotifier<ResearchScope> activeResearchScopeNotifier =
      ValueNotifier<ResearchScope>(ResearchScope.empty);

  static final ValueNotifier<ResearchTaxonomySelection> activeTaxonomyNotifier =
      ValueNotifier<ResearchTaxonomySelection>(ResearchTaxonomySelection.empty);

  static final ValueNotifier<PublicationFilter> publicationFilterNotifier =
      ValueNotifier<PublicationFilter>(PublicationFilter.empty);

  static final ValueNotifier<List<Publication>> originalPublicationsNotifier =
      ValueNotifier<List<Publication>>(const []);

  static final ValueNotifier<List<Publication>> filteredPublicationsNotifier =
      ValueNotifier<List<Publication>>(const []);

  static final ValueNotifier<int> totalPublicationsCountNotifier = ValueNotifier<int>(0);

  /// Quản lý tìm kiếm độc lập cho tab Tạp chí (Journals)
  static final ValueNotifier<String> journalQueryNotifier = ValueNotifier<String>('');
  static final ValueNotifier<List<Map<String, dynamic>>> journalSourcesNotifier = ValueNotifier<List<Map<String, dynamic>>>(const []);
  static final ValueNotifier<bool> journalLoadingNotifier = ValueNotifier<bool>(false);

  /// Quản lý danh sách bài báo đã bookmark
  static final ValueNotifier<List<Publication>> bookmarkedPublicationsNotifier =
      ValueNotifier<List<Publication>>([]);

  static Future<File> _getBookmarksFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/bookmarks.json');
  }

  static Future<void> loadBookmarks() async {
    try {
      final file = await _getBookmarksFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final List<Publication> loaded = jsonList
            .map((j) => Publication.fromJson(j as Map<String, dynamic>))
            .toList();
        bookmarkedPublicationsNotifier.value = loaded;
      }
    } catch (_) {}
  }

  static Future<void> _saveBookmarks() async {
    try {
      final file = await _getBookmarksFile();
      final jsonList = bookmarkedPublicationsNotifier.value
          .map((p) => p.toJson())
          .toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }

  static void toggleBookmark(Publication pub) {
    final current = List<Publication>.from(bookmarkedPublicationsNotifier.value);
    final index = current.indexWhere((p) => p.id == pub.id);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(pub);
    }
    bookmarkedPublicationsNotifier.value = current;
    _saveBookmarks();
  }

  /// Quản lý danh sách bài báo xem gần đây
  static final ValueNotifier<List<Publication>> recentlyViewedNotifier =
      ValueNotifier<List<Publication>>([]);

  static Future<File> _getRecentlyViewedFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/recently_viewed.json');
  }

  static Future<void> loadRecentlyViewed() async {
    try {
      final file = await _getRecentlyViewedFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final List<Publication> loaded = jsonList
            .map((j) => Publication.fromJson(j as Map<String, dynamic>))
            .toList();
        recentlyViewedNotifier.value = loaded;
      }
    } catch (_) {}
  }

  static Future<void> _saveRecentlyViewed() async {
    try {
      final file = await _getRecentlyViewedFile();
      final jsonList = recentlyViewedNotifier.value
          .map((p) => p.toJson())
          .toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }

  static void addToRecentlyViewed(Publication pub) {
    final current = List<Publication>.from(recentlyViewedNotifier.value);
    current.removeWhere((p) => p.id == pub.id);
    current.insert(0, pub);
    if (current.length > 5) {
      current.removeLast();
    }
    recentlyViewedNotifier.value = current;
    _saveRecentlyViewed();
  }

  static void setTotalPublicationsCount(int count) {
    totalPublicationsCountNotifier.value = count;
  }

  /// Quản lý chế độ giao diện sáng/tối (Light/Dark Mode).
  /// Mặc định là ThemeMode.light.
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Quản lý ngôn ngữ hoạt động toàn cục ('en' hoặc 'vi').
  /// Mặc định là 'en' (tiếng Anh).
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  /// Quản lý Tab đang hoạt động toàn cục (0: Trang chủ, 1: Tìm kiếm, 2: Xu hướng, 3: Dashboard).
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  static void toggleLanguage() {
    languageNotifier.value = languageNotifier.value == 'en' ? 'vi' : 'en';
  }

  static void setKeyword(String keyword) {
    publicationFilterNotifier.value =
        publicationFilterNotifier.value.reset(keyword: keyword);
    activeResearchScopeNotifier.value =
        activeResearchScopeNotifier.value.copyWith(
      keyword: keyword,
      clearTaxonomy: true,
      clearAuthor: true,
      clearSource: true,
      clearInstitution: true,
      clearFunder: true,
    );
    activeTaxonomyNotifier.value = ResearchTaxonomySelection.empty;
    activeQueryNotifier.value = keyword;
  }

  static void setResearchTaxonomy(ResearchTaxonomySelection selection) {
    publicationFilterNotifier.value = publicationFilterNotifier.value.copyWith(
      keyword: '',
      taxonomy: selection,
    );
    activeResearchScopeNotifier.value =
        activeResearchScopeNotifier.value.copyWith(
      keyword: '',
      taxonomy: selection,
      clearAuthor: true,
      clearSource: true,
      clearInstitution: true,
      clearFunder: true,
    );
    activeTaxonomyNotifier.value = selection;
    activeQueryNotifier.value = selection.displayLabel;
  }

  static void updateResearchScope(ResearchScope scope) {
    activeResearchScopeNotifier.value = scope;
    activeTaxonomyNotifier.value = scope.taxonomy;
    publicationFilterNotifier.value = publicationFilterNotifier.value.copyWith(
      keyword: scope.keyword,
      taxonomy: scope.taxonomy,
      fromYear: scope.yearFrom,
      toYear: scope.yearTo,
      minCitations: scope.minCitationCount,
      openAccessOnly: scope.isOpenAccess == true,
      publicationType: scope.publicationType ?? 'all',
    );
    activeQueryNotifier.value = scope.displayLabel;
  }

  static void setPublicationFilter(PublicationFilter filter) {
    publicationFilterNotifier.value = filter;
  }

  static void setOriginalPublications(List<Publication> publications) {
    originalPublicationsNotifier.value = publications;
  }

  static void setFilteredPublications(List<Publication> publications) {
    filteredPublicationsNotifier.value = publications;
  }

  static void clearFilters({bool keepKeyword = true}) {
    final keyword = keepKeyword ? publicationFilterNotifier.value.keyword : '';
    publicationFilterNotifier.value =
        PublicationFilter.empty.copyWith(keyword: keyword);
    activeResearchScopeNotifier.value =
        activeResearchScopeNotifier.value.copyWith(
      keyword: keyword,
      clearTaxonomy: true,
      clearYearRange: true,
      clearPublicationType: true,
      clearOpenAccess: true,
      clearMinCitationCount: true,
    );
    activeTaxonomyNotifier.value = ResearchTaxonomySelection.empty;
    activeQueryNotifier.value = keyword;
    if (!keepKeyword) {
      totalPublicationsCountNotifier.value = 0;
    }
  }

  static void clearResearchTaxonomy() {
    publicationFilterNotifier.value =
        publicationFilterNotifier.value.copyWith(clearTaxonomy: true);
    activeResearchScopeNotifier.value =
        activeResearchScopeNotifier.value.copyWith(clearTaxonomy: true);
    activeTaxonomyNotifier.value = ResearchTaxonomySelection.empty;
  }

  static void clearResearchScope() {
    publicationFilterNotifier.value = PublicationFilter.empty;
    originalPublicationsNotifier.value = const [];
    filteredPublicationsNotifier.value = const [];
    totalPublicationsCountNotifier.value = 0;
    activeResearchScopeNotifier.value = ResearchScope.empty;
    activeTaxonomyNotifier.value = ResearchTaxonomySelection.empty;
    activeQueryNotifier.value = '';
  }
}
