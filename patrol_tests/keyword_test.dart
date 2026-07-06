import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 6 & 7 - Keywords Navigation & Keyword Details',
    ($) async {
      // 1. Khởi chạy và Đăng nhập tự động
      app.main();
      await $.pumpAndSettle();
      if (find.text('Sign in with Google').evaluate().isNotEmpty) {
        await $.tap(find.text('Sign in with Google'));
        await $.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Điều hướng sang tab Từ khóa (Keywords tab - index 2)
      await $(Icons.tag_rounded).tap();
      await $.pumpAndSettle();

      // 3. Xác minh thống kê Từ khóa hiển thị
      expect(find.text('Tổng số từ khóa'), findsOneWidget);
      expect(find.text('Biểu đồ tần suất xuất hiện'), findsOneWidget);
      expect(find.text('Từ khóa phổ biến nhất'), findsOneWidget);

      // 4. Nhấn mở một Từ khóa cụ thể trong danh sách
      // Các từ khóa dạng ActionChip
      final keywordChip = find.byType(ActionChip).first;
      expect(keywordChip, findsOneWidget);
      await $.tap(keywordChip);
      await $.pumpAndSettle();

      // 5. Xác minh màn hình Chi tiết Từ khóa (KeywordDetailPage)
      expect(find.text('Chi tiết Từ khóa'), findsOneWidget);
      expect(find.text('Xu hướng công bố theo năm'), findsOneWidget);
      expect(find.text('Tác giả đóng góp hàng đầu'), findsOneWidget);
      expect(find.text('Tạp chí liên quan'), findsOneWidget);

      // Quay lại màn hình chính
      await $(Icons.arrow_back_rounded).tap();
      await $.pumpAndSettle();
    },
  );
}
