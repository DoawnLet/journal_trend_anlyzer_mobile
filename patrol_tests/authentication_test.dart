import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 1 & 11 - Google Sign-In & Logout',
    ($) async {
      // 1. Khởi chạy ứng dụng
      app.main();
      await $.pumpAndSettle();

      // Xác minh đang ở màn hình Đăng nhập (LoginPage)
      expect(find.text('Journal Trend Analyzer'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);

      // 2. Thực hiện nhấn Đăng nhập bằng Google
      await $(#googleSignInButton).tap(); // Hoặc tìm theo văn bản nếu nút không có key
      // Hỗ trợ tìm theo text nếu không dùng key
      if (find.text('Sign in with Google').evaluate().isNotEmpty) {
        await $.tap(find.text('Sign in with Google'));
      }
      
      // Chờ tiến trình đăng nhập (1.2s mock delay) hoàn tất
      await $.pumpAndSettle(const Duration(seconds: 2));

      // 3. Xác minh điều hướng thành công vào Trang chủ (Home Screen)
      // Màn hình chính sẽ có tiêu đề "Tổng quan" (hoặc "Overview" tùy ngôn ngữ)
      expect(find.text('Overview'), findsOneWidget);

      // 4. Di chuyển sang tab Cá nhân (Profile tab - chỉ mục index 3)
      // Tìm icon person đại diện tab Cá nhân và tap
      await $(Icons.person_rounded).tap();
      await $.pumpAndSettle();

      // Xác minh đã sang màn hình cá nhân thành công
      expect(find.text('Firebase Remote Config Demo'), findsOneWidget);

      // 5. Thực hiện nhấn Đăng xuất (Logout)
      await $(Icons.logout_rounded).tap();
      await $.pumpAndSettle();

      // 6. Xác minh đã bị đẩy ngược lại màn hình đăng nhập
      expect(find.text('Journal Trend Analyzer'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    },
  );
}
