import 'package:flutter/material.dart';
import 'views/pages/home_page.dart';
import 'views/pages/journals_page.dart';
import 'views/pages/keywords_page.dart';
import 'views/pages/profile_page.dart';
import 'views/state_management/home_notifier.dart';
import 'views/state_management/search_notifier.dart';
import 'views/state_management/trend_notifier.dart';
import 'views/state_management/shared_state.dart';
import 'views/widgets/custom_bottom_nav_bar.dart';

/// Trang quản lý điều hướng / Cấu trúc widget chính của ứng dụng.
/// Khởi tạo các Notifier điều khiển trạng thái và tích hợp thanh CustomBottomNavBar để phân chia màn hình.
class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  int _currentIndex = 0;

  // Khởi tạo các Notifier quản lý logic của các phân vùng chính
  late final HomeNotifier _homeNotifier;
  late final SearchNotifier _searchNotifier;
  late final TrendNotifier _trendNotifier;

  @override
  void initState() {
    super.initState();
    _homeNotifier = HomeNotifier();
    _searchNotifier = SearchNotifier();
    _trendNotifier = TrendNotifier();
    
    // Đăng ký lắng nghe sự thay đổi của tab hoạt động toàn cục
    SharedState.activeTabNotifier.addListener(_onTabChanged);
    _currentIndex = SharedState.activeTabNotifier.value.clamp(0, 3);
  }

  @override
  void dispose() {
    SharedState.activeTabNotifier.removeListener(_onTabChanged);
    _homeNotifier.dispose();
    _searchNotifier.dispose();
    _trendNotifier.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = SharedState.activeTabNotifier.value.clamp(0, 3);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các trang nghiệp vụ (4 Tab theo yêu cầu Lab 03)
    final List<Widget> pages = [
      HomePage(notifier: _homeNotifier, searchNotifier: _searchNotifier),
      const JournalsPage(),
      const KeywordsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          SharedState.activeTabNotifier.value = index.clamp(0, pages.length - 1);
        },
      ),
    );
  }
}
