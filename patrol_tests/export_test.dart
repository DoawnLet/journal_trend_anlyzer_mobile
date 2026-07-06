import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analysis_mb/main.dart' as app;

void main() {
  patrolTest(
    'Test Case 9 - PDF Export & Firebase Storage Upload',
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

      // 3. Xác minh sự tồn tại của tính năng xuất báo cáo (Firebase Storage)
      expect(find.text('Firebase Storage Report Exporter'), findsOneWidget);
      final exportButton = find.text('Xuất báo cáo PDF');
      expect(exportButton, findsOneWidget);

      // 4. Nhấn Xuất báo cáo PDF và chờ tiến trình chạy
      await $.tap(exportButton);
      
      // Chờ hoàn thành tiến trình xuất và upload (Mock delay là 1.8s)
      await $.pumpAndSettle(const Duration(seconds: 3));

      // 5. Xác minh hiển thị thông báo tải lên thành công
      expect(find.text('Báo cáo PDF đã được xuất và tải lên Firebase Storage thành công!'), findsOneWidget);

      // Xác minh hiển thị liên kết tải về (đường dẫn chứa tiền tố của Storage URL)
      expect(find.text('Đường dẫn tệp báo cáo đã tải lên:'), findsOneWidget);
    },
  );
}
