import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dịch vụ xác thực sử dụng Firebase Auth và Google Sign-In thực tế trên Android
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['openid', 'email', 'profile'],
  );

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Lấy thông tin người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// Trạng thái đã đăng nhập hay chưa
  bool get isSignedIn => _auth.currentUser != null;

  /// Đăng ký lắng nghe sự thay đổi trạng thái xác thực
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng tài khoản Google thực tế
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Thử đăng nhập im lặng trước (không hiện dialog)
      final alreadySignedIn = await _googleSignIn.isSignedIn();
      debugPrint('[FirebaseAuthService] Already signed in with Google: $alreadySignedIn');

      // 2. Kích hoạt hộp thoại đăng nhập Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[FirebaseAuthService] Google sign-in returned null (user cancelled).');
        return null;
      }

      // 3. Lấy thông tin xác thực từ tài khoản Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Tạo credential đăng nhập Firebase từ ID Token
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // 5. Đăng nhập vào Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('[FirebaseAuthService] Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      debugPrint('[FirebaseAuthService] Error during Google Sign-In: $e');
      if (errorStr.contains('network') || errorStr.contains('network-error')) {
        throw Exception('NETWORK_ERROR:Lỗi kết nối mạng. Vui lòng kiểm tra Internet.');
      }
      if (errorStr.contains('sign_in_canceled') || errorStr.contains('user_cancelled') ||
          errorStr.contains('sign_in_required') || errorStr.contains('sign_in_cancelled')) {
        throw Exception('SIGN_IN_CANCELLED:Đăng nhập bị hủy hoặc chưa đăng nhập Google trên thiết bị.');
      }
      if (errorStr.contains('sign_in_failed') || errorStr.contains('12500') || errorStr.contains('10 ')) {
        throw Exception(
          'CONFIG_ERROR:Lỗi cấu hình Google Sign-In (API Exception). Hãy chắc chắn SHA-1 đã được thêm vào Firebase Console.',
        );
      }
      rethrow;
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('[FirebaseAuthService] Successfully signed out.');
    } catch (e) {
      debugPrint('[FirebaseAuthService] Error during signOut: $e');
      rethrow;
    }
  }
}
