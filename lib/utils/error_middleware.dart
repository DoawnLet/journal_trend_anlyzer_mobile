import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:journal_trend_analysis_mb/utils/error_translator.dart';

/// Middleware xử lý lỗi hệ thống toàn cục cho ứng dụng.
/// Tập trung thu gom các lỗi hiển thị (render) và lỗi bất đồng bộ (async exceptions) tại một nơi.
class ErrorMiddleware {
  ErrorMiddleware._();

  /// Đăng ký các bộ lắng nghe lỗi của hệ thống.
  static void init() {
    // 1. Xử lý lỗi dựng hình giao diện (Render/Build Errors) của Flutter framework
    ErrorWidget.builder = _buildErrorWidget;

    // 2. Bắt các lỗi bất đồng bộ chưa được xử lý khác (Uncaught Asynchronous Errors) ở tầng máy ảo Dart
    PlatformDispatcher.instance.onError = _handleAsyncError;
  }

  /// Trình dựng giao diện thay thế khi xảy ra lỗi Render/Build
  static Widget _buildErrorWidget(FlutterErrorDetails details) {
    // Sử dụng bộ chuyển dịch lỗi toàn cục để đưa ra thông báo thân thiện
    final String friendlyMsg = ErrorTranslator.translate(details.exception);

    return Material(
      color: const Color(0xFF235C5C), // Màu nền Green Teal đồng bộ với theme
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 54),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi hiển thị giao diện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                friendlyMsg,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bộ xử lý và ghi nhận lỗi bất đồng bộ toàn cục
  static bool _handleAsyncError(Object error, StackTrace stack) {
    final errorStr = error.toString();
    if (errorStr.contains('Failed to load font') || errorStr.contains('fonts.gstatic.com')) {
      // Bỏ qua lỗi tải font của Google Fonts để tránh làm loãng log lỗi hệ thống
      return true;
    }
    
    debugPrint('ErrorMiddleware - Đã bắt được lỗi bất đồng bộ toàn cục: $error');
    // Trả về true để thông báo lỗi đã được xử lý và ngăn chặn sập ứng dụng
    return true;
  }
}
