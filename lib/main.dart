import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_middleware.dart';
import 'views/state_management/shared_state.dart';
import 'widget_tree.dart';

Future<void> main() async {
  // Đảm bảo Flutter framework được khởi tạo hoàn chỉnh trước khi load assets
  WidgetsFlutterBinding.ensureInitialized();

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
    return ListenableBuilder(
      listenable: SharedState.themeModeNotifier,
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
          home: const WidgetTree(),
        );
      },
    );
  }
}
