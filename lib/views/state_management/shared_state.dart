import 'package:flutter/material.dart';

/// Lưu trữ trạng thái chia sẻ toàn cục giữa các trang.
/// Đảm bảo quy tắc duy nhất về trạng thái tìm kiếm (Unified State Rule).
class SharedState {
  SharedState._();

  /// Quản lý từ khóa tìm kiếm chủ đề đang hoạt động toàn cục.
  /// Mặc định ban đầu là "Artificial Intelligence".
  static final ValueNotifier<String> activeQueryNotifier = ValueNotifier<String>('Artificial Intelligence');

  /// Quản lý chế độ giao diện sáng/tối (Light/Dark Mode).
  /// Mặc định là ThemeMode.light.
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
}
