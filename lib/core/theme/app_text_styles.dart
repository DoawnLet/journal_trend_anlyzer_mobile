import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Lớp lưu trữ các cấu hình Typography (Kiểu chữ) cho ứng dụng.
/// Sử dụng font chữ hiện đại Google Fonts (Outfit) kết hợp với bảng màu đặc tả.
class AppTextStyles {
  AppTextStyles._();

  // --- Display Styles (Dành cho tiêu đề cực lớn, số liệu lớn trên Dashboard) ---

  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    color: AppColors.whiteAccent,
    height: 1.12,
  );

  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    color: AppColors.whiteAccent,
    height: 1.16,
  );

  static TextStyle displaySmall = GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.whiteAccent,
    height: 1.22,
  );

  // --- Headline Styles (Dành cho tiêu đề trang hoặc khối lớn) ---

  static TextStyle headlineLarge = GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.whiteAccent,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.whiteAccent,
    height: 1.29,
  );

  static TextStyle headlineSmall = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteAccent,
    height: 1.33,
  );

  // --- Title Styles (Dành cho tiêu đề bài báo, tiêu đề card, v.v.) ---

  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteAccent,
    height: 1.27,
  );

  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteAccent,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle titleSmall = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.whiteAccent.withOpacity(0.7),
    height: 1.43,
    letterSpacing: 0.1,
  );

  // --- Body Styles (Dành cho nội dung bài viết, tóm tắt abstract, v.v.) ---

  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.whiteAccent,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.whiteAccent.withOpacity(0.8),
    height: 1.43,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.whiteAccent.withOpacity(0.65),
    height: 1.33,
    letterSpacing: 0.4,
  );

  // --- Label Styles (Dành cho nhãn nút bấm, tag chips, v.v.) ---

  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.whiteAccent,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.whiteAccent.withOpacity(0.7),
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.whiteAccent.withOpacity(0.6),
    height: 1.45,
    letterSpacing: 0.5,
  );

  /// Tạo một `TextTheme` hoàn chỉnh dựa trên cấu hình trên để gán vào `ThemeData`
  static TextTheme getTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
