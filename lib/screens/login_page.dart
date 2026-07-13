import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:journal_trend_analysis_mb/theme/app_colors.dart';
import 'package:journal_trend_analysis_mb/utils/translation.dart';
import 'package:journal_trend_analysis_mb/viewmodels/auth_notifier.dart';
import 'package:journal_trend_analysis_mb/widgets/glass_card.dart';

/// Màn hình đăng nhập (Login Screen) theo phong cách thiết kế Glassmorphism
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final success = await authNotifier.signInWithGoogle();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('welcome_user'.tr().replaceAll('{name}', authNotifier.currentUser?.displayName ?? '')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMsg = authNotifier.errorMessage ?? 'login_failed_try_again'.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF102828),
                    const Color(0xFF071926),
                  ]
                : [
                    const Color(0xFF235C5C),
                    const Color(0xFF0F364A),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Họa tiết trang trí phát sáng tròn (Glow details)
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF80CBC4).withOpacity(0.12),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00ACC1).withOpacity(0.1),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

              // Nội dung chính
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo / Icon
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.science_rounded,
                              size: 64,
                              color: Color(0xFF80CBC4),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tên ứng dụng
                          Text(
                            'Journal Trend Analyzer',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              textStyle: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Glassmorphic Login Card
                          GlassCard(
                            borderRadius: 24.0,
                            blurSigma: 16.0,
                            color: Colors.white.withOpacity(0.08),
                            borderColor: Colors.white.withOpacity(0.12),
                            borderWidth: 1.0,
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Security Lock Badge
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF80CBC4).withOpacity(0.1),
                                      border: Border.all(
                                        color: const Color(0xFF80CBC4).withOpacity(0.2),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFF80CBC4),
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'welcome_to_portal'.tr().isEmpty 
                                      ? 'Cổng Thông Tin Học Thuật' 
                                      : 'welcome_to_portal'.tr(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'sign_in_desc'.tr().isEmpty
                                      ? 'Đăng nhập để xem thống kê xu hướng xuất bản, quản lý hồ sơ và trải nghiệm dịch vụ đám mây.'
                                      : 'sign_in_desc'.tr(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.65),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Google Sign-In Button
                                Consumer<AuthNotifier>(
                                  builder: (context, auth, _) {
                                    if (auth.isLoggingIn) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12.0),
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF80CBC4),
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        key: const Key('googleSignInButton'),
                                        onPressed: () => _handleGoogleSignIn(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF0F2537),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildGoogleIcon(),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Sign in with Google',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: const Color(0xFF1E293B),
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          // Chú thích chân trang
                          Text(
                            'PRM393 - Mobile Programming',
                            style: GoogleFonts.inter(
                              textStyle: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white38,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double length = size.width;
    final double arcThickness = length / 4.5;
    final double halfThickness = arcThickness / 2;
    final bounds = Rect.fromLTRB(
      halfThickness,
      halfThickness,
      length - halfThickness,
      length - halfThickness,
    );
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcThickness
      ..isAntiAlias = true;

    void drawArc(double startAngle, double sweepAngle, Color color) {
      canvas.drawArc(bounds, startAngle, sweepAngle, false, paint..color = color);
    }

    drawArc(3.5, 1.9, const Color(0xFFEA4335)); // Red
    drawArc(2.5, 1.0, const Color(0xFFFBBC05)); // Amber/Yellow
    drawArc(0.9, 1.6, const Color(0xFF34A853)); // Green
    drawArc(-0.18, 1.18, const Color(0xFF4285F4)); // Blue

    final center = bounds.center;
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
      
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - (arcThickness / 2),
        length - halfThickness + 0.5,
        center.dy + (arcThickness / 2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
