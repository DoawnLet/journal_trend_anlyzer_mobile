import 'package:flutter/material.dart';
import 'views/pages/home_page.dart';
import 'views/pages/search_page.dart';
import 'views/pages/trend_page.dart';
import 'views/pages/dashboard_page.dart';
import 'views/state_management/home_notifier.dart';
import 'views/state_management/search_notifier.dart';
import 'views/state_management/trend_notifier.dart';
import 'views/state_management/dashboard_notifier.dart';
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
  late final DashboardNotifier _dashboardNotifier;

  @override
  void initState() {
    super.initState();
    _homeNotifier = HomeNotifier();
    _searchNotifier = SearchNotifier();
    _trendNotifier = TrendNotifier();
    _dashboardNotifier = DashboardNotifier();
    
    // Đăng ký lắng nghe sự thay đổi của tab hoạt động toàn cục
    SharedState.activeTabNotifier.addListener(_onTabChanged);
    _currentIndex = SharedState.activeTabNotifier.value;
  }

  @override
  void dispose() {
    SharedState.activeTabNotifier.removeListener(_onTabChanged);
    _homeNotifier.dispose();
    _searchNotifier.dispose();
    _trendNotifier.dispose();
    _dashboardNotifier.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _currentIndex = SharedState.activeTabNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các trang nghiệp vụ
    final List<Widget> pages = [
      HomePage(notifier: _homeNotifier, searchNotifier: _searchNotifier),
      SearchPage(notifier: _searchNotifier),
      TrendPage(notifier: _trendNotifier),
      DashboardPage(notifier: _dashboardNotifier),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          SharedState.activeTabNotifier.value = index;
        },
      ),
    );
  }
}
