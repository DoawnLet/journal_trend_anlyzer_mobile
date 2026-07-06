import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'firebase_auth_service.dart';

/// Lớp đại diện cho User mock của ứng dụng
class MockFirebaseUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;

  const MockFirebaseUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });
}

/// Lớp đại diện cho Notification mock
class MockNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });
}

/// Lớp lưu trữ thông tin sự kiện Analytics được ghi nhận
class MockAnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  const MockAnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
}

/// Dịch vụ quản lý Mock Firebase tập trung toàn cục
class MockFirebaseService extends ChangeNotifier {
  // Singleton pattern
  MockFirebaseService._() {
    // Thêm một số thông báo mặc định ban đầu
    _notifications.addAll([
      MockNotification(
        id: '1',
        title: 'New trending research topic',
        body: 'Deep Learning trends show a 40% growth in publications this year.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MockNotification(
        id: '2',
        title: 'Highly cited publication alert',
        body: '"Attention Is All You Need" reached 150,000+ citations.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Lắng nghe thay đổi trạng thái xác thực từ Firebase thực tế để đồng bộ
    try {
      FirebaseAuthService.instance.authStateChanges.listen((User? firebaseUser) {
        final oldUser = _currentUser;
        if (firebaseUser != null) {
          _currentUser = MockFirebaseUser(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? 'Google User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80',
          );
          // Ghi nhận sự kiện Analytics nếu chuyển từ chưa đăng nhập sang đã đăng nhập
          if (oldUser == null) {
            logAnalyticsEvent(
              name: 'login',
              parameters: {
                'method': 'google_sign_in',
                'email': _currentUser!.email,
                'uid': _currentUser!.uid,
              },
            );
          }
        } else {
          _currentUser = null;
          // Ghi nhận sự kiện Analytics nếu chuyển từ đã đăng nhập sang đăng xuất
          if (oldUser != null) {
            logAnalyticsEvent(
              name: 'logout',
              parameters: {
                'email': oldUser.email,
                'uid': oldUser.uid,
              },
            );
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[MockFirebaseService] Real Firebase Auth listener failed (expected in tests): $e');
    }
  }
  static final MockFirebaseService instance = MockFirebaseService._();

  // --- 1. AUTHENTICATION STATE ---
  MockFirebaseUser? _currentUser;
  MockFirebaseUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<bool> signInWithGoogle() async {
    final result = await FirebaseAuthService.instance.signInWithGoogle();
    return result != null;
  }

  void signOut() {
    FirebaseAuthService.instance.signOut();
  }

  // --- 2. ANALYTICS ---
  final List<MockAnalyticsEvent> _analyticsEvents = [];
  List<MockAnalyticsEvent> get loggedEvents => List.unmodifiable(_analyticsEvents);

  void logAnalyticsEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    final event = MockAnalyticsEvent(
      name: name,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    );
    _analyticsEvents.insert(0, event); // Đưa lên đầu danh sách
    debugPrint('[Firebase Analytics] Event logged: "$name" with parameters: $parameters');
    notifyListeners();
  }

  // --- 3. REMOTE CONFIG ---
  int _maxJournalsDisplayed = 5;
  int _maxKeywordsDisplayed = 10;

  int get maxJournalsDisplayed => _maxJournalsDisplayed;
  int get maxKeywordsDisplayed => _maxKeywordsDisplayed;

  void updateRemoteConfig({required int maxJournals, required int maxKeywords}) {
    _maxJournalsDisplayed = maxJournals;
    _maxKeywordsDisplayed = maxKeywords;
    debugPrint('[Firebase Remote Config] Config updated. max_journals=$maxJournals, max_keywords=$maxKeywords');
    notifyListeners();
  }

  // --- 4. CLOUD STORAGE ---
  final List<Map<String, dynamic>> _uploadedFiles = [];
  List<Map<String, dynamic>> get uploadedFiles => List.unmodifiable(_uploadedFiles);

  Future<String> uploadPdfReport(String topicName, List<int> bytes) async {
    // Giả lập độ trễ tải lên 1.8s
    await Future.delayed(const Duration(milliseconds: 1800));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'reports/report_${topicName.replaceAll(' ', '_')}_$timestamp.pdf';
    final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/journal-trend-analyzer.appspot.com/o/${Uri.encodeComponent(fileName)}?alt=media';

    _uploadedFiles.insert(0, {
      'fileName': fileName,
      'topic': topicName,
      'url': downloadUrl,
      'sizeBytes': bytes.length,
      'uploadedAt': DateTime.now(),
    });

    logAnalyticsEvent(
      name: 'export_pdf',
      parameters: {
        'topic': topicName,
        'file_name': fileName,
        'size_bytes': bytes.length,
      },
    );

    notifyListeners();
    return downloadUrl;
  }

  // --- 5. CLOUD MESSAGING (FCM) ---
  final List<MockNotification> _notifications = [];
  List<MockNotification> get notifications => List.unmodifiable(_notifications);

  void simulateIncomingNotification(String title, String body) {
    final notification = MockNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notification);
    debugPrint('[Firebase Messaging] Notification received: $title - $body');
    notifyListeners();
  }

  // --- 6. CRASHLYTICS ---
  final List<Map<String, dynamic>> _loggedExceptions = [];
  List<Map<String, dynamic>> get loggedExceptions => List.unmodifiable(_loggedExceptions);

  void logHandledException(dynamic exception, [StackTrace? stackTrace]) {
    final log = {
      'exception': exception.toString(),
      'stackTrace': stackTrace?.toString() ?? 'No StackTrace available',
      'timestamp': DateTime.now(),
    };
    _loggedExceptions.insert(0, log);
    debugPrint('[Firebase Crashlytics] Exception logged: $exception');
    notifyListeners();
  }

  void triggerTestCrash() {
    debugPrint('[Firebase Crashlytics] Triggering test crash...');
    // Quăng ra lỗi chưa được xử lý để làm crash app
    throw StateError('This is a simulated fatal crash generated for Firebase Crashlytics testing.');
  }
}
