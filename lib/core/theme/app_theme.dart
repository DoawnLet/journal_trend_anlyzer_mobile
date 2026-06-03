import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Lớp cấu hình hệ thống giao diện (ThemeData) chính cho ứng dụng.
/// Thiết lập tương thích hoàn toàn với Material 3, hỗ trợ chuyển đổi Light/Dark Mode
/// và sử dụng tông nền Green Teal `#235C5C` (rgb(35, 92, 92)) đặc tả.
class AppTheme {
  AppTheme._();

  /// Giao diện sáng (Light Theme) chủ đạo với nền Green Teal `#235C5C`
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      
      // Cấu hình bảng màu chuẩn Material 3 (Độ tương phản cao cho nền xanh tối)
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.whiteAccent, // Màu chính (Trắng)
        onPrimary: AppColors.primaryText, // Chữ Navy đậm trên nền chính
        secondary: Color(0xFF80CBC4), // Xanh bạc hà sáng làm màu nhấn phụ
        onSecondary: AppColors.primaryText,
        background: AppColors.background, // Nền Green Teal rgb(35, 92, 92)
        onBackground: AppColors.whiteAccent,
        surface: Color(0xFF1A4747), // Bề mặt tối hơn nền một chút
        onSurface: AppColors.whiteAccent,
        error: AppColors.error,
        onError: AppColors.whiteAccent,
      ),

      // Cấu hình Font chữ và Typography
      textTheme: AppTextStyles.getTextTheme(),

      // Cấu hình AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.whiteAccent),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.whiteAccent,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Cấu hình các thẻ Card mặc định (Áp dụng phong cách kính mờ)
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.12),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
        ),
      ),

      // Cấu hình các trường nhập liệu (TextField & SearchBar)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        hoverColor: Colors.white.withOpacity(0.22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.whiteAccent,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteAccent.withOpacity(0.8)),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteAccent.withOpacity(0.5)),
      ),

      // Cấu hình ElevatedButton (Nút chính - Nền trắng chữ Navy đậm)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whiteAccent,
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryText),
        ),
      ),

      // Cấu hình OutlinedButton (Nút viền - Viền trắng chữ trắng)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.whiteAccent,
          side: const BorderSide(color: AppColors.whiteAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.whiteAccent),
        ),
      ),

      // Cấu hình TextButton (Nút chữ trắng)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.whiteAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.whiteAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Cấu hình BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.whiteAccent,
        unselectedItemColor: Colors.white60,
      ),

      // Cấu hình các nhãn dán Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.15),
        disabledColor: Colors.transparent,
        selectedColor: AppColors.whiteAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.whiteAccent,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryText,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Giao diện tối (Dark Theme) với nền Green Teal đậm tối `#102828`
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF80CBC4), // Xanh ngọc sáng
        onPrimary: AppColors.primaryText,
        secondary: Color(0xFF4DB6AC),
        onSecondary: AppColors.primaryText,
        background: AppColors.darkBackground,
        onBackground: AppColors.whiteAccent,
        surface: Color(0xFF141F1F),
        onSurface: AppColors.whiteAccent,
        error: AppColors.error,
        onError: AppColors.whiteAccent,
      ),

      // Cấu hình Font chữ và Typography
      textTheme: AppTextStyles.getTextTheme(),

      // Cấu hình AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.whiteAccent),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.whiteAccent,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Thẻ Card kính mờ tối màu hơn
      cardTheme: CardThemeData(
        color: Colors.black.withOpacity(0.25),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1.0,
          ),
        ),
      ),

      // Cấu hình trường nhập liệu trong chế độ tối
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        hoverColor: Colors.black.withOpacity(0.28),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Color(0xFF80CBC4),
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2.0,
          ),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteAccent.withOpacity(0.7)),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.whiteAccent.withOpacity(0.4)),
      ),

      // Cấu hình ElevatedButton chế độ tối
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF80CBC4),
          foregroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryText),
        ),
      ),

      // Cấu hình OutlinedButton chế độ tối
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF80CBC4),
          side: const BorderSide(color: Color(0xFF80CBC4), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF80CBC4)),
        ),
      ),

      // Cấu hình TextButton chế độ tối
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF80CBC4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: const Color(0xFF80CBC4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Cấu hình BottomNavigationBar cho Dark Mode
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Color(0xFF80CBC4),
        unselectedItemColor: Colors.white54,
      ),

      // Cấu hình Chip chế độ tối
      chipTheme: ChipThemeData(
        backgroundColor: Colors.black.withOpacity(0.2),
        disabledColor: Colors.transparent,
        selectedColor: const Color(0xFF80CBC4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.whiteAccent,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primaryText,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
    );
  }
}
