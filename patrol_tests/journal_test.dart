import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 4 & 5 - Journals Navigation & Journal Details',
    ($) async {
      // 1. Khởi chạy và Đăng nhập tự động
      app.main();
      await $.pumpAndSettle();
      if (find.text('Sign in with Google').evaluate().isNotEmpty) {
        await $.tap(find.text('Sign in with Google'));
        await $.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Điều hướng sang tab Tạp chí (Journals tab - index 1)
      await $(Icons.menu_book_rounded).tap();
      await $.pumpAndSettle();

      // 3. Xác minh thống kê Tạp chí hiển thị
      expect(find.text('Tổng số tạp chí'), findsOneWidget);
      expect(find.text('Bài viết TB / Tạp chí'), findsOneWidget);
      expect(find.text('Biểu đồ đóng góp sản lượng'), findsOneWidget);

      // 4. Nhấn mở một Tạp chí cụ thể trong danh sách
      // Danh sách các tạp chí dạng ListTile
      final firstJournalTile = find.byType(ListTile).first;
      expect(firstJournalTile, findsOneWidget);
      await $.tap(firstJournalTile);
      await $.pumpAndSettle();

      // 5. Xác minh màn hình Chi tiết Tạp chí (JournalDetailPage)
      expect(find.text('Chi tiết Tạp chí'), findsOneWidget);
      expect(find.text('Tổng bài báo'), findsOneWidget);
      expect(find.text('Tổng trích dẫn'), findsOneWidget);
      expect(find.text('Trích dẫn TB'), findsOneWidget);

      // Quay lại màn hình chính
      await $(Icons.arrow_back_rounded).tap();
      await $.pumpAndSettle();
    },
  );
}
