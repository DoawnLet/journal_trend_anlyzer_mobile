import 'package:flutter/material.dart';
import 'views/pages/search_page.dart';
import 'views/pages/trend_page.dart';
import 'views/pages/dashboard_page.dart';
import 'views/state_management/search_notifier.dart';
import 'views/state_management/trend_notifier.dart';
import 'views/state_management/dashboard_notifier.dart';
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

  // Khởi tạo các Notifier quản lý logic của 3 phân vùng chính
  late final SearchNotifier _searchNotifier;
  late final TrendNotifier _trendNotifier;
  late final DashboardNotifier _dashboardNotifier;

  @override
  void initState() {
    super.initState();
    _searchNotifier = SearchNotifier();
    _trendNotifier = TrendNotifier();
    _dashboardNotifier = DashboardNotifier();
  }

  @override
  void dispose() {
    _searchNotifier.dispose();
    _trendNotifier.dispose();
    _dashboardNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các trang nghiệp vụ
    final List<Widget> pages = [
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
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
