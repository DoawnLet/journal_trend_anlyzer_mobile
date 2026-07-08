import 'package:flutter/material.dart';

/// Lớp lưu trữ toàn bộ các hằng số màu sắc của ứng dụng theo đặc tả
/// trong AGENT.md và các màu sắc bổ trợ chuẩn Material 3.
class AppColors {
  AppColors._();

  // --- Bảng màu chính từ AGENT.md (đã điều chỉnh) ---

  /// Màu nền chính (Green Teal) - `#235C5C` (rgb(35, 92, 92))
  static const Color background = Color(0xFF235C5C);

  /// Màu nền tối cho Dark Mode
  static const Color darkBackground = Color(0xFF102828);

  /// Chữ chính / Tiêu đề (Deep Navy Blue / White tùy theme) - `#0B2545`
  static const Color primaryText = Color(0xFF0B2545);

  /// Chữ phụ / Nhãn phụ (Slate Navy) - `#243A57`
  static const Color secondaryText = Color(0xFF243A57);

  /// Nút bấm / Icon lớn / Chữ cỡ đại (White) - `#FFFFFF`
  static const Color whiteAccent = Color(0xFFFFFFFF);

  // --- Các màu sắc bổ trợ chuẩn thiết kế Glassmorphism & Material 3 ---

  /// Màu trắng nền Glassmorphic (bán trong suốt)
  static final Color glassBackground = Colors.white.withOpacity(0.15);

  /// Màu trắng viền Glassmorphic (bán trong suốt để tạo hiệu ứng nổi cạnh)
  static final Color glassBorder = Colors.white.withOpacity(0.25);

  /// Màu bóng đổ mịn
  static final Color shadow = const Color(0xFF0B2545).withOpacity(0.08);

  /// Màu sắc báo lỗi (Error)
  static const Color error = Color(0xFFBA1A1A);

  /// Màu sắc thông báo thành công (Success)
  static const Color success = Color(0xFF2E7D32);

  /// Màu sắc cảnh báo (Warning)
  static const Color warning = Color(0xFFED6C02);

  /// Màu sắc thông tin (Info)
  static const Color info = Color(0xFF0288D1);
}
