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
    final errorStr = e.toString();
    final errorLower = errorStr.toLowerCase();
    if (errorLower.startsWith('no_credential:')) {
      final colonIdx = errorStr.indexOf(':');
      return colonIdx >= 0 ? errorStr.substring(colonIdx + 1).trim() : 'Chưa đăng nhập tài khoản Google trên thiết bị.';
    }
    if (errorLower.startsWith('sign_in_cancelled:')) {
      final colonIdx = errorStr.indexOf(':');
      return colonIdx >= 0 ? errorStr.substring(colonIdx + 1).trim() : 'Đăng nhập bị hủy bởi người dùng.';
    }
    if (errorLower.contains('sign_in_failed') && (errorLower.contains('10') || errorLower.contains('12500'))) {
      return 'Lỗi cấu hình Google Sign-In (API Exception 10/12500). Bạn cần thêm mã vân tay SHA-1 của thiết bị vào cài đặt ứng dụng Android trên Firebase Console.';
    } else if (errorLower.contains('network_error') || errorLower.contains('network-request-failed')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại kết nối Internet và thử lại.';
    } else if (errorLower.contains('sign_in_canceled') || errorLower.contains('user-cancelled') || errorLower.contains('canceled')) {
      return 'Đăng nhập bị hủy bởi người dùng.';
    } else if (errorLower.contains('user-disabled')) {
      return 'Tài khoản này đã bị vô hiệu hóa trong Firebase Console.';
    }
    return 'Đăng nhập thất bại: $e';
  }
}
