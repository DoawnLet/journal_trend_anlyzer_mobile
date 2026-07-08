import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:journal_trend_analysis_mb/theme/app_theme.dart';
import 'package:journal_trend_analysis_mb/utils/error_middleware.dart';
import 'package:journal_trend_analysis_mb/screens/login_page.dart';
import 'package:journal_trend_analysis_mb/viewmodels/auth_notifier.dart';
import 'package:journal_trend_analysis_mb/viewmodels/shared_state.dart';
import 'package:journal_trend_analysis_mb/widget_tree.dart';
import 'package:journal_trend_analysis_mb/services/mock_firebase_service.dart';

Future<void> main() async {
  // Đảm bảo Flutter framework được khởi tạo hoàn chỉnh trước khi load assets
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Khởi tạo các dịch vụ Firebase thật (Storage, Remote Config, FCM, Crashlytics)
  await MockFirebaseService.instance.initRealFirebase();

  // Khởi tạo hệ thống xử lý lỗi toàn cục thông qua Middleware
  ErrorMiddleware.init();

  // Tải các biến cấu hình môi trường từ file .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không tìm thấy file .env hoặc lỗi tải: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthNotifier>(
      create: (_) => AuthNotifier(),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          SharedState.themeModeNotifier,
          SharedState.languageNotifier,
        ]),
        builder: (context, _) {
          return MaterialApp(
            title: 'Journal Trend Analyzer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: SharedState.themeModeNotifier.value,
            builder: (context, child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: child,
              );
            },
            home: Consumer<AuthNotifier>(
              builder: (context, auth, _) {
                return auth.isSignedIn ? const WidgetTree() : const LoginPage();
              },
            ),
          );
        },
      ),
    );
  }
}
