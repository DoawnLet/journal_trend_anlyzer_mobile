import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_middleware.dart';
import 'views/pages/login_page.dart';
import 'views/state_management/auth_notifier.dart';
import 'views/state_management/shared_state.dart';
import 'widget_tree.dart';
import 'core/services/mock_firebase_service.dart';

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
