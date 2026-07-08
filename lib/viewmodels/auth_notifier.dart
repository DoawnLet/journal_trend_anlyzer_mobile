import 'package:flutter/material.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';

/// Notifier quản lý trạng thái xác thực người dùng (Auth ViewModel)
class AuthNotifier extends ChangeNotifier {
  final MockFirebaseService _firebaseService = MockFirebaseService.instance;

  AuthNotifier() {
    _firebaseService.addListener(_onAuthServiceChanged);
  }

  @override
  void dispose() {
    _firebaseService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }

  void _onAuthServiceChanged() {
    notifyListeners();
  }

  /// Trạng thái đăng nhập hiện tại
  bool get isSignedIn => _firebaseService.isSignedIn;

  /// Thông tin người dùng hiện tại
  MockFirebaseUser? get currentUser => _firebaseService.currentUser;

  /// Biến trạng thái loading khi đang đăng nhập
  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  /// Thông báo lỗi đăng nhập gần nhất
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Xóa thông báo lỗi cũ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Đăng nhập bằng tài khoản Google thực tế
  Future<bool> signInWithGoogle() async {
    _isLoggingIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _firebaseService.signInWithGoogle();
      if (!success) {
        _errorMessage = 'Đăng nhập bị hủy bởi người dùng.';
      }
      return success;
    } catch (e) {
      _errorMessage = _parseAuthError(e);
      return false;
    } finally {
      _isLoggingIn = false;
      notifyListeners();
    }
  }

  /// Đăng xuất khỏi ứng dụng
  void signOut() {
    _firebaseService.signOut();
  }

  /// Phân tích thông tin lỗi xác thực thực tế
  String _parseAuthError(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('sign_in_failed') && (errorStr.contains('10') || errorStr.contains('12500'))) {
      return 'Lỗi cấu hình Google Sign-In (API Exception 10/12500). Bạn cần thêm mã vân tay SHA-1 của thiết bị vào cài đặt ứng dụng Android trên Firebase Console.';
    } else if (errorStr.contains('network_error') || errorStr.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối Internet và thử lại.';
    } else if (errorStr.contains('sign_in_canceled') || errorStr.contains('user-cancelled') || errorStr.contains('canceled')) {
      return 'Đăng nhập bị hủy bởi người dùng.';
    } else if (errorStr.contains('user-disabled')) {
      return 'Tài khoản này đã bị vô hiệu hóa trong Firebase Console.';
    }
    return 'Đăng nhập thất bại: $e';
  }
}
