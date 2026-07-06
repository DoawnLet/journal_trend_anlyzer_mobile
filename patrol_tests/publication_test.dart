import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 2 & 3 - Topic Search & Publication Details',
    ($) async {
      // 1. Khởi chạy và Đăng nhập tự động
      app.main();
      await $.pumpAndSettle();
      if (find.text('Sign in with Google').evaluate().isNotEmpty) {
        await $.tap(find.text('Sign in with Google'));
        await $.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Tìm ô nhập tìm kiếm đề tài
      final searchTextField = find.byType(TextField);
      expect(searchTextField, findsOneWidget);

      // Nhập từ khóa đề tài (ví dụ: Deep Learning)
      await $.enterText(searchTextField, 'Deep Learning');
      await $.pump();

      // Thực thi tìm kiếm bằng cách nhấn nút Search trên bàn phím giả lập
      await $.testGestureHolder.testTextInput.receiveAction(TextInputAction.search);
      await $.pumpAndSettle(const Duration(seconds: 3));

      // 3. Xác minh kết quả tìm kiếm hiển thị
      // Ít nhất phải hiển thị biểu đồ xu hướng xuất bản và danh sách bài báo
      expect(find.text('Publication Trend'), findsOneWidget);
      expect(find.text('Top Influential Papers'), findsOneWidget);

      // 4. Nhấn mở một bài viết cụ thể trong danh sách
      // Các bài báo trong danh sách sẽ có biểu tượng ngôi sao trích dẫn trailing
      final firstPublicationItem = find.byType(ListTile).first;
      expect(firstPublicationItem, findsOneWidget);
      await $.tap(firstPublicationItem);
      await $.pumpAndSettle();

      // 5. Xác minh màn hình Chi tiết bài viết (DetailPage) hoạt động
      // Màn hình chi tiết bài viết có tiêu đề AppBar là "Publication Details" (hoặc dịch tương ứng)
      expect(find.text('Publication Details'), findsOneWidget);
      expect(find.text('Abstract'), findsOneWidget);
      expect(find.text('Open DOI Link'), findsOneWidget);

      // Quay lại màn hình chính
      await $(Icons.arrow_back_rounded).tap();
      await $.pumpAndSettle();
    },
  );
}
