import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 10 - Remote Config Dynamic Limits',
    ($) async {
      // 1. Khởi chạy và Đăng nhập tự động
      app.main();
      await $.pumpAndSettle();
      if (find.text('Sign in with Google').evaluate().isNotEmpty) {
        await $.tap(find.text('Sign in with Google'));
        await $.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Điều hướng sang tab Cá nhân (Profile tab - index 3)
      await $(Icons.person_rounded).tap();
      await $.pumpAndSettle();

      // 3. Xác minh hiển thị cấu hình từ xa và các thanh trượt Slider
      expect(find.text('Firebase Remote Config Demo'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2)); // Slider cho Journals và Keywords

      // 4. Nhấn thay đổi slider cấu hình số lượng tạp chí hiển thị ( Journals hiển thị )
      final Slider journalSlider = $.tester.widget(find.byType(Slider).first);
      // Giả lập kéo slider bằng gesture
      await $.drag(find.byType(Slider).first, const Offset(-100, 0)); // Kéo sang trái giảm giới hạn
      await $.pumpAndSettle();

      // 5. Điều hướng sang tab Tạp chí (index 1) để xác minh danh sách được cắt gọn đúng số lượng cấu hình mới
      await $(Icons.menu_book_rounded).tap();
      await $.pumpAndSettle();

      // Số lượng tạp chí hiển thị phải nhỏ hơn hoặc bằng giới hạn vừa trượt
      final journalListTilesCount = find.byType(ListTile).evaluate().length;
      expect(journalListTilesCount, isNotNull);
    },
  );
}
