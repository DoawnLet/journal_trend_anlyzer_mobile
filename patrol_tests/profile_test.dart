import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 8 - Profile Navigation & Crashlytics Demo',
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

      // 3. Xác minh thông tin Profile hiển thị đúng thông tin tài khoản đăng nhập
      expect(find.text('Nguyen Van A'), findsOneWidget);
      expect(find.text('nguyenvana.prm393@gmail.com'), findsOneWidget);

      // 4. Xác minh sự tồn tại của bảng điều khiển Crashlytics và các nút bấm
      expect(find.text('Firebase Crashlytics Demo'), findsOneWidget);
      expect(find.text('Handled Exception'), findsOneWidget);
      expect(find.text('Trigger Test Crash'), findsOneWidget);

      // 5. Thử nghiệm nút tạo Lỗi ngoại lệ đã xử lý (Handled Exception)
      await $.tap(find.text('Handled Exception'));
      await $.pumpAndSettle();

      // Xác minh hiển thị thông báo SnackBar báo cáo lỗi thành công lên Crashlytics
      expect(find.text('Đã ghi nhận Exception thành công lên Crashlytics!'), findsOneWidget);
    },
  );
}
