import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:journal_trend_analysis_mb/services/firebase_auth_service.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';

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
  final String? url;
  final String? publicationTitle;
  final String? journalName;

  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.url,
    this.publicationTitle,
    this.journalName,
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

/// Dịch vụ quản lý Firebase tích hợp thực tế kết hợp mock dự phòng toàn cục
class MockFirebaseService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  // Singleton pattern
  MockFirebaseService._() {
    // Thêm một số thông báo mặc định ban đầu
    _notifications.addAll([
      MockNotification(
        id: '1',
        title: 'New trending research topic',
        body:
            'Deep Learning trends show a 40% growth in publications this year.',
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
      FirebaseAuthService.instance.authStateChanges.listen((
        User? firebaseUser,
      ) {
        final oldUser = _currentUser;
        if (firebaseUser != null) {
          _currentUser = MockFirebaseUser(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? 'Google User',
            email: firebaseUser.email ?? '',
            photoUrl:
                firebaseUser.photoURL ??
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150&q=80',
          );
          // Ghi nhận sự kiện Analytics
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
          // Ghi nhận sự kiện Analytics
          if (oldUser != null) {
            logAnalyticsEvent(
              name: 'logout',
              parameters: {'email': oldUser.email, 'uid': oldUser.uid},
            );
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint(
        '[MockFirebaseService] Real Firebase Auth listener failed: $e',
      );
    }
  }

  static final MockFirebaseService instance = MockFirebaseService._();

  /// Khởi tạo các dịch vụ Firebase thực tế trên Android/iOS
  Future<void> initRealFirebase() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        // 1. Cấu hình Remote Config thực tế
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setDefaults(<String, dynamic>{
          'max_journals_displayed': 5,
          'max_keywords_displayed': 10,
        });
        await remoteConfig.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(minutes: 1),
            minimumFetchInterval: const Duration(
              minutes: 5,
            ), // Tải nhanh khi test
          ),
        );
        await remoteConfig.fetchAndActivate();
        _maxJournalsDisplayed = remoteConfig.getInt('max_journals_displayed');
        _maxKeywordsDisplayed = remoteConfig.getInt('max_keywords_displayed');

        // Lắng nghe thay đổi cấu hình thời gian thực từ Console
        remoteConfig.onConfigUpdated.listen((event) async {
          await remoteConfig.activate();
          _maxJournalsDisplayed = remoteConfig.getInt('max_journals_displayed');
          _maxKeywordsDisplayed = remoteConfig.getInt('max_keywords_displayed');
          notifyListeners();
        });
        debugPrint(
          '[Firebase Remote Config] Real config loaded: max_journals=$_maxJournalsDisplayed, max_keywords=$_maxKeywordsDisplayed',
        );
      } catch (e) {
        debugPrint('[MockFirebaseService] Real Remote Config init failed: $e');
      }

      try {
        await _initializeLocalNotifications();

        // 2. Thiết lập thông báo FCM thực tế
        final messaging = FirebaseMessaging.instance;
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        await _requestNotificationPermissions();
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

        // Đăng ký nhận tin nhắn từ Topic chung
        await messaging.subscribeToTopic("new_publications");
        debugPrint('[FCM] Subscribed to topic: new_publications');

        // Lấy và in FCM Token để kiểm tra
        final token = await messaging.getToken();
        debugPrint('[FCM] Token: $token');

        // Lắng nghe thông báo ở chế độ foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          await _showSystemNotification(message);
        });

        // Lắng nghe thông báo khi bấm mở app từ khay hệ thống (khi app đang chạy nền)
        FirebaseMessaging.onMessageOpenedApp.listen((
          RemoteMessage message,
        ) async {
          await _showSystemNotification(message);
          // Tự động chuyển hướng sang tab Profile (index 3) để người dùng xem thông báo
          try {
            SharedState.activeTabNotifier.value = 3;
          } catch (e) {
            debugPrint('[FCM] Failed to redirect to Profile tab: $e');
          }
          final publicationUrl = message.data['publication_url']?.toString();
          if (publicationUrl != null && publicationUrl.isNotEmpty) {
            _launchUrlHelper(publicationUrl);
          }
        });

        // Xử lý thông báo khi app bị tắt hoàn toàn (Terminated state) và được mở bởi bấm thông báo
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          final publicationUrl = initialMessage.data['publication_url']?.toString();
          if (publicationUrl != null && publicationUrl.isNotEmpty) {
            _launchUrlHelper(publicationUrl);
          }
        }
      } catch (e) {
        debugPrint('[MockFirebaseService] Real FCM init failed: $e');
      }

      try {
        // 3. Kích hoạt thu thập Crashlytics thực tế
        if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled ==
            false) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
            true,
          );
        }
      } catch (e) {
        debugPrint('[MockFirebaseService] Real Crashlytics init failed: $e');
      }
    }
  }

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
  List<MockAnalyticsEvent> get loggedEvents =>
      List.unmodifiable(_analyticsEvents);

  void logAnalyticsEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    final event = MockAnalyticsEvent(
      name: name,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    );
    _analyticsEvents.insert(0, event);
    debugPrint(
      '[Firebase Analytics] Event logged: "$name" with parameters: $parameters',
    );

    // Gửi sự kiện Analytics thật lên Console nếu có hỗ trợ
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        final Map<String, Object> convertedParams = {};
        parameters?.forEach((key, value) {
          if (value is String || value is num) {
            convertedParams[key] = value;
          } else {
            convertedParams[key] = value.toString();
          }
        });
        FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: convertedParams,
        );
      } catch (e) {
        debugPrint('[Firebase Analytics] Real logEvent failed: $e');
      }
    }

    notifyListeners();
  }

  // --- 3. REMOTE CONFIG ---
  int _maxJournalsDisplayed = 5;
  int _maxKeywordsDisplayed = 10;

  int get maxJournalsDisplayed => _maxJournalsDisplayed;
  int get maxKeywordsDisplayed => _maxKeywordsDisplayed;

  void updateRemoteConfig({
    required int maxJournals,
    required int maxKeywords,
  }) {
    _maxJournalsDisplayed = maxJournals;
    _maxKeywordsDisplayed = maxKeywords;
    debugPrint(
      '[Firebase Remote Config] Local config updated. max_journals=$maxJournals, max_keywords=$maxKeywords',
    );
    notifyListeners();
  }

  // --- 4. CLOUD STORAGE ---
  final List<Map<String, dynamic>> _uploadedFiles = [];
  List<Map<String, dynamic>> get uploadedFiles =>
      List.unmodifiable(_uploadedFiles);

  Future<String> uploadPdfReport(String topicName, List<int> bytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        'reports/report_${topicName.replaceAll(' ', '_')}_$timestamp.pdf';
    String downloadUrl = '';
    const bucketName = 'prm393-2a9d2.appspot.com';

    // Cố gắng tải lên Storage thật nếu chạy trên di động và có kết nối
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = storageRef.putData(
          Uint8List.fromList(bytes),
          SettableMetadata(contentType: 'application/pdf'),
        );
        // Đặt giới hạn timeout 3 giây để tránh bị treo do lỗi liên kết gói cước thanh toán của Firebase
        final snapshot = await uploadTask.timeout(const Duration(seconds: 3));
        downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('[Firebase Storage] Real upload success. URL: $downloadUrl');
      } catch (e) {
        debugPrint(
          '[Firebase Storage] Real upload failed or timed out (using project mock URL): $e',
        );
      }
    }

    // Nếu không tải lên thật được (hoặc trên desktop/web), sinh URL giả lập theo đúng ID project prm393-2a9d2
    if (downloadUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      downloadUrl =
          'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/${Uri.encodeComponent(fileName)}?alt=media';
    }

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

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final url = data['publication_url']?.toString();
            if (url != null && url.isNotEmpty) {
              _launchUrlHelper(url);
            }
          } catch (e) {
            debugPrint('[FCM] Error handling local notification tap payload: $e');
          }
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'journal_trend_channel',
      'Journal Trend Notifications',
      description: 'Notifications for new publications',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _localNotificationsInitialized = true;
  }

  Future<void> _requestNotificationPermissions() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final androidPlugin = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidPlugin?.requestNotificationsPermission();
        debugPrint('[FCM] Local notifications permission granted: $granted');
      } catch (e) {
        debugPrint(
          '[FCM] Failed to request local notifications permission: $e',
        );
      }
    }
  }

  Future<void> _showSystemNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Journal Trend Update';
    final body = message.notification?.body ?? 'You have a new update';
    final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'journal_trend_channel',
          'Journal Trend Notifications',
          channelDescription: 'Notifications for new publications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );

    final publicationUrl = message.data['publication_url']?.toString();
    final publicationTitle = message.data['publication_title']?.toString();
    final journalName = message.data['journal_name']?.toString();
    simulateIncomingNotification(
      title,
      body,
      url: publicationUrl,
      publicationTitle: publicationTitle,
      journalName: journalName,
    );
  }

  void simulateIncomingNotification(
    String title,
    String body, {
    String? url,
    String? publicationTitle,
    String? journalName,
  }) {
    final notification = MockNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      url: url,
      publicationTitle: publicationTitle,
      journalName: journalName,
    );
    _notifications.insert(0, notification);
    debugPrint(
      '[Firebase Messaging] Notification received: $title - $body${url != null ? ' - $url' : ''}',
    );
    notifyListeners();
  }

  Future<void> _launchUrlHelper(String urlStr) async {
    final cleanUrl = urlStr.trim();
    if (cleanUrl.isEmpty) return;
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[FCM] Could not launch URL: $urlStr, error: $e');
      }
    }
  }

  // --- 6. CRASHLYTICS ---
  final List<Map<String, dynamic>> _loggedExceptions = [];
  List<Map<String, dynamic>> get loggedExceptions =>
      List.unmodifiable(_loggedExceptions);

  void logHandledException(dynamic exception, [StackTrace? stackTrace]) {
    final log = {
      'exception': exception.toString(),
      'stackTrace': stackTrace?.toString() ?? 'No StackTrace available',
      'timestamp': DateTime.now(),
    };
    _loggedExceptions.insert(0, log);
    debugPrint('[Firebase Crashlytics] Exception logged: $exception');

    // Gửi báo cáo lỗi handled thật lên Crashlytics
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        FirebaseCrashlytics.instance.recordError(exception, stackTrace);
      } catch (e) {
        debugPrint('[Firebase Crashlytics] Real recordError failed: $e');
      }
    }

    notifyListeners();
  }

  void triggerTestCrash() {
    debugPrint('[Firebase Crashlytics] Triggering test crash...');

    // Gây lỗi sập thật nếu chạy trên di động
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      try {
        FirebaseCrashlytics.instance.crash();
        return;
      } catch (e) {
        debugPrint('[Firebase Crashlytics] Real crash failed: $e');
      }
    }

    // Fallback ném lỗi nội bộ làm sập app
    throw StateError(
      'This is a simulated fatal crash generated for Firebase Crashlytics testing.',
    );
  }
}
