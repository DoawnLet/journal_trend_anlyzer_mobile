import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Dịch vụ xác thực sử dụng Firebase Auth và Google Sign-In thực tế trên Android
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

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
      // 1. Khởi tạo Google Sign-in (bắt buộc đối với google_sign_in v7.0+)
      await GoogleSignIn.instance.initialize();

      // 2. Kích hoạt hộp thoại đăng nhập của Google
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3. Lấy thông tin xác thực (đồng bộ trong v7.0+)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Tạo credential đăng nhập Firebase từ ID Token
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Đăng nhập vào Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('[FirebaseAuthService] Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e, stack) {
      debugPrint('[FirebaseAuthService] Error during Google Sign-In: $e');
      debugPrint('Stacktrace: $stack');
      rethrow;
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      debugPrint('[FirebaseAuthService] Successfully signed out.');
    } catch (e) {
      debugPrint('[FirebaseAuthService] Error during signOut: $e');
      rethrow;
    }
  }
}
